[![Build Status](https://travis-ci.com/haorenW1025/completion-nvim.svg?branch=master)](https://travis-ci.com/haorenW1025/completion-nvim)
[![Gitter](https://badges.gitter.im/completion-nvim/community.svg)](https://gitter.im/completion-nvim/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
# completion-nvim

completion-nvim is an auto completion framework that aims to provide a better
completion experience with neovim's built-in LSP.  Other LSP functionality is not
supported.

## Features

- Asynchronous completion using the `libuv` api.
- Automatically open hover windows when popupmenu is available.
- Automatically open signature help if it's available.
- Snippets integration with UltiSnips and Neosnippet and vim-vsnip.
- Apply *additionalTextEdits* in LSP spec if it's available.
- Chain completion support inspired by [vim-mucomplete](https://github.com/lifepillar/vim-mucomplete)

## Demo

Demo using `sumneko_lua`
![](https://user-images.githubusercontent.com/35623968/76489411-3ca1d480-6463-11ea-8c3a-7f0e3c521cdb.gif)

## Prerequisites
- Neovim nightly
- You should set up your language server of choice with the help of [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)

## Install

- Install with any plugin manager by using the path on GitHub.

```vim
Plug 'nvim-lua/completion-nvim'
```

## Setup

- completion-nvim requires several autocommands set up to work properly. You should
  set it up using the `on_attach` function like this.

```vim
lua require'nvim_lsp'.pyls.setup{on_attach=require'completion'.on_attach}
```
- Change `pyls` to whichever language server you're using.
- If you want completion-nvim to be set up for all buffers instead of only being
  used when lsp is enabled, call the `on_attach` function directly:

```vim
" Use completion-nvim in every buffer
autocmd BufEnter * lua require'completion'.on_attach()
```

*NOTE* It's okay to set up completion-nvim without lsp. It will simply use
another completion source instead(Ex: snippets).

## Supported Completion Source

- built-in sources

    * lsp: completion source for neovim's built-in LSP.
    * snippet: completion source for snippet.
    * path: completion source for path from current file.

- ins-complete sources

    * See `:h ins-completion` and [wiki](https://github.com/haorenW1025/completion-nvim/wiki/chain-complete-support)

- external sources

    * [completion-buffers](https://github.com/steelsojka/completion-buffers): completion for
    buffers word.
    * [completion-treesitter](https://github.com/nvim-treesitter/completion-treesitter): treesitter
    based completion sources.
    * [vim-dadbod-completion](https://github.com/kristijanhusak/vim-dadbod-completion): completion sources
    for `vim-dadbod`.
    * [completion-tabnine](https://github.com/aca/completion-tabnine): AI code completion tool TabNine integration.
    * [completion-tags](https://github.com/kristijanhusak/completion-tags): Slightly improved ctags completion

## Configuration

### Recommended Setting

```vim
" Use <Tab> and <S-Tab> to navigate through popup menu
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect

" Avoid showing message extra message when using completion
set shortmess+=c
```

### Enable/Disable auto popup

- By default auto popup is enabled, turn it off by

```vim
let g:completion_enable_auto_popup = 0
```
- Or you can toggle auto popup on the fly by using command `CompletionToggle`
- You can manually trigger completion with mapping key by

```vim
"map <c-p> to manually trigger completion
imap <silent> <c-p> <Plug>(completion_trigger)
```

- Or you want to use `<Tab>` as trigger keys

```vim
nmap <tab> <Plug>(completion_smart_tab)
nmap <s-tab> <Plug>(completion_smart_s_tab)
```

### Enable Snippets Support

- By default other snippets source support are disabled, turn them on by

```vim
" possible value: 'UltiSnips', 'Neosnippet', 'vim-vsnip', 'snippets.nvim'
let g:completion_enable_snippet = 'UltiSnips'
```
- Supports `UltiSnips`, `Neosnippet`, `vim-vsnip` and `snippets.nvim`

### LSP Based Snippet parsing

- Some language server have snippet support but neovim couldn't handle that for now, `completion-nvim` can integrate
with other LSP snippet parsing plugin for this support.

- Right now only support `vim-vsnip`(require `vim-vsnip-integ`), it should
work out of the box if you have [vim-vsnip](https://github.com/hrsh7th/vim-vsnip) and
[vim-vsnip-integ](https://github.com/hrsh7th/vim-vsnip-integ) installed.

### Chain Completion Support

- completion-nvim supports chain completion, which use other completion sources
  and `ins-completion` as a fallback for lsp completion.

- See [wiki](https://github.com/haorenW1025/completion-nvim/wiki/chain-complete-support) for
  details on how to set this up.

### Changing Completion Confirm key

- By default `<CR>` is used to confirm completion and expand snippets, change it by

```vim
let g:completion_confirm_key = "\<C-y>"
```

- Make sure to use `" "` and add escape key `\` to avoid parsing issues.
- If the confirm key has a fallback mapping, for example when using the auto
  pairs plugin, it maps to `<CR>`. You can avoid using the default confirm key option and
  use a mapping like this instead.

```.vim
let g:completion_confirm_key = ""
imap <expr> <cr>  pumvisible() ? complete_info()["selected"] != "-1" ?
                 \ "\<Plug>(completion_confirm_completion)"  : "\<c-e>\<CR>" :  "\<CR>"
```

### Enable/Disable auto hover

- By default when navigating through completion items, LSP's hover is automatically
  called and displays in a floating window. Disable it by

```vim
let g:completion_enable_auto_hover = 0
```

### Enable/Disable auto signature

- By default signature help opens automatically whenever it's available. Disable
  it by

```vim
let g:completion_enable_auto_signature = 0
```

### Sorting completion items

- You can decide how your items being sorted in the popup menu. The default value
is `"alphabet"`, change it by
```vim
" possible value: "length", "alphabet", "none"
let g:completion_sorting = "length"
```

- If you don't want any sorting, you can set this value to `"none"`.

### Matching Strategy

- There are three different kind of matching technique implement in
completion-nvim: `substring`, `fuzzy`, `exact` or `all`.

- You can specify a list of matching strategy, completion-nvim will loop through the list and
assign priority from high to low. For example

```vim
let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy', 'all']
```

*NOTE* Fuzzy match highly dependent on what language server you're using. It might not
work as you expect on some language server.

- You can also enable ignore case matching by
```vim
g:completion_matching_ignore_case = 1
```
- Or smart case matching by
```vim
g:completion_matching_smart_case = 1
```

### Trigger Characters

- By default, `completion-nvim` respect the trigger character of your language server, if you
want more trigger characters, add it by


```vim
let g:completion_trigger_character = ['.', '::']
```

*NOTE* use `:lua print(vim.inspect(vim.lsp.buf_get_clients()[1].server_capabilities.completionProvider.triggerCharacters))`
to see the trigger character of your language server.

- If you want different trigger character for different languages, wrap it in an autocommand like

```vim
augroup CompletionTriggerCharacter
    autocmd!
    autocmd BufEnter * let g:completion_trigger_character = ['.']
    autocmd BufEnter *.c,*.cpp let g:completion_trigger_character = ['.', '::']
augroup end
```

### Trigger keyword length

- You can specify keyword length for triggering completion, if the current word is less then keyword length, completion won't be
triggered.

```vim
let g:completion_trigger_keyword_length = 3 " default = 1
```

**NOTE** `completion-nvim` will ignore keyword length if you're on trigger character.

### Trigger on delete

- `completion-nvim` doesn't trigger completion on delete by default because sometimes I've found it annoying. However,
you can enable it by

```vim
let g:completion_trigger_on_delete = 1
```

### Timer Adjustment

- completion-nvim uses a timer to control the rate of completion. You can adjust the timer rate by

```vim
let g:completion_timer_cycle = 200 "default value is 80
```

### Per Server Setup

- You can have different setup for each server in completion-nvim using lua, see [wiki]
(https://github.com/nvim-lua/completion-nvim/wiki/per-server-setup-by-lua) for more guide.

## Compatibility with diagnostic-nvim

- This plugin only focuses on the **completion** part of the built-in LSP. If
  you want similar help with diagnostics (e.g. virtual text, jump to diagnostic,
  open line diagnostic automatically...), take a look at [diagnostic-nvim](https://github.com/haorenW1025/diagnostic-nvim).

- Both diagnostic-nvim and completion-nvim require setting up via `on_attach`.
  To use them together, create a wrapper function like this.

```vim
lua << EOF
local on_attach_vim = function(client)
  require'completion'.on_attach(client)
  require'diagnostic'.on_attach(client)
end
require'nvim_lsp'.pyls.setup{on_attach=on_attach_vim}
EOF
```

## Trouble Shooting

- This plugin is in the early stages and might have unexpected issues.
  Please follow [wiki](https://github.com/haorenW1025/completion-nvim/wiki/trouble-shooting)
  for trouble shooting.
- Feel free to post issues on any unexpected behavior or open a feature request!
