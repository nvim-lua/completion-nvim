local vim = vim
local protocol = require 'vim.lsp.protocol'
local util = require 'completion.util'
local match = require 'completion.matching'
local M = {}

M.callback = false

M.getCompletionItems = function(_, _)
  return M.items
end

local function get_completion_word(item)
  if item.textEdit ~= nil and item.textEdit.newText ~= nil then
    if protocol.InsertTextFormat[item.insertTextFormat] == "PlainText" then
      return item.textEdit.newText
    else
      -- workaround to prevent compatibility issue
      if vim.lsp.util.parse_snippet ~= nil then
        return vim.lsp.util.parse_snippet(item.textEdit.newText)
      else
        return item.textEdit.newText
      end
    end
  elseif item.insertText ~= nil then
    if protocol.InsertTextFormat[item.insertTextFormat] == "PlainText" then
      return item.insertText
    else
      -- workaround to prevent compatibility issue
      if vim.lsp.util.parse_snippet ~= nil then
        return vim.lsp.util.parse_snippet(item.insertText)
      else
        return item.insertText
      end
    end
  end
  return item.label
end

local function text_document_completion_list_to_complete_items(result, prefix)
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
    if vim.fn.exists('g:loaded_vsnip_integ') == 1 then
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
      item.info = info

      item.word = get_completion_word(completion_item)
      item.user_data = {
        lsp = {
          completion_item = completion_item
        }
      }
      local kind = protocol.CompletionItemKind[completion_item.kind]
      item.kind = customize_label[kind] or kind
      item.abbr = completion_item.label
      item.priority = vim.g.completion_items_priority[item.kind]
      item.menu = completion_item.detail or ''

      match.matching(matches, prefix, item)
    end
  end

  return matches
end

M.getCallback = function()
  return M.callback
end

M.triggerFunction = function(prefix, _, bufnr, _)
  local params = vim.lsp.util.make_position_params()
  M.callback = false
  M.items = {}
  if #vim.lsp.buf_get_clients() == 0 then
    M.callback = true
    return
  end
  vim.lsp.buf_request(bufnr, 'textDocument/completion', params, function(err, _, result)
    if err or not result then
      M.callback = true
      return
    end
    local matches = text_document_completion_list_to_complete_items(result, prefix, util.fuzzy_score)
    M.items = matches
    M.callback = true
  end)
end

return M
