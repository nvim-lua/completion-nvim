local vim = vim
local api = vim.api
local source = require'source'

local health_start = vim.fn["health#report_start"]
local health_ok = vim.fn['health#report_ok']
local health_info = vim.fn['health#report_info']
local health_error = vim.fn['health#report_error']

local M = {}

local checkCompletionSource = function()
  source.checkHealth()
end

local checkSnippetSource = function()
  local snippet_source = vim.g.completion_enable_snippet
  if snippet_source == nil then
    health_info("You haven't setup any snippet source.")
  elseif snippet_source == 'UltiSnips' then
    if string.match(api.nvim_get_option("rtp"), ".*ultisnips.*") then
      health_ok("You are using UltiSnips as your snippet source")
    else
      health_error("UltiSnips is not available! Check if you install Ultisnips correctly.")
    end
  elseif snippet_source == 'Neosnippet' then
    if string.match(api.nvim_get_option("rtp"), ".*neosnippet.vim.*") == 1 then
      health_ok("You are using Neosnippet as your snippet source")
    else
      health_error("Neosnippet is not available! Check if you install Neosnippet correctly.")
    end
  elseif snippet_source == 'Vsnip' then
    if string.match(api.nvim_get_option("rtp"), ".*vsnip.*") then
      health_ok("You are using Vsnip as your snippet source")
    else
      health_error("Vsnip is not available! Check if you install Vsnip correctly.")
    end
  else
    health_error("You're snippet source is not available! possible value are: UltiSnips, Neosnippet, Vsnip")
  end
end

function M.checkHealth()
  health_start("general")
  if vim.tbl_filter == nil then
    health_error("vim.tbl_filter is not found!", {'consider recompile neovim from the latest master branch'})
  else
    health_ok("neovim version is supported")
  end
  health_start("completion source")
  checkCompletionSource()
  health_start("snippet source")
  checkSnippetSource()
end

return M
