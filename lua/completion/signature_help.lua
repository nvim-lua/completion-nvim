local vim = vim
local validate = vim.validate
local api = vim.api
local util = require 'completion.util'
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
    vim.lsp.buf_request(0, 'textDocument/signatureHelp', params, function(...)
      local result = select(3, ...)
      local client_id = select(4, ...)
      if type(select(2, ...)) == 'table' then
        result = select(2, ...)
        client_id = select(3, ...).client_id
      end

      local client = vim.lsp.get_client_by_id(client_id)
      local handler = client and client.handlers['textDocument/signatureHelp']
      if handler then
          handler(...)
          return
      end
      if not (result and result.signatures and result.signatures[1]) then
        return
      end
      local lines = vim.lsp.util.convert_signature_help_to_markdown_lines(result, filetype)
      if vim.tbl_isempty(lines) then
        return
      end

      -- if `lines` can be trimmed, it is modified in place
      local trimmed_lines_filetype = vim.lsp.util.try_trim_markdown_code_blocks(lines)
	  local opts = {}
	  if vim.g.completion_popup_border then
	    opts.border = vim.g.completion_popup_border
	  end
      local bufnr, _ = vim.lsp.util.open_floating_preview(
        -- TODO show popup when signatures is empty?
        vim.lsp.util.trim_empty_lines(lines),
        trimmed_lines_filetype,
	opts
      )
      -- setup a variable for floating window, fix #223
      vim.api.nvim_buf_set_var(bufnr, "lsp_floating", true)
    end)
  end
end


return M
