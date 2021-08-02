local vim = vim
local api = vim.api
local util = require "completion.util"
local M = {}

----------------------
--  signature help  --
----------------------
M.autoOpenSignatureHelp = function()
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

    line_to_cursor = vim.trim(line_to_cursor)
    triggered = util.checkTriggerCharacter(line_to_cursor,
      value.server_capabilities.signatureHelpProvider.triggerCharacters)
  end

  if triggered then
    -- overwrite signature help here to disable "no signature help" message
    local params = vim.lsp.util.make_position_params()
    local filetype = vim.api.nvim_buf_get_option(0, 'filetype')
    vim.lsp.buf_request(0, 'textDocument/signatureHelp', params, function(err, method, result, client_id)
      local client = vim.lsp.get_client_by_id(client_id)
      local handler = client and client.handlers['textDocument/signatureHelp']
      if handler then
        handler(err, method, result, client_id)
        return
      end
      if not (result and result.signatures and result.signatures[1]) then
        return
      end
      local lines, hl = vim.lsp.util.convert_signature_help_to_markdown_lines(result, filetype)
      lines = vim.lsp.util.trim_empty_lines(lines)
      if vim.tbl_isempty(lines) then
        return
      end

      -- if `lines` can be trimmed, it is modified in place
      local trimmed_lines_filetype = vim.lsp.util.try_trim_markdown_code_blocks(lines)
      local opts = {}
      if vim.g.completion_popup_border then
        opts.border = vim.g.completion_popup_border
      end
      local fbuf, fwin = vim.lsp.util.open_floating_preview(
        vim.lsp.util.trim_empty_lines(lines),
        trimmed_lines_filetype,
        opts
      )
      if hl then
        vim.api.nvim_buf_add_highlight(fbuf, -1, "LspSignatureActiveParameter", 0, unpack(hl))
      end
      return fbuf, fwin
    end)
  end
end

return M
