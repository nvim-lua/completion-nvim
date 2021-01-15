local vim = vim
local api = vim.api
local match = require'completion.matching'
local source = require 'completion.source'
local signature = require'completion.signature_help'
local hover = require'completion.hover'
local opt = require'completion.option'
local manager = require'completion.manager'
local M = {}


------------------------------------------------------------------------
--                          external commands                         --
------------------------------------------------------------------------

M.insertCompletionItems = function(completed_items, prefix, item)
  match.matching(completed_items, prefix, item)
end

M.addCompletionSource = function(key, completed_item)
  source.addCompleteItems(key, completed_item)
end

M.nextSource = function()
  source.nextCompletion()
end

M.prevSource = function()
  source.prevCompletion()
end

M.triggerCompletion = function()
  source.triggerCompletion(true, manager)
end

M.completionToggle = function()
  local enable = vim.b.completion_enable
  if enable == nil then
    M.on_attach()
  elseif enable == 0 then
    vim.b.completion_enable = 1
  else
    vim.b.completion_enable = 0
  end
end

------------------------------------------------------------------------
--                         smart tab                                  --
------------------------------------------------------------------------

function M.smart_tab()
  if vim.fn.pumvisible() ~= 0 then
    api.nvim_eval([[feedkeys("\<c-n>", "n")]])
    return
  end

  local col = vim.fn.col('.') - 1
  if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
    api.nvim_eval([[feedkeys("\<tab>", "n")]])
    return
  end

  source.triggerCompletion(true, manager)
end

function M.smart_s_tab()
  if vim.fn.pumvisible() ~= 0 then
    api.nvim_eval([[feedkeys("\<c-p>", "n")]])
    return
  end

  api.nvim_eval([[feedkeys("\<s-tab>", "n")]])
end

------------------------------------------------------------------------
--                         confirm completion                         --
------------------------------------------------------------------------

-- I want to deprecate this...
local function autoAddParens(completed_item)
  if completed_item.kind == nil then return end
  if string.match(completed_item.kind, '.*Function.*') ~= nil or string.match(completed_item.kind, '.*Method.*') then
    api.nvim_input("()<left>")
  end
end

-- Workaround to avoid expand snippets when not confirm
-- confirmCompletion is now triggered by CompleteDone autocmd to solve issue with noselect
-- Will cause snippets to expand with not pressing confirm key
-- Add a flag completionConfirm to avoid this issue
function M.confirmCompletion(completed_item)
  manager.confirmedCompletion = true
end

-- apply additionalTextEdits in LSP specs
local function applyAddtionalTextEdits(completed_item)
  local lnum = api.nvim_win_get_cursor(0)[1]
  if completed_item.user_data.lsp ~= nil then
    local item = completed_item.user_data.lsp.completion_item
    -- vim-vsnip have better additional text edits...
    if vim.fn.exists('g:loaded_vsnip_integ') == 1 then
      api.nvim_call_function('vsnip_integ#do_complete_done', {
        {
          completed_item = completed_item,
          completion_item = item,
          apply_additional_text_edits = true
        }
      })
    else
      if item.additionalTextEdits then
        local bufnr = api.nvim_get_current_buf()
        local edits = vim.tbl_filter(
          function(x) return x.range.start.line ~= (lnum - 1) end,
          item.additionalTextEdits
        )
        vim.lsp.util.apply_text_edits(edits, bufnr)
      end
    end
  end
end

-- handle completeDone stuff here
local function hasConfirmedCompletion()
  local completed_item = api.nvim_get_vvar('completed_item')
  if completed_item.user_data == nil then return end
  if completed_item.user_data.lsp ~= nil then
    applyAddtionalTextEdits(completed_item)
    if opt.get_option('enable_snippet') == "snippets.nvim" then
      require 'snippets'.expand_at_cursor(completed_item.user_data.actual_item, completed_item.word)
    end
  end
  if opt.get_option('enable_auto_paren') == 1 then
    autoAddParens(completed_item)
  end
  if completed_item.user_data.snippet_source == 'UltiSnips' then
    api.nvim_call_function('UltiSnips#ExpandSnippet', {})
  elseif completed_item.user_data.snippet_source == 'Neosnippet' then
    api.nvim_input("<c-r>".."=neosnippet#expand('"..completed_item.word.."')".."<CR>")
  elseif completed_item.user_data.snippet_source == 'vim-vsnip' then
    api.nvim_call_function('vsnip#anonymous', {
      table.concat(completed_item.user_data.snippet_body, "\n"),
      {
        prefix = completed_item.word
      }
    })
  elseif completed_item.user_data.snippet_source == 'snippets.nvim' then
    require'snippets'.expand_at_cursor()
  end
