local vim = vim
local validate = vim.validate
local api = vim.api

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

---------------------------------
--  floating window for hover  --
---------------------------------
local make_floating_popup_options = function(width, height, opts)
  validate {
    opts = { opts, 't', true };
  }
  opts = opts or {}
  validate {
    ["opts.offset_x"] = { opts.offset_x, 'n', true };
    ["opts.offset_y"] = { opts.offset_y, 'n', true };
  }


  local lines_above = vim.fn.winline() - 1
  local lines_below = vim.fn.winheight(0) - lines_above

  local col

  if lines_above < lines_below then
    height = math.min(lines_below, height)
  else
    height = math.min(lines_above, height)
  end

  if opts.align == 'right' then
    col = opts.col + opts.width
  else
    col = opts.col - width - 1
  end

  return {
    col = col,
    height = height,
    relative = 'editor',
    row = opts.row,
    focusable = false,
    style = 'minimal',
    width = width,
  }
end

local fancy_floating_markdown = function(contents, opts)
  local pad_left = opts and opts.pad_left
  local pad_right = opts and opts.pad_right
  local stripped = {}
  local highlights = {}

  local max_width
  if opts.align == 'right' then
    local columns = api.nvim_get_option('columns')
    max_width = columns - opts.col - opts.width
  else
    max_width = opts.col - 1
  end

  do
    local i = 1
    while i <= #contents do
      local line = contents[i]
      local ft = line:match("^```([a-zA-Z0-9_]*)$")
      if ft then
        local start = #stripped
        i = i + 1
        while i <= #contents do
          line = contents[i]
          if line == "```" then
            i = i + 1
            break
          end
          if #line > max_width then
            while #line > max_width do
              local trimmed_line = string.sub(line, 1, max_width)
              local index = trimmed_line:reverse():find(" ")
              if index == nil or index > #trimmed_line/2 then
                break
              else
                table.insert(stripped, string.sub(line, 1, max_width-index))
                line = string.sub(line, max_width-index+2, #line)
              end
            end
            table.insert(stripped, line)
          else
            table.insert(stripped, line)
          end
          i = i + 1
        end
        table.insert(highlights, {
          ft = ft;
          start = start + 1;
          finish = #stripped + 1 - 1
        })
      else
        if #line > max_width then
          while #line > max_width do
            local trimmed_line = string.sub(line, 1, max_width)
            -- local index = math.max(trimmed_line:reverse():find(" "), trimmed_line:reverse():find("/"))
            local index = trimmed_line:reverse():find(" ")
            if index == nil or index > #trimmed_line/2 then
              break
            else
              table.insert(stripped, string.sub(line, 1, max_width-index))
              line = string.sub(line, max_width-index+2, #line)
            end
          end
          table.insert(stripped, line)
        else
          table.insert(stripped, line)
        end
        i = i + 1
      end
    end
  end
  -- print(vim.inspect(stripped))
  local width = 0
  for i, v in ipairs(stripped) do
    v = v:gsub("\r", "")
    if pad_left then v = (" "):rep(pad_left)..v end
    if pad_right then v = v..(" "):rep(pad_right) end
    stripped[i] = v
    width = math.max(width, #v)
  end

  if opts.align == 'right' then
    local columns = api.nvim_get_option('columns')
    if opts.col + opts.row + width > columns then
      width = columns - opts.col - opts.width -1
    end
  else
    if width > opts.col then
      width = opts.col - 1
    end
  end

  local insert_separator = true
  if insert_separator then
    for i, h in ipairs(highlights) do
      h.start = h.start + i - 1
      h.finish = h.finish + i - 1
      if h.finish + 1 <= #stripped then
        table.insert(stripped, h.finish + 1, string.rep("─", width))
      end
    end
  end


  -- Make the floating window.
  local height = #stripped
  local bufnr = api.nvim_create_buf(false, true)
  local winnr = api.nvim_open_win(bufnr, false, make_floating_popup_options(width, height, opts))
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, stripped)

  local cwin = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(winnr)

  vim.cmd("ownsyntax markdown")
  local idx = 1
  local function highlight_region(ft, start, finish)
    if ft == '' then return end
    local name = ft..idx
    idx = idx + 1
    local lang = "@"..ft:upper()
    -- TODO(ashkan): better validation before this.
    if not pcall(vim.cmd, string.format("syntax include %s syntax/%s.vim", lang, ft)) then
      return
    end
    vim.cmd(string.format("syntax region %s start=+\\%%%dl+ end=+\\%%%dl+ contains=%s", name, start, finish + 1, lang))
  end
  for _, h in ipairs(highlights) do
    highlight_region(h.ft, h.start, h.finish)
  end

  vim.api.nvim_set_current_win(cwin)
  return bufnr, winnr
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
      local bufnr, winnr
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

        bufnr, winnr = fancy_floating_markdown(markdown_lines, {
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
