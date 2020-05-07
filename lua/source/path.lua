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
    local vals = vim.split(data, "\n")
    for _,i in pairs(vals) do
      if #i ~= 0 then
        table.insert(M.items, {t = i:sub(1,1), name = i:sub(3)})
      end
    end
  end
end

local fileTypesMap = {
    ['f'] = "(file)",
    ['d'] = "(dir)",
    ['c'] = "(char)",
    ['l'] = "(link)",
    ['b'] = "(block)",
    ['p'] = "(pipe)",
    ['s'] = "(socket)"
}

M.getCompletionItems = function(prefix, score_func)
  local complete_items = {}
  for _, val in ipairs(M.items) do
    local score = score_func(prefix, val.name)
    if score < #prefix/3 or #prefix == 0 then
      table.insert(complete_items, {
        word = val.name,
        kind = 'Path ' .. fileTypesMap[val.t],
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
  local keyword = line_to_cursor:sub(textMatch+1)
  if keyword ~= '/' then
    keyword = keyword:match("%s*(%S+)%w*/.*$")
  end
  local path = vim.fn.expand('%:p:h')
  if keyword ~= nil then
    -- dealing with special case in matching
    if keyword == "/" and line:sub(pos[2], pos[2]) then
      path = keyword
      goto continue
    elseif string.sub(keyword, 1, 1) == "\"" or string.sub(keyword, 1, 1) == "'" then
      keyword = string.sub(keyword, 2, #keyword)
    end

    local expanded_keyword = vim.fn.glob(keyword)
    local home = vim.fn.expand("$HOME")
    if expanded_keyword == '/' then
      goto continue
    elseif expanded_keyword ~= nil and expanded_keyword ~= '/' then
      path = expanded_keyword
    else
      path = vim.fn.expand('%:p:h')
      path = path..'/'..keyword
    end
  end

  ::continue::
  path = path..'/'
  M.items = {}
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local handle, pid
  handle, pid = vim.loop.spawn('find', {
    args = {path, '-mindepth', '1', '-maxdepth', '1', '-printf', '%y %f\n'},
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
