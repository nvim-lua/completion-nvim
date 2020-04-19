local vim = vim
local api = vim.api
local util = require 'utility'
local source = require 'source'
local signature = require'signature_help'
local hover = require'hover'
local M = {}

------------------------------------------------------------------------
--                           local function                           --
------------------------------------------------------------------------

M.completionConfirm = false
M.prefixLength = 0

-- Manager variable to keep all state accross completion
local manager = {
  insertChar = false,
  insertLeave = false,
  textHover = false,
  selected = -1,
  changedTick = 0,
  changeSource = false,
  autochange = false
}

local autoCompletion = function(bufnr, line_to_cursor)
  -- Get the start position of the current keyword
  local textMatch = vim.fn.match(line_to_cursor, '\\k*$')
  local prefix = line_to_cursor:sub(textMatch+1)
  local length = api.nvim_get_var('completion_trigger_keyword_length')
  if #prefix < M.prefixLength and vim.fn.pumvisible() == 0 then
    if vim.fn.pumvisible() > 0 then
      api.nvim_input("<c-g><C-g>")
    end
    source.chain_complete_index = 1
    source.stop_complete = false
  end
  M.prefixLength = #prefix
  -- force reset chain completion if entering a new word
  if (#prefix < length) and string.sub(line_to_cursor, #line_to_cursor, #line_to_cursor) == ' ' then
    source.chain_complete_index = 1
    source.stop_complete = false
    manager.changeSource = false
  end
  if source.stop_complete == true then return end
  local source_trigger_character = source.getTriggerCharacter()
  local triggerCharacter = util.checkTriggerCharacter(line_to_cursor, source_trigger_character)
  if #prefix >= length or triggerCharacter == true then
    if triggerCharacter == true then
      source.chain_complete_index = 1
    end
    source.triggerCurrentCompletion(manager, bufnr, prefix, textMatch)
  end
end

local autoOpenHoverInPopup = function(bufnr)
  if api.nvim_call_function('pumvisible', {}) == 1 then
    -- Auto open hover
    local items = api.nvim_call_function('complete_info', {{"eval", "selected", "items", "user_data"}})
    if items['selected'] ~= manager.selected then
      manager.textHover = true
      if M.winnr ~= nil and api.nvim_win_is_valid(M.winnr) then
        api.nvim_win_close(M.winnr, true)
      end
      M.winnr = nil
    end
    if manager.textHover == true and items['selected'] ~= -1 then
      if items['selected'] == -2 then
        items['selected'] = 0
      end
      local item = items['items'][items['selected']+1]
      if item['user_data'] ~= nil and #item['user_data'] ~= 0 then
        local user_data = vim.fn.json_decode(item['user_data'])
        if user_data['hover'] ~= nil and type(user_data['hover']) == 'string' and #user_data['hover'] ~= 0 then
          local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(user_data['hover'])
          markdown_lines = vim.lsp.util.trim_empty_lines(markdown_lines)
          local bufnr, winnr
          local position = vim.fn.pum_getpos()
          -- Set max width option to avoid overlapping with popup menu
          local total_column = api.nvim_get_option('columns')
          local align
          if position['col'] < total_column/2 then
            align = 'right'
          else
            align = 'left'
          end
          bufnr, winnr = hover.fancy_floating_markdown(markdown_lines, {
            pad_left = 1; pad_right = 1;
            col = position['col']; width = position['width']; row = position['row']-1;
            align = align
          })
          M.winnr = winnr
        end
      elseif item['kind'] ~= 'UltiSnips' and
          item['kind'] ~= 'Neosnippet' then
        local row, col = unpack(api.nvim_win_get_cursor(0))
        row = row - 1
        local line = api.nvim_buf_get_lines(0, row, row+1, true)[1]
        col = vim.str_utfindex(line, col)
        local params = {
          textDocument = vim.lsp.util.make_text_document_params();
          position = { line = row; character = col-1; }
        }
        local winnr
        vim.lsp.buf_request(bufnr, 'textDocument/hover', params)
      end
      manager.textHover = false
    end
    manager.selected = items['selected']
  end
end

local autoOpenSignatureHelp = function(bufnr, line_to_cursor)
  local params = vim.lsp.util.make_position_params()
  if string.sub(line_to_cursor, #line_to_cursor, #line_to_cursor) == '(' then
    vim.lsp.buf_request(bufnr, 'textDocument/signatureHelp', params, function(_, method, result)
      if not (result and result.signatures and result.signatures[1]) then
        return
      else
        signature.focusable_preview(method, function()
          local lines = signature.signature_help_to_preview_contents(result)
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

  autoCompletion(bufnr, line_to_cursor)

  if api.nvim_get_var('completion_enable_auto_hover') == 1 then
    autoOpenHoverInPopup(bufnr)
  end
  if api.nvim_get_var('completion_enable_auto_signature') == 1 then
    autoOpenSignatureHelp(bufnr, line_to_cursor)
  end
end


------------------------------------------------------------------------
--                          member function                           --
------------------------------------------------------------------------

function M.autoAddParens(complete_item)
  if complete_item.kind == nil then return end
  if string.match(complete_item.kind, '.*Function.*') ~= nil or string.match(complete_item.kind, '.*Method.*') then
    api.nvim_input("()<ESC>i")
  end
end

-- Workaround to avoid expand snippets when not confirm
-- confirmCompletion is now triggered by CompleteDone autocmd to solve issue with noselect
-- Will cause snippets to expand with not pressing confirm key
-- Add a flag completionConfirm to avoid this issue
function M.toggleConfirm()
  M.completionConfirm = true
end

function M.confirmCompletion()
  if M.completionConfirm == true then
    local complete_item = api.nvim_get_vvar('completed_item')
    if api.nvim_get_var('completion_enable_auto_paren') then
      M.autoAddParens(complete_item)
    end
    if complete_item.kind == 'UltiSnips' then
      api.nvim_call_function('UltiSnips#ExpandSnippet', {})
    elseif complete_item.kind == 'Neosnippet' then
      api.nvim_input("<c-r>".."=neosnippet#expand('"..complete_item.word.."')".."<CR>")
    end
    M.completionConfirm = false
  end
  if M.winnr ~= nil and api.nvim_win_is_valid(M.winnr) then
    api.nvim_win_close(M.winnr, true)
  end
end


M.triggerCompletion = function(force)
  local bufnr = api.nvim_get_current_buf()
  local pos = api.nvim_win_get_cursor(0)
  local line = api.nvim_get_current_line()
  local line_to_cursor = line:sub(1, pos[2])
  local textMatch = vim.fn.match(line_to_cursor, '\\k*$')
  local prefix = line_to_cursor:sub(textMatch+1)
  manager.insertChar = true
  -- force is used when manually trigger, so it doesn't repect the trigger word length
  local length = api.nvim_get_var('completion_trigger_keyword_length')
  if force == true or (#prefix >= length or util.checkTriggerCharacter(line_to_cursor)) then
    source.triggerCurrentCompletion(manager, bufnr, prefix, textMatch)
  end
end

function M.on_InsertCharPre()
  manager.insertChar = true
  manager.textHover = true
  manager.selected = -1
  if api.nvim_get_var('completion_auto_change_source') == 1 then
    manager.autochange = true
  end
end

function M.on_InsertLeave()
  manager.insertLeave = true
end

function M.on_InsertEnter()
  local enable = api.nvim_call_function('completion#get_buffer_variable', {'completion_enable'})
  if enable == nil or enable == 0 then
    return
  end
  if api.nvim_get_var('completion_enable_auto_popup') == 0 then return end
  local timer = vim.loop.new_timer()
  -- setup variable
  manager.changedTick = api.nvim_buf_get_changedtick(0)
  manager.insertLeave = false
  manager.insertChar = false
  manager.changeSource = false
  if api.nvim_get_var('completion_auto_change_source') == 1 then
    manager.autochange = true
  end

  -- reset source
  source.chain_complete_index = 1
  source.stop_complete = false
  local l_complete_index = source.chain_complete_index
  local timer_cycle = api.nvim_get_var('completion_timer_cycle')

  timer:start(100, timer_cycle, vim.schedule_wrap(function()
    local l_changedTick = api.nvim_buf_get_changedtick(0)
    -- complete if changes are made
    if l_changedTick ~= manager.changedTick then
      manager.changedTick = l_changedTick
      completionManager()
    end
    -- change source if no item is available
    if manager.changeSource and manager.autochange then
      manager.changeSource = false
      if source.chain_complete_index ~= source.chain_complete_length then
        source.chain_complete_index = source.chain_complete_index + 1
        l_complete_index = source.chain_complete_index
      else
        source.stop_complete = true
      end
    end
    -- force trigger completion when manaully chaging source
    if l_complete_index ~= source.chain_complete_index then
      -- force clear completion
      if vim.api.nvim_get_mode()['mode'] == 'i' or vim.api.nvim_get_mode()['mode'] == 'ic' then
        vim.fn.complete(vim.api.nvim_win_get_cursor(0)[2], {})
      end
      M.triggerCompletion(false)
      manager.autochange = false
      l_complete_index = source.chain_complete_index
    end
    -- closing timer if leaving insert mode
    if manager.insertLeave == true and timer:is_closing() == false then
      timer:stop()
      timer:close()
    end
  end))
end

M.completionToggle = function()
  local enable = api.nvim_call_function('completion#get_buffer_variable', {'completion_enable'})
  if enable == nil then
    M.on_attach()
  elseif enable == 0 then
    api.nvim_buf_set_var(0, 'completion_enable', 1)
  else
    api.nvim_buf_set_var(0, 'completion_enable', 0)
  end
end

M.on_attach = function()
  hover.modifyCallback()
  api.nvim_command [[augroup CompletionCommand]]
    api.nvim_command("autocmd InsertEnter <buffer> lua require'completion'.on_InsertEnter()")
    api.nvim_command("autocmd InsertLeave <buffer> lua require'completion'.on_InsertLeave()")
    api.nvim_command("autocmd InsertCharPre <buffer> lua require'completion'.on_InsertCharPre()")
    api.nvim_command("autocmd CompleteDone <buffer> lua require'completion'.confirmCompletion()")
  api.nvim_command [[augroup end]]
  if not api.nvim_get_var('completion_confirm_key') == '' then
    api.nvim_buf_set_keymap(0, 'i', api.nvim_get_var('completion_confirm_key'),
      '<cmd>call completion#wrap_completion()<CR>', {silent=true, noremap=true})
  end
  api.nvim_buf_set_var(0, 'completion_enable', 1)
end

return M