end

------------------------------------------------------------------------
--                            autocommands                            --
------------------------------------------------------------------------

function M.on_InsertCharPre()
  manager.insertChar = true
  manager.textHover = true
  manager.selected = -1
end

function M.on_InsertLeave()
  manager.insertLeave = true
end

-- TODO: need further refactor, very messy now:(
function M.on_InsertEnter()
  local enable = vim.b.completion_enable
  if enable == nil or enable == 0 then
    return
  end
  local timer = vim.loop.new_timer()
  -- setup variable
  manager.init()

  -- TODO: remove this
  local autoChange = false
  if opt.get_option('auto_change_source') == 1 then
    autoChange = true
  end

  -- reset source
  manager.chainIndex = 1
  source.stop_complete = false
  local l_complete_index = manager.chainIndex
  local timer_cycle = opt.get_option('timer_cycle')

  timer:start(100, timer_cycle, vim.schedule_wrap(function()
    local l_changedTick = api.nvim_buf_get_changedtick(0)
    -- complete if changes are made
    if l_changedTick ~= manager.changedTick then
      manager.changedTick = l_changedTick
      if opt.get_option('enable_auto_popup') == 1 then
        source.autoCompletion()
      end
      if opt.get_option('enable_auto_hover') == 1 then
        hover.autoOpenHoverInPopup(manager)
      end
      if opt.get_option('enable_auto_signature') == 1 then
        signature.autoOpenSignatureHelp()
      end
    end
    -- change source if no item is available
    if manager.changeSource and autoChange then
      manager.changeSource = false
      if manager.chainIndex ~= source.chain_complete_length then
        manager.chainIndex = manager.chainIndex + 1
        l_complete_index = manager.chainIndex
        manager.insertChar = true
        source.triggerCompletion(false, manager)
      else
        source.stop_complete = true
      end
    end
    -- force trigger completion when manaully chaging source
    if l_complete_index ~= manager.chainIndex then
      -- force clear completion
      if vim.api.nvim_get_mode()['mode'] == 'i' or vim.api.nvim_get_mode()['mode'] == 'ic' then
        vim.fn.complete(vim.api.nvim_win_get_cursor(0)[2], {})
      end
      source.triggerCompletion(false, manager)
      l_complete_index = manager.chainIndex
    end
    -- closing timer if leaving insert mode
    if manager.insertLeave == true and timer:is_closing() == false then
      timer:stop()
      timer:close()
    end
  end))
end

-- handle completion confirmation and dismiss hover popup
function M.on_CompleteDone()
  if manager.confirmedCompletion then
    manager.confirmedCompletion = false
    hasConfirmedCompletion()
    -- auto trigger signature help when we confirm completion
    if vim.g.completion_enable_auto_signature ~= 0 then
      signature.autoOpenSignatureHelp()
    end
  end
  if hover.winnr ~= nil and api.nvim_win_is_valid(hover.winnr) then
    api.nvim_win_close(hover.winnr, true)
  end
end

M.on_attach = function(option)
  -- setup completion_option tables
  opt.set_option_table(option)
  -- setup autocommand
  -- TODO: Modified this if lua callbacks for autocmd is merged
  api.nvim_command("augroup CompletionCommand")
    api.nvim_command("autocmd! * <buffer>")
    api.nvim_command("autocmd InsertEnter <buffer> lua require'completion'.on_InsertEnter()")
    api.nvim_command("autocmd InsertLeave <buffer> lua require'completion'.on_InsertLeave()")
    api.nvim_command("autocmd InsertCharPre <buffer> lua require'completion'.on_InsertCharPre()")
    api.nvim_command("autocmd CompleteDone <buffer> lua require'completion'.on_CompleteDone()")
  api.nvim_command("augroup end")
  if string.len(opt.get_option('confirm_key')) ~= 0 then
    api.nvim_buf_set_keymap(0, 'i', opt.get_option('confirm_key'),
      'pumvisible() ? complete_info()["selected"] != "-1" ? "\\<Plug>(completion_confirm_completion)" :'..
      ' "\\<c-e>\\<CR>" : "\\<CR>"',
      {silent=false, noremap=false, expr=true})
  end
  vim.b.completion_enable = 1
end

return M
