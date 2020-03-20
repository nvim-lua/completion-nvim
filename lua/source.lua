local vim = vim
local util = require 'utility'
local lsp = require 'source.lsp'
local snippet = require 'source.snippet'
local ins = require 'source.ins_complete'
local ts = require'source.ts_complete'

local M = {}

local chain_complete_list = {
  {
    ins_complete = false,
    trigger_function = {lsp.getCompletionItems, snippet.getCompletionItems},
  },
  {
    ins_complete = false,
    trigger_function = {snippet.getCompletionItems},
  },
  {
    ins_complete=false,
    trigger_function = {ts.getCompletionItems}
  },
  {
    ins_complete = true,
    mode = '<c-p>'
  },
  {
    ins_complete = true,
    mode = '<c-n>'
  },
}


M.chain_complete_index = 1
M.stop_complete = false
M.chain_complete_length = #chain_complete_list

function M.triggerCurrentCompletion(manager, bufnr, prefix, textMatch)
  if manager.insertChar == false then return end
  if vim.api.nvim_get_mode()['mode'] == 'i' or vim.api.nvim_get_mode()['mode'] == 'ic' then
    local complete_source = chain_complete_list[M.chain_complete_index]
    if complete_source.ins_complete then
      ins.triggerCompletion(manager, complete_source.mode)
    else
      items = {}
      for _, func in ipairs(complete_source.trigger_function) do
        item = func(prefix, util.fuzzy_score, bufnr)
        vim.list_extend(items, item)
      end
      util.sort_completion_items(items)
      vim.fn.complete(textMatch+1, items)
      if #items ~= 0 then
        manager.insertChar = false
        manager.changeSource = false
      else
        manager.changeSource = true
      end
    end
  end
end

function M.nextCompletion()
  if M.chain_complete_index ~= #chain_complete_list then
    M.chain_complete_index = M.chain_complete_index + 1
  else
	M.chain_complete_index = 1
  end
end

function M.prevCompletion()
  if M.chain_complete_index ~= 1 then
    M.chain_complete_index = M.chain_complete_index - 1
  else
	M.chain_complete_index = #chain_complete_list
  end
end

function M.on_InsertEnter()
end
  

return M
