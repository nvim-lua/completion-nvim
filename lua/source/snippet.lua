local vim = vim
local api = vim.api
local M = {}


local getUltisnipItems = function(prefix, score_func)
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
    local score = score_func(prefix, key)
    local user_data = {hover = val}
    if score < #prefix/2 then
      table.insert(complete_items, {
        word = key,
        kind = 'UltiSnips',
        menu = val,
        score = score,
        priority = priority,
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
  if vim.fn.exists("*neosnippet#helpers#get_completion_snippets") == 0 then return {} end
  local snippetsList = api.nvim_call_function('neosnippet#helpers#get_completion_snippets', {})
  local complete_items = {}
  if vim.tbl_isempty(snippetsList) == 0 then
    return {}
  end
  local priority = vim.g.completion_items_priority['Neosnippet'] or 1
  for key, val in pairs(snippetsList) do
    if key == true then
      key = 'true'
    end
    local user_data = {hover = val.description}
    local score = score_func(prefix, key)
      if score < #prefix/2 then
        table.insert(complete_items, {
          word = key,
          kind = 'Neosnippet',
          menu = val.description,
          score = score,
          priority = priority,
          icase = 1,
          dup = 1,
          empty = 1,
          user_data = vim.fn.json_encode(user_data)
        })
      end
    end
  return complete_items
end

M.getCompletionItems = function(prefix, score_func, _)
  local source = vim.g.completion_enable_snippet
  local snippet_list = {}
  if source == 'UltiSnips' then
    snippet_list = getUltisnipItems(prefix, score_func)
  elseif source == 'Neosnippet' then
    snippet_list = getNeosnippetItems(prefix, score_func)
  end
  return snippet_list
end

return M
