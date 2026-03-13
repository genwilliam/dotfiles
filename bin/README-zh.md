中文 | [English](README.md)

## `bin/` 目录的作用

`bin/` 目录用于存放个人可执行脚本（personal CLI utilities）。
该目录会被加入到 `PATH` 中，因此其中的脚本可以像普通命令一样在终端中直接运行。

这些脚本通常用于封装日常开发或系统操作中的常见任务，以减少重复输入命令并提高效率。

典型用途包括：

- 封装常用命令组合
- 自动化日常开发流程
- 提供个人 CLI 工具
- 辅助 Git、Docker 等工具的使用
- 管理或维护本地开发环境

例如：

```
bin/
  mkcd        # 创建目录并进入
  extract     # 自动解压多种压缩文件
  git-sync    # 同步远程仓库
  docker-clean # 清理 Docker 资源
```

一般约定：

- 每个脚本应包含正确的 shebang，例如：

```
#!/usr/bin/env bash
```

- 每个脚本只做一件事情，保持简单且可组合。
- 脚本应具有可执行权限：

```
chmod +x bin/*
```
