local vim = vim
local validate = vim.validate
local api = vim.api
local util = require 'completion.util'
local M = {}

----------------------
--  signature help  --
----------------------
M.autoOpenSignatureHelp = function()
  local bufnr = api.nvim_get_current_buf()
  local pos = api.nvim_win_get_cursor(0)
  local line = api.nvim_get_current_line()
  local line_to_cursor = line:sub(1, pos[2])
  if vim.lsp.buf_get_clients() == nil then return end

  local triggered
  for _, value in pairs(vim.lsp.buf_get_clients(0)) do
    if value.resolved_capabilities.signature_help == false or
      value.server_capabilities.signatureHelpProvider == nil then
      return
    end

    if value.resolved_capabilities.hover == false then return end
      triggered = util.checkTriggerCharacter(line_to_cursor,
        value.server_capabilities.signatureHelpProvider.triggerCharacters)
  end

  if triggered then
    vim.lsp.buf.signature_help()
  end
end


return M
