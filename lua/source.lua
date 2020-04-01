local vim = vim
local api = vim.api
local util = require 'utility'
local lsp = require 'source.lsp'
local snippet = require 'source.snippet'
local ins = require 'source.ins_complete'

local M = {}

local complete_items_map = {
  ['lsp'] = {
    trigger = lsp.triggerFunction,
    callback = lsp.getCallback,
    item = lsp.getCompletionItems
  },
  ['snippet'] = {
    item = snippet.getCompletionItems
  },
}

M.chain_complete_index = 1
M.stop_complete = false


local function checkCallback(callback_array)
  for _,val in ipairs(callback_array) do
    if val == false then return false end
    if type(val) == 'function' then
      if val() == false then return end
    end
  end
  return true
end

function M.addCompleteItems(key, complete_item)
  complete_items_map[key] = complete_item
end

local function getCompletionItems(items_array, prefix)
  local complete_items = {}
  for _,func in ipairs(items_array) do
    vim.list_extend(complete_items, func(prefix, util.fuzzy_score))
  end
  return complete_items
end

local function chain_list_to_tree(complete_list)
    if util.is_list(complete_list) then
        return {
            default = {
                default= complete_list
            }
        }
    else
        local complete_tree = {}
        for ft, c_list in pairs(complete_list) do
            if util.is_list(c_list) then
                complete_tree[ft] = {
                    default=c_list
                }
            else
                complete_tree[ft] = c_list
            end
        end

        return complete_tree
    end
end

local function getScopedChain(ft_subtree)

  local function syntaxGroupAtPoint()
      local pos = api.nvim_win_get_cursor(0)
      return vim.fn.synIDattr(vim.fn.synID(pos[1], pos[2]-1, 1), "name")
  end

  local VAR_NAME = "completion_syntax_at_point"

  local syntax_getter

  -- If this option is effectively a function, use it to determine syntax group at point
  if vim.fn.exists("g:" .. VAR_NAME) > 0 and vim.is_callable(api.nvim_get_var(VAR_NAME)) > 0 then
      syntax_getter = api.nvim_get_var(VAR_NAME)
  else
      syntax_getter = syntaxGroupAtPoint
  end

  local atPoint = syntax_getter():lower()
  for syntax_regex, complete_list in pairs(ft_subtree) do
      if string.match(atPoint, '.*' .. syntax_regex:lower() .. '.*') ~= nil and syntax_regex ~= "default" then
          return complete_list
      end
  end

  return nil
end

-- preserve compatiblity of completion_chain_complete_list
local function getChainCompleteList()

  local chain_complete_list = chain_list_to_tree(api.nvim_get_var('completion_chain_complete_list'))
  -- check if chain_complete_list is a array
  
  local filetype = api.nvim_buf_get_option(0, 'filetype')

  return getScopedChain(chain_complete_list[filetype])
    or getScopedChain(chain_complete_list.default)
    or chain_complete_list[filetype].default
    or chain_complete_list.default.default
end

function M.triggerCurrentCompletion(manager, bufnr, prefix, textMatch)
  if manager.insertChar == false then return end
  M.chain_complete_list = getChainCompleteList()
  M.chain_complete_length = #M.chain_complete_list
  if api.nvim_get_mode()['mode'] == 'i' or api.nvim_get_mode()['mode'] == 'ic' then
    local complete_source = M.chain_complete_list[M.chain_complete_index]

    if complete_source == nil then return end

    if vim.fn.has_key(complete_source, "mode") > 0 then
      ins.triggerCompletion(manager, complete_source.mode)
    elseif vim.fn.has_key(complete_source, "complete_items") > 0 then
      local callback_array = {}
      local items_array = {}
      for _, item in ipairs(complete_source.complete_items) do
        local complete_items = complete_items_map[item]
        if complete_items.callback == nil then
          table.insert(callback_array, true)
        else
          table.insert(callback_array, complete_items.callback)
          complete_items.trigger(prefix, textMatch, bufnr, manager)
        end
        table.insert(items_array, complete_items.item)
      end
      local timer = vim.loop.new_timer()
      timer:start(20, 50, vim.schedule_wrap(function()
        if checkCallback(callback_array) == true and timer:is_closing() == false then
          if api.nvim_get_mode()['mode'] == 'i' or api.nvim_get_mode()['mode'] == 'ic' then
            local items = getCompletionItems(items_array, prefix)
            util.sort_completion_items(items)
            if api.nvim_get_var('completion_max_items') ~= nil then
              items = { unpack(items, 1, api.nvim_get_var('completion_max_items'))}
            end
            vim.fn.complete(textMatch+1, items)
            if #items ~= 0 then
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
end

function M.nextCompletion()
  if M.chain_complete_index ~= #M.chain_complete_list then
    M.chain_complete_index = M.chain_complete_index + 1
  else
    M.chain_complete_index = 1
  end
end

function M.prevCompletion()
  if M.chain_complete_index ~= 1 then
    M.chain_complete_index = M.chain_complete_index - 1
  else
    M.chain_complete_index = #M.chain_complete_list
  end
end


return M
