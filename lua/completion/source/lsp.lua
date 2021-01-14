local vim = vim
local protocol = require 'vim.lsp.protocol'
local util = require 'completion.util'
local match = require 'completion.matching'
local opt = require 'completion.option'
local M = {}

M.callback = false

M.isIncomplete = true

M.getCompletionItems = function(_, _)
  return M.items
end

local function sort_completion_items(items)
  table.sort(items, function(a, b)
    return (a.sortText or a.label) < (b.sortText or b.label)
  end)
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
    if protocol.InsertTextFormat[item.insertTextFormat] == "PlainText"
		or opt.get_option('enable_snippet') == "snippets.nvim" then
      return newText
    else
      return vim.lsp.util.parse_snippet(newText)
    end
  elseif item.insertText ~= nil and item.insertText ~= vim.NIL then
    if protocol.InsertTextFormat[item.insertTextFormat] == "PlainText"
		or opt.get_option('enable_snippet') == "snippets.nvim" then
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
  if #nextWord == 0 then
    return
  end
  for _,ch in ipairs(vim.g.completion_expand_characters) do
    if nextWord == ch then
      return
    end
  end
  item.user_data = {}
  local matches, word
  word, matches = item.word:gsub("%(.*%)$", "")
  if matches == 0 then
    word, matches = item.word:gsub("<.*>$", "")
  end
  if matches ~= 0 then
    item.word = word
  end
end

local function text_document_completion_list_to_complete_items(result, params)
  local items = vim.lsp.util.extract_completion_items(result)
  if vim.tbl_isempty(items) then
    return {}
  end

  local customize_label = opt.get_option('customize_lsp_label')
  -- items = remove_unmatch_completion_items(items, prefix)
  sort_completion_items(items)

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

    item.word = get_completion_word(completion_item, params.prefix, params.suffix)
    item.word = item.word:gsub('\n', ' ')
    item.word = vim.trim(item.word)
    item.dup = opt.get_option("items_duplicate")['lsp']
    item.user_data = {
      lsp = {
        completion_item = completion_item,
      }
    }
	if protocol.InsertTextFormat[completion_item.insertTextFormat] == 'Snippet'
		and opt.get_option('enable_snippet') == "snippets.nvim" then
	  item.user_data.actual_item = item.word
	  item.word = vim.trim(completion_item.label)
	end
    local kind = protocol.CompletionItemKind[completion_item.kind]
    item.kind = customize_label[kind] or kind
    item.abbr = vim.trim(completion_item.label)
    if params.suffix ~= nil and #params.suffix ~= 0 then
      local index = item.word:find(params.suffix)
      if index ~= nil then
        local newWord = item.word
        newWord = newWord:sub(1, index-1)
        item.word = newWord
        item.user_data = {}
      end
    end
    get_context_aware_snippets(item, completion_item, params.line_to_cursor)
    item.priority = opt.get_option('items_priority')[item.kind] or opt.get_option('items_priority')[kind]
    item.menu = completion_item.detail or ''
    match.matching(matches, params.prefix, item)
  end

  return matches
end

M.getCallback = function()
  return M.callback
end

M.triggerFunction = function(_, params)
  local position_param = vim.lsp.util.make_position_params()
  M.callback = false
  M.items = {}
  if vim.tbl_isempty(vim.lsp.buf_get_clients()) then
    M.callback = true
    return
  end
  vim.lsp.buf_request(params.bufnr, 'textDocument/completion', position_param, function(err, _, result)
    if err or not result then
      M.callback = true
      return
    end
    local matches = text_document_completion_list_to_complete_items(result, params)
    M.items = matches
    M.isIncomplete = result.isIncomplete
    M.callback = true
  end)
end

return M
