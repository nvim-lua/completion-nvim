local vim = vim
local api = vim.api
local match = require'completion.matching'
local opt = require 'completion.option'
local M = {}


M.getUltisnipItems = function(prefix)
  if vim.fn.exists("*UltiSnips#SnippetsInCurrentScope") == 0 then return {} end
  local snippetsList = vim.call('UltiSnips#SnippetsInCurrentScope')
  local complete_items = {}
  if vim.tbl_isempty(snippetsList) then
    return {}
  end
  local priority = vim.g.completion_items_priority['UltiSnips'] or 1
  local kind = 'UltiSnips'
  kind = opt.get_option('customize_lsp_label')[kind] or kind
  for key, val in pairs(snippetsList) do
    local item = {}
    item.word = key
    item.kind = kind
    item.priority = priority
    local user_data = {snippet_source = 'UltiSnips', hover = val}
    item.user_data = user_data
    match.matching(complete_items, prefix, item)
  end
  return complete_items
end

M.getNeosnippetItems = function(prefix)
  if vim.fn.exists("*neosnippet#helpers#get_completion_snippets") == 0 then return {} end
  local snippetsList = vim.call('neosnippet#helpers#get_completion_snippets')
  local complete_items = {}
  if vim.tbl_isempty(snippetsList) == 0 then
    return {}
  end
  local kind = 'Neosnippet'
  kind = opt.get_option('customize_lsp_label')[kind] or kind
  local priority = vim.g.completion_items_priority['Neosnippet']
  for key, val in pairs(snippetsList) do
    local description
    if val == nil or type(val) ~= "table" then description = nil else description = val.description end
    local user_data = {snippet_source = 'Neosnippet', hover = description}
    local item = {}
    item.word = key
    item.kind = kind
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
  local kind = 'vim-vsnip'
  kind = opt.get_option('customize_lsp_label')[kind] or kind
  local priority = vim.g.completion_items_priority['vim-vsnip']
  for _, source in pairs(snippetsList) do
    for _, snippet in pairs(source) do
      for _, word in pairs(snippet.prefix) do
        local user_data = {snippet_source = 'vim-vsnip', hover = snippet.description}
        local item = {}
        item.word = word
        item.kind = kind
        item.menu = snippet.label
        item.priority = priority
        item.user_data = user_data
        match.matching(complete_items, prefix, item)
      end
    end
  end
  return complete_items
end

-- Cribbed almost wholesale from snippets.lookup_snippet()
M.getSnippetsNvimItems = function(prefix)
  local snippets = require 'snippets'
  if not snippets then return {} end
  local ft = vim.bo.filetype
  local snippetsList = vim.tbl_extend('force', snippets.snippets._global or {}, snippets.snippets[ft] or {})
  local complete_items = {}
  if vim.tbl_isempty(snippetsList) == 0 then
    return {}
  end
  local priority = vim.g.completion_items_priority['snippets.nvim'] or 1
  local kind = 'snippets.nvim'
  kind = opt.get_option('customize_lsp_label')[kind] or kind
  for short, long in pairs(snippetsList) do
    -- TODO: We cannot put the parsed snippet itself in userdata, since it may
    -- contain Lua functions (see
    -- https://github.com/norcalli/snippets.nvim#notes-because-this-is-beta-release-software)
    local user_data = {snippet_source = 'snippets.nvim'}
    local item = {}
    item.word = short
    item.kind = kind
    -- TODO: Turn actual snippet text into label/description?
    item.menu = short
    item.priority = priority
    item.user_data = user_data
    match.matching(complete_items, prefix, item)
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
  elseif source == 'snippets.nvim' then
    snippet_list = M.getSnippetsNvimItems(prefix)
  end
  return snippet_list
end

return M
