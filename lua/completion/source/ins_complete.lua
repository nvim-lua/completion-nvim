-- luacheck: globals vim
local vim = vim
local api = vim.api
local manager = require 'completion.manager'
local M = {}

local ins_complete_table = {
  ['line'] = "<c-x><c-l>",
  ['cmd'] = "<c-x><c-v>",
  ['defs'] = "<c-x><c-d>",
  ['dict'] = "<c-x><c-k>",
  ['file'] = "<c-x><c-f>",
  ['incl'] = "<c-x><c-i>",
  ['keyn'] = "<c-x><c-n>",
  ['keyp'] = "<c-x><c-p>",
  ['omni'] = "<c-x><c-o>",
  ['spel'] = "<c-x>s",
  ['tags'] = "<c-x><c-]>",
  ['thes'] = "<c-x><c-t>",
  ['user'] = "<c-x><c-u>",
  ['<c-p>'] = "<c-g><c-g><c-p>",
  ['<c-n>'] = "<c-g><c-g><c-n>",
}

-- HACK workaround to handle delay of ins-complete
local checkEmptyCompletion = function()
  local timer = vim.loop.new_timer()
  timer:start(200, 0, vim.schedule_wrap(function()
    if vim.fn.pumvisible() == 0 then
      manager.changeSource = true
    else
      manager.changeSource = false
    end
    timer:stop()
    timer:close()
  end))
end

M.checkHealth = function(mode)
  if ins_complete_table[mode] == nil then
    return false
  end
end

M.triggerCompletion = function(mode)
  if ins_complete_table[mode] == nil then return end
  if vim.fn.pumvisible() == 0 then
    if vim.api.nvim_get_mode()['mode'] == 'i' or vim.api.nvim_get_mode()['mode'] == 'ic' then
      local mode_keys = ins_complete_table[mode]
      -- See https://github.com/neovim/neovim/issues/12297.
      mode_keys = api.nvim_replace_termcodes(mode_keys, true, false, true)
      api.nvim_feedkeys(mode_keys, 'n', true)
      checkEmptyCompletion()
    end
  else
    manager.insertChar = false
  end
end

return M

