# completion-nvim

completion-nvim is a auto completion framework aims to provide a better completion experience with neovim's built-in LSP.
Other LSP sources is not supported.

## Features

- Asynchronous completion using `libuv` api.
- Automatically opens signature help if it's available.
- Snippets integration with UltiSnips.

## Demo

## Prerequisite
- Neovim nightly
- You should be setting up language server with the help of [nvim-lsp](https://github.com/neovim/nvim-lsp)

## Install

- Install with any plugin manager by using the path on GitHub.
```
Plug 'haorenW1025/completion-nvim'
```

## Setup
- completion-nvim require several autocommand set up to work properly, you should
  set it up using the `on_attach` function like this.
  ```
  lua require'nvim_lsp'.pyls.setup{on_attach=require'completion'.on_attach}
  ```
- Change `pyls` to whatever language server you are using.

## Options

## TODO

- [ ] File name completion
- [ ] Support other snippets engine

## WARNING
This plugin is in early stage, might have unexpected issues.
