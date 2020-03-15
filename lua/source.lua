local vim = vim
local lsp = require 'source.lsp'
local snippet = require 'source.snippet'
local ins = require 'source.ins_complete'

local M = {}

local chain_complete_list = {
  {
    ins_complete = false,
    trigger_function = lsp.triggerCompletion,
  },
  {
    ins_complete = false,
    trigger_function = snippet.triggerCompletion,
  },
  {
    ins_complete = true,
    mode = 'keyn'
  },
  {
    ins_complete = true,
    mode = 'keyp'
  },
}


M.chain_complete_index = 1
M.stop_complete = false

function M.triggerCurrentCompletion(Manager, bufnr, prefix, textMatch)
  if vim.api.nvim_get_mode()['mode'] == 'i' or vim.api.nvim_get_mode()['mode'] == 'ic' then
    local complete_source = chain_complete_list[M.chain_complete_index]
    if complete_source.ins_complete == true then
      ins.triggerCompletion(Manager, complete_source.mode)
    else
      complete_source.trigger_function(Manager, bufnr, prefix, textMatch)
    end
  end
end

function M.nextCompletion()
  if M.chain_complete_index ~= #chain_complete_list then
    M.chain_complete_index = M.chain_complete_index + 1
  else
    print('no next completion method')
    -- Avoid keep completing if no source are avaiable
    M.stop_complete = true
  end
end

function M.prevCompletion()
  if M.chain_complete_index ~= 1 then
    M.chain_complete_index = M.chain_complete_index - 1
  else
    print('no previous completion method')
  end
end

function M.on_InsertEnter()
end
  

return M
