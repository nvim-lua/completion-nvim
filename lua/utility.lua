local vim = vim
local validate = vim.validate
local api = vim.api
local M = {}

------------------------------------------------------------------------
--      utility function that are modified from neovim's source       --
------------------------------------------------------------------------


-- local function copy from neovim's source code
M.signature_help_to_preview_contents = function(input)
  if not input.signatures then
    return
  end
  local contents = {}
  local active_signature = input.activeSignature or 0
  if active_signature >= #input.signatures then
    active_signature = 0
  end
  local signature = input.signatures[active_signature + 1]
  if not signature then
    return
  end
  vim.list_extend(contents, vim.split(signature.label, '\n', true))
  if signature.documentation then
    vim.lsp.util.convert_input_to_markdown_lines(signature.documentation, contents)
  end
  if input.parameters then
    local active_parameter = input.activeParameter or 0
    if active_parameter >= #input.parameters then
      active_parameter = 0
    end
    local parameter = signature.parameters and signature.parameters[active_parameter]
    if parameter then
      if parameter.documentation then
        vim.lsp.util.convert_input_to_markdown_lines(parameter.documentation, contents)
      end
    end
  end
  return contents
end

local make_floating_popup_options = function(width, height, opts)
  validate {
    opts = { opts, 't', true };
  }
  opts = opts or {}
  validate {
    ["opts.offset_x"] = { opts.offset_x, 'n', true };
    ["opts.offset_y"] = { opts.offset_y, 'n', true };
  }

  local anchor = ''
  local row, col

  local lines_above = vim.fn.winline() - 1
  local lines_below = vim.fn.winheight(0) - lines_above

  if lines_above < lines_below then
    anchor = anchor..'N'
    height = math.min(lines_below, height)
    row = 1
  else
    anchor = anchor..'S'
    height = math.min(lines_above, height)
    row = 0
  end

  if vim.fn.wincol() + width <= api.nvim_get_option('columns') then
    anchor = anchor..'W'
    col = 0
  else
    anchor = anchor..'E'
    col = 1
  end

  print(opts.col, opts.row)
  return {
    -- anchor = anchor,
    col = opts.col,
    height = height,
    relative = 'win',
    row = opts.row,
    style = 'minimal',
    width = width,
  }
end

M.fancy_floating_markdown = function(contents, opts)
  local pad_left = opts and opts.pad_left
  local pad_right = opts and opts.pad_right
  local stripped = {}
  local highlights = {}
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
          table.insert(stripped, line)
          i = i + 1
        end
        table.insert(highlights, {
          ft = ft;
          start = start + 1;
          finish = #stripped + 1 - 1;
        })
      else
        table.insert(stripped, line)
        i = i + 1
      end
    end
  end
  local width = 0
  for i, v in ipairs(stripped) do
    v = v:gsub("\r", "")
    if pad_left then v = (" "):rep(pad_left)..v end
    if pad_right then v = v..(" "):rep(pad_right) end
    stripped[i] = v
    width = math.max(width, #v)
  end
  if opts and opts.max_width then
    width = math.min(opts.max_width, width)
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

return M
