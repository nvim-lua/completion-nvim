local vim = vim
local api = vim.api
local match = require'completion.matching'
local source = require 'source'
local signature = require'completion.signature_help'
local hover = require'completion.hover'
local M = {}

------------------------------------------------------------------------
--                           local function                           --
------------------------------------------------------------------------

M.completionConfirm = false


-- Manager variable to keep all state accross completion
local manager = {
  -- Handle insertCharPre event, turn off imediately when preforming completion
  insertChar = false,
  -- Handle insertLeave event
  insertLeave = false,
  -- Handle auto hover
  textHover = false,
  -- Handle selected items in v:complete-items for auto hover
  selected = -1,
  -- Handle changeTick
  changedTick = 0,
  -- handle auto changing source
  changeSource = false,
  autoChange = false
}

------------------------------------------------------------------------
--                          member function                           --
------------------------------------------------------------------------

function M.autoAddParens(complete_item)
  if complete_item.kind == nil then return end
  if string.match(complete_item.kind, '.*Function.*') ~= nil or string.match(complete_item.kind, '.*Method.*') then
    api.nvim_input("()<left>")
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
    local lnum, _ = unpack(api.nvim_win_get_cursor(0))
    if complete_item.user_data.lsp ~= nil then
      local item = complete_item.user_data.lsp.completion_item
      local bufnr = api.nvim_get_current_buf()
      if item.additionalTextEdits then
        local edits = vim.tbl_filter(
          function(x) return x.range.start.line ~= (lnum - 1) end,
          item.additionalTextEdits
        )
        vim.lsp.util.apply_text_edits(edits, bufnr)
      end
      if vim.fn.exists('g:loaded_vsnip_integ') == 1 then
        api.nvim_call_function('vsnip_integ#on_complete_done_for_lsp',
          { { completed_item = complete_item, completion_item = item } })
      end
    end

    if vim.g.completion_enable_auto_paren == 1 then
      M.autoAddParens(complete_item)
    end
    if complete_item.kind == 'UltiSnips' then
      api.nvim_call_function('UltiSnips#ExpandSnippet', {})
    elseif complete_item.kind == 'Neosnippet' then
      api.nvim_input("<c-r>".."=neosnippet#expand('"..complete_item.word.."')".."<CR>")
    elseif complete_item.kind == 'vim-vsnip' then
      api.nvim_call_function('vsnip#expand', {})
    end
    M.completionConfirm = false
  end
  if hover.winnr ~= nil and api.nvim_win_is_valid(hover.winnr) then
    api.nvim_win_close(hover.winnr, true)
  end
end


function M.on_InsertCharPre()
  manager.insertChar = true
  manager.textHover = true
  manager.selected = -1
  if vim.g.completion_auto_change_source == 1 then
    manager.autoChange = true
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
  local timer = vim.loop.new_timer()
  -- setup variable
  manager.changedTick = api.nvim_buf_get_changedtick(0)
  manager.insertLeave = false
  manager.insertChar = false
  manager.changeSource = false
  if vim.g.completion_auto_change_source == 1 then
    manager.autoChange = true
  end

  -- reset source
  source.chain_complete_index = 1
  source.stop_complete = false
  local l_complete_index = source.chain_complete_index
  local timer_cycle = vim.g.completion_timer_cycle

  timer:start(100, timer_cycle, vim.schedule_wrap(function()
    local l_changedTick = api.nvim_buf_get_changedtick(0)
    -- complete if changes are made
    if l_changedTick ~= manager.changedTick then
      manager.changedTick = l_changedTick
      if vim.g.completion_enable_auto_popup == 1 then
        source.autoCompletion(manager)
      end
      if vim.g.completion_enable_auto_hover == 1 then
        hover.autoOpenHoverInPopup(manager)
      end
      if vim.g.completion_enable_auto_signature == 1 then
        signature.autoOpenSignatureHelp()
      end
    end
    -- change source if no item is available
    if manager.changeSource and manager.autoChange then
      manager.changeSource = false
      if source.chain_complete_index ~= source.chain_complete_length then
        source.chain_complete_index = source.chain_complete_index + 1
        l_complete_index = source.chain_complete_index
        manager.insertChar = true
        source.triggerCompletion(false, manager)
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
      source.triggerCompletion(false, manager)
      l_complete_index = source.chain_complete_index
    end
    -- closing timer if leaving insert mode
    if manager.insertLeave == true and timer:is_closing() == false then
      timer:stop()
      timer:close()
    end
  end))
end

M.triggerCompletion = function()
  source.triggerCompletion(true, manager)
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

-- Deprecated
M.customize_buf_label = function(label)
  api.nvim_buf_set_var(0, "completion_buf_customize_lsp_label", label)
end

M.insertCompletionItems = function(complete_items, prefix, item)
  match.matching(complete_items, prefix, item)
end

M.addCompletionSource = function(key, complete_item)
  source.addCompleteItems(key, complete_item)
end

M.on_attach = function(opt)
  api.nvim_command("augroup CompletionCommand")
    api.nvim_command("autocmd! * <buffer>")
    api.nvim_command("autocmd InsertEnter <buffer> lua require'completion'.on_InsertEnter()")
    api.nvim_command("autocmd InsertLeave <buffer> lua require'completion'.on_InsertLeave()")
    api.nvim_command("autocmd InsertCharPre <buffer> lua require'completion'.on_InsertCharPre()")
    api.nvim_command("autocmd CompleteDone <buffer> lua require'completion'.confirmCompletion()")
  api.nvim_command("augroup end")
  if string.len(vim.g.completion_confirm_key) ~= 0 then
    api.nvim_buf_set_keymap(0, 'i', vim.g.completion_confirm_key,
      '<cmd>call completion#wrap_completion()<CR>', {silent=true, noremap=true})
  end
  api.nvim_buf_set_var(0, 'completion_enable', 1)
  if opt == nil then return end
  local sorter = opt.sorter
  local matcher = opt.matcher
  if sorter ~= nil then
    vim.validate{sorter={sorter, 'string'}}
    vim.b.completion_sorting = sorter
  end
  if matcher ~= nil then
    vim.validate{matcher={matcher, 'table'}}
    vim.b.completion_matching_strategy_list = matcher
  end
end

return M

