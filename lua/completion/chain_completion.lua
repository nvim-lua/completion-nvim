local vim = vim
local api = vim.api
local util = require 'completion.util'
local opt = require 'completion.option'
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

local function getScopedChain(ft_subtree)

  local syntax_getter = function()
    local pos = api.nvim_win_get_cursor(0)
    return vim.fn.synIDattr(vim.fn.synID(pos[1], pos[2]-1, 1), "name")
  end

  -- If this option is effectively a function, use it to determine syntax group at point
  local syntax_at_point = opt.get_option("syntax_at_point")
  if syntax_at_point then
      if vim.is_callable(syntax_at_point) then
          syntax_getter = syntax_at_point
      elseif type(syntax_at_point) == "string" and vim.fn.exists("*" .. syntax_at_point) then
          syntax_getter = vim.fn[syntax_at_point]
      end
  end

  local atPoint = syntax_getter():lower()
  for syntax_regex, complete_list in pairs(ft_subtree) do
    if type(syntax_regex) == "string" and string.match(atPoint, '.*' .. syntax_regex:lower() .. '.*') ~= nil and syntax_regex ~= "default" then
      return complete_list
    end
  end

  return nil
end

-- preserve compatiblity of completion_chain_complete_list
function M.getChainCompleteList(filetype)

  local chain_complete_list = chain_list_to_tree(opt.get_option('chain_complete_list'))
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
    if chain_complete_list ~= nil then
      for _,complete_source in ipairs(chain_complete_list) do
        if vim.fn.has_key(complete_source, "complete_items") > 0 then
          for _,item in ipairs(complete_source.complete_items) do
            if complete_items_map[item] == nil then
              health_error(item.." is not a valid completion source (in filetype "..filetype..")")
              error = true
            end
          end
        else
          local ins = require 'completion.source.ins_complete'
          if ins.checkHealth(complete_source.mode) then
            health_error(complete_source.mode.." is not a valid insert completion mode")
          end
        end
      end
    end
  end
  if not error then
    health_ok("all completion sources are valid")
  end
end

return M
