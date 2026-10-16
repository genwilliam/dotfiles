中文 | [English](README.md)

# zshrc.d 模块边界约定

为了降低维护成本，`zsh` 配置采用单一职责分层：

- `zshenv`：universal shell（所有 zsh 进程）
  - 仅保留最小通用环境变量（如 locale）
  - 刻意保持极小：脚本、`ssh`/`scp` 以及所有非交互 zsh 都会读取它，因此不能放任何慢操作或交互内容
- `zprofile`：login shell
  - 登录时初始化与 `PATH` 主权（如 `brew shellenv`）
- `zshrc`：interactive shell
  - 负责加载顺序与模块编排

## zshrc.d 下的职责

在 Oh My Zsh 之前加载（`plugins.zsh` 必须在前，因为 Oh My Zsh 启动时会读取 `plugins` 数组）：

- `env.zsh`：交互环境变量，以及 Homebrew 之外的额外 `PATH`（Rust、JDK、Maven）
- `env.local.zsh`：机器特定覆盖；已被 gitignore 且默认为空，因此新克隆的仓库里没有这个文件。存在时加载，不存在时跳过。
- `plugins.zsh`：仅定义 `plugins=(...)`

在 Oh My Zsh 之后加载：

- `aliases.zsh`：别名
- `completion.zsh`：补全行为与 `compinit`/`compdump` 处理
- `tools.zsh`：工具初始化与 runtime 懒加载钩子（尽量懒加载）

不再有 `local/` 目录。机器特定的设置请放到 `env.local.zsh`（见下）。

## Runtime 策略

- `nvm` 提供默认的 Node。通过快速 `PATH` 回退把默认 Node 的 `bin` 目录加入 `PATH`，而不加载 `nvm.sh`，这样 `node` 立即可用且启动开销很低。
- `nvm` 本身在首次执行 `nvm` 函数时懒加载。
- 该快速 PATH 回退不代表 NVM 已激活，也不设置 `NVM_BIN`；需要完整环境时请执行 `nvm use`。
- `.nvmrc` 版本切换由可选的 `chpwd` hook 处理，可通过 `NVM_AUTO_USE=0` 关闭。
- 最近的父级 `.nvmrc` 对子目录生效；离开项目后不会自动恢复 `default`，因此不会静默覆盖你手动选择的版本。
- 如果 Shell 在项目目录中启动，会执行一次 `.nvmrc`；普通目录启动仍不会加载 `nvm.sh`。
- 相同 `.nvmrc` 的连续失败会被抑制，文件变化后才自动重试；安装版本后可显式执行 `nvm use`。
- 避免为 `node/npm/npx` 增加 wrapper，减少冲突和 hook。
- `mise` 采用懒激活：首次执行 `mise` 时才会 `mise activate zsh`。请注意 `~/.local/share/mise/shims` **不在** `PATH` 上，因此 mise 不会覆盖 nvm 管理的 Node。如果你希望 mise 全局接管 runtime，请在 `env.local.zsh` 中主动激活并把 shims 目录加入 `PATH` —— 但要刻意这么做，因为它会改变 `node`/`python` 的解析结果。

## 性能定位

- 基线：`/usr/bin/time -lp zsh -i -c exit`
- 模块级：`ZSH_STARTUP_PROFILE=1 zsh -i -c exit 2>&1 | grep '^zsh-startup'`

每个被加载的模块会在 stderr 输出一行 `zsh-startup <ms> <module>`。计时逻辑只由一次变量判断保护，未设置该变量时没有额外开销。

说明：优化优先级遵循“延迟加载 > 删除功能”。

# env.local.zsh 是做什么的

`env.local.zsh` 用来放“机器特定”或“临时实验”的交互 shell 配置。
典型内容：公司内网代理、某台机器专用路径、临时 alias、一次性调试开关、不能提交的密钥。

它已被 gitignore（`.gitignore` 中的 `*.local.*`），并且由 `~/.zshrc` 在 `env.zsh` 与 `plugins.zsh` 之间加载，因此既能覆盖 `env.zsh` 的设置，也能继续扩展 `plugins` 数组。

不建议把通用配置放这里，否则会破坏“仓库即真相”。如果某个设置应该在每台机器上都存在，它就应该放进被跟踪的文件。

# 每个文件该放什么

zshenv
放：所有 zsh 都需要的最基础环境（LANG、通用 locale）。
不放：alias、插件、prompt、`PATH` 组装、任何慢命令（如大量 eval / 外部探测）。

zprofile
放：仅 login shell 需要的一次性初始化（例如 brew shellenv）与 PATH 组装。
不放：交互体验相关（补全、alias、prompt、插件）。

zshrc
放：交互 shell 的“加载编排器”（模块顺序、prompt 风味切换）。
不放：`PATH` 条目（那是 `zprofile` 的职责）或大量具体业务配置（那些应下沉到 zshrc.d 各模块）。

env.zsh
放：交互 shell 专属环境变量，以及 Homebrew 未链接的工具 `PATH`（Rust、JDK、Maven）。请使用 zsh 的 `path=(...)` 数组，并为每个条目加存在性判断，以保持文件可移植。
不放：基础 `PATH`（那在 `zprofile`）、alias、补全规则。

tools.zsh
放：工具初始化与 hook（starship、thefuck 懒加载、nvm 懒加载、mise 懒加载）。
不放：与工具无关的环境变量、alias、补全规则。
