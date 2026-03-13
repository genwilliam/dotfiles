中文 | [English](README.md)

# zshrc.d 模块边界约定

为了降低维护成本，`zsh` 配置采用单一职责分层：

- `zshenv`：universal shell（所有 zsh 进程）
  - 唯一的 `PATH` 权威入口
  - 基础 locale 等通用环境变量
- `zprofile`：login shell
  - 登录时初始化（如 `brew shellenv`）
- `zshrc`：interactive shell
  - 负责加载顺序与模块编排

## zshrc.d 下的职责

- `env.zsh`（Pre-OMZ）：交互环境变量与 runtime 策略（不维护 PATH）
- `plugins.zsh`（Pre-OMZ）：仅定义 `plugins=(...)`
- `aliases.zsh`（Post-OMZ）：别名
- `completion.zsh`（Post-OMZ）：补全与 fzf-tab 行为
- `tools.zsh`（Post-OMZ）：工具初始化（尽量懒加载）
- `local/*.zsh`（Post-OMZ）：本地或机器特定扩展

## Runtime 策略

- `mise` 作为主 runtime 管理器（通过 `~/.local/share/mise/shims`）
- `nvm` 作为按需 fallback，仅在首次执行 `nvm` 时懒加载
- 避免为 `node/npm/npx` 增加 wrapper，减少冲突和 hook

## 性能定位

- 基线：`/usr/bin/time -lp zsh -i -c exit`
- 模块级：`ZSH_STARTUP_PROFILE=1 zsh -i -c exit 2>&1 | grep '^zsh-startup'`

说明：优化优先级遵循“延迟加载 > 删除功能”。

# local 目录是做什么的

local 用来放“机器特定”或“临时实验”配置。
典型内容：公司内网代理、某台机器专用路径、临时 alias、一次性调试开关。
你的 zshrc:56-58 会自动加载这个目录下所有 .zsh 文件。
不建议把通用配置放这里，否则会破坏“仓库即真相”。

# 每个文件该放什么

zshenv
放：所有 zsh 都需要的最基础环境（PATH 主入口、LANG、通用 locale）。
不放：alias、插件、prompt、任何慢命令（如大量 eval / 外部探测）。

zprofile
放：仅 login shell 需要的一次性初始化（例如 brew shellenv）。
不放：交互体验相关（补全、alias、prompt、插件）。

zshrc
放：交互 shell 的“加载编排器”（模块顺序、profile 开关）。
不放：大量具体业务配置（那些应下沉到 zshrc.d 各模块）。

env.zsh
放：交互 shell 专属环境变量、runtime 策略（现在的 nvm 懒加载）。
不放：PATH 主权配置（现在已在 zshenv）。

tools.zsh
放：工具初始化与 hook（starship、mise 可选激活、thefuck 懒加载）。
不放：与工具无关的环境变量、alias、补全规则。
