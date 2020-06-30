local vim = vim
local api = vim.api
local util = require 'completion.util'
local ins = require 'completion.source.ins_complete'
local match = require'completion.matching'

local M = {}

local cache_complete_items = {}

local function checkCallback(callback_array)
  for _,val in ipairs(callback_array) do
    if not val then return false end
    if type(val) == 'function' then
      if val() == false then return end
    end
  end
  return true
end

local function getCompletionItems(items_array, prefix)
  local complete_items = {}
  for _,func in ipairs(items_array) do
    vim.list_extend(complete_items, func(prefix))
  end
  return complete_items
end

M.clearCache = function()
  cache_complete_items = {}
end

-- perform completion
M.performComplete = function(complete_source, complete_items_map, manager, opt)

  manager.insertChar = false
  if vim.fn.has_key(complete_source, "mode") > 0 then
    -- ins-complete source
    ins.triggerCompletion(manager, complete_source.mode)
  elseif vim.fn.has_key(complete_source, "complete_items") > 0 then
    if #cache_complete_items == 0 then
      -- use callback_array to handle async behavior
      local callback_array = {}
      local items_array = {}
      -- collect getCompleteItems function of current completion source
      for _, item in ipairs(complete_source.complete_items) do
        local complete_items = complete_items_map[item]
        if complete_items ~= nil then
          if complete_items.callback == nil then
            table.insert(callback_array, true)
          else
            table.insert(callback_array, complete_items.callback)
            complete_items.trigger(manager, opt)
          end
          table.insert(items_array, complete_items.item)
        end
      end

      local timer = vim.loop.new_timer()
      timer:start(20, 50, vim.schedule_wrap(function()
        if manager.insertChar == true and not timer:is_closing() then
          timer:stop()
          timer:close()
        end
        -- only perform complete when callback_array are all true
        if checkCallback(callback_array) == true and timer:is_closing() == false then
          if api.nvim_get_mode()['mode'] == 'i' or api.nvim_get_mode()['mode'] == 'ic' then
            local items = getCompletionItems(items_array, opt.prefix)
            if vim.g.completion_sorting ~= "none" then
              util.sort_completion_items(items)
            end
            if #items ~= 0 then
              -- reset insertChar and handle auto changing source
              cache_complete_items = items
              vim.fn.complete(opt.textMatch+1, items)
              manager.changeSource = false
            else
              manager.changeSource = true
            end
          end
          timer:stop()
          timer:close()
        end
      end))
    else
      if api.nvim_get_mode()['mode'] == 'i' or api.nvim_get_mode()['mode'] == 'ic' then
        local items = {}
        for _, item in ipairs(cache_complete_items) do
          match.matching(items, opt.prefix, item)
        end
        if vim.g.completion_sorting ~= "none" then
          util.sort_completion_items(items)
        end
        if #items ~= 0 then
          -- reset insertChar and handle auto changing source
          cache_complete_items = items
          vim.fn.complete(opt.textMatch+1, items)
          manager.changeSource = false
        else
          cache_complete_items = {}
          manager.changeSource = true
        end
      end
    end
  end
end

return M
