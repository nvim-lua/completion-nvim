local protocol = require 'vim.lsp.protocol'
local vim = vim
local validate = vim.validate
local api = vim.api
local M = {}

------------------------------------------------------------------------
--      utility function that are modified from neovim's source       --
------------------------------------------------------------------------

------------------------
--  completion items  --
------------------------
local function remove_unmatch_completion_items(items, prefix)
  return vim.tbl_filter(function(item)
    local word = item.insertText or item.label
    return vim.startswith(word, prefix)
  end, items)
end

function M.sort_completion_items(items)
  table.sort(items, function(a, b) return string.len(a.word) < string.len(b.word)
  end)
end

function M.text_document_completion_list_to_complete_items(result, prefix)
  local items = vim.lsp.util.extract_completion_items(result)
  if vim.tbl_isempty(items) then
    return {}
  end

  items = remove_unmatch_completion_items(items, prefix)
  -- sort_completion_items(items)

  local matches = {}

  for _, completion_item in ipairs(items) do
    -- skip snippets items
    if protocol.CompletionItemKind[completion_item.kind] ~= 'Snippet' then
      local info = ' '
      local documentation = completion_item.documentation
      if documentation then
        if type(documentation) == 'string' and documentation ~= '' then
          info = documentation
        elseif type(documentation) == 'table' and type(documentation.value) == 'string' then
          info = documentation.value
        -- else
          -- TODO(ashkan) Validation handling here?
        end
      end

      local word = completion_item.insertText or completion_item.label
      table.insert(matches, {
        word = word,
        abbr = completion_item.label,
        kind = protocol.CompletionItemKind[completion_item.kind] or '',
        menu = completion_item.detail or '',
        info = info,
        icase = 1,
        dup = 1,
        empty = 1,
      })
    end
  end

  return matches
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

M.fancy_floating_markdown = function(contents, opts)
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

-- Check trigger character
M.checkTriggerCharacter = function(line_to_cursor)
  local trigger_character = api.nvim_get_var('completion_trigger_character')
  for _, ch in ipairs(trigger_character) do
    local current_char = string.sub(line_to_cursor, #line_to_cursor-#ch+1, #line_to_cursor)
    if current_char == ch then
      return true
    end
  end
  return false
end

return M
