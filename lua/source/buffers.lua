local M = {}
local api = vim.api

local function get_buf_var(bufnr, name, default)
  local success, value = pcall(function() api.nvim_buf_get_var(bufnr, name) end)

  return success and value or default
end

function M.get_words(bufnr, separator, min_length)
  separator = separator or get_buf_var(bufnr, "completion_word_separator", "\\A")
  min_length = min_length or get_buf_var(bufnr, "completion_word_min_length", 3)

  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, true)
  local parts = vim.fn.split(vim.fn.join(lines), separator)
  local words = {}

  for _,part in ipairs(parts) do
    if #part >= min_length and not words[part] then
      words[part] = true
    end
  end

  return words
end

function M.get_all_buffer_words(separator, min_length)
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  local result = {}

  for _,buf in ipairs(bufs) do
    result = vim.tbl_extend("keep", M.get_words(buf.bufnr, separator, min_length), result)
  end

  return result
end

function M.get_completion_items(words, prefix, score_func, kind)
  local complete_items = {}

  for _,word in ipairs(words) do
    local score = score_func(prefix, word)

    if score < #prefix / 2 and word ~= prefix then
      table.insert(complete_items, {
        word = word;
        kind = kind;
        score = score;
        icase = 1;
        dup = 0;
        empty = 0;
      })
    end
  end

  return complete_items
end

function M.getBuffersCompletionItems(prefix, score_func)
  return M.get_completion_items(vim.tbl_keys(M.get_all_buffer_words()), prefix, score_func, "buffers")
end

function M.getBufferCompletionItems(prefix, score_func)
  return M.get_completion_items(vim.tbl_keys(M.get_words(vim.fn.bufnr('.'))), prefix, score_func, "buffer")
end

return M
