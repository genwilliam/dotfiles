[中文](README-zh.md) | English

## Purpose of the `bin/` directory

The `bin/` directory holds personal executable scripts (personal CLI utilities).

It is **not** put on `PATH` as a directory. Instead, `install.sh` symlinks every
*executable* file under `bin/` into `~/.local/bin`, and `~/.local/bin` is the directory
that `.zprofile` puts on `PATH`. Symlinking (rather than copying) means `git pull`
updates the installed command immediately.

Typical use cases:

- wrapping frequently used command combinations
- automating development workflows
- providing personal CLI utilities
- extending tools such as Git or Docker
- managing or maintaining the local development environment

Example layout:

```
bin/
  local/
    adminrun        # run a command with macOS admin privileges
  README.md         # not linked: not executable
```

Subdirectories are included, so `bin/local/adminrun` is installed as
`~/.local/bin/adminrun`.

Common conventions:

- Every script needs a shebang, for example:

  ```bash
  #!/usr/bin/env bash
  ```

- Every script should be executable, otherwise it will not be linked. `install.sh`
  prints `SKIP (not executable): bin/<name>` and counts it as skipped:

  ```bash
  chmod +x bin/my-tool
  ```

- Files that are not meant to be commands (READMEs, fixtures, data files) can simply
  stay non-executable.
- Each script should do one thing and stay composable.
- Prefer `#!/usr/bin/env bash` or `#!/bin/zsh`; see `local/adminrun` for a zsh example
  that uses `osascript` to obtain administrator rights without requiring `sudo`.

After adding a script:

```bash
chmod +x bin/my-tool
./install.sh --link-only     # or: ./bootstrap.sh --fix
./bootstrap.sh --no-warm     # confirm it is linked
```

`bin/` needs no mapping entry in `install.sh`: the whole directory is scanned, so a new
executable is picked up automatically.
