local M = {}
local vim = vim
local loop = vim.loop
local api = vim.api

M.items = {}
M.callback = false

-- onread handler for vim.loop
local function onread(err, data)
  if err then
    -- print('ERROR: ', err)
    -- TODO handle err
  end
  if data then
    for i in string.gmatch(data, "%S+") do
      if #i ~= 0 then
        table.insert(M.items, i)
      end
    end
  end
end

M.getCompletionItems = function(prefix, score_func)
  local complete_items = {}
  for _, val in ipairs(M.items) do
    local score = score_func(prefix, val)
    if score < #prefix/3 or #prefix == 0 then
      table.insert(complete_items, {
        word = val,
        kind = 'Path',
        score = score,
        icase = 1,
        dup = 1,
        empty = 1,
      })
    end
  end
  -- print(vim.inspect(complete_items))
  return complete_items
end

M.getCallback = function()
  return M.callback
end

M.triggerFunction = function(_, _, _, manager)
  local pos = api.nvim_win_get_cursor(0)
  local line = api.nvim_get_current_line()
  local line_to_cursor = line:sub(1, pos[2])
  local textMatch = vim.fn.match(line_to_cursor, '\\f*$')
  local keyword = line_to_cursor:match("%s*(%S+)%w*/.*$")
  local path = vim.fn.expand('%:p:h')
  if keyword ~= nil then
    -- dealing with special case in matching
    if string.sub(keyword, 1, 1) == "\"" or string.sub(keyword, 1, 1) == "'" then
      keyword = string.sub(keyword, 2, #keyword)
    end
    path = path..'/'..keyword
  end
  path = vim.fn.glob(path)
  M.items = {}
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local handle, pid
  handle, pid = vim.loop.spawn('ls', {
    args = {path, '-A'},
    stdio = {stdout,stderr}
    },
    vim.schedule_wrap(function()
      stdout:read_stop()
      stderr:read_stop()
      stdout:close()
      stderr:close()
      handle:close()
      M.callback = true
    end
    ))
  vim.loop.read_start(stdout, onread)
  vim.loop.read_start(stderr, onread)
end

return M
