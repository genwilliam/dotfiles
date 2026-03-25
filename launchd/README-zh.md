# macOS Launchd 详解与配置

> 掌握 launchd，让你的 Mac 在你睡觉时也在工作 😴

## 目录

- [什么是 Launchd？](#什么是-launchd)
- [执行流程](#执行流程)
- [权限管理](#权限管理)
- [LaunchDaemons vs LaunchAgents](#launchdaemons-vs-launchagents)
- [核心配置参数](#核心配置参数)
- [常见使用场景](#常见使用场景)
- [最佳实践](#最佳实践)
- [故障排除](#故障排除)

## 什么是 Launchd？

`launchd` 是 Apple 设计的开源服务管理框架，目的是用来替代传统 Linux 中的多个组件：

- `init` 进程
- `rc.d` 脚本
- `SystemStarter`
- `inetd`/`xinetd`
- `crond`/`atd`
- `watchdogd`

作为 macOS 系统启动后的第一个进程（PID=1），`launchd` 负责：

1. 系统启动
2. 启动系统级别的守护进程
3. 加载和管理所有服务
4. 监控和重启崩溃的服务

**核心优势：**

- ✅ 统一的服务管理接口
- ✅ 按需加载服务（提升启动速度）
- ✅ 自动重启失败的服务
- ✅ 更好的资源管理

## 执行流程

### macOS 启动序列

```
1. Open Firmware 激活
   ↓
2. BootX 加载内核和内核扩展 (kexts)
   ↓
3. 内核加载 launchd (PID=1)
   ↓
4. launchd 执行 /etc/rc
   ↓
5. launchd 扫描配置目录：
   - /System/Library/LaunchDaemons
   - /Library/LaunchDaemons
   - /System/Library/LaunchAgents
   - /Library/LaunchAgents
   - ~/Library/LaunchAgents
   ↓
6. launchd 读取 .plist 配置文件
   ↓
7. 按配置启动服务
   ↓
8. 登录窗口显示
```

### Job 的生命周期

```
plist 文件被加载
   ↓
launchd 解析 plist 配置
   ↓
检查 OnDemand 键：
  ├─ 存在 → 等待被调用（按需加载）
  └─ 不存在 → 立即启动
   ↓
监控运行中的服务
   ↓
服务异常？→ 根据配置自动重启
   ↓
服务卸载或禁用？→ 停止监控
```

## 权限管理

### 三类启动项的权限层级

| 类型               | 路径                            | 权限     | 何时运行     | 用途                 |
| ------------------ | ------------------------------- | -------- | ------------ | -------------------- |
| **System Daemons** | `/System/Library/LaunchDaemons` | root     | 系统启动时   | 系统级别的后台服务   |
| **Local Daemons**  | `/Library/LaunchDaemons`        | root     | 系统启动时   | 第三方软件的后台服务 |
| **System Agents**  | `/System/Library/LaunchAgents`  | 当前用户 | 用户登录时   | 系统级别的用户任务   |
| **Local Agents**   | `/Library/LaunchAgents`         | 当前用户 | 用户登录时   | 第三方软件的用户任务 |
| **User Agents**    | `~/Library/LaunchAgents`        | 当前用户 | 该用户登录时 | 用户自定义任务       |

### 权限设置

```bash
# 创建 plist 文件后，必须设置正确的权限

# 对于 root 运行的任务（Daemons）
sudo chown root:wheel /Library/LaunchDaemons/com.example.script.plist
sudo chmod 644 /Library/LaunchDaemons/com.example.script.plist

# 对于用户任务（Agents）
chmod 644 ~/Library/LaunchAgents/com.example.script.plist
```

### 权限错误影响

| 错误权限     | 后果                   |
| ------------ | ---------------------- |
| `755` 或更高 | launchd 会拒绝加载     |
| `600`        | 文件所有者之外无法访问 |
| `644` ✅     | 标准权限（推荐）       |
| `664`        | 组可写（不推荐）       |

## LaunchDaemons vs LaunchAgents

### LaunchDaemons（守护进程）

```
概念：在系统启动时以 root 权限运行的后台服务
特点：
  • 系统启动时自动运行（无需登录）
  • 通常以 root 权限运行
  • 可用于系统级别的任务
  • 无法访问 GUI 和用户资源

典型场景：
  • 系统监控
  • 网络服务
  • 数据库服务
  • 日志管理
  • 备份任务
```

### LaunchAgents（用户代理）

```
概念：在用户登录后运行的任务
特点：
  • 用户登录后启动
  • 以当前用户权限运行
  • 可以访问 GUI 和用户文件
  • 用户注销时停止

典型场景：
  • 定时获取邮件
  • 定期同步文件
  • 清理临时文件
  • 更新检查
  • 开发工具集成
```

### 如何选择？

```
问题：我的任务什么时候需要运行？
  ├─ 用户登录前需要 → LaunchDaemon + root 权限
  └─ 用户登录后运行 → LaunchAgent + 用户权限

问题：任务需要哪些权限？
  ├─ 需要 root 权限 → LaunchDaemon
  └─ 用户权限即可 → LaunchAgent
```

## 核心配置参数

### 必需参数

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- 任务名称（全局唯一标识） -->
  <key>Label</key>
  <string>com.example.myscript</string>

  <!-- 可选：程序路径 -->
  <key>Program</key>
  <string>/usr/local/bin/myscript</string>

  <!-- 或：程序和参数 -->
  <key>ProgramArguments</key>
  <array>
    <string>/usr/local/bin/myscript</string>
    <string>--verbose</string>
    <string>--config=/etc/myscript.conf</string>
  </array>
</dict>
</plist>
```

### 启动控制参数

| 参数                    | 类型         | 说明                                       |
| ----------------------- | ------------ | ------------------------------------------ |
| `RunAtLoad`             | Boolean      | 加载后立即运行（默认 NO）                  |
| `KeepAlive`             | Boolean/Dict | 服务异常时自动重启                         |
| `StartInterval`         | Integer      | 间隔秒数运行（如：3600 = 每小时）          |
| `StartCalendarInterval` | Array/Dict   | 按时间表运行（支持秒、分、小时、日期、周） |
| `OnDemand`              | Boolean      | 按需启动（已过时，用 KeepAlive 替代）      |

### 资源与环境参数

| 参数                   | 类型   | 说明                     |
| ---------------------- | ------ | ------------------------ |
| `WorkingDirectory`     | String | 工作目录                 |
| `UserName`             | String | 运行用户（默认当前用户） |
| `GroupName`            | String | 运行用户组               |
| `EnvironmentVariables` | Dict   | 环境变量                 |
| `StandardOutPath`      | String | 标准输出重定向           |
| `StandardErrorPath`    | String | 标准错误重定向           |
| `StandardInPath`       | String | 标准输入重定向           |

### 监控参数

| 参数                     | 类型    | 说明                                       |
| ------------------------ | ------- | ------------------------------------------ |
| `Errno`                  | Integer | 进程异常退出时的行为                       |
| `ExitTimeOut`            | Integer | 关闭等待时间（秒）                         |
| `RestartOnCrash`         | Boolean | 崩溃时重启（已过时）                       |
| `ThrottleInterval`       | Integer | 重启的最小间隔（秒）                       |
| `LimitLoadToHosts`       | Array   | 限制运行的主机类型                         |
| `LimitLoadToSessionType` | Array   | 限制会话类型（Aqua/StandardIO/Background） |

## 常见使用场景

### 1. 定时清理日志（每天午夜）

查看 [examples/com.example.cleanup-logs.plist](examples/com.example.cleanup-logs.plist)

```bash
cp examples/com.example.cleanup-logs.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.example.cleanup-logs.plist
```

### 2. 每小时同步代码仓库

```xml
<key>StartInterval</key>
<integer>3600</integer>
```

### 3. 系统启动时运行脚本

```xml
<key>RunAtLoad</key>
<boolean>true</boolean>
```

### 4. 服务异常时自动重启

```xml
<key>KeepAlive</key>
<boolean>true</boolean>
```

## 最佳实践

### ✅ DO（应该做）

1. **使用反向域名** 作为 Label 标识

   ```
   com.username.taskname
   com.company.applicationname
   ```

2. **为脚本设置执行权限**

   ```bash
   chmod +x /usr/local/bin/myscript
   ```

3. **使用绝对路径**

   ```xml
   <!-- 好 -->
   <string>/usr/local/bin/myscript</string>

   <!-- 不好 -->
   <string>myscript</string>
   ```

4. **记录日志便于调试**

   ```xml
   <key>StandardOutPath</key>
   <string>/var/log/myscript.log</string>
   <key>StandardErrorPath</key>
   <string>/var/log/myscript.error.log</string>
   ```

5. **测试脚本的可执行性**

   ```bash
   /path/to/your/script.sh  # 直接测试
   ```

6. **使用适当的 XML 编码**
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   ```

### ❌ DON'T（不应该做）

1. **不要在脚本中使用用户变量**

   ```bash
   # 不好 - $HOME 可能为空
   cd ~ && ./backup.sh

   # 好 - 使用绝对路径
   /usr/local/bin/backup.sh
   ```

2. **不要忽视权限设置**

   ```bash
   # 错误
   chmod 755 /Library/LaunchAgents/com.example.plist

   # 正确
   chmod 644 /Library/LaunchAgents/com.example.plist
   ```

3. **不要在 Daemon 中依赖 GUI**

   ```
   Daemon 运行于系统级别，无法访问 GUI 资源
   → 改用 LaunchAgent
   ```

4. **不要频繁的 load/unload**

   ```bash
   # 有脚本错误时不要反复 load/unload
   # 而是修复脚本后再重新加载
   ```

5. **不要使用相对路径**

   ```bash
   # 不好
   Program = "./script.sh"

   # 好
   Program = "/usr/local/bin/script.sh"
   ```

## 故障排除

### launchctl 常用命令

```bash
# 列出所有已加载的 jobs
launchctl list

# 列出特定 jobs（包含未加载的）
launchctl list | grep com.example

# 加载 plist 文件
launchctl load ~/Library/LaunchAgents/com.example.plist

# 卸载 plist 文件
launchctl unload ~/Library/LaunchAgents/com.example.plist

# 启动已加载的 job
launchctl start com.example.plist

# 停止运行中的 job
launchctl stop com.example.plist

# 查看 job 的详细信息
launchctl list com.example.plist

# 移除 job
launchctl remove com.example.plist
```

### 常见问题

#### 问题 1: "plist 不被加载"

**可能原因：**

- ❌ plist 文件权限不是 644
- ❌ 文件位置错误
- ❌ XML 格式有误
- ❌ Label 中包含空格或特殊字符

**解决方案：**

```bash
# 检查权限
ls -la ~/Library/LaunchAgents/com.example.plist
# 应该显示 -rw-r--r--

# 验证 XML 格式
plutil -lint ~/Library/LaunchAgents/com.example.plist

# 查看加载错误
launchctl load ~/Library/LaunchAgents/com.example.plist
```

#### 问题 2: "脚本不执行"

**可能原因：**

- ❌ 脚本没有执行权限
- ❌ 脚本中使用了不存在的 shell
- ❌ 脚本有语法错误
- ❌ 使用了相对路径

**解决方案：**

```bash
# 赋予脚本执行权限
chmod +x /usr/local/bin/myscript.sh

# 直接运行脚本测试
/usr/local/bin/myscript.sh

# 指定正确的 shebang（脚本首行）
#!/bin/bash
```

#### 问题 3: "环境变量不识别"

**可能原因：**

- ❌ 脚本依赖 shell 环境变量（如 $PATH）
- ❌ launchd 启动的进程环境变量有限

**解决方案：**

```xml
<!-- 在 plist 中显式设置环境变量 -->
<key>EnvironmentVariables</key>
<dict>
  <key>PATH</key>
  <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  <key>HOME</key>
  <string>/Users/username</string>
</dict>
```

#### 问题 4: "权限被拒绝"

**可能原因：**

- ❌ 脚本属于不同用户
- ❌ UserName 设置错误
- ❌ Daemon 试图访问用户文件

**解决方案：**

```bash
# 检查脚本所有者
ls -la /usr/local/bin/myscript.sh

# 改变所有者
sudo chown username /usr/local/bin/myscript.sh

# 查看 plist 中的 UserName 设置
```

#### 问题 5: "频繁重启循环"

**可能原因：**

- ❌ 脚本立即退出并返回错误代码
- ❌ KeepAlive = true 导致不断重启
- ❌ 脚本仍有 bug

**解决方案：**

```xml
<!-- 添加 ThrottleInterval 避免过度重启 -->
<key>ThrottleInterval</key>
<integer>10</integer>  <!-- 最少间隔 10 秒 -->
```

### 查看日志

```bash
# 查看 launchd 的系统日志
log stream --predicate 'process == "launchd"' --level debug

# 查看特定任务的日志
cat /var/log/myscript.log
cat /var/log/myscript.error.log

# 实时查看日志
tail -f /var/log/myscript.log
```

## 相关文件位置

```
系统级 Daemon：
/System/Library/LaunchDaemons/
/Library/LaunchDaemons/

用户级 Agent：
/System/Library/LaunchAgents/
/Library/LaunchAgents/
~/Library/LaunchAgents/

配置文件：
/etc/launchd.conf（系统级，已过时）
~/.launchd.conf（用户级，不推荐）
```

## 参考资源

- 📖 官方文档：`man launchd`、`man launchctl`、`man plist`
- 🔗 Apple 开发者文档
- 💻 其他资源：本目录的示例 plist 文件

---

**最后的话：** launchd 虽然强大，但也是 macOS 中被很多开发者忽视的瑰宝。掌握它，你的 Mac 将为你工作 24/7！🚀
