local vim = vim
local util = require 'completion.util'
local opt = require 'completion.option'
local M = {}

local function setup_case(prefix, word)
  local ignore_case = opt.get_option('matching_ignore_case') == 1

  if ignore_case and opt.get_option('matching_smart_case') == 1 and prefix:match('[A-Z]') then
    ignore_case = false
  end

  if ignore_case then
    return string.lower(prefix), string.lower(word)
  end

  return prefix, word
end

local function fuzzy_match(prefix, word)
  prefix, word = setup_case(prefix, word)
  local score = util.fuzzy_score(prefix, word)
  if score < 1 then
    return true, score
  else
    return false
  end
end


local function substring_match(prefix, word)
  prefix, word = setup_case(prefix, word)
  if string.find(word, prefix) then
    return true
  else
    return false
  end
end

local function exact_match(prefix, word)
  prefix, word = setup_case(prefix, word)
  if vim.startswith(word, prefix) then
    return true
  else
    return false
  end
end

local function all_match()
  return true
end

local matching_strategy = {
  fuzzy = fuzzy_match,
  substring = substring_match,
  exact = exact_match,
  all = all_match,
}

M.matching = function(complete_items, prefix, item)
  local matcher_list = opt.get_option('matching_strategy_list')
  local matching_priority = 2
  for _, method in ipairs(matcher_list) do
    local is_match, score = matching_strategy[method](prefix, item.word)
    if is_match then
      if item.abbr == nil then
        item.abbr = item.word
      end
      item.score = score
      if item.priority ~= nil then
        item.priority = item.priority + 10*matching_priority
      else
        item.priority = 10*matching_priority
      end
      util.addCompletionItems(complete_items, item)
      break
    end
    matching_priority = matching_priority - 1
  end
end

return M
