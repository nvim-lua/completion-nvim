local vim = vim
local api = vim.api
local util = require 'completion.util'
local M = {}

M.callback = false

M.getCompletionItems = function(_, _)
  return M.items
end

M.getCallback = function()
  return M.callback
end

M.triggerFunction = function(prefix, _, bufnr, manager)
  local params = vim.lsp.util.make_position_params()
  M.callback = false
  M.items = {}
  if #vim.lsp.buf_get_clients() == 0 then
    M.callback = true
    return
  end
  vim.lsp.buf_request(bufnr, 'textDocument/completion', params, function(err, _, result)
    if err or not result then
      M.callback = true
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
