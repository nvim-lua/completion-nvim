local protocol = require 'vim.lsp.protocol'
local vim = vim
local api = vim.api
local M = {}

function M.is_list(thing)
    return vim.fn.type(thing) == api.nvim_get_vvar("t_list")
end

------------------------------------------------------------------------
--      utility function that are modified from neovim's source       --
------------------------------------------------------------------------

------------------------
--  completion items  --
------------------------
local function get_completion_word(item)
  if item.insertText ~= nil then
    return item.insertText
  elseif item.textEdit ~= nil and item.textEdit.newText ~= nil and item.insertTextFormat ~= 2 then
    return item.textEdit.newText
  end
  return item.label
end

local function remove_unmatch_completion_items(items, prefix)
  return vim.tbl_filter(function(item)
    local word = get_completion_word(item)
    return vim.startswith(word, prefix)
  end, items)
end

function M.sort_completion_items(items)
  table.sort(items, function(a, b)
    if a.score ~= b.score and a.score ~= nil and b.score ~= nil then
      return a.score < b.score
    else
      return string.len(a.word) < string.len(b.word)
    end
  end)
end

function M.text_document_completion_list_to_complete_items(result, prefix)
  local items = vim.lsp.util.extract_completion_items(result)
  local customize_label = api.nvim_get_var('completion_customize_lsp_label')
  if vim.tbl_isempty(items) then
    return {}
  end

  items = remove_unmatch_completion_items(items, prefix)
  -- sort_completion_items(items)

  local matches = {}

  for _, completion_item in ipairs(items) do
    -- skip snippets items
    if api.nvim_get_var('completion_enable_snippet') == nil or
      protocol.CompletionItemKind[completion_item.kind] ~= 'Snippet' then
      local info = ' '
      local documentation = completion_item.documentation
      if documentation then
        if type(documentation) == 'string' and documentation ~= '' then
          info = documentation
        elseif type(documentation) == 'table' and type(documentation.value) == 'string' then
          info = documentation.value
        -- else
          -- TODO(ashkan) Validation handling here?
        end
      end

      local word = get_completion_word(completion_item)
      local user_data = {
        lsp = {
          completion_item = completion_item
        }
      }
      local kind = protocol.CompletionItemKind[completion_item.kind]
      table.insert(matches, {
        word = word,
        abbr = completion_item.label,
        kind = customize_label[kind] or kind or '',
        menu = completion_item.detail or '',
        info = info,
        icase = 1,
        user_data = vim.fn.json_encode(user_data),
        dup = 1,
        empty = 1,
      })
    end
  end

  return matches
end

-- Levenshtein algorithm for fuzzy matching
-- https://gist.github.com/james2doyle/e406180e143da3bdd102
function M.fuzzy_score(str1, str2)
  local len1 = #str1
  local len2 = #str2
  local matrix = {}
  local cost
  local min = math.min;

  -- quick cut-offs to save time
  if (len1 == 0) then
    return len2
  elseif (len2 == 0) then
    return len1
  elseif (str1 == str2) then
    return 0
  end

  -- initialise the base matrix values
  for i = 0, len1, 1 do
    matrix[i] = {}
    matrix[i][0] = i
  end
  for j = 0, len2, 1 do
    matrix[0][j] = j
  end

  -- actual Levenshtein algorithm
  for i = 1, len1, 1 do
    for j = 1, len2, 1 do
      if (str1:byte(i) == str2:byte(j)) then
        cost = 0
      else
        cost=1
      end
      matrix[i][j] = min(matrix[i-1][j] + 2, matrix[i][j-1], matrix[i-1][j-1] + cost)
    end
  end

  -- return the last value - this is the Levenshtein distance
  return matrix[len1][len2]
end



-- Check trigger character
M.checkTriggerCharacter = function(line_to_cursor, source_trigger_character)
  local trigger_character = api.nvim_get_var('completion_trigger_character')
  if source_trigger_character ~= nil then
    for _,val in ipairs(source_trigger_character) do
      table.insert(trigger_character, val)
    end
  end
  for _, ch in ipairs(trigger_character) do
    local current_char = string.sub(line_to_cursor, #line_to_cursor-#ch+1, #line_to_cursor)
    if current_char == ch then
      return true
    end
  end
  return false
end

return M
