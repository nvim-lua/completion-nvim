local vim = vim
local protocol = require 'vim.lsp.protocol'
local api = vim.api
local util = require 'completion.util'
local match = require 'completion.matching'
local M = {}

M.callback = false

M.getCompletionItems = function(_, _)
  return M.items
end

local function get_completion_word(item)
  if item.textEdit ~= nil and item.textEdit ~= vim.NIL
    and item.textEdit.newText ~= nil and (item.insertTextFormat ~= 2 or vim.fn.exists('g:loaded_vsnip_integ')) then
    return item.textEdit.newText
  elseif item.insertText ~= nil and item.insertText ~= vim.NIL then
    return item.insertText
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
    -- skip snippets items if snippet parsing source in unavailable
    if vim.fn.exists('g:loaded_vsnip_integ') or
      protocol.CompletionItemKind[completion_item.kind] ~= 'Snippet' then
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
      item.kind = customize_label[kind] or kind or ''
      item.abbr = completion_item.label
      item.priority = vim.g.completion_items_priority[item.kind] or 1
      item.menu = completion_item.detail or ''
      local matching_piroity = 1

      local matcher_list = vim.b.completion_matching_strategy_list or vim.g.completion_matching_strategy_list
      for _, method in ipairs(matcher_list) do
        local is_match, score = match.matching_strategy[method](prefix, item.word)
        item.score = score
        if is_match then
          item.user_data.matching_piroity = matching_piroity
          util.addCompletionItems(matches, item)
          break
        end
      end
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
    if api.nvim_get_mode()['mode'] == 'i' or api.nvim_get_mode()['mode'] == 'ic' then
      local matches = text_document_completion_list_to_complete_items(result, prefix, util.fuzzy_score)
      M.items = matches
    end
    M.callback = true
  end)
end

return M
