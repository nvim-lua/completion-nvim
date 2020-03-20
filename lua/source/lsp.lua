local vim = vim
local api = vim.api
local util = require 'utility'
local snippet = require 'source.snippet'
local M = {}


M.getCompletionItems = function(prefix, _, bufnr)
  local items = {}
  -- M.callback_complete = false
  local params = vim.lsp.util.make_position_params()
  local callback = vim.lsp.buf_request_sync(bufnr, 'textDocument/completion', params, 1000)
  local result, err
  for _, val in pairs(callback) do
    result = val.result
    err = val.error
  end
  if err or not result then 
    return {}
  end
  if api.nvim_get_mode()['mode'] == 'i' or api.nvim_get_mode()['mode'] == 'ic' then
    local matches = util.text_document_completion_list_to_complete_items(result, prefix)
    items = matches
  end
  return items
end

return M
