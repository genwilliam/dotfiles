[中文](README-zh.md) | English

# Introduction

After reading [webpro's article](https://github.com/webpro/awesome-dotfiles), I discovered many useful dotfiles. I think they are great, but I don't want to copy them directly (I believe everyone's computer setup is unique). I want a configuration that fits me, just like [mathiasbynens](https://github.com/mathiasbynens/dotfiles).

> This repository is a personal, macOS-first setup. It is written to be readable and
> reproducible rather than to be a general-purpose framework: every file that is
> installed is declared in one place (`install.sh`), and `./bootstrap.sh` checks that
> what is on disk matches that declaration.

## Repository layout

| Path | What it is | Installed by `install.sh` |
| --- | --- | --- |
| `install.sh` | Installer: links files, optionally installs tooling | — |
| `bootstrap.sh` | Verifier: read-only check of the install (and `--fix`) | — |
| `tests/test-install.sh` | Regression tests for both scripts | — |
| `zsh/` | Shell startup files and `zshrc.d/` modules | yes |
| `p10k/` | powerlevel10k flavour (`zshrc` overlay + `p10k.zsh`) | yes, with `--prompt p10k` |
| `git/` | `gitconfig`, `gitignore_global`, `gitconfig.local` | yes |
| `editorconfig` | EditorConfig rules | yes → `~/.editorconfig` |
| `tmux/` | oh-my-tmux `tmux.conf` + personal `tmux.conf.local` | yes → `~/.config/tmux` |
| `nvim/` | Neovim (NvChad) configuration | yes → `~/.config/nvim` |
| `bin/` | Personal commands; executables land in `~/.local/bin` | yes |
| `config/` | `starship.toml`, `thefuck/`, `aria2/` | yes |
| `Brewfile` | Homebrew formulae, casks and VS Code extensions | yes (macOS) |
| `macos` | Script that changes system-wide macOS preferences | **no** — run manually |
| `defaults` | Read-only dump of this machine's `defaults` state | **no** — reference only |
| `macos_other.md` | Notes and snippets not automated | **no** — documentation |
| `launchd/` | Documentation about `launchd` | **no** — documentation |

## Requirements and supported platforms

| Platform | Support |
| --- | --- |
| macOS (Apple Silicon and Intel) | Full: dotfiles, Homebrew + Brewfile, zsh, prompt, tmux, nvim |
| Linux | Partial: dotfiles + zsh only. Homebrew/Brewfile/macOS steps are skipped |
| Windows / WSL | Not supported by `install.sh`. Use WSL and run the Linux path, or link files manually |

Requirements:

- `bash` >= 3.2 — the version macOS ships at `/bin/bash`. The scripts avoid bash 4+
  features on purpose, so no Homebrew bash is needed.
- `zsh` >= 5.0 for the shell configuration.
- `git` for cloning zsh plugins (and for `Brewfile`'s `go`/`uv` entries).

## Install

```bash
git clone https://github.com/genwilliam/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Options

| Option | Effect |
| --- | --- |
| `-n`, `--dry-run` | Print what would happen; change nothing |
| `--link-only` | Only create symlinks. Skip Homebrew, Brewfile, zsh, Oh My Zsh and plugins |
| `--prompt FLAVOUR` | `starship` (default) or `p10k`. Skips the interactive question |
| `--print-map` | Print `source<TAB>target<TAB>required\|optional` for every managed path and exit |
| `--uninstall` | Remove the symlinks that point into this repository |
| `--remove-readmes` | Delete `README*` files from `$HOME` after installing |
| `-y`, `--yes` | Answer "yes" to every confirmation |
| `-h`, `--help` | Usage |

Useful combinations:

```bash
./install.sh --dry-run                 # preview a full install
./install.sh --link-only --prompt p10k # only link files, powerlevel10k flavour
./install.sh -y                        # unattended
```

`install.sh` needs to run on macOS or Linux; it stops with a clear message
otherwise. It never uses `sudo` except when it has to register a shell in
`/etc/shells` for `chsh`, and it tells you the manual command when it cannot.

### What gets installed where

`install.sh` has a single mapping table (`link_dotfiles`). This is the complete
list for the default (`starship`) flavour:

| Source in this repo | Target |
| --- | --- |
| `git/gitconfig` | `~/.gitconfig` |
| `git/gitignore_global` | `~/.gitignore_global` |
| `git/gitconfig.local` | `~/.gitconfig.local` *(optional, see below)* |
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
| each executable in `bin/` | `~/.local/bin/<name>` |

With `--prompt p10k`, `p10k/zshrc` is linked to `~/.zshrc`, `p10k/p10k.zsh` to
`~/.p10k.zsh`, and `config/starship.toml` is not linked. Switching flavour also
removes the other flavour's link.

`git/gitconfig.local` is **optional**: it is gitignored, so a fresh clone does not
contain it. `install.sh` skips it silently and `bootstrap.sh` reports it as a note.
Create it yourself for machine-local identity:

```bash
cat > ~/dotfiles/git/gitconfig.local <<'EOF'
[user]
    name = Your Name
    email = you@example.com
EOF
./install.sh --link-only
```

Only *executable* files under `bin/` are linked, so the `bin/README.md` files never
end up in `~/.local/bin`. Files in subdirectories (such as `bin/local/adminrun`) are
included.

### How existing files are handled

Linking is idempotent and non-destructive:

- A target that is already a symlink to the correct source is left untouched.
- A target that is a symlink to something else is replaced by the correct symlink.
- A target that is a **real file or directory** is first moved to
  `<target>.bak.<YYYYmmddHHMMSS>` and never deleted. If that name is taken, a
  numeric suffix is appended.
- A missing source is reported: a required mapping that points at a file which no
  longer exists is a failure, not a silent skip.

The script summarises what it did (linked / already correct / skipped / backed up /
removed) and exits non-zero if any step failed.

## Verify an install

```bash
./bootstrap.sh              # read-only check
./bootstrap.sh --fix        # repair missing or wrong links
./bootstrap.sh --no-warm    # skip the interactive zsh smoke test
./bootstrap.sh --prompt p10k
```

`bootstrap.sh` reads the mapping from `install.sh --print-map`, so the two can never
disagree. It checks that:

1. every mapping points at a source that still exists (this is what catches a
   configuration file that was renamed but not updated in `install.sh`);
2. every target in `$HOME` is a symlink to that exact source;
3. no stale symlink points into this repository that is no longer part of the
   mapping (these silently change shell behaviour — for example a leftover
   `~/.tmux.conf` or `~/.p10k.zsh`);
4. the managed zsh files pass `zsh -n`;
5. an interactive zsh starts cleanly (skip with `--no-warm`).

It exits `0` when everything verifies and `1` when it finds a problem. Repair only
happens with `--fix`, which delegates to `./install.sh --link-only` — there is only
one implementation of the linking logic, so there is nothing to drift.

## Update, re-run, uninstall

Re-running is safe; that is the normal update path:

```bash
cd ~/dotfiles
git pull
./install.sh --link-only    # or ./install.sh to also run the tooling steps
./bootstrap.sh
```

To remove the configuration without touching anything else:

```bash
./install.sh --uninstall --dry-run   # preview
./install.sh --uninstall             # remove only repo-owned symlinks
```

`--uninstall` removes a path **only** if it is a symlink that resolves to this
repository. Regular files, directories, and symlinks pointing elsewhere are left
alone, and backups are kept. There is no separate uninstall script by design:
uninstalling is just removing the links, which the installer can do precisely.

To restore a configuration that was replaced during an install:

```bash
ls -d ~/.zshrc.bak.*                    # find the backups
mv ~/.zshrc.bak.20260101120000 ~/.zshrc # restore one
```

## Manual steps (deliberately not automated)

| Step | Command / action | Why it is manual |
| --- | --- | --- |
| macOS system preferences | `./macos` | Changes system-wide settings, needs `sudo` and a re-login |
| Reviewing your defaults | `./defaults` is a **dump, not a script** | See the warning below |
| Meslo Nerd Font | `brew install --cask font-meslo-lg-nerd-font` | Also in the `Brewfile` |
| powerlevel10k wizard | `p10k configure` | Regenerates `~/.p10k.zsh` |
| tmux plugins | start tmux, then `Prefix + I` | TPM installs/updates plugins itself |
| Neovim plugins | start `nvim` once | lazy.nvim installs plugins on first start |
| GitHub Copilot auth | `:Copilot setup` in Neovim | Interactive authentication |
| Homebrew itself | prompted by `./install.sh` | Runs the upstream installer, which needs your consent |

### A warning about `defaults`

`defaults` is a 195 KB, automatically generated dump of **this machine's** current
macOS defaults (`defaults read` output), kept for reference. It is not a script and
is not executed by anything.

It contains binary plist data and machine-specific personal information: absolute
paths under a home directory, recent Finder locations, Dock entries, and similar.
Treat it as a private backup. If you fork this repository, delete that file (or keep
it out of version control) before publishing.

## zsh

> Before you begin, please read [zsh/bash loading order](https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/).

| File | Load order | When it is loaded | Runs every shell start? | Responsibility here |
| --- | --- | --- | --- | --- |
| `.zshenv` | 1 | **Every** zsh invocation | yes | Locale only, kept minimal so scripts/`scp` are unaffected |
| `.zprofile` | 2 | Login shells | no | **Owns `PATH`**: user bins, Homebrew `shellenv` |
| `.zshrc` | 3 | Interactive shells | no | Orchestrator: cache paths, module order, Oh My Zsh |
| `.zlogin` | 4 | After `.zshrc` in login shells | no | Terminal title |
| `.zlogout` | 5 | When a login shell exits | no | Cleanup hook (currently a no-op, documented) |

### Oh My Zsh is used

`~/.zshrc` sources `$ZSH/oh-my-zsh.sh`, and `install.sh` runs the official Oh My
Zsh installer plus clones the plugins that are not bundled with it. The plugin list
in `zsh/zshrc.d/plugins.zsh` is the source of truth:

- bundled with Oh My Zsh, nothing to install: `git`, `fzf`, `aliases`,
  `colored-man-pages`, `zoxide`, `extract`
- installed by `install.sh`: `zsh-autosuggestions`, `fast-syntax-highlighting`,
  `you-should-use`

`fzf-tab` is intentionally **disabled** (commented out in `plugins.zsh`, and no
`fzf-tab` keybinding is configured). Tab uses menu completion.

### Module boundaries

`zsh/zshrc.d/` is split by responsibility, and the load order matters:

```
~/.zshrc
  ├─ pre-Oh-My-Zsh :  env.zsh  →  env.local.zsh  →  plugins.zsh
  ├─ Oh My Zsh     :  $ZSH/oh-my-zsh.sh
  └─ post-Oh-My-Zsh:  aliases.zsh  →  completion.zsh  →  tools.zsh
```

- `env.zsh` — interactive environment variables and extra `PATH` entries
  (Rust, JDK, Maven).
- `env.local.zsh` — gitignored, empty by default; put machine-specific settings
  here. It is sourced even when absent.
- `plugins.zsh` — only the `plugins=(...)` array.
- `completion.zsh` — completion policy and `compinit`.
- `tools.zsh` — tool initialisation: starship, lazy `thefuck`, lazy `nvm`,
  lazy `mise`.

See [`zsh/zshrc.d/README.md`](zsh/zshrc.d/README.md) for the full conventions.

### PATH ownership

`PATH` is composed in `.zprofile` in this order (last prepended wins):

1. `~/.local/bin`, `~/Library/pnpm`
2. `/opt/homebrew/bin`, `/usr/local/bin` (then Homebrew's `shellenv` prepends
   `/opt/homebrew/bin` and `/opt/homebrew/sbin` again)
3. `~/.openclaw/bin` and other per-user tool bins, guarded by an existence check

`zsh/zshrc.d/env.zsh` prepends Rust/JDK/Maven paths afterwards. Nothing hard-codes a
user name or a home directory: paths are built from `$HOME` and existence-checked, so
the same files work on another machine or another architecture (the JDK check covers
both `/opt/homebrew` and `/usr/local`). The Maven path is resolved with a glob, so
upgrading Maven does not require editing the config.

`path`/`PATH` are kept unique (`typeset -gU path`), so re-sourcing `~/.zshrc` never
grows or duplicates `PATH`.

### Prompt flavours

Both flavours share `~/.zshrc.d`, so aliases, completion and tool initialisation are
identical. Only the prompt differs:

- **starship** (default, currently used): `zsh/zshrc` → `~/.zshrc`, config in
  `config/starship.toml`.
- **powerlevel10k**: `p10k/zshrc` → `~/.zshrc`. That file is a thin overlay — it
  initialises the instant prompt, sets `ZSH_THEME` and
  `ZSH_PROMPT_FLAVOR=p10k`, then sources the shared orchestrator found relative to
  its own resolved symlink. It no longer duplicates the module list.

```bash
./install.sh --link-only --prompt p10k
```

Installing both at once is not supported; `install.sh` removes the other flavour's
link so that exactly one prompt is active. Changing flavour takes effect in a new
shell.

To configure starship, edit `config/starship.toml` — it is linked into
`~/.config/starship.toml` (the README used to show a wrong path for this).

![CleanShot 2026-03-12 at 10.46.26@2x](https://raw.githubusercontent.com/genwilliam/picgo_img/main/img/CleanShot%202026-03-12%20at%2010.46.26%402x.png)

### Completion cache stability (`compinit` / `compdump`)

In large plugin setups, repeated `source ~/.zshrc` can become unexpectedly slow when
`compinit` keeps rebuilding completion metadata (`compdump`).

- Re-sourcing `~/.zshrc` in the same shell can cause completion metadata drift if path
  arrays are not deduplicated.
- Once metadata differs, `compinit` may regenerate the completion cache, which can
  make reload time jump from milliseconds to hundreds of milliseconds.

Current fix in this repo:

- `typeset -gU path fpath` prevents duplication during repeated sourcing.
- `ZSH_CACHE_DIR` and `ZSH_COMPDUMP` pin the cache under `~/.cache` for deterministic
  behaviour.
- `completion.zsh` uses `compinit -C -d "$ZSH_COMPDUMP"` to prefer cache reuse.
- Completion policy is explicit: Tab uses menu selection; `fzf-tab` is available but
  disabled.

### Startup profiling

This actually works now:

```bash
ZSH_STARTUP_PROFILE=1 zsh -i -c exit 2>&1 | grep '^zsh-startup'
```

Each sourced module prints one `zsh-startup <ms> <module>` line on stderr. With the
variable unset there is no overhead (the timing code is guarded behind a single
variable check). Baseline stays available with:

```bash
/usr/bin/time -lp zsh -i -c exit
```

## tmux

The tmux configuration is based on [oh-my-tmux](https://github.com/gpakosz/.tmux).
Unlike the instructions in older versions of this README, **do not run the upstream
`install.sh`**: this repository already tracks oh-my-tmux's `tmux.conf`, and the
upstream installer would write through the symlink and modify the tracked file.

The layout is XDG-based:

```
~/.config/tmux            ->  <repo>/tmux
~/.config/tmux/tmux.conf  ->  oh-my-tmux base config (tracked, do not edit)
~/.config/tmux/tmux.conf.local  ->  personal overrides (edit this one)
~/.config/tmux/plugins/   ->  TPM's plugin directory (gitignored)
```

tmux >= 3.1 reads `~/.config/tmux/tmux.conf` by itself, and oh-my-tmux derives its
plugin directory from the config location, which is why the whole `tmux` directory is
linked at once. Older installs that created `~/.tmux.conf` are migrated
automatically: `install.sh` removes that symlink when it points into this repository
and prints a note (otherwise a stale `~/.tmux.conf` would keep taking precedence).

### Plugins

Declared in `tmux/tmux.conf.local` and installed by TPM:

- `tmux-plugins/tmux-copycat` — regex search in scrollback/copy mode
- `tmux-plugins/tmux-resurrect` — save and restore sessions
- `tmux-plugins/tmux-open` — open the highlighted path/URL

Commented out (available, not enabled):

- `tmux-plugins/tmux-cpu`, `tmux-plugins/tmux-continuum`,
  `27medkamal/tmux-session-wizard`, `tmux-plugins/tmux-sensible`,
  `tmux-plugins/tmux-yank`

`tmux_conf_uninstall_plugins_on_reload=true` means plugins that are removed from the
list above are uninstalled the next time the configuration is reloaded. That is
intended.

TPM keys (oh-my-tmux's integration, slightly different from upstream TPM):

| Keys | Action |
| --- | --- |
| `Prefix + I` | install plugins |
| `Prefix + u` | update plugins |
| `Prefix + Alt + u` | uninstall removed plugins |

### Bindings that actually exist here

| Binding | Action |
| --- | --- |
| `Prefix + -` | split top/bottom |
| `Prefix + _` | split left/right |
| `Prefix + H/J/K/L` | resize pane (repeatable) |
| `Prefix + r` | reload configuration |
| `Prefix + e` | edit `tmux.conf.local` |
| `Prefix + m` | toggle mouse mode (personal override) |
| `Prefix + +` | maximise/restore a pane |
| `Prefix + s` | tmux's built-in choose-tree |
| `Prefix + c` / `w` / `x` / `z` / `q` | new window, window list, kill pane, zoom, pane numbers |
| `Prefix + [` then `v` / `y` | copy mode: select, copy to the OS clipboard |

> Earlier versions of this README documented a `Prefix + =` split and a `dd` delete
> flow in `Prefix + s`. Neither exists in the tracked configuration, so they have been
> removed from this document rather than left as wishful thinking.

Personal settings from `tmux.conf.local`: mouse mode on, `history-limit 10000`,
copy-to-OS-clipboard enabled, and the dark theme colours.

## nvim

Based on [NvChad](https://nvchad.com/) v2.5. `nvim/init.lua` bootstraps
[lazy.nvim](https://github.com/folke/lazy.nvim), which installs and loads every
plugin, including `github/copilot.vim` declared in `nvim/lua/plugins/init.lua`. The
pinned versions live in `nvim/lazy-lock.json`.

Because lazy.nvim is the plugin manager, `nvim/pack/` is only a placeholder (kept by
`nvim/pack/.gitkeep`). If you do not have Neovim yet:

```bash
brew install nvim     # macOS
# or download from https://neovim.io/
```

First start installs the plugins; run `:Copilot setup` once to authenticate Copilot.

## git

`git/gitconfig` holds global settings. Private per-machine values live in
`git/gitconfig.local`, which `gitconfig` includes when it exists:

```ini
[include]
  path = ~/.gitconfig.local
```

`git/gitconfig.local` is gitignored and therefore absent from a fresh clone; Git
ignores a missing include path, so everything still works. Create it as shown in
[Install](#install).

One important note: if your email is written directly in config, it may expose your
address. [GitHub](https://github.com) can hide your email address — see
[this article](https://docs.github.com/en/account-and-profile/how-tos/email-preferences/setting-your-commit-email-address).
Enable `Keep my email addresses private` in GitHub to get a `noreply` address; CLI
Git will not use it automatically, but you can put it in `gitconfig.local` to avoid
exposing your real email.

`git/gitignore_global` holds global ignore rules (OS junk, editor files, build
output, `node_modules`, Python caches, Go binaries). Its path must match
`core.excludesFile` in `gitconfig`, which it does (`~/.gitignore_global`).

## Brewfile

It contains the [Homebrew](https://github.com/Homebrew/brew) packages installed via
`brew bundle`. **Inspect it with a text editor first and adjust it to your needs** —
it installs a lot of large casks. Then:

```bash
brew bundle --file=./Brewfile
```

`install.sh` runs the equivalent of `brew bundle --file=<repo>/Brewfile --no-upgrade`,
after asking for confirmation. It runs that step synchronously and before the shell
setup, because the tools it installs (`starship`, `zoxide`, `nvm`, `git`) are used by
the following steps.

### About the `appdir` parameter

`appdir` is a Homebrew Brewfile option that specifies where cask apps are installed.
By default, Homebrew installs apps into `/Applications`. This repo sets a global
default through `HOMEBREW_CASK_OPTS` in `zsh/zshrc.d/env.zsh`:

```zsh
export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications --require-sha"
```

Individual casks in the `Brewfile` also pass `args: { appdir: "~/Applications" }`.

#### Why do I use `appdir`?

On macOS, the first user account is always an administrator account. Administrator
accounts belong to the `admin` group and have sudo privileges. This means they can
effectively control the system, including privileged operations, which increases risk.

Tools like `sudo` can have [weaknesses](https://bogner.sh/2014/03/another-mac-os-x-sudo-password-bypass/)
that may be exploited by concurrently running programs.

[Apple](https://help.apple.com/machelp/mac/10.12/index.html#/mh11389) recommends this
best practice: use a separate standard account for daily work, and use an
administrator account only for installation and system configuration.

You don't have to log in through the macOS login screen as the admin account all the
time. When terminal commands require admin privileges, the system prompts for
authentication, then the terminal continues with those privileges. For this, Apple
provides guidance on hiding the admin account and its home directory
[here](https://support.apple.com/HT203998). It's an elegant approach to avoid having a
visible "ghost" account.

> Quoted from https://github.com/drduh/macOS-Security-and-Privacy-Guide
>
> [Chinese translation](https://github.com/genwilliam/macOS-Security-and-Privacy-Guide-cn)

## bin

`bin/` holds personal commands. Every **executable** file in it is linked into
`~/.local/bin`, which is on `PATH` via `.zprofile`, so `bin/local/adminrun` becomes
`adminrun`:

```bash
adminrun <command> [args...]   # run a command with macOS admin privileges
```

Non-executable files such as `bin/README.md` are skipped, so documentation never ends
up on `PATH`. To add a command:

```bash
chmod +x bin/my-tool
./install.sh --link-only      # or ./bootstrap.sh --fix
```

## macOS specifics

### `macos`

`macos` is a **single script** (not a directory). It applies system preference changes
with `defaults`, plus a few commands that need `sudo`. It is **not** run by `install.sh`,
because it changes system-wide state and typically needs a log out/in.

```bash
./macos --dry-run    # preview every command; changes nothing
./macos              # ask for confirmation, then apply
./macos --yes        # apply without asking (for example after a dry run)
```

What it changes:

- `defaults write` preferences: hot corners, tap-to-click, three-finger drag, keyboard
  UI mode, Finder path bar / search scope / extension warnings, menu bar clock, Mail
  attachments, Mission Control window grouping, screenshot, font and login-window keys
- `chflags hidden ~/Library` — hides your Library folder in Finder
- a `hidutil` CapsLock delay override (cleared again on the next reboot)
- flushes the DNS cache and switches the **application firewall on** (`sudo`)
- removes Google's software updater if it is installed — **this deletes files**
- restarts Finder, Dock and SystemUIServer (closes any open Finder windows)

`--dry-run` shadows `defaults`/`sudo`/`hidutil`/`chflags` with printers, so you can read
exactly what would happen without touching anything. Individual `defaults write`
failures are not fatal by design: the script applies the whole list rather than stopping
at the first key the current macOS version no longer supports. Read it first — it is a
personal list, not a supported configuration profile.

### `defaults`

See the [warning above](#a-warning-about-defaults). Reference material only.

### `macos_other.md`

Notes and snippets that are deliberately not automated (for example the Mail.app
index vacuum). Documentation only.

### `launchd`

`launchd/README.md` and `launchd/README-zh.md` explain launchd and provide reference
material. They are documentation — no `LaunchAgent`/`LaunchDaemon` plists are
installed by this repository. Never put secrets in a plist, and note that
`~/Library/LaunchAgents` files are readable only by you while most of those paths are
below `/Library/LaunchAgents` and need admin rights.

## Adding a new configuration file

1. Add the file to the repository, in the directory that matches its purpose.
2. Add it to the mapping table in `link_dotfiles()` in `install.sh`:

   ```bash
   link_dotfile "$DOTFILES/config/my-tool.toml" "$HOME/.config/my-tool.toml"
   ```

   Use the third argument `optional` if the source is machine-local and gitignored.
3. Document it in this README (the layout table above).
4. Verify:

   ```bash
   ./install.sh --dry-run      # the new file should be listed
   ./bootstrap.sh --no-warm    # it should verify
   ./tests/test-install.sh     # links and mappings are exercised
   ```

`bootstrap.sh` gets its expectations from `install.sh`, so as long as you add the
mapping, the verifier starts checking it immediately. Nothing else needs updating.

## Tests and CI

```bash
./tests/test-install.sh     # full suite: isolated temp HOME, no network
shellcheck --shell=bash --severity=style install.sh bootstrap.sh tests/test-install.sh
```

The test suite simulates a fresh clone (no gitignored files, no vendored plugins) and
checks: the mapping is well-formed and complete, a fresh install links everything
correctly, no documentation leaks into `~/.local/bin`, pre-existing files are backed up
with their content intact, a second run is a no-op, `--dry-run` changes nothing,
legacy `~/.tmux.conf` symlinks are migrated while foreign files are left alone, prompt
flavours switch cleanly, `bootstrap.sh` detects damage and repairs it, `--uninstall`
removes only repo-owned links, and a renamed source is reported as an error by both
scripts.

CI (`.github/workflows/ci.yml`) runs shellcheck, `bash -n`, `zsh -n`, the test suite,
and a real Linux install-and-verify — it needs no network and no Homebrew.

## Known limitations and risks

- **macOS-only parts are not covered by CI.** `install.sh`'s Homebrew, `chsh` and
  `~/.config/tmux` behaviour and the `macos` script are only exercised on macOS by
  hand. CI covers the linking logic on Linux.
- **`defaults` contains personal data** and is committed on purpose (see the warning
  above). It is not a credential, but it does describe this machine. Removing it from
  future commits does not remove it from Git history; that would need a history
  rewrite, which is intentionally not done here.
- **Linux support is partial and best-effort.** `zsh/zprofile` handles Linux paths and
  `install.sh` can use `apt-get`/`dnf`/`yum`/`pacman`/`zypper`/`apk`, but the `Brewfile`,
  the `macos` script, `launchd` and the pnpm/Homebrew paths are macOS-oriented.
- **`*.txt` is gitignored** in this repository on purpose. If you ever need to track a
  `.txt` file (for example `requirements.txt`), add an explicit `!path/to/file.txt`.
- `fzf-tab` is installed by nobody and enabled by nobody; the clone step was removed.
  Its keybindings were also removed from the p10k overlay, which previously referenced
  it while it was disabled.

## Credits

> As [Joshua Clayton said in a recent episode of The Changelog](http://thechangelog.com/post/17827235767/episode-0-7-3-tmux-with-brian-hogan-and-josh-clayton), if you're unhappy with your dotfiles, you're doing it wrong™. Pick and choose what you like from other people's dotfiles. Learn from everyone, follow no one. Build your own lightsaber. Rebuild it from scratch with confidence. Original: https://wynnnetherland.com/journal/dotfiles-discovery

If you don't know what dotfiles are, this [article](https://jogendra.dev/i-do-dotfiles) is helpful.

If you don't want to read it, here's a short explanation:

> **Dotfiles** are configuration files in **Unix-like systems** (such as macOS and Linux) whose names start with **`.`**.
> They are usually used to store **user-level application settings**.
>
> They are called _dotfiles_ because each filename starts with a **dot**.

> [!IMPORTANT]
>
> My shell setup is based on `zsh`. If you use another shell (such as bash or fish), this
> setup will not work as-is. [This repository](https://github.com/mathiasbynens/dotfiles)
> may help you.

## License

See [LICENSE](LICENSE).
