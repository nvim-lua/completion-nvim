------------------------------------------------------------------------
--      utility function that are modified from neovim's source       --
------------------------------------------------------------------------

local vim = vim
local api = vim.api
local opt = require 'completion.option'
local M = {}

function M.is_list(thing)
    return vim.fn.type(thing) == api.nvim_get_vvar("t_list")
end


------------------------
--  completion items  --
------------------------

function M.sort_completion_items(items)
  table.sort(items, function(a, b)
    if a.priority ~= b.priority and a.priority ~= nil and b.priority ~= nil then
      return a.priority > b.priority
    elseif a.score ~= b.score and a.score ~= nil and b.score ~= nil then
      return a.score < b.score
    elseif opt.get_option("sorting") == 'alphabet' then
      return a.word < b.word
    elseif opt.get_option("sorting") == 'length_desc' then
      return string.len(a.word) > string.len(b.word)
    else
      return string.len(a.word) < string.len(b.word)
    end
  end)
end

function M.addCompletionItems(item_table, item)
  -- word cannot be nil
  if item.word == nil then return end
  local menu_length = opt.get_option('menu_length')
  if menu_length ~= 0 then
    if string.len(item.abbr) > menu_length then
      item.abbr = string.sub(item.abbr, 0, menu_length).."..."
    end
  end
  table.insert(item_table, {
      word = item.word,
      abbr = item.abbr or '',
      kind = item.kind or '',
      menu = item.menu or '',
      info = item.info or '',
      priority = item.priority or 1,
      icase = 1,
      dup = item.dup or 1,
      empty = 1,
      user_data = item.user_data or {},
    })
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
M.checkTriggerCharacter = function(line_to_cursor, trigger_character)
  if trigger_character == nil then return end
  for _, ch in ipairs(trigger_character) do
    local current_char = string.sub(line_to_cursor, #line_to_cursor-#ch+1, #line_to_cursor)
    if current_char == ch then
      return true
    end
  end
  return false
end

return M
