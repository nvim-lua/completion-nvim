local vim = vim
local api = vim.api
local snippet = require 'source.snippet'
local M = {}

local performCompletion = function(bufnr, line_to_cursor)
  -- Get the start position of the current keyword
  local textMatch = vim.fn.match(line_to_cursor, '\\k*$')
  local prefix = line_to_cursor:sub(textMatch+1)

  local params = vim.lsp.util.make_position_params()
  local items = {}
  if prefix ~= '' and api.nvim_call_function('pumvisible', {}) == 0 then
    vim.lsp.buf_request(bufnr, 'textDocument/completion', params, function(err, _, result)
      if err or not result then return end
      local matches = vim.lsp.util.text_document_completion_list_to_complete_items(result, prefix)
      local snippets = snippet.getUltisnipItems(prefix)
      vim.list_extend(matches, snippets)
      if #matches ~= 0 and M.insertChar == true then
        vim.list_extend(items, matches)
        api.nvim_call_function('complete', {textMatch+1, items})
        vim.fn.complete(textMatch+1, matches)
        M.insertChar = false
      end
    end)
  end
end


-- local function copy from neovim's source code
local signature_help_to_preview_contents = function(input)
  if not input.signatures then
    return
  end
  local contents = {}
  local active_signature = input.activeSignature or 0
  if active_signature >= #input.signatures then
    active_signature = 0
  end
  local signature = input.signatures[active_signature + 1]
  if not signature then
    return
  end
  vim.list_extend(contents, vim.split(signature.label, '\n', true))
  if signature.documentation then
    vim.lsp.util.convert_input_to_markdown_lines(signature.documentation, contents)
  end
  if input.parameters then
    local active_parameter = input.activeParameter or 0
    if active_parameter >= #input.parameters then
      active_parameter = 0
    end
    local parameter = signature.parameters and signature.parameters[active_parameter]
    if parameter then
      if parameter.documentation then
        vim.lsp.util.convert_input_to_markdown_lines(parameter.documentation, contents)
      end
    end
  end
  return contents
end

local autoOpenSignatureHelp = function(bufnr, line_to_cursor)
  local params = vim.lsp.util.make_position_params()
  if string.sub(line_to_cursor, #line_to_cursor, #line_to_cursor) == '(' then
    vim.lsp.buf_request(bufnr, 'textDocument/signatureHelp', params, function(_, method, result)
      if not (result and result.signatures and result.signatures[1]) then
        return
      else
        vim.lsp.util.focusable_preview(method, function()
          local lines = signature_help_to_preview_contents(result)
          lines = vim.lsp.util.trim_empty_lines(lines)
          if vim.tbl_isempty(lines) then
            return { 'No signature available' }
          end
          return lines, vim.lsp.util.try_trim_markdown_code_blocks(lines)
        end)
      end
    end)
  end
end

local completionManager = function()
  local bufnr = api.nvim_get_current_buf()
  local pos = api.nvim_win_get_cursor(0)
  local line = api.nvim_get_current_line()
  local line_to_cursor = line:sub(1, pos[2])
  performCompletion(bufnr, line_to_cursor)
  autoOpenSignatureHelp(bufnr, line_to_cursor)
end

function M.on_CompleteDone()
  local complete_item = api.nvim_get_vvar('completed_item')
  if complete_item.kind == 'UltiSnips' then
    api.nvim_call_function('UltiSnips#ExpandSnippet', {})
  end
end

function M.on_InsertCharPre()
  M.insertChar = true
end

function M.on_InsertLeave()
  M.insertLeave = true
end

function M.on_InsertEnter()
  local timer = vim.loop.new_timer()
  M.changedTick = api.nvim_buf_get_changedtick(0)
  M.insertLeave = false
  M.insertChar = false
  timer:start(100, 30, vim.schedule_wrap(function()
    local l_changedTick = api.nvim_buf_get_changedtick(0)
    if l_changedTick ~= M.changedTick then
      M.changedTick = l_changedTick
      completionManager()
    end
    if M.insertLeave == true and timer:is_closing() == false then
      timer:stop()
      timer:close()
    end
  end))
end

M.on_attach = function()
  api.nvim_command("autocmd InsertEnter * lua require'completor'.on_InsertEnter()")
  api.nvim_command("autocmd InsertLeave * lua require'completor'.on_InsertLeave()")
  api.nvim_command("autocmd InsertCharPre * lua require'completor'.on_InsertCharPre()")
  api.nvim_command("autocmd CompleteDone * lua require'completor'.on_CompleteDone()")
end

return M


