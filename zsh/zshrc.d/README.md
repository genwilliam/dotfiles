[中文](README-zh.md) | English

# zshrc.d Module Boundary Conventions

To reduce maintenance overhead, the `zsh` config follows a single-responsibility layered structure:

- `zshenv`: universal shell (all zsh processes)
  - Minimal universal environment variables only (e.g. locale)
  - Deliberately tiny: this file is read by scripts, `ssh`/`scp` and every
    non-interactive zsh, so nothing slow or interactive may live here
- `zprofile`: login shell
  - Login-time initialization and `PATH` ownership (e.g. `brew shellenv`)
- `zshrc`: interactive shell
  - Orchestrates load order and module sourcing

## Module Responsibilities in zshrc.d

Loaded before Oh My Zsh (`plugins.zsh` must be, because Oh My Zsh reads the
`plugins` array when it starts):

- `env.zsh`: interactive environment variables **and** the extra `PATH` entries for
  tools installed outside Homebrew (Rust, JDK, Maven)
- `env.local.zsh`: machine-specific overrides; gitignored and empty by default, so a
  fresh clone has none. Sourced when present, skipped when absent.
- `plugins.zsh`: only defines `plugins=(...)`

Loaded after Oh My Zsh:

- `aliases.zsh`: aliases
- `completion.zsh`: completion behaviour and `compinit`/`compdump` handling
- `tools.zsh`: tool initialization and runtime lazy-load hooks (lazy-load wherever
  possible)

There is no `local/` directory any more. Machine-local settings go in
`env.local.zsh` (see below).

## Runtime Strategy

- `nvm` provides the default Node installation. A fast `PATH` fallback prepends the
  default Node `bin` directory without loading `nvm.sh`, so `node` works immediately
  and startup stays cheap.
- `nvm` itself is lazy-loaded on the first invocation of the `nvm` function.
- That fast `PATH` fallback does not activate NVM and does not set `NVM_BIN`; use
  `nvm use` when you need a fully activated environment.
- `.nvmrc` switching is handled by an optional `chpwd` hook and can be disabled with
  `NVM_AUTO_USE=0`.
- The nearest parent `.nvmrc` applies to child directories; leaving a project does not
  restore `default`, so an explicit `nvm use` is never silently overwritten.
- A shell started inside a project applies `.nvmrc` once; ordinary directories still
  avoid loading `nvm.sh`.
- A repeated failed `.nvmrc` lookup is suppressed until the file changes; retry
  explicitly with `nvm use` after installing a version.
- Avoid adding wrappers for `node/npm/npx` to minimize conflicts and hook overhead.
- `mise` is activated lazily: the first `mise` invocation runs `mise activate zsh`.
  Note that `~/.local/share/mise/shims` is **not** on `PATH`, so mise does not shadow
  the nvm-managed Node. If you want mise to own runtimes globally, activate it eagerly
  in `env.local.zsh` and put the shims directory on `PATH` — but do that deliberately,
  because it changes which `node`/`python` win.

## Performance Profiling

- Baseline: `/usr/bin/time -lp zsh -i -c exit`
- Per-module: `ZSH_STARTUP_PROFILE=1 zsh -i -c exit 2>&1 | grep '^zsh-startup'`

Each sourced module then prints one `zsh-startup <ms> <module>` line on stderr. The
timing code sits behind a single variable check, so there is no overhead when the
variable is unset.

Note: optimization priority follows "lazy-load first > remove feature".

# What is `env.local.zsh` for?

`env.local.zsh` holds machine-specific or experimental configuration for interactive
shells. Typical contents: corporate proxy settings, per-machine paths, temporary
aliases, one-off debug flags, secrets that must not be committed.

It is gitignored (`*.local.*` in `.gitignore`) and it is sourced by `~/.zshrc` between
`env.zsh` and `plugins.zsh`, so it can override anything `env.zsh` set and can still
extend the `plugins` array.

Avoid placing general-purpose config here — that would break the "repo as source of
truth" principle. If a setting should exist on every machine, it belongs in a tracked
file.

# What belongs in each file

**zshenv**
✅ Put: the most fundamental environment needed by all zsh processes (`LANG`, locale).
❌ Don't put: aliases, plugins, prompt, `PATH` composition, any slow commands (heavy `eval` / external probing).

**zprofile**
✅ Put: one-time login-shell initialization (e.g. `brew shellenv`) and `PATH` composition.
❌ Don't put: interactive-experience config (completion, aliases, prompt, plugins).

**zshrc**
✅ Put: the interactive shell "load orchestrator" (module order, prompt flavour switch).
❌ Don't put: `PATH` entries (that is `zprofile`'s job) or heavy business config — push those down into the zshrc.d modules.

**env.zsh**
✅ Put: interactive-shell-specific env vars, plus `PATH` entries for tools that Homebrew does not link (Rust, JDK, Maven). Use the zsh `path=(...)` array and guard every entry with an existence check so the file stays portable.
❌ Don't put: the baseline `PATH` (that lives in `zprofile`), aliases, or completion rules.

**tools.zsh**
✅ Put: tool initialization and hooks (starship, lazy `thefuck`, lazy `nvm`, lazy `mise`).
❌ Don't put: unrelated env vars, aliases, or completion rules.
