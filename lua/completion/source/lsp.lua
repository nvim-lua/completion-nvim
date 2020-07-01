local vim = vim
local protocol = require 'vim.lsp.protocol'
local util = require 'completion.util'
local match = require 'completion.matching'
local M = {}

M.callback = false

M.getCompletionItems = function(_, _)
  return M.items
end

local function get_completion_word(item, prefix, suffix)
  if item.textEdit ~= nil and item.textEdit ~= vim.NIL
    and item.textEdit.newText ~= nil and (item.insertTextFormat ~= 2 or vim.fn.exists('g:loaded_vsnip_integ')) then
      local start_range = item.textEdit.range["start"]
      local end_range = item.textEdit.range["end"]
      local newText
      if start_range.line == end_range.line and start_range.character == end_range.character then
          newText = prefix .. item.textEdit.newText
      else
          newText = item.textEdit.newText
      end
    if protocol.InsertTextFormat[item.insertTextFormat] == "PlainText" then
      return newText
    else
      return vim.lsp.util.parse_snippet(newText)
    end
  elseif item.insertText ~= nil and item.insertText ~= vim.NIL then
    if protocol.InsertTextFormat[item.insertTextFormat] == "PlainText" then
      return item.insertText
    else
      return vim.lsp.util.parse_snippet(item.insertText)
    end
  end
  return item.label
end

local function get_context_aware_snippets(item, completion_item, line_to_cursor)
  if protocol.InsertTextFormat[completion_item.insertTextFormat] == "PlainText" then
    return
  end
  local line = vim.api.nvim_get_current_line()
  local nextWord = line:sub(#line_to_cursor+1, #line_to_cursor+1)
  if nextWord == " " or #nextWord == 0 then
    return
  else
    local matches
    word, matches = item.word:gsub("%(.*%)$", "")
    if matches == 0 then
      word, matches = item.word:gsub("<.*>$", "")
    end
    if matches ~= 0 then
      item.word = word
      item.user_data = {}
    end
  end
end

local function text_document_completion_list_to_complete_items(result, opt)
  local items = vim.lsp.util.extract_completion_items(result)
  if vim.tbl_isempty(items) then
    return {}
  end

  local customize_label = vim.g.completion_customize_lsp_label
  -- items = remove_unmatch_completion_items(items, prefix)
  -- sort_completion_items(items)

  local matches = {}

  for _, completion_item in ipairs(items) do
    local item = {}
    local info = ' '
    local documentation = completion_item.documentation
    if documentation then
      if type(documentation) == 'string' and documentation ~= '' then
        info = documentation
      elseif type(documentation) == 'table' and type(documentation.value) == 'string' then
        info = documentation.value
      end
    end
    item.info = info

    item.word = get_completion_word(completion_item, opt.prefix, opt.suffix)
    item.user_data = {
      lsp = {
        completion_item = completion_item,
      }
    }
    local kind = protocol.CompletionItemKind[completion_item.kind]
    item.kind = customize_label[kind] or kind
    item.abbr = completion_item.label
    if opt.suffix ~= nil and #opt.suffix ~= 0 then
      local index = item.word:find(opt.suffix)
      if index ~= nil then
        local newWord = item.word
        newWord = newWord:sub(1, index-1)
        item.word = newWord
        item.user_data = {}
      end
    end
    get_context_aware_snippets(item, completion_item, opt.line_to_cursor)
    item.priority = vim.g.completion_items_priority[item.kind]
    item.menu = completion_item.detail or ''
    match.matching(matches, opt.prefix, item)
  end

  return matches
end

M.getCallback = function()
  return M.callback
end

M.triggerFunction = function(manager, opt)
  local params = vim.lsp.util.make_position_params()
  M.callback = false
  M.items = {}
  if #vim.lsp.buf_get_clients() == 0 then
    M.callback = true
    return
  end
  vim.lsp.buf_request(opt.bufnr, 'textDocument/completion', params, function(err, _, result)
    if err or not result then
      M.callback = true
      return
    end
    local matches = text_document_completion_list_to_complete_items(result, opt)
    M.items = matches
    M.callback = true
  end)
end

return M
