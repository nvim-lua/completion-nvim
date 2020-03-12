# completion-nvim

completion-nvim is a auto completion framework aims to provide a better completion experience with neovim's built-in LSP.
Other LSP sources is not supported.

## Features

- Asynchronous completion using `libuv` api.
- Automatically open hover windows when popupmenu is available.
- Automatically open signature help if it's available.
- Snippets integration with UltiSnips.

## Demo

Demo using `sumneko_lua`
![](https://user-images.githubusercontent.com/35623968/76489411-3ca1d480-6463-11ea-8c3a-7f0e3c521cdb.gif)

## Prerequisite
- Neovim nightly
- You should be setting up language server with the help of [nvim-lsp](https://github.com/neovim/nvim-lsp)

## Install

- Install with any plugin manager by using the path on GitHub.
```.vim
Plug 'haorenW1025/completion-nvim'
```

## Setup
- completion-nvim require several autocommand set up to work properly, you should
  set it up using the `on_attach` function like this.
  ```.vim
  lua require'nvim_lsp'.pyls.setup{on_attach=require'completion'.on_attach}
  ```
- Change `pyls` to whatever language server you are using.

## Configuration

### Recommended Setting
```.vim
" Use <Tab> and <S-Tab> to navigate through popup menu
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Auto close popup menu when finish completion
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

" Set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect
```

### Enable Snippets Support
- By default other snippets source support are closed, turn it on by
```.vim
let g:completion_enable_snippet = 'UltiSnips'
```
- Only support `UltiSnips` in current stage.

### Changing Completion Confirm key
- By default `<CR>` is use for confirm completion and expand snippets, change it by
```.vim
let g:completion_confirm_key = "\<C-y>"
```
- Make sure to use `" "` and add escape key `\` to avoid parsing issue.

### Enable/Disable auto hover
- By default when navigate through complete items, LSP's hover is automatically
called and display in floating window, disable it by
```.vim
let g:completion_enable_auto_hover = 0
```

### Enable/Disable auto signature
- By default signature help is open automatically whenever it's available, disable
it by
```.vim
let g:completion_enable_auto_signature = 0
```

### Enable/Disable completion in comment
- By default completion will not activate when you're in a comment section, enable
it by
```.vim
let g:completion_enable_in_comment = 1
```

## TODO

- [ ] File name completion
- [ ] Support other snippets engine
- [ ] Support custom source

## WARNING
This plugin is in early stage, might have unexpected issues.
