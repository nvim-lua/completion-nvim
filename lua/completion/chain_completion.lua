local vim = vim
local api = vim.api
local util = require 'completion.util'
local M ={}

--------------------------------------------------------------
--  local function to parse completion_chain_complete_list  --
--------------------------------------------------------------
local function chain_list_to_tree(complete_list)
  if util.is_list(complete_list) then
    return {
      default = {
          default= complete_list
      }
    }
  else
    local complete_tree = {}
    for ft, c_list in pairs(complete_list) do
      if util.is_list(c_list) then
        complete_tree[ft] = {
          default=c_list
        }
      else
      complete_tree[ft] = c_list
      end
    end

    -- Be sure that default.default exists
    if not complete_tree.default then
      complete_tree.default = {
        default = {
          { complete_items={ 'lsp', 'snippet' } }
        }
      }
    end
    return complete_tree
  end
end

function getScopedChain(ft_subtree)

  local function syntaxGroupAtPoint()
    local pos = api.nvim_win_get_cursor(0)
    return vim.fn.synIDattr(vim.fn.synID(pos[1], pos[2]-1, 1), "name")
  end

  local VAR_NAME = "completion_syntax_at_point"

  local syntax_getter

  -- If this option is effectively a function, use it to determine syntax group at point
  if vim.fn.exists("g:" .. VAR_NAME) > 0 and vim.is_callable(api.nvim_get_var(VAR_NAME)) > 0 then
    syntax_getter = api.nvim_get_var(VAR_NAME)
  else
    syntax_getter = syntaxGroupAtPoint
  end

  local atPoint = syntax_getter():lower()
  for syntax_regex, complete_list in pairs(ft_subtree) do
    if string.match(atPoint, '.*' .. syntax_regex:lower() .. '.*') ~= nil and syntax_regex ~= "default" then
      return complete_list
    end
  end

  return nil
end

-- preserve compatiblity of completion_chain_complete_list
function M.getChainCompleteList(filetype)

  local chain_complete_list = chain_list_to_tree(vim.g.completion_chain_complete_list)
  -- check if chain_complete_list is a array

  if chain_complete_list[filetype] then
    return getScopedChain(chain_complete_list[filetype])
    or getScopedChain(chain_complete_list.default)
    or chain_complete_list[filetype].default
    or chain_complete_list.default.default
  else
    return getScopedChain(chain_complete_list.default) or chain_complete_list.default.default
  end
end

function M.checkHealth(complete_items_map)
  local completion_list = vim.g.completion_chain_complete_list
  local health_ok = vim.fn['health#report_ok']
  local health_error = vim.fn['health#report_error']
  local error = false
  for filetype, _ in pairs(completion_list) do
    local chain_complete_list
    if filetype ~= 'default' then
      chain_complete_list = M.getChainCompleteList(filetype)
    else
      chain_complete_list = getScopedChain(completion_list.default) or completion_list.default.default
    end
    for _,complete_source in ipairs(chain_complete_list) do
      if vim.fn.has_key(complete_source, "complete_items") > 0 then
        for _,item in ipairs(complete_source.complete_items) do
          if complete_items_map[item] == nil then
            health_error(item.." is not a valid completion source (in filetype "..filetype..")")
            error = true
          end
        end
      else
        local ins = require 'source.ins_complete'
        if ins.checkHealth(complete_source.mode) then
          health_error(complete_source.mode.." is not a valid insert complete mode")
        end
      end
    end
  end
  if not error then
    health_ok("all completion source are valid")
  end
  
end

return M
