local vim = vim
local api = vim.api
local util = require 'utility'
local snippet = require 'source.snippet'
local M = {}


M.triggerCompletion = function(manager, bufnr, prefix, textMatch)
  M.items = {}
  M.callback_complete = false
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(bufnr, 'textDocument/completion', params, function(err, _, result)
    if err or not result then return end
    if api.nvim_get_mode()['mode'] == 'i' or api.nvim_get_mode()['mode'] == 'ic' then
      local matches = util.text_document_completion_list_to_complete_items(result, prefix)
      if api.nvim_get_var('completion_enable_snippet') ~= nil then
        local snippet_list = snippet.getSnippetItems(prefix)
        vim.list_extend(matches, snippet_list)
      end
      util.sort_completion_items(matches)
      if #matches ~= 0 and manager.insertChar == true then
        vim.fn.complete(textMatch+1, matches)
        manager.insertChar = false
      else
        manager.changeSource = true
      end
    end
  end)
end

return M
