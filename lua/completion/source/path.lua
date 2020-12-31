local M = {}
local vim = vim
local loop = vim.loop
local api = vim.api
local util = require 'completion.util'
local opt = require 'completion.option'

M.items = {}
M.callback = false

-- onDirScanned handler for vim.loop
local function onDirScanned(_, data)
  if data then
    local function iter()
      return vim.loop.fs_scandir_next(data)
    end
    for name, type in iter do
      table.insert(M.items, {type = type, name=name})
    end
  end
  M.callback = true
end


local fileTypesMap = setmetatable({
    file = "(file)",
    directory = "(dir)",
    char = "(char)",
    link = "(link)",
    block = "(block)",
    fifo = "(pipe)",
    socket = "(socket)"
}, {__index = function()
    return '(unknown)'
  end
})

M.getCompletionItems = function(prefix)
  local complete_items = {}
  local kind = 'Path'
  kind = opt.get_option('customize_lsp_label')[kind] or kind
  for _, val in ipairs(M.items) do
    local score = util.fuzzy_score(prefix, val.name)
    if score < #prefix/3 or #prefix == 0 then
      table.insert(complete_items, {
        word = val.name,
        kind = kind,
        menu = fileTypesMap[val.type],
        score = score,
        icase = 1,
        dup = 1,
        empty = 1,
      })
    end
  end
  return complete_items
end

M.getCallback = function()
  return M.callback
end

M.triggerFunction = function(_, opt)
  local keyword
  if vim.v.completed_item ~= nil and vim.v.completed_item.kind == 'Path' and
    opt.line_to_cursor:find(vim.v.completed_item.word) then
    keyword = M.keyword..vim.v.completed_item.word..'/'
  else
    M.keyword = nil
    keyword = opt.line_to_cursor:match("[^%s\"\']+%S*/?$")
  end

  if keyword ~= nil and keyword ~= '/' then
    local index = string.find(keyword:reverse(), '/')
    if index == nil then index = keyword:len() + 1 end
    local length = string.len(keyword) - index + 1
    keyword = string.sub(keyword, 1, length)
  end

  local path = vim.fn.expand('%:p:h')
  if keyword ~= nil then
    local expanded_keyword = vim.fn.glob(keyword)
    local home = vim.fn.expand("$HOME")
    if expanded_keyword:sub(1, 1) == '/' or string.find(expanded_keyword, home) ~= nil then
      path = expanded_keyword
    else
      path = vim.fn.expand('%:p:h')
      path = path..'/'..keyword
    end
  end

  M.keyword = keyword
  M.items = {}
  loop.fs_scandir(path, onDirScanned)
end

return M
