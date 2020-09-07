local vim = vim
local api = vim.api
local source = require 'completion.source'
local opt = require 'completion.option'

local health_start = vim.fn["health#report_start"]
local health_ok = vim.fn['health#report_ok']
local health_info = vim.fn['health#report_info']
local health_error = vim.fn['health#report_error']

local M = {}

local checkCompletionSource = function()
  source.checkHealth()
end

local checkSnippetSource = function()
  local snippet_source = opt.get_option('enable_snippet')
  if snippet_source == nil then
    health_info("You haven't setup any snippet source.")
  else
    local rtp = string.lower(api.nvim_get_option("rtp"))
    local unknown_snippet_source = true
    local snippet_sources = {
        ["UltiSnips"] = "ultisnips",
        ["Neosnippet"] = "neosnippet.vim",
        ["vim-vsnip"] = "vsnip",
        ["snippets.nvim"] = "snippets.nvim"
    }

    for k,v in pairs(snippet_sources) do
        if snippet_source == k then
            unknown_snippet_source = false
            if string.match(rtp, ".*"..v..".*") then
                health_ok("You are using "..k.." as your snippet source")
            else
                health_error(k.." is not available! Check if you install "..k.." correctly.")
            end
            break
        end
    end

    if unknown_snippet_source then
        health_error("Your snippet source is not available! Possible values are: UltiSnips, Neosnippet, vim-vsnip, snippets.nvim")
    end
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
