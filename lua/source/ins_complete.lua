-- luacheck: globals vim
local vim = vim
local api = vim.api
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

local checkEmptyCompletion = function(manager)
  local timer = vim.loop.new_timer()
  timer:start(200, 0, vim.schedule_wrap(function()
    if vim.fn.pumvisible() == 0 then
      manager.changeSource = true
    else
      manager.insertChar = false
      manager.changeSource = false
    end
    timer:stop()
    timer:close()
  end))
end

M.triggerCompletion = function(manager, mode)
  if manager.insertChar == true and vim.fn.pumvisible() == 0 then
    api.nvim_input(ins_complete_table[mode])
    checkEmptyCompletion(manager)
  end
end

return M

