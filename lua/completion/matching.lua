local vim = vim
local M = {}

-- Levenshtein algorithm for fuzzy matching
-- https://gist.github.com/james2doyle/e406180e143da3bdd102
local function fuzzy_score(str1, str2)
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

local function fuzzy_match(prefix, word)
  local score = fuzzy_score(prefix, word)
  if score < 1 then
    return true, score
  else
    return false
  end
end


local function substring_match(prefix, word)
  if string.find(word, prefix) then
    return true
  else
    return false
  end
end

local function exact_match(prefix, word)
  if vim.startswith(word, prefix) then
    return true
  else
    return false
  end
end

M.matching_strategy = {
  fuzzy = fuzzy_match,
  substr = substring_match,
  exact = exact_match
}

return M
