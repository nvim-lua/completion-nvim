local vim = vim
local validate = vim.validate
local api = vim.api
local util = require 'completion.util'
local M = {}

----------------------
--  signature help  --
----------------------
local function ok_or_nil(status, ...)
  if not status then return end
  return ...
end

local function npcall(fn, ...)
  return ok_or_nil(pcall(fn, ...))
end

local function find_window_by_var(name, value)
  for _, win in ipairs(api.nvim_list_wins()) do
    if npcall(api.nvim_win_get_var, win, name) == value then
      return win
    end
  end
end

local function focusable_float(unique_name, fn)
  if npcall(api.nvim_win_get_var, 0, unique_name) then
    return api.nvim_command("wincmd p")
  end
  local bufnr = api.nvim_get_current_buf()
  do
    local win = find_window_by_var(unique_name, bufnr)
    if win then
      api.nvim_win_close(win, true)
    end
  end
  local pbufnr, pwinnr = fn()
  if pbufnr then
    api.nvim_win_set_var(pwinnr, unique_name, bufnr)
    return pbufnr, pwinnr
  end
end

function M.open_floating_preview(contents, filetype, opts)
  validate {
    contents = { contents, 't' };
    filetype = { filetype, 's', true };
    opts = { opts, 't', true };
  }
  opts = opts or {}

  -- Trim empty lines from the end.
  contents = vim.lsp.util.trim_empty_lines(contents)

  local width = opts.width
  local height = opts.height or #contents
  if not width then
    width = 0
    for i, line in ipairs(contents) do
      -- Clean up the input and add left pad.
      line = " "..line:gsub("\r", "")
      -- TODO(ashkan) use nvim_strdisplaywidth if/when that is introduced.
      local line_width = vim.fn.strdisplaywidth(line)
      width = math.max(line_width, width)
      contents[i] = line
    end
    -- Add right padding of 1 each.
    width = width + 1
  end

  local floating_bufnr = api.nvim_create_buf(false, true)
  if filetype then
    api.nvim_buf_set_option(floating_bufnr, 'filetype', filetype)
  end
  local float_option = vim.lsp.util.make_floating_popup_options(width, height, opts)
  float_option.focusable = false
  local floating_winnr = api.nvim_open_win(floating_bufnr, false, float_option)
  if filetype == 'markdown' then
    api.nvim_win_set_option(floating_winnr, 'conceallevel', 2)
  end
  api.nvim_buf_set_lines(floating_bufnr, 0, -1, true, contents)
  api.nvim_buf_set_option(floating_bufnr, 'modifiable', false)
  api.nvim_command("autocmd CursorMovedI,BufHidden,TextChangedI,InsertLeave <buffer> ++once lua pcall(vim.api.nvim_win_close, "
    ..floating_winnr..", true)")
  return floating_bufnr, floating_winnr
end

local focusable_preview = function(unique_name, fn)
  return focusable_float(unique_name, function()
    return M.open_floating_preview(fn())
  end)
end

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

M.autoOpenSignatureHelp = function(bufnr, line_to_cursor)
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
    local params = vim.lsp.util.make_position_params()
    vim.lsp.buf_request(bufnr, 'textDocument/signatureHelp', params, function(_, method, result)
      if not (result and result.signatures and result.signatures[1]) then
        return
      else
        focusable_preview(method, function()
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


return M
