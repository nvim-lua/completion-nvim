local vim = vim
local api = vim.api
local util = require 'utility'
local snippet = require 'source.snippet'
local util = require 'utility'
local M = {}

M.callback = false

M.getCompletionItems = function(_, _)
  return M.items
end

M.getCallback = function()
  return M.callback
end

M.triggerFunction = function(prefix, textMatch, bufnr, manager)
  local params = vim.lsp.util.make_position_params()
  M.callback = false
  M.items = {}
  vim.lsp.buf_request(bufnr, 'textDocument/completion', params, function(err, _, result)
    if err or not result then
      manager.changeSource = true
      return
    end
    if api.nvim_get_mode()['mode'] == 'i' or api.nvim_get_mode()['mode'] == 'ic' then
      local matches = util.text_document_completion_list_to_complete_items(result, prefix)
      M.items = matches
    end
    M.callback = true
  end)
end

return M
