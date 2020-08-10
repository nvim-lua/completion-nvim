local vim = vim
local api = vim.api
local match = require'completion.matching'
local M = {}


M.getUltisnipItems = function(prefix)
  if vim.fn.exists("*UltiSnips#SnippetsInCurrentScope") == 0 then return {} end
  local snippetsList = api.nvim_call_function('UltiSnips#SnippetsInCurrentScope', {})
  local complete_items = {}
  if vim.tbl_isempty(snippetsList) then
    return {}
  end
  local priority = vim.g.completion_items_priority['UltiSnips'] or 1
  for key, val in pairs(snippetsList) do
    -- fix lua parsing issue
    if key == true then
      key = 'true'
    end
    local item = {}
    item.word = key
    item.kind = 'UltiSnips'
    item.priority = priority
    local user_data = {hover = val}
    item.user_data = user_data
    match.matching(complete_items, prefix, item)
  end
  return complete_items
end

M.getNeosnippetItems = function(prefix)
  if vim.fn.exists("*neosnippet#helpers#get_completion_snippets") == 0 then return {} end
  local snippetsList = api.nvim_call_function('neosnippet#helpers#get_completion_snippets', {})
  local complete_items = {}
  if vim.tbl_isempty(snippetsList) == 0 then
    return {}
  end
  local priority = vim.g.completion_items_priority['Neosnippet']
  for key, val in pairs(snippetsList) do
    if key == true then
      key = 'true'
    end
    local user_data = {hover = val.description}
    local item = {}
    item.word = key
    item.kind = 'Neosnippet'
    item.priority = priority
    item.user_data = user_data
    match.matching(complete_items, prefix, item)
  end
  return complete_items
end

M.getVsnipItems = function(prefix)
  if vim.fn.exists('g:loaded_vsnip') == 0 then return {} end
  local snippetsList = api.nvim_call_function('vsnip#source#find', {api.nvim_get_current_buf()})
  local complete_items = {}
  if vim.tbl_isempty(snippetsList) == 0 then
    return {}
  end
  local priority = vim.g.completion_items_priority['vim-vsnip']
  for _, source in pairs(snippetsList) do
    for _, snippet in pairs(source) do
      for _, word in pairs(snippet.prefix) do
        local user_data = {hover = snippet.description}
        local item = {}
        item.word = word
        item.kind = 'vim-vsnip'
        item.menu = snippet.label
        item.priority = priority
        item.user_data = user_data
        match.matching(complete_items, prefix, item)
      end
    end
  end
  return complete_items
end

M.getCompletionItems = function(prefix)
  local source = vim.g.completion_enable_snippet
  local snippet_list = {}
  if source == 'UltiSnips' then
    snippet_list = M.getUltisnipItems(prefix)
  elseif source == 'Neosnippet' then
    snippet_list = M.getNeosnippetItems(prefix)
  elseif source == 'vim-vsnip' then
    snippet_list = M.getVsnipItems(prefix)
  end
  return snippet_list
end

return M
