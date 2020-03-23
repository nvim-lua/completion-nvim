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
  ['line'] = "<c-x><c-l>",
  ['omni'] = "<c-x><c-o>",
  ['spel'] = "<c-x>s"     ,
  ['tags'] = "<c-x><c-]>",
  ['thes'] = "<c-x><c-t>",
  ['user'] = "<c-x><c-u>",
  ['<c-p>'] = "<c-p>",
  ['<c-n>'] = "<c-n>",
}

local checkEmptyCompletion = function(manager)
  local item = api.nvim_call_function('complete_info', {{"items"}})
  if #item['items'] == 0 then
    manager.changeSource = true
  else
    manager.insertChar = false
    manager.changeSource = false
  end
end

M.triggerCompletion = function(manager, mode)
  if manager.insertChar == true and vim.fn.pumvisible() == 0 then
    if api.nvim_get_mode()['mode'] == 'ic' then
      api.nvim_input("<C-E>")
    end
    api.nvim_input(ins_complete_table[mode])
    checkEmptyCompletion(manager)
  end
end

return M

