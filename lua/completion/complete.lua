local vim = vim
local api = vim.api
local util = require 'completion.util'
local ins = require 'source.ins_complete'

local M = {}

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
    vim.list_extend(complete_items, func(prefix, util.fuzzy_score))
  end
  return complete_items
end

-- perform completion
M.performComplete = function(complete_source, complete_items_map, manager, bufnr, prefix, textMatch)

  if vim.fn.has_key(complete_source, "mode") > 0 then
    -- ins-complete source
    ins.triggerCompletion(manager, complete_source.mode)
  elseif vim.fn.has_key(complete_source, "complete_items") > 0 then
    -- use callback_array to handle async behavior
    local callback_array = {}
    local items_array = {}
    -- collect getCompleteItems function of current completion source
    for _, item in ipairs(complete_source.complete_items) do
      local complete_items = complete_items_map[item]
      if complete_items == nil then
        goto continue
      end
      if complete_items.callback == nil then
        table.insert(callback_array, true)
      else
        table.insert(callback_array, complete_items.callback)
        complete_items.trigger(prefix, textMatch, bufnr, manager)
      end
      table.insert(items_array, complete_items.item)
      ::continue::
    end

    local timer = vim.loop.new_timer()
    timer:start(20, 50, vim.schedule_wrap(function()
      -- only perform complete when callback_array are all true
      if checkCallback(callback_array) == true and timer:is_closing() == false then
        if api.nvim_get_mode()['mode'] == 'i' or api.nvim_get_mode()['mode'] == 'ic' then
          local items = getCompletionItems(items_array, prefix)
          util.sort_completion_items(items)
          if vim.g.completion_max_items ~= nil then
            items = { unpack(items, 1, vim.g.completion_max_items)}
          end
          vim.fn.complete(textMatch+1, items)
          -- vim.fn.complete_add(items[3])
          if #items ~= 0 then
            -- reset insertChar and handle auto changing source
            manager.insertChar = false
            manager.changeSource = false
          else
            manager.changeSource = true
          end
        end
        timer:stop()
        timer:close()
      end
    end))
  end
end

return M
