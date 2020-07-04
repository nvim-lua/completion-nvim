local M = {}


-- fallback to using global variable as default
local completion_opt_metatable = {
  __index = function(_, key)
    key = 'completion_'..key
    return vim.g[key]
  end
}

local option_table = setmetatable({}, completion_opt_metatable)

M.set_option_table = function(opt)
  if opt ~= nil then
    option_table = setmetatable(opt, completion_opt_metatable)
  else
    option_table = setmetatable({}, completion_opt_metatable)
  end
end

M.get_option = function(opt)
  return option_table[opt]
end

return M
