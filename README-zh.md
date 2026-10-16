[中文](README-zh.md) | English

# 简介

看了[webpro的文章](https://github.com/webpro/awesome-dotfiles)，发现了很多有用的点文件(dotfiles)。我觉得它们很棒，但我不想直接复制它们(我相信每个人的电脑配置都是独一无二的)。我想要一个适合我的配置文件。就像[mathiasbynens](https://github.com/mathiasbynens/dotfiles)一样。

> 本仓库是一套个人向、以 macOS 为先的配置。它的目标是可读、可复现，而不是成为通用框架：
> 每一个被安装的文件都在同一处声明（`install.sh`），而 `./bootstrap.sh` 负责检查
> 磁盘上的实际状态是否与该声明一致。

## 仓库结构

| 路径 | 说明 | 由 `install.sh` 安装 |
| --- | --- | --- |
| `install.sh` | 安装器：链接文件，并可选安装工具链 | — |
| `bootstrap.sh` | 校验器：对安装做只读检查（以及 `--fix`） | — |
| `tests/test-install.sh` | 两个脚本的回归测试 | — |
| `zsh/` | Shell 启动文件与 `zshrc.d/` 模块 | 是 |
| `p10k/` | powerlevel10k flavour（`zshrc` 覆盖层 + `p10k.zsh`） | 是，需配合 `--prompt p10k` |
| `git/` | `gitconfig`、`gitignore_global`、`gitconfig.local` | 是 |
| `editorconfig` | EditorConfig 规则 | 是 → `~/.editorconfig` |
| `tmux/` | oh-my-tmux 的 `tmux.conf` + 个人 `tmux.conf.local` | 是 → `~/.config/tmux` |
| `nvim/` | Neovim（NvChad）配置 | 是 → `~/.config/nvim` |
| `bin/` | 个人命令；可执行文件落到 `~/.local/bin` | 是 |
| `config/` | `starship.toml`、`thefuck/`、`aria2/` | 是 |
| `Brewfile` | Homebrew formulae、casks 与 VS Code 扩展 | 是（macOS） |
| `macos` | 修改系统级 macOS 偏好的脚本 | **否** — 手动运行 |
| `defaults` | 本机 `defaults` 状态的只读导出 | **否** — 仅作参考 |
| `macos_other.md` | 未自动化的笔记与片段 | **否** — 文档 |
| `launchd/` | 关于 `launchd` 的文档 | **否** — 文档 |

## 环境要求与支持的平台

| 平台 | 支持情况 |
| --- | --- |
| macOS（Apple Silicon 与 Intel） | 完整：dotfiles、Homebrew + Brewfile、zsh、提示符、tmux、nvim |
| Linux | 部分：仅 dotfiles + zsh。会跳过 Homebrew/Brewfile/macOS 相关步骤 |
| Windows / WSL | `install.sh` 不支持。请使用 WSL 走 Linux 路径，或手动链接文件 |

环境要求：

- `bash` >= 3.2 —— macOS 在 `/bin/bash` 自带的版本。脚本特意避免使用 bash 4+ 的
  特性，因此不需要另外安装 Homebrew 的 bash。
- `zsh` >= 5.0，用于 shell 配置。
- `git`，用于克隆 zsh 插件（以及 `Brewfile` 中的 `go`/`uv` 条目）。

## 安装

```bash
git clone https://github.com/genwilliam/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### 选项

| 选项 | 作用 |
| --- | --- |
| `-n`, `--dry-run` | 打印将要执行的操作；不做任何改动 |
| `--link-only` | 只创建符号链接。跳过 Homebrew、Brewfile、zsh、Oh My Zsh 与插件 |
| `--prompt FLAVOUR` | `starship`（默认）或 `p10k`。跳过交互式提问 |
| `--print-map` | 为每个受管路径打印 `source<TAB>target<TAB>required\|optional` 并退出 |
| `--uninstall` | 移除指向本仓库的符号链接 |
| `--remove-readmes` | 安装完成后删除 `$HOME` 下的 `README*` 文件 |
| `-y`, `--yes` | 对所有确认一律回答“是” |
| `-h`, `--help` | 用法说明 |

常用组合：

```bash
./install.sh --dry-run                 # preview a full install
./install.sh --link-only --prompt p10k # only link files, powerlevel10k flavour
./install.sh -y                        # unattended
```

`install.sh` 需要在 macOS 或 Linux 上运行；否则它会以一条清晰的提示终止。它从不使用
`sudo`，只有一种情况例外：为 `chsh` 在 `/etc/shells` 中注册 shell；当它无法完成时，
会把手动命令告诉你。

### 安装内容与位置

`install.sh` 只有一张映射表（`link_dotfiles`）。以下是默认（`starship`）flavour 的
完整列表：

| 本仓库中的源 | 目标 |
| --- | --- |
| `git/gitconfig` | `~/.gitconfig` |
| `git/gitignore_global` | `~/.gitignore_global` |
| `git/gitconfig.local` | `~/.gitconfig.local` *（可选，见下文）* |
| `editorconfig` | `~/.editorconfig` |
| `zsh/zshenv` | `~/.zshenv` |
| `zsh/zprofile` | `~/.zprofile` |
| `zsh/zlogin` | `~/.zlogin` |
| `zsh/zlogout` | `~/.zlogout` |
| `zsh/zshrc.d` | `~/.zshrc.d` |
| `zsh/zshrc` | `~/.zshrc` |
| `config/starship.toml` | `~/.config/starship.toml` |
| `tmux` | `~/.config/tmux` |
| `config/thefuck` | `~/.config/thefuck` |
| `config/aria2` | `~/.config/aria2` |
| `nvim` | `~/.config/nvim` |
| `bin/` 下的每个可执行文件 | `~/.local/bin/<name>` |

使用 `--prompt p10k` 时，`p10k/zshrc` 会被链接到 `~/.zshrc`，`p10k/p10k.zsh` 被链接到
`~/.p10k.zsh`，并且不再链接 `config/starship.toml`。切换 flavour 还会移除另一个
flavour 的链接。

`git/gitconfig.local` 是**可选**的：它被 gitignore，因此全新克隆中并不包含它。
`install.sh` 会静默跳过它，`bootstrap.sh` 会把它报告为一条提示。如需机器本地的身份
信息，请自行创建：

```bash
cat > ~/dotfiles/git/gitconfig.local <<'EOF'
[user]
    name = Your Name
    email = you@example.com
EOF
./install.sh --link-only
```

只有 `bin/` 下的*可执行*文件会被链接，因此 `bin/README.md` 之类的文件永远不会出现在
`~/.local/bin` 中。子目录中的文件（例如 `bin/local/adminrun`）也会被包含。

### 已有文件如何处理

链接操作是幂等且非破坏性的：

- 已经是指向正确源的符号链接的目标保持不动。
- 指向其他位置的符号链接目标会被替换为正确的符号链接。
- 是**真实文件或目录**的目标会先被移动到
  `<target>.bak.<YYYYmmddHHMMSS>`，绝不会被删除。如果该名称已被占用，会追加一个
  数字后缀。
- 缺失的源会被报告：指向已不存在文件的必需映射属于失败，而不是静默跳过。

脚本会汇总它所做的事情（已链接 / 已正确 / 已跳过 / 已备份 / 已移除），并在任何步骤
失败时以非零状态退出。

## 校验安装

```bash
./bootstrap.sh              # read-only check
./bootstrap.sh --fix        # repair missing or wrong links
./bootstrap.sh --no-warm    # skip the interactive zsh smoke test
./bootstrap.sh --prompt p10k
```

`bootstrap.sh` 从 `install.sh --print-map` 读取映射，因此二者永远不会出现分歧。它会
检查：

1. 每条映射都指向仍然存在的源（这正是用来发现“配置文件已重命名但 `install.sh` 未同步
   更新”的机制）；
2. `$HOME` 中的每个目标都是指向该确切源的符号链接；
3. 没有指向本仓库、但已不再属于映射的陈旧符号链接（它们会悄悄改变 shell 行为 —— 例如
   遗留的 `~/.tmux.conf` 或 `~/.p10k.zsh`）；
4. 受管的 zsh 文件能通过 `zsh -n`；
5. 交互式 zsh 能干净启动（用 `--no-warm` 跳过）。

一切通过时它退出码为 `0`，发现问题时为 `1`。只有在 `--fix` 时才会修复，而它会委托给
`./install.sh --link-only` —— 链接逻辑只有一份实现，因此不存在漂移的可能。

## 更新、重跑、卸载

重复运行是安全的；这就是常规的更新方式：

```bash
cd ~/dotfiles
git pull
./install.sh --link-only    # or ./install.sh to also run the tooling steps
./bootstrap.sh
```

要在不触碰其他任何东西的前提下移除配置：

```bash
./install.sh --uninstall --dry-run   # preview
./install.sh --uninstall             # remove only repo-owned symlinks
```

`--uninstall` **仅当**路径是解析后指向本仓库的符号链接时才会移除它。普通文件、
目录以及指向其他位置的符号链接都会保留，备份也会保留。刻意没有单独的卸载脚本：卸载
无非就是删除链接，而安装器可以精确地做到这一点。

要恢复安装过程中被替换的配置：

```bash
ls -d ~/.zshrc.bak.*                    # find the backups
mv ~/.zshrc.bak.20260101120000 ~/.zshrc # restore one
```

## 手动步骤（刻意不自动化）

| 步骤 | 命令 / 操作 | 为什么是手动 |
| --- | --- | --- |
| macOS 系统偏好 | `./macos` | 修改系统级设置，需要 `sudo` 并重新登录 |
| 检查你的 defaults | `./defaults` 是**导出，不是脚本** | 见下方警告 |
| Meslo Nerd Font | `brew install --cask font-meslo-lg-nerd-font` | `Brewfile` 中也有 |
| powerlevel10k 向导 | `p10k configure` | 重新生成 `~/.p10k.zsh` |
| tmux 插件 | 启动 tmux，然后按 `Prefix + I` | TPM 会自行安装/更新插件 |
| Neovim 插件 | 启动一次 `nvim` | lazy.nvim 在首次启动时安装插件 |
| GitHub Copilot 认证 | 在 Neovim 中执行 `:Copilot setup` | 交互式认证 |
| Homebrew 本体 | 由 `./install.sh` 提示 | 会运行上游安装器，需要你本人同意 |

### 关于 `defaults` 的警告

`defaults` 是一个 195 KB、自动生成的**本机**当前 macOS defaults 导出（`defaults read`
的输出），保留下来仅供参考。它不是脚本，也不会被任何东西执行。

它包含二进制 plist 数据以及机器特定的个人信息：家目录下的绝对路径、最近的 Finder
位置、Dock 条目等。请把它当作私人备份。如果你 fork 了这个仓库，请在发布前删除该文件
（或让它不进入版本控制）。

## zsh

> 在开始之前,请先阅读[zsh/bash的加载顺序](https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/)

| 文件 | 加载顺序 | 何时加载 | 每次启动 shell 都会执行吗？ | 在此的职责 |
| --- | --- | --- | --- | --- |
| `.zshenv` | 1 | **每一次** zsh 调用 | 是 | 仅 locale，保持最小化，以免影响脚本/`scp` |
| `.zprofile` | 2 | 登录 shell | 否 | **掌管 `PATH`**：用户 bin、Homebrew `shellenv` |
| `.zshrc` | 3 | 交互式 shell | 否 | 编排者：缓存路径、模块顺序、Oh My Zsh |
| `.zlogin` | 4 | 登录 shell 中 `.zshrc` 之后 | 否 | 终端标题 |
| `.zlogout` | 5 | 登录 shell 退出时 | 否 | 清理钩子（目前是空操作，已有文档说明） |

### 使用了 Oh My Zsh

`~/.zshrc` 会 source `$ZSH/oh-my-zsh.sh`，而 `install.sh` 会运行官方的 Oh My Zsh
安装器，并克隆它未自带的插件。`zsh/zshrc.d/plugins.zsh` 中的插件列表是唯一真相：

- Oh My Zsh 自带，无需安装：`git`、`fzf`、`aliases`、`colored-man-pages`、
  `zoxide`、`extract`
- 由 `install.sh` 安装：`zsh-autosuggestions`、`fast-syntax-highlighting`、
  `you-should-use`

`fzf-tab` 被有意**禁用**（在 `plugins.zsh` 中已注释，且没有配置任何 `fzf-tab` 按键
绑定）。Tab 使用菜单补全。

### 模块边界

`zsh/zshrc.d/` 按职责拆分，且加载顺序很重要：

```
~/.zshrc
  ├─ pre-Oh-My-Zsh :  env.zsh  →  env.local.zsh  →  plugins.zsh
  ├─ Oh My Zsh     :  $ZSH/oh-my-zsh.sh
  └─ post-Oh-My-Zsh:  aliases.zsh  →  completion.zsh  →  tools.zsh
```

- `env.zsh` —— 交互式环境变量和额外的 `PATH` 条目（Rust、JDK、Maven）。
- `env.local.zsh` —— 被 gitignore，默认为空；把机器特定的设置放在这里。即使文件不存在
  也会被 source。
- `plugins.zsh` —— 只有 `plugins=(...)` 数组。
- `completion.zsh` —— 补全策略与 `compinit`。
- `tools.zsh` —— 工具初始化：starship、懒加载 `thefuck`、懒加载 `nvm`、懒加载
  `mise`。

完整约定见 [`zsh/zshrc.d/README.md`](zsh/zshrc.d/README.md)。

### PATH 归属

`PATH` 在 `.zprofile` 中按以下顺序组装（后前置者胜）：

1. `~/.local/bin`、`~/Library/pnpm`
2. `/opt/homebrew/bin`、`/usr/local/bin`（随后 Homebrew 的 `shellenv` 会再次前置
   `/opt/homebrew/bin` 与 `/opt/homebrew/sbin`）
3. `~/.openclaw/bin` 以及其他按用户划分的工具 bin，带存在性检查

`zsh/zshrc.d/env.zsh` 会在之后前置 Rust/JDK/Maven 路径。没有任何地方硬编码用户名或
家目录：路径都由 `$HOME` 构造并做存在性检查，因此同一套文件在另一台机器或另一种架构
上同样可用（JDK 的检查同时覆盖 `/opt/homebrew` 和 `/usr/local`）。Maven 路径通过
glob 解析，因此升级 Maven 无需修改配置。

`path`/`PATH` 保持唯一（`typeset -gU path`），因此重复 source `~/.zshrc` 永远不会让
`PATH` 增长或出现重复。

### 提示符 flavour

两个 flavour 共用 `~/.zshrc.d`，因此别名、补全和工具初始化完全一致。只有提示符不同：

- **starship**（默认，当前使用）：`zsh/zshrc` → `~/.zshrc`，配置在
  `config/starship.toml`。
- **powerlevel10k**：`p10k/zshrc` → `~/.zshrc`。该文件是一个薄覆盖层 —— 它初始化
  instant prompt，设置 `ZSH_THEME` 和 `ZSH_PROMPT_FLAVOR=p10k`，然后 source 相对其
  自身已解析符号链接找到的共享编排器。它不再重复模块列表。

```bash
./install.sh --link-only --prompt p10k
```

不支持同时安装两者；`install.sh` 会移除另一个 flavour 的链接，以保证只有一个提示符
生效。切换 flavour 在新开的 shell 中生效。

要配置 starship，请编辑 `config/starship.toml` —— 它会被链接到
`~/.config/starship.toml`（本 README 以前展示过错误的路径）。

![CleanShot 2026-03-12 at 10.46.26@2x](https://raw.githubusercontent.com/genwilliam/picgo_img/main/img/CleanShot%202026-03-12%20at%2010.46.26%402x.png)

### 补全缓存稳定性（`compinit` / `compdump`）

在插件较多的配置中，重复 `source ~/.zshrc` 可能出人意料地变慢，因为 `compinit` 会
不断重建补全元数据（`compdump`）。

- 在同一 shell 中重复 source `~/.zshrc` 时，如果路径数组没有去重，补全元数据可能
  发生漂移。
- 一旦元数据不一致，`compinit` 可能重新生成补全缓存，使重载时间从毫秒级跳到
  数百毫秒。

本仓库当前的修复方式：

- `typeset -gU path fpath` 防止重复 source 时产生重复项。
- `ZSH_CACHE_DIR` 与 `ZSH_COMPDUMP` 将缓存固定在 `~/.cache` 下，保证行为确定。
- `completion.zsh` 使用 `compinit -C -d "$ZSH_COMPDUMP"`，优先复用缓存。
- 补全策略是显式的：Tab 使用菜单选择；`fzf-tab` 可用但已禁用。

### 启动性能分析

现在它确实可用了：

```bash
ZSH_STARTUP_PROFILE=1 zsh -i -c exit 2>&1 | grep '^zsh-startup'
```

每个被 source 的模块会在 stderr 打印一行 `zsh-startup <ms> <module>`。未设置该变量时
没有额外开销（计时代码被单个变量检查守卫着）。基线仍然可用：

```bash
/usr/bin/time -lp zsh -i -c exit
```

## tmux

tmux 配置基于 [oh-my-tmux](https://github.com/gpakosz/.tmux)。与旧版本 README 中的
说明不同，**不要运行上游的 `install.sh`**：本仓库已经跟踪了 oh-my-tmux 的
`tmux.conf`，上游安装器会穿透符号链接写入并修改被跟踪的文件。

目录布局基于 XDG：

```
~/.config/tmux            ->  <repo>/tmux
~/.config/tmux/tmux.conf  ->  oh-my-tmux base config (tracked, do not edit)
~/.config/tmux/tmux.conf.local  ->  personal overrides (edit this one)
~/.config/tmux/plugins/   ->  TPM's plugin directory (gitignored)
```

tmux >= 3.1 会自行读取 `~/.config/tmux/tmux.conf`，而 oh-my-tmux 从配置文件位置推导
插件目录，这就是整个 `tmux` 目录被一次性链接的原因。创建过 `~/.tmux.conf` 的旧安装会
被自动迁移：当其指向本仓库时，`install.sh` 会移除该符号链接并打印一条提示（否则陈旧的
`~/.tmux.conf` 会继续优先生效）。

### 插件

在 `tmux/tmux.conf.local` 中声明，由 TPM 安装：

- `tmux-plugins/tmux-copycat` —— 在回滚缓冲区/复制模式中做正则搜索
- `tmux-plugins/tmux-resurrect` —— 保存与恢复会话
- `tmux-plugins/tmux-open` —— 打开高亮的路径/URL

已注释（可用但未启用）：

- `tmux-plugins/tmux-cpu`、`tmux-plugins/tmux-continuum`、
  `27medkamal/tmux-session-wizard`、`tmux-plugins/tmux-sensible`、
  `tmux-plugins/tmux-yank`

`tmux_conf_uninstall_plugins_on_reload=true` 意味着：下次重新加载配置时，从上面列表中
移除的插件会被卸载。这是有意为之。

TPM 按键（oh-my-tmux 的集成，与上游 TPM 略有不同）：

| 按键 | 操作 |
| --- | --- |
| `Prefix + I` | 安装插件 |
| `Prefix + u` | 更新插件 |
| `Prefix + Alt + u` | 卸载已移除的插件 |

### 此处真实存在的按键绑定

| 绑定 | 操作 |
| --- | --- |
| `Prefix + -` | 上下分屏 |
| `Prefix + _` | 左右分屏 |
| `Prefix + H/J/K/L` | 调整面板大小（可重复） |
| `Prefix + r` | 重新加载配置 |
| `Prefix + e` | 编辑 `tmux.conf.local` |
| `Prefix + m` | 切换鼠标模式（个人覆盖） |
| `Prefix + +` | 最大化/还原面板 |
| `Prefix + s` | tmux 内置的 choose-tree |
| `Prefix + c` / `w` / `x` / `z` / `q` | 新建窗口、窗口列表、关闭面板、缩放、面板编号 |
| `Prefix + [` 然后 `v` / `y` | 复制模式：选择、复制到系统剪贴板 |

> 本 README 的早期版本记录过 `Prefix + =` 分屏，以及 `Prefix + s` 中的 `dd` 删除
> 流程。二者在被跟踪的配置中都不存在，因此已从本文档中删除，而不是继续留作
> 一厢情愿的想法。

`tmux.conf.local` 中的个人设置：鼠标模式开启、`history-limit 10000`、启用复制到系统
剪贴板，以及深色主题配色。

## nvim

基于 [NvChad](https://nvchad.com/) v2.5。`nvim/init.lua` 引导
[lazy.nvim](https://github.com/folke/lazy.nvim)，由它安装并加载每一个插件，包括在
`nvim/lua/plugins/init.lua` 中声明的 `github/copilot.vim`。锁定的版本记录在
`nvim/lazy-lock.json`。

由于插件管理器是 lazy.nvim，`nvim/pack/` 只是一个占位目录（由 `nvim/pack/.gitkeep`
保留）。如果你还没有 Neovim：

```bash
brew install nvim     # macOS
# or download from https://neovim.io/
```

首次启动会安装插件；运行一次 `:Copilot setup` 来完成 Copilot 认证。

## git

`git/gitconfig` 保存全局设置。每台机器的私有值放在 `git/gitconfig.local`，当它存在时
`gitconfig` 会 include 它：

```ini
[include]
  path = ~/.gitconfig.local
```

`git/gitconfig.local` 被 gitignore，因此全新克隆中并不存在；Git 会忽略不存在的
include 路径，所以一切仍然正常工作。请按[安装](#安装)一节的说明创建它。

一点重要提醒：如果你的邮箱直接写在配置里，可能会暴露你的地址。[GitHub](https://github.com)
可以隐藏你的邮箱地址 —— 见[这篇文章](https://docs.github.com/en/account-and-profile/how-tos/email-preferences/setting-your-commit-email-address)。
在 GitHub 中启用 `Keep my email addresses private` 可以获得一个 `noreply` 地址；
命令行 Git 不会自动使用它，但你可以把它写进 `gitconfig.local`，从而避免暴露真实
邮箱。

`git/gitignore_global` 保存全局忽略规则（操作系统垃圾文件、编辑器文件、构建产物、
`node_modules`、Python 缓存、Go 二进制）。它的路径必须与 `gitconfig` 中的
`core.excludesFile` 一致，目前确实一致（`~/.gitignore_global`）。

## Brewfile

它包含通过 `brew bundle` 安装的 [Homebrew](https://github.com/Homebrew/brew) 软件包。
**请先用文本编辑器查看并按需调整** —— 它会安装大量体积很大的 cask。然后：

```bash
brew bundle --file=./Brewfile
```

`install.sh` 会执行等价于 `brew bundle --file=<repo>/Brewfile --no-upgrade` 的操作，
并在执行前请求确认。该步骤是同步执行的，且在 shell 配置之前，因为它安装的工具
（`starship`、`zoxide`、`nvm`、`git`）会被后续步骤使用。

### 关于 `appdir` 参数

`appdir` 是 Homebrew Brewfile 的一个选项，用于指定 cask 应用的安装位置。默认情况下，
Homebrew 会把应用安装到 `/Applications`。本仓库通过 `zsh/zshrc.d/env.zsh` 中的
`HOMEBREW_CASK_OPTS` 设置了一个全局默认值：

```zsh
export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications --require-sha"
```

`Brewfile` 中的各个 cask 也会传入 `args: { appdir: "~/Applications" }`。

#### 我为什么使用 `appdir`？

在 macOS 上，第一个用户账户始终是管理员账户。管理员账户属于 `admin` 组并拥有 sudo
权限。这意味着它们实际上可以控制系统，包括特权操作，从而增加风险。

像 `sudo` 这样的工具可能存在会被并发运行的程序利用的[弱点](https://bogner.sh/2014/03/another-mac-os-x-sudo-password-bypass/)。

[Apple](https://help.apple.com/machelp/mac/10.12/index.html#/mh11389) 推荐这一最佳
实践：日常使用单独的标准账户，只在安装和系统配置时使用管理员账户。

你不必一直通过 macOS 登录界面以管理员账户登录。当终端命令需要管理员权限时，系统会
提示认证，随后终端会以这些权限继续。为此，Apple 在[这里](https://support.apple.com/HT203998)
提供了关于隐藏管理员账户及其家目录的指引。这是一种优雅的做法，可以避免出现一个
可见的“幽灵”账户。

> 引用自 https://github.com/drduh/macOS-Security-and-Privacy-Guide
>
> [中文翻译](https://github.com/genwilliam/macOS-Security-and-Privacy-Guide-cn)

## bin

`bin/` 存放个人命令。其中每个**可执行**文件都会被链接到 `~/.local/bin`，该目录通过
`.zprofile` 加入 `PATH`，因此 `bin/local/adminrun` 会变成 `adminrun`：

```bash
adminrun <command> [args...]   # run a command with macOS admin privileges
```

像 `bin/README.md` 这样的非可执行文件会被跳过，因此文档永远不会出现在 `PATH` 上。
要添加一个命令：

```bash
chmod +x bin/my-tool
./install.sh --link-only      # or ./bootstrap.sh --fix
```

## macOS 相关

### `macos`

`macos` 是一个**单一脚本**（不是目录）。它用 `defaults` 应用系统偏好修改，外加少量
需要 `sudo` 的命令。它**不**由 `install.sh` 运行，因为它会修改系统级状态，并且通常需要
注销/重新登录。

```bash
./macos --dry-run    # 预览每一条命令；不做任何修改
./macos              # 先请求确认，然后应用
./macos --yes        # 不询问直接应用（例如在 dry-run 之后）
```

它会修改：

- `defaults write` 偏好：触发角、轻点来点按、三指拖移、键盘 UI 模式、Finder 路径栏 /
  搜索范围 / 扩展名警告、菜单栏时钟、Mail 附件、Mission Control 窗口分组、截图、字体
  以及登录窗口相关键
- `chflags hidden ~/Library` —— 在 Finder 中隐藏你的资源库文件夹
- 用 `hidutil` 覆盖 CapsLock 延迟（下次重启后失效）
- 刷新 DNS 缓存，并**打开应用防火墙**（`sudo`）
- 如果已安装，则移除 Google 的软件更新器 —— **这会删除文件**
- 重启 Finder、Dock 和 SystemUIServer（会关闭已打开的 Finder 窗口）

`--dry-run` 会用打印函数替换 `defaults`/`sudo`/`hidutil`/`chflags`，因此你可以在不触碰
任何东西的情况下看清将要发生什么。单条 `defaults write` 失败被刻意设计为非致命：脚本会
应用整份清单，而不是在遇到当前 macOS 版本已不再支持的第一个键时就停下。请先阅读它 ——
这是一份个人清单，不是受支持的配置描述文件。

### `defaults`

见[上方警告](#关于-defaults-的警告)。仅供参考。

### `macos_other.md`

刻意不自动化的笔记与片段（例如 Mail.app 索引整理）。仅为文档。

### `launchd`

`launchd/README.md` 和 `launchd/README-zh.md` 解释 launchd 并提供参考资料。它们是
文档 —— 本仓库不会安装任何 `LaunchAgent`/`LaunchDaemon` plist。绝不要把密钥放进
plist，并注意 `~/Library/LaunchAgents` 中的文件只有你自己可读，而其中大多数路径位于
`/Library/LaunchAgents` 之下，需要管理员权限。

## 添加新的配置文件

1. 把文件加入仓库，放在与其用途相符的目录中。
2. 在 `install.sh` 的 `link_dotfiles()` 映射表中添加它：

   ```bash
   link_dotfile "$DOTFILES/config/my-tool.toml" "$HOME/.config/my-tool.toml"
   ```

   如果源是机器本地且被 gitignore，请使用第三个参数 `optional`。
3. 在本 README（即上面的结构表）中记录它。
4. 验证：

   ```bash
   ./install.sh --dry-run      # the new file should be listed
   ./bootstrap.sh --no-warm    # it should verify
   ./tests/test-install.sh     # links and mappings are exercised
   ```

`bootstrap.sh` 的预期来自 `install.sh`，所以只要你添加了映射，校验器就会立刻开始检查
它。其他任何东西都无需更新。

## 测试与 CI

```bash
./tests/test-install.sh     # full suite: isolated temp HOME, no network
shellcheck --shell=bash --severity=style install.sh bootstrap.sh tests/test-install.sh
```

测试套件会模拟一次全新克隆（不包含被 gitignore 的文件、也不包含随仓库附带的插件），并检查：
映射格式良好且完整，全新安装能正确链接所有内容，没有文档泄漏到 `~/.local/bin`，已存在
的文件会被备份且内容完好，第二次运行是空操作，`--dry-run` 不做任何改动，旧的
`~/.tmux.conf` 符号链接会被迁移而外来文件保持不动，提示符 flavour 能干净切换，
`bootstrap.sh` 能发现损坏并修复它，`--uninstall` 只移除仓库自有的链接，以及重命名源
文件会被两个脚本都报告为错误。

CI（`.github/workflows/ci.yml`）会运行 shellcheck、`bash -n`、`zsh -n`、测试套件，
以及一次真实的 Linux 安装并校验 —— 它不需要网络，也不需要 Homebrew。

## 已知限制与风险

- **仅 macOS 的部分未被 CI 覆盖。** `install.sh` 的 Homebrew、`chsh` 和
  `~/.config/tmux` 行为以及 `macos` 脚本只能在 macOS 上手动验证。CI 在 Linux 上
  覆盖链接逻辑。
- **`defaults` 包含个人数据**，并且是有意提交的（见上方警告）。它不是凭据，但确实
  描述了这台机器。把它从未来的提交中移除并不会把它从 Git 历史中移除；那需要重写
  历史，而这里有意不做。
- **Linux 支持是部分且尽力而为的。** `zsh/zprofile` 处理 Linux 路径，`install.sh`
  可以使用 `apt-get`/`dnf`/`yum`/`pacman`/`zypper`/`apk`，但 `Brewfile`、`macos`
  脚本、`launchd` 以及 pnpm/Homebrew 路径都是面向 macOS 的。
- **`*.txt` 在本仓库中被有意 gitignore。** 如果你确实需要跟踪一个 `.txt` 文件
  （例如 `requirements.txt`），请添加一条显式的 `!path/to/file.txt`。
- `fzf-tab` 没有任何人安装，也没有任何人启用；克隆步骤已被移除。它的按键绑定也已从
  p10k 覆盖层中移除，此前该覆盖层在它被禁用的情况下仍然引用了它。

## 致谢

> 正如 [Joshua Clayton 在最近一期 The Changelog 中](http://thechangelog.com/post/17827235767/episode-0-7-3-tmux-with-brian-hogan-and-josh-clayton)所说，如果你对自己的 dotfiles 不满意，那你就做错了™。从别人的 dotfiles 中挑选你喜欢的部分。向所有人学习，不追随任何人。打造你自己的光剑。充满信心地从头重建它。原文:https://wynnnetherland.com/journal/dotfiles-discovery

如果不知道什么是 dotfiles，这篇[文章](https://jogendra.dev/i-do-dotfiles)会很有帮助。

如果你不想看它，下面是一个简洁的解释：

> **Dotfiles（点文件）**指的是在 **类 Unix 系统**（如 macOS 和 Linux）中，以 **`.` 开头命名的配置文件**。
> 它们通常用来保存 **用户级别的程序配置**。
>
> 之所以叫 _dotfiles_，是因为文件名前面有一个 **点（dot）**。

> [!IMPORTANT]
>
> 我的 shell 配置基于 `zsh`。如果你使用其他 shell（例如 bash 或 fish），这套配置
> 无法直接使用。[这个仓库](https://github.com/mathiasbynens/dotfiles)可能对你有帮助。

## 许可证

见 [LICENSE](LICENSE)。
