local vim = vim
local api = vim.api
local util = require 'utility'

local M = {}

local function ok_or_nil(status, ...)
  if not status then return end
  return ...
end

local function npcall(fn, ...)
  return ok_or_nil(pcall(fn, ...))
end

local function find_window_by_var(name, value)
  for _, win in ipairs(api.nvim_list_wins()) do
    if npcall(api.nvim_win_get_var, win, name) == value then
      return win
    end
  end
end

local function focusable_float(unique_name, fn)
  if npcall(api.nvim_win_get_var, 0, unique_name) then
    return api.nvim_command("wincmd p")
  end
  local bufnr = api.nvim_get_current_buf()
  do
    local win = find_window_by_var(unique_name, bufnr)
    if win then
      if api.nvim_get_var('completion_enable_focusable_hover') == 0 then
        api.nvim_win_close(win, true)
      else
        api.nvim_set_current_win(win)
        api.nvim_command("stopinsert")
        return
      end
    end
  end
  local pbufnr, pwinnr = fn()
  if pbufnr then
    api.nvim_win_set_var(pwinnr, unique_name, bufnr)
    return pbufnr, pwinnr
  end
end

-- Modify hover callback
function M.modifyCallback()
  local callback = 'textDocument/hover'
  vim.lsp.callbacks[callback] = function(_, method, result)
    -- if M.winnr ~= nil and api.nvim_win_is_valid(M.winnr) then
      -- api.nvim_win_close(M.winnr, true)
    -- end
    focusable_float(method, function()
      if not (result and result.contents) then
        -- return { 'No information available' }
        return
      end
      local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
      markdown_lines = vim.lsp.util.trim_empty_lines(markdown_lines)
      if vim.tbl_isempty(markdown_lines) then
        -- return { 'No information available' }
        return
      end
      local bufnr, winnr = nil, nil
      -- modified to open hover window align to popupmenu
      if vim.fn.pumvisible() == 1 then
        local position = vim.fn.pum_getpos()
        -- Set max width option to avoid overlapping with popup menu
        local total_column = api.nvim_get_option('columns')
        local align
        if position['col'] < total_column/2 then
          align = 'right'
        else
          align = 'left'
        end

        bufnr, winnr = util.fancy_floating_markdown(markdown_lines, {
          pad_left = 1; pad_right = 1;
          col = position['col']; width = position['width']; row = position['row']-1;
          align = align
        })
        M.winnr = winnr
      else
        bufnr, winnr = vim.lsp.util.fancy_floating_markdown(markdown_lines, {
          pad_left = 1; pad_right = 1;
        })
      end
      vim.lsp.util.close_preview_autocmd({"CursorMoved", "BufHidden", "InsertCharPre"}, winnr)
      return bufnr, winnr
    end)
  end
end

return M
