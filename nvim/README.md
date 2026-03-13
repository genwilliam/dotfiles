[中文](README-zh.md) | English

# Neovim Keybindings

This config is built on top of [NvChad](https://nvchad.com/).
The `<leader>` key is **`Space`**.

> Custom mappings are defined in [`lua/mappings.lua`](lua/mappings.lua).
> NvChad base mappings are loaded via `require "nvchad.mappings"`.

---

## General

| Key         | Mode   | Description            |
| ----------- | ------ | ---------------------- |
| `;`         | Normal | Enter command mode     |
| `jk`        | Insert | Exit insert mode (Esc) |
| `<leader>q` | Normal | Close current window   |

---

## Terminal

A **singleton terminal** is used — pressing `<leader>t` always reuses the same terminal buffer.

| Key         | Mode              | Description                    |
| ----------- | ----------------- | ------------------------------ |
| `<leader>t` | Normal            | Open / focus terminal (bottom) |
| `Esc`       | Terminal (insert) | Back to terminal normal mode   |
| `q`         | Terminal normal   | Close terminal buffer (`bd!`)  |
| `<leader>q` | Terminal (insert) | Close terminal buffer (`bd!`)  |

---

## File Explorer

| Key         | Mode   | Description     |
| ----------- | ------ | --------------- |
| `<leader>e` | Normal | Toggle NvimTree |

---

## Find & Search (Telescope)

| Key         | Mode   | Description                      |
| ----------- | ------ | -------------------------------- |
| `<C-p>`     | Normal | Find files (like VS Code Ctrl+P) |
| `<C-F>`     | Normal | Global search (live grep)        |
| `<leader>/` | Normal | Fuzzy search in current buffer   |

---

## LSP

| Key          | Mode   | Description          |
| ------------ | ------ | -------------------- |
| `gd`         | Normal | Go to definition     |
| `gr`         | Normal | Show references      |
| `gi`         | Normal | Go to implementation |
| `K`          | Normal | Hover documentation  |
| `<leader>rn` | Normal | Rename symbol        |
| `<leader>ca` | Normal | Code action          |

---

## Formatting

| Key           | Mode   | Description   |
| ------------- | ------ | ------------- |
| `<leader>fmt` | Normal | Format buffer |

> Powered by [conform.nvim](https://github.com/stevearc/conform.nvim). Formatters are configured in [`lua/configs/conform.lua`](lua/configs/conform.lua).

---

## Comments

| Key     | Mode   | Description          |
| ------- | ------ | -------------------- |
| `<C-/>` | Normal | Toggle line comment  |
| `<C-/>` | Visual | Toggle block comment |

---

## Debugging (DAP)

| Key         | Mode   | Description            |
| ----------- | ------ | ---------------------- |
| `<F5>`      | Normal | Continue / Start debug |
| `<F9>`      | Normal | Toggle breakpoint      |
| `<F10>`     | Normal | Step over              |
| `<F11>`     | Normal | Step into              |
| `Shift+F11` | Normal | Step out               |

> DAP is configured in [`lua/configs/dap.lua`](lua/configs/dap.lua).

---

## Plugin Overview

| Plugin       | Role                     | Config File                                              |
| ------------ | ------------------------ | -------------------------------------------------------- |
| NvimTree     | File explorer            | Built-in NvChad                                          |
| Telescope    | Fuzzy finder             | Built-in NvChad                                          |
| LSP          | Language Server Protocol | [`lua/configs/lspconfig.lua`](lua/configs/lspconfig.lua) |
| conform.nvim | Formatting               | [`lua/configs/conform.lua`](lua/configs/conform.lua)     |
| nvim-dap     | Debugging                | [`lua/configs/dap.lua`](lua/configs/dap.lua)             |
| lazy.nvim    | Plugin manager           | [`lua/configs/lazy.lua`](lua/configs/lazy.lua)           |
