中文 | [English](README.md)

## `bin/` 目录的作用

`bin/` 目录用于存放个人可执行脚本（personal CLI utilities）。

它**不会**作为一个目录被加入 `PATH`。真正的做法是：`install.sh` 把 `bin/` 下每一个
*可执行* 文件软链接到 `~/.local/bin`，而 `~/.local/bin` 才是 `.zprofile` 加入 `PATH`
的目录。使用软链接而不是复制，意味着 `git pull` 之后命令立即更新。

典型用途包括：

- 封装常用命令组合
- 自动化日常开发流程
- 提供个人 CLI 工具
- 辅助 Git、Docker 等工具的使用
- 管理或维护本地开发环境

目录示例：

```
bin/
  local/
    adminrun        # 以 macOS 管理员权限执行命令
  README.md         # 不会被链接：不可执行
```

子目录同样会被处理，因此 `bin/local/adminrun` 会安装为 `~/.local/bin/adminrun`。

一般约定：

- 每个脚本都应包含正确的 shebang，例如：

  ```bash
  #!/usr/bin/env bash
  ```

- 每个脚本都应具有可执行权限，否则不会被链接。`install.sh` 会输出
  `SKIP (not executable): bin/<name>` 并计入 skipped：

  ```bash
  chmod +x bin/my-tool
  ```

- 不作为命令使用的文件（README、测试数据等）保持不可执行即可。
- 每个脚本只做一件事情，保持简单且可组合。
- 优先使用 `#!/usr/bin/env bash` 或 `#!/bin/zsh`；`local/adminrun` 是一个 zsh 示例，
  它通过 `osascript` 获取管理员权限，而不需要依赖 `sudo`。

新增脚本之后：

```bash
chmod +x bin/my-tool
./install.sh --link-only     # 或者：./bootstrap.sh --fix
./bootstrap.sh --no-warm     # 确认已链接
```

`bin/` 不需要在 `install.sh` 中登记映射：整个目录会被扫描，因此新的可执行文件会自动
被安装。
