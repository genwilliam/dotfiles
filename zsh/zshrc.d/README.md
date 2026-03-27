[中文](README-zh.md) | English

# zshrc.d Module Boundary Conventions

To reduce maintenance overhead, the `zsh` config follows a single-responsibility layered structure:

- `zshenv`: universal shell (all zsh processes)
  - Minimal universal environment variables only (e.g. locale)
- `zprofile`: login shell
  - Login-time initialization and `PATH` ownership (e.g. `brew shellenv`)
- `zshrc`: interactive shell
  - Orchestrates load order and module sourcing

## Module Responsibilities in zshrc.d

- `env.zsh` (Pre-OMZ): Interactive env vars only (does not manage PATH)
- `plugins.zsh` (Pre-OMZ): Only defines `plugins=(...)`
- `aliases.zsh` (Post-OMZ): Aliases
- `completion.zsh` (Post-OMZ): Completion behavior and fzf integration
- `tools.zsh` (Post-OMZ): Tool initialization and runtime lazy-load hooks (lazy-load wherever possible)
- `local/*.zsh` (Post-OMZ): Machine-specific or local extensions

## Runtime Strategy

- `mise` is the primary runtime manager (via `~/.local/share/mise/shims`)
- `nvm` is an on-demand fallback, lazy-loaded on first invocation of `nvm/node/npm/npx`
- Avoid adding wrappers for `node/npm/npx` to minimize conflicts and hook overhead

## Performance Profiling

- Baseline: `/usr/bin/time -lp zsh -i -c exit`
- Per-module: `ZSH_STARTUP_PROFILE=1 zsh -i -c exit 2>&1 | grep '^zsh-startup'`

Note: optimization priority follows "lazy-load first > remove feature".

# What is the `local/` directory for?

`local/` holds machine-specific or experimental configuration.
Typical contents: corporate proxy settings, per-machine paths, temporary aliases, one-off debug flags.
`zshrc` auto-sources all `.zsh` files under this directory.
Avoid placing general-purpose config here — that would break the "repo as source of truth" principle.

# What belongs in each file

**zshenv**
✅ Put: the most fundamental environment needed by all zsh processes (`LANG`, locale).
❌ Don't put: aliases, plugins, prompt, any slow commands (heavy `eval` / external probing).

**zprofile**
✅ Put: one-time login-shell initialization (e.g. `brew shellenv`) and `PATH` composition.
❌ Don't put: interactive-experience config (completion, aliases, prompt, plugins).

**zshrc**
✅ Put: the interactive shell "load orchestrator" (module order, profile switch).
❌ Don't put: heavy business config — push those down into the zshrc.d modules.

**env.zsh**
✅ Put: interactive-shell-specific env vars.
❌ Don't put: PATH ownership (that lives in `zshenv` now).

**tools.zsh**
✅ Put: tool initialization and hooks (starship, optional mise activation, thefuck lazy-load, nvm lazy-load).
❌ Don't put: unrelated env vars, aliases, or completion rules.
