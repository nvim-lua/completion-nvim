local vim = vim
local api = vim.api
local util = require 'utility'
local snippet = require 'source.snippet'
local M = {}

------------------------------------------------------------------------
--                           local function                           --
------------------------------------------------------------------------

local performCompletion = function(bufnr, line_to_cursor)
  -- Get the start position of the current keyword
  local textMatch = vim.fn.match(line_to_cursor, '\\k*$')
  local prefix = line_to_cursor:sub(textMatch+1)

  local params = vim.lsp.util.make_position_params()
  M.items = {}
  if prefix ~= '' and api.nvim_call_function('pumvisible', {}) == 0 then
    vim.lsp.buf_request(bufnr, 'textDocument/completion', params, function(err, _, result)
      if err or not result then return end
      local comment_string = api.nvim_buf_get_option(0, 'commentstring')
      if api.nvim_get_mode()['mode'] == 'i' or api.nvim_get_mode()['mode'] == 'ic' then
        local matches = vim.lsp.util.text_document_completion_list_to_complete_items(result, prefix)
        local snippets = snippet.getUltisnipItems(prefix)
        vim.list_extend(matches, snippets) 
        if #matches ~= 0 and M.insertChar == true then
          vim.list_extend(M.items, matches)
          vim.fn.complete(textMatch+1, matches)
          M.insertChar = false
        end
      end
    end)
  elseif api.nvim_call_function('pumvisible', {}) == 1 then
    -- Auto open hover and signature help
    local item = api.nvim_call_function('complete_info', {{"eval", "selected", "items"}})
    if item['selected'] ~= -1 then
      print(item['items'][item['selected']+1]['kind'])
    end
    if item['selected'] ~= M.selected then
      M.textHover = true
      if M.winnr ~= nil and api.nvim_win_is_valid(M.winnr) then
        api.nvim_win_close(M.winnr, true)
      end
      M.winner = nil
    end
    if M.textHover == true and item['selected'] ~= -1 then
      if item['items'][item['selected']+1]['kind'] == 'UltiSnips' then
      else
        vim.lsp.buf.hover()
      end
      M.textHover = false
    end
    M.selected = item['selected']
  end
end

local autoOpenSignatureHelp = function(bufnr, line_to_cursor)
  local params = vim.lsp.util.make_position_params()
  if string.sub(line_to_cursor, #line_to_cursor, #line_to_cursor) == '(' then
    vim.lsp.buf_request(bufnr, 'textDocument/signatureHelp', params, function(_, method, result)
      if not (result and result.signatures and result.signatures[1]) then
        return
      else
        vim.lsp.util.focusable_preview(method, function()
          local lines = util.signature_help_to_preview_contents(result)
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
  local status = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.synID(pos[1], pos[2]-1, 1)), "name")
  if status ~= 'Comment' or api.nvim_get_var('completion_disable_in_comment') == 0 then
    performCompletion(bufnr, line_to_cursor)
  end
  autoOpenSignatureHelp(bufnr, line_to_cursor)
end


------------------------------------------------------------------------
--                          member function                           --
------------------------------------------------------------------------

-- Modify hover callback
function M.modifyCallback()
  local callback = 'textDocument/hover'
  vim.lsp.callbacks[callback] = function(_, method, result)
    vim.lsp.util.focusable_float(method, function()
      if not (result and result.contents) then
        -- return { 'No information available' }
        return
      end
      local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
      markdown_lines = vim.lsp.util.trim_empty_lines(markdown_lines)
      if vim.tbl_isempty(markdown_lines) then
        -- return { 'No information available' }
        return
      end
      local bufnr, winnr = nil, nil
      if vim.fn.pumvisible() == 1 then
        local position = vim.fn.pum_getpos()
        -- print(position['col'], position['row'])
        bufnr, winnr = util.fancy_floating_markdown(markdown_lines, {
          pad_left = 1; pad_right = 1;
          col = position['col'] + position['width']; row = position['row']-1;
        })
      else
        bufnr, winnr = vim.lsp.util.fancy_floating_markdown(markdown_lines, {
          pad_left = 1; pad_right = 1;
        })
      end
      vim.lsp.util.close_preview_autocmd({"CursorMoved", "BufHidden", "InsertCharPre"}, winnr)
      M.winnr = winnr
      return bufnr, winnr
    end)
  end
end

M.confirmCompletion = function()
  api.nvim_call_function('completion#completion_confirm', {})
  local complete_item = api.nvim_get_vvar('completed_item')
  if complete_item.kind == 'UltiSnips' then
    api.nvim_call_function('UltiSnips#ExpandSnippet', {})
  end
  if M.winnr ~= nil and api.nvim_win_is_valid(M.winnr) then
    api.nvim_win_close(M.winnr, true)
  end
end

function M.on_InsertCharPre()
  M.insertChar = true
  M.textHover = true
  M.selected = -1
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
  M.modifyCallback()
  api.nvim_command("autocmd InsertEnter * lua require'completor'.on_InsertEnter()")
  api.nvim_command("autocmd InsertLeave * lua require'completor'.on_InsertLeave()")
  api.nvim_command("autocmd InsertCharPre * lua require'completor'.on_InsertCharPre()")
  api.nvim_buf_set_keymap(0, 'i', api.nvim_get_var('completion_confirm_key'), '<cmd>call completion#wrap_completion()<CR>', {silent=true, noremap=true})
end

return M


