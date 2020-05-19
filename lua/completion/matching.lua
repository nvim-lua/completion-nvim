local vim = vim
local util = require'completion.util'
local M = {}

local function fuzzy_match(prefix, word)
  if vim.g.completion_matching_ignore_case == 1 then
    prefix = string.lower(prefix)
    word = string.lower(word)
  end
  local score = util.fuzzy_score(prefix, word)
  if score < 1 then
    return true, score
  else
    return false
  end
end


local function substring_match(prefix, word)
  if vim.g.completion_matching_ignore_case == 1 then
    prefix = string.lower(prefix)
    word = string.lower(word)
  end
  if string.find(word, prefix) then
    return true
  else
    return false
  end
end

local function exact_match(prefix, word)
  if vim.g.completion_matching_ignore_case == 1 then
    prefix = string.lower(prefix)
    word = string.lower(word)
  end
  if vim.startswith(word, prefix) then
    return true
  else
    return false
  end
end

local matching_strategy = {
  fuzzy = fuzzy_match,
  substring = substring_match,
  exact = exact_match
}

M.matching = function(complete_items, prefix, item)
  local matcher_list = vim.b.completion_matching_strategy_list or vim.g.completion_matching_strategy_list
  local matching_piroity = 1
  for _, method in ipairs(matcher_list) do
    local is_match, score = matching_strategy[method](prefix, item.word)
    if is_match then
      item.user_data.matching_piroity = matching_piroity
      item.score = score
      util.addCompletionItems(complete_items, item)
      break
    end
  end
end

return M
