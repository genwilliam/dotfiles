# macOS Launchd Guide & Configuration

> Master launchd and let your Mac work for you while you sleep 😴

## Table of Contents

- [What is Launchd?](#what-is-launchd)
- [Execution Flow](#execution-flow)
- [Permissions](#permissions)
- [LaunchDaemons vs LaunchAgents](#launchdaemons-vs-launchagents)
- [Core Configuration Parameters](#core-configuration-parameters)
- [Common Use Cases](#common-use-cases)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## What is Launchd?

`launchd` is an open-source service management framework designed by Apple to replace multiple traditional Unix/Linux components:

- `init` process
- `rc.d` scripts
- `SystemStarter`
- `inetd`/`xinetd`
- `crond`/`atd`
- `watchdogd`

As the first process after macOS kernel initialization (PID=1), `launchd` is responsible for:

1. System launch and initialization
2. Starting system-level daemons
3. Loading and managing all services
4. Monitoring and restarting crashed services

**Key Advantages:**

- ✅ Unified service management interface
- ✅ On-demand service loading (faster boot times)
- ✅ Automatic service restart on failure
- ✅ Better resource management
- ✅ Language and framework agnostic

## Execution Flow

### macOS Boot Sequence

```
1. Open Firmware activates
   ↓
2. BootX loads kernel and kernel extensions (kexts)
   ↓
3. Kernel loads launchd (PID=1)
   ↓
4. launchd executes /etc/rc
   ↓
5. launchd scans configuration directories:
   - /System/Library/LaunchDaemons
   - /Library/LaunchDaemons
   - /System/Library/LaunchAgents
   - /Library/LaunchAgents
   - ~/Library/LaunchAgents
   ↓
6. launchd parses .plist configuration files
   ↓
7. Services are launched according to configuration
   ↓
8. Login window displayed
```

### Job Lifecycle

```
plist file is loaded
   ↓
launchd parses plist configuration
   ↓
Check OnDemand/KeepAlive settings:
  ├─ On-Demand → Wait for invocation
  └─ Not On-Demand → Start immediately
   ↓
Monitor running services
   ↓
Service crashes/exits?
  → Restart based on configuration
   ↓
Service disabled/unloaded?
  → Stop monitoring
```

## Permissions

### Three Categories of Launch Items

| Type               | Location                        | Owner        | When        | Purpose                          |
| ------------------ | ------------------------------- | ------------ | ----------- | -------------------------------- |
| **System Daemons** | `/System/Library/LaunchDaemons` | root         | System boot | System-level background services |
| **Local Daemons**  | `/Library/LaunchDaemons`        | root         | System boot | Third-party background services  |
| **System Agents**  | `/System/Library/LaunchAgents`  | Current User | User login  | System-level user tasks          |
| **Local Agents**   | `/Library/LaunchAgents`         | Current User | User login  | Third-party user tasks           |
| **User Agents**    | `~/Library/LaunchAgents`        | Current User | User login  | Custom personal tasks            |

### Setting Permissions

```bash
# After creating a plist file, set correct permissions

# For daemons (root-run tasks)
sudo chown root:wheel /Library/LaunchDaemons/com.example.script.plist
sudo chmod 644 /Library/LaunchDaemons/com.example.script.plist

# For user agents
chmod 644 ~/Library/LaunchAgents/com.example.script.plist
```

### Permission Impact

| Permission      | Consequence                       |
| --------------- | --------------------------------- |
| `755` or higher | launchd refuses to load           |
| `600`           | Access restricted to file owner   |
| `644` ✅        | Standard permission (recommended) |
| `664`           | Group writable (not recommended)  |
| `700`           | Owner executable only             |

## LaunchDaemons vs LaunchAgents

### LaunchDaemons (System Services)

```
Concept: Background services running at boot with root privileges
Characteristics:
  • Run automatically at system startup (no login required)
  • Typically execute with root privileges
  • Designed for system-level tasks
  • No access to GUI or user resources
  • Continue running even if user logs out

Typical Use Cases:
  • System monitoring/surveillance
  • Network services (web servers, proxies)
  • Database services
  • Logging and log rotation
  • Backup services
  • Security scanning
```

### LaunchAgents (User Tasks)

```
Concept: Tasks launched after user login with user privileges
Characteristics:
  • Start after user logs in
  • Execute with current user privileges
  • Can access GUI and user files
  • Stop when user logs out
  • More flexible resource access

Typical Use Cases:
  • Email synchronization
  • File synchronization
  • Temp file cleanup
  • Update checking
  • IDE/editor integration
  • Development tools
  • Backup/archiving
```

### How to Choose?

```
Question: When does my task need to run?
  ├─ Before user login needed → LaunchDaemon + root
  └─ After user login → LaunchAgent + user privileges

Question: What permissions does it need?
  ├─ Needs root privilege → LaunchDaemon
  └─ User privilege sufficient → LaunchAgent
```

## Core Configuration Parameters

### Essential Parameters

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- Unique identifier for the job -->
  <key>Label</key>
  <string>com.example.myscript</string>

  <!-- Option 1: Direct program path -->
  <key>Program</key>
  <string>/usr/local/bin/myscript</string>

  <!-- Option 2: Program with arguments -->
  <key>ProgramArguments</key>
  <array>
    <string>/usr/local/bin/myscript</string>
    <string>--verbose</string>
    <string>--config=/etc/myscript.conf</string>
  </array>
</dict>
</plist>
```

### Execution Control Parameters

| Parameter               | Type         | Description                                    |
| ----------------------- | ------------ | ---------------------------------------------- |
| `RunAtLoad`             | Boolean      | Run immediately upon load (default: NO)        |
| `KeepAlive`             | Boolean/Dict | Auto-restart if service crashes                |
| `StartInterval`         | Integer      | Run every N seconds (e.g. 3600 = hourly)       |
| `StartCalendarInterval` | Array/Dict   | Schedule by calendar (minute/hour/day/weekday) |
| `OnDemand`              | Boolean      | (Deprecated - use KeepAlive instead)           |

### Resource & Environment Parameters

| Parameter              | Type   | Description                            |
| ---------------------- | ------ | -------------------------------------- |
| `WorkingDirectory`     | String | Working directory for the process      |
| `UserName`             | String | User to run as (default: current user) |
| `GroupName`            | String | Group to run as                        |
| `EnvironmentVariables` | Dict   | Environment variables for process      |
| `StandardOutPath`      | String | Redirect stdout to file                |
| `StandardErrorPath`    | String | Redirect stderr to file                |
| `StandardInPath`       | String | Redirect stdin from file               |

### Monitoring Parameters

| Parameter                | Type    | Description                                     |
| ------------------------ | ------- | ----------------------------------------------- |
| `Errno`                  | Integer | Behavior when process exits abnormally          |
| `ExitTimeOut`            | Integer | Grace period before force termination (seconds) |
| `RestartOnCrash`         | Boolean | (Deprecated - use KeepAlive)                    |
| `ThrottleInterval`       | Integer | Minimum interval between restarts (seconds)     |
| `LimitLoadToHosts`       | Array   | Restrict to specific host types                 |
| `LimitLoadToSessionType` | Array   | Restrict to session types (Aqua/StandardIO)     |

### Advanced Parameters

| Parameter             | Type    | Description                                           |
| --------------------- | ------- | ----------------------------------------------------- |
| `Nice`                | Integer | Process priority (-20 to 20)                          |
| `ProcessType`         | String  | Process classification (Background/Standard/Adaptive) |
| `TimeOut`             | Integer | Max execution time (seconds)                          |
| `AbandonProcessGroup` | Boolean | Don't terminate child processes                       |

## Common Use Cases

### 1. Daily Log Cleanup (Runs at Midnight)

See [examples/com.example.daily-cleanup.plist](examples/com.example.daily-cleanup.plist)

```bash
cp examples/com.example.daily-cleanup.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.example.daily-cleanup.plist
```

### 2. Hourly Repository Sync

```xml
<key>StartInterval</key>
<integer>3600</integer>
```

### 3. Run Script at Boot

```xml
<key>RunAtLoad</key>
<boolean>true</boolean>
```

### 4. Auto-Restart Service

```xml
<key>KeepAlive</key>
<boolean>true</boolean>
```

## Best Practices

### ✅ DO (Recommended)

1. **Use reverse domain notation** for Label

   ```
   com.username.taskname
   com.company.applicationname
   ```

2. **Make scripts executable**

   ```bash
   chmod +x /usr/local/bin/myscript
   ```

3. **Always use absolute paths**

   ```xml
   <!-- Good -->
   <string>/usr/local/bin/myscript</string>

   <!-- Bad -->
   <string>./myscript</string>
   ```

4. **Enable logging for debugging**

   ```xml
   <key>StandardOutPath</key>
   <string>/var/log/myscript.log</string>
   <key>StandardErrorPath</key>
   <string>/var/log/myscript.error.log</string>
   ```

5. **Test scripts directly first**

   ```bash
   /path/to/your/script.sh
   echo $?  # Check exit code
   ```

6. **Use proper XML encoding**

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   ```

7. **Specify bash explicitly**

   ```bash
   #!/bin/bash
   ```

8. **Use proper indentation**
   ```bash
   # Use 2 or 4 spaces for readability
   ```

### ❌ DON'T (Avoid)

1. **Don't rely on shell environment variables**

   ```bash
   # Bad - $HOME may be empty
   cd ~ && ./backup.sh

   # Good - use absolute paths
   /usr/local/bin/backup.sh
   ```

2. **Don't ignore file permissions**

   ```bash
   # Wrong
   chmod 755 /Library/LaunchAgents/com.example.plist

   # Correct
   chmod 644 /Library/LaunchAgents/com.example.plist

   # Wrong
   chmod 755 /usr/local/bin/myscript.sh

   # Correct
   chmod 755 /usr/local/bin/myscript.sh  # Script needs execute
   ```

3. **Don't use GUI in Daemons**

   ```
   Daemons run at system level without GUI access
   → Use LaunchAgent instead
   ```

4. **Don't repeatedly load/unload**

   ```bash
   # Fix your script first
   # Then reload once
   ```

5. **Don't hardcode paths**

   ```bash
   # Bad
   /Users/john/scripts/backup.sh

   # Check with `whoami` or use absolute paths appropriate for user
   ```

6. **Don't forget the XML DOCTYPE**
   ```xml
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
     "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   ```

## Troubleshooting

### Common launchctl Commands

```bash
# List all loaded jobs with PIDs
launchctl list

# Find jobs matching pattern
launchctl list | grep com.example

# Load a plist file
launchctl load ~/Library/LaunchAgents/com.example.plist

# Unload a job
launchctl unload ~/Library/LaunchAgents/com.example.plist

# Start a specific job
launchctl start com.example.plist

# Stop a running job
launchctl stop com.example.plist

# View job details
launchctl list com.example.plist

# Remove a job
launchctl remove com.example.plist

# Check plist syntax
plutil -lint ~/Library/LaunchAgents/com.example.plist
```

### Common Issues

#### Issue 1: "Plist Won't Load"

**Possible Causes:**

- ❌ Invalid file permissions (not 644)
- ❌ Wrong file location
- ❌ Malformed XML
- ❌ Invalid characters in Label
- ❌ Duplicate Label

**Solutions:**

```bash
# Check permissions
ls -la ~/Library/LaunchAgents/com.example.plist
# Should show: -rw-r--r--

# Validate XML
plutil -lint ~/Library/LaunchAgents/com.example.plist

# Check for load errors
launchctl load -D all

# Look for duplicates
launchctl list | grep com.example
```

#### Issue 2: "Script Doesn't Execute"

**Possible Causes:**

- ❌ Script not executable
- ❌ Wrong or missing shebang
- ❌ Script syntax errors
- ❌ Relative paths used
- ❌ Missing dependencies

**Solutions:**

```bash
# Make script executable
chmod +x /usr/local/bin/myscript.sh

# Test script directly
/usr/local/bin/myscript.sh

# Use proper shebang (first line)
#!/bin/bash

# Check for script errors
bash -n /usr/local/bin/myscript.sh
```

#### Issue 3: "Environment Variables Not Working"

**Possible Causes:**

- ❌ Script depends on shell variables
- ❌ launchd provides limited environment

**Solutions:**

```xml
<!-- Explicitly set in plist -->
<key>EnvironmentVariables</key>
<dict>
  <key>PATH</key>
  <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  <key>HOME</key>
  <string>/Users/username</string>
</dict>
```

#### Issue 4: "Permission Denied"

**Possible Causes:**

- ❌ Wrong script owner
- ❌ Incorrect UserName in plist
- ❌ Daemon accessing user-only files

**Solutions:**

```bash
# Check script ownership
ls -la /usr/local/bin/myscript.sh

# Change owner if needed
sudo chown username /usr/local/bin/myscript.sh

# Verify UserName in plist
```

#### Issue 5: "Restart Loop"

**Possible Causes:**

- ❌ Script exits immediately with error
- ❌ KeepAlive = true causing infinite loop
- ❌ Unresolved script bugs

**Solutions:**

```xml
<!-- Add throttling -->
<key>ThrottleInterval</key>
<integer>10</integer>  <!-- Min 10 seconds between restarts -->
```

### Viewing Logs

```bash
# View launchd system logs
log stream --predicate 'process == "launchd"' --level debug

# View your specific job logs
cat /var/log/myscript.log
cat /var/log/myscript.error.log

# Real-time monitoring
tail -f /var/log/myscript.log

# System log for specific label
log stream --predicate 'eventMessage contains "com.example"'
```

## File Locations

```
System Daemons:
/System/Library/LaunchDaemons/
/Library/LaunchDaemons/

User Agents:
/System/Library/LaunchAgents/
/Library/LaunchAgents/
~/Library/LaunchAgents/

Config Files:
/etc/launchd.conf (deprecated)
~/.launchd.conf (not recommended)
```

## Reference

- 📖 Man Pages: `man launchd`, `man launchctl`, `man launchd.plist`
- 🔗 Apple Developer Documentation
- 💻 Example plist files in this directory
- 🐛 Check system logs: `log stream`

---

**Final Thought:** launchd is a hidden gem in macOS that many developers overlook. Master it, and your Mac will work for you 24/7! 🚀

---

**Last Updated:** 2024  
**Compatibility:** macOS 10.5+
