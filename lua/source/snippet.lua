local vim = vim
local api = vim.api
local util = require 'utility'
local M = {}


local getUltisnipItems = function(prefix, score_func)
  local snippetsList = api.nvim_call_function('UltiSnips#SnippetsInCurrentScope', {})
  local complete_items = {}
  if vim.tbl_isempty(snippetsList) then
    return {}
  end
  for key, val in pairs(snippetsList) do
    -- fix lua parsing issue
    if key == true then
      key = 'true'
    end
    local score = score_func(prefix, key)
    local user_data = {hover = val}
    if score < #prefix/2 then
      table.insert(complete_items, {
        word = key,
        kind = 'UltiSnips',
        score = score,
        icase = 1,
        dup = 1,
        empty = 1,
        user_data = vim.fn.json_encode(user_data)
      })
    end
  end
  return complete_items
end

local getNeosnippetItems = function(prefix, score_func)
  local snippetsList = api.nvim_call_function('neosnippet#helpers#get_completion_snippets', {})
  local complete_items = {}
  if vim.tbl_isempty(snippetsList) == 0 then
    return {}
  end
  for key, _ in pairs(snippetsList) do
    if key == true then
      key = 'true'
    end
	local score = score_func(prefix, key)
    if score < #prefix/2 then
      table.insert(complete_items, {
        word = key,
        kind = 'Neosnippet',
        score = score,
        icase = 1,
        dup = 1,
        empty = 1,
      })
    end
  end
  return complete_items
end

M.getCompletionItems = function(prefix, score_func, _)
  local source = api.nvim_get_var('completion_enable_snippet')
  local snippet_list = {}
  if source == 'UltiSnips' then
    snippet_list = getUltisnipItems(prefix, score_func)
  elseif source == 'Neosnippet' then
    snippet_list = getNeosnippetItems(prefix, score_func)
  end
  return snippet_list
end

M.triggerCompletion = function(manager, _, prefix, textMatch)
  local snippet_list = M.getCompletionItemsItem(prefix)
  util.sort_completion_items(snippet_list)
  if manager.insertChar == true then
    vim.fn.complete(textMatch+1, snippet_list)
    if #snippet_list ~= 0 then
      manager.insertChar = false
      manager.changeSource = false
    else
      manager.changeSource = true
    end
  end
end

return M
