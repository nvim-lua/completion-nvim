local vim = vim
local api = vim.api
local util = require 'utility'
local M = {}


local getUltisnipItems = function(prefix)
  snippetsList = api.nvim_call_function('UltiSnips#SnippetsInCurrentScope', {})
  local complete_items = {}
  if vim.tbl_isempty(snippetsList) then
    return {}
  end
  for key, _ in pairs(snippetsList) do
    -- fix lua parsing issue
    if key == true then
      key = 'true'
    end
    if string.sub(key, 1, #prefix) == prefix then
      table.insert(complete_items, {
        word = key,
        kind = 'UltiSnips',
        icase = 1,
        dup = 1,
        empty = 1,
      })
    end
  end
  return complete_items
end

local getNeosnippetItems = function(prefix)
  snippetsList = api.nvim_call_function('neosnippet#helpers#get_completion_snippets', {})
  local complete_items = {}
  if vim.tbl_isempty(snippetsList) == 0 then
    return {}
  end
  for key, _ in pairs(snippetsList) do
    if key == true then
      key = 'true'
    end
    if string.sub(key, 1, #prefix) == prefix then
      table.insert(complete_items, {
        word = key,
        kind = 'Neosnippet',
        icase = 1,
        dup = 1,
        empty = 1,
      })
    end
  end
  return complete_items
end

M.getSnippetItems = function(prefix)
  local source = api.nvim_get_var('completion_enable_snippet')
  local snippet_list = {}
  if source == 'UltiSnips' then
    snippet_list = getUltisnipItems(prefix)
  elseif source == 'Neosnippet' then
    snippet_list = getNeosnippetItems(prefix)
  end
  return snippet_list
end

M.triggerCompletion = function(manager, bufnr, prefix, textMatch)
  local snippet_list = M.getSnippetItems(prefix)
  util.sort_completion_items(snippet_list)
  print(manager.insertChar)
  if #snippet_list ~= 0 and manager.insertChar == true then
    vim.fn.complete(textMatch+1, snippet_list)
    manager.insertChar = false
  else
    manager.changeSource = true
  end
end

return M
