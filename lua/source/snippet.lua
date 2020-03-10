local vim = vim
local api = vim.api
local M = {}

M.getUltisnipItems = function(prefix)
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

return M
