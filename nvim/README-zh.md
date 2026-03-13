中文 | [English](README.md)

# Neovim 快捷键说明

本配置基于 [NvChad](https://nvchad.com/) 构建。
`<leader>` 键为 **`Space`（空格）**。

> 自定义快捷键定义于 [`lua/mappings.lua`](lua/mappings.lua)。
> NvChad 基础快捷键通过 `require "nvchad.mappings"` 加载。

---

## 通用

| 快捷键      | 模式 | 说明                     |
| ----------- | ---- | ------------------------ |
| `;`         | 普通 | 进入命令模式             |
| `jk`        | 插入 | 退出插入模式（等同 Esc） |
| `<leader>q` | 普通 | 关闭当前窗口             |

---

## 终端

采用**单例终端**模式——无论按多少次 `<leader>t`，始终复用同一个终端 buffer。

| 快捷键      | 模式             | 说明                        |
| ----------- | ---------------- | --------------------------- |
| `<leader>t` | 普通             | 打开 / 聚焦终端（底部分屏） |
| `Esc`       | 终端（插入模式） | 切换到终端普通模式          |
| `q`         | 终端普通模式     | 关闭终端 buffer（`bd!`）    |
| `<leader>q` | 终端（插入模式） | 关闭终端 buffer（`bd!`）    |

---

## 文件浏览器

| 快捷键      | 模式 | 说明          |
| ----------- | ---- | ------------- |
| `<leader>e` | 普通 | 切换 NvimTree |

---

## 文件查找与搜索（Telescope）

| 快捷键      | 模式 | 说明                            |
| ----------- | ---- | ------------------------------- |
| `<C-p>`     | 普通 | 查找文件（类似 VS Code Ctrl+P） |
| `<C-F>`     | 普通 | 全局搜索（live grep）           |
| `<leader>/` | 普通 | 在当前 buffer 内模糊搜索        |

---

## LSP 语言服务

| 快捷键       | 模式 | 说明         |
| ------------ | ---- | ------------ |
| `gd`         | 普通 | 跳转到定义   |
| `gr`         | 普通 | 查看引用     |
| `gi`         | 普通 | 跳转到实现   |
| `K`          | 普通 | 悬停文档提示 |
| `<leader>rn` | 普通 | 重命名符号   |
| `<leader>ca` | 普通 | 代码操作     |

---

## 代码格式化

| 快捷键        | 模式 | 说明           |
| ------------- | ---- | -------------- |
| `<leader>fmt` | 普通 | 格式化当前文件 |

> 由 [conform.nvim](https://github.com/stevearc/conform.nvim) 驱动，格式化器配置见 [`lua/configs/conform.lua`](lua/configs/conform.lua)。

---

## 注释

| 快捷键  | 模式 | 说明       |
| ------- | ---- | ---------- |
| `<C-/>` | 普通 | 切换行注释 |
| `<C-/>` | 可视 | 切换块注释 |

---

## 调试（DAP）

| 快捷键      | 模式 | 说明            |
| ----------- | ---- | --------------- |
| `<F5>`      | 普通 | 继续 / 开始调试 |
| `<F9>`      | 普通 | 切换断点        |
| `<F10>`     | 普通 | 单步跳过        |
| `<F11>`     | 普通 | 单步进入        |
| `Shift+F11` | 普通 | 单步跳出        |

> DAP 配置见 [`lua/configs/dap.lua`](lua/configs/dap.lua)。

---

## 插件一览

| 插件         | 功能         | 配置文件                                                 |
| ------------ | ------------ | -------------------------------------------------------- |
| NvimTree     | 文件浏览器   | NvChad 内置                                              |
| Telescope    | 模糊查找器   | NvChad 内置                                              |
| LSP          | 语言服务协议 | [`lua/configs/lspconfig.lua`](lua/configs/lspconfig.lua) |
| conform.nvim | 代码格式化   | [`lua/configs/conform.lua`](lua/configs/conform.lua)     |
| nvim-dap     | 调试         | [`lua/configs/dap.lua`](lua/configs/dap.lua)             |
| lazy.nvim    | 插件管理器   | [`lua/configs/lazy.lua`](lua/configs/lazy.lua)           |
