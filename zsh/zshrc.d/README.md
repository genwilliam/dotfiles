[中文](README-zh.md) | English

# zshrc.d Module Boundary Conventions

To reduce maintenance overhead, the `zsh` config follows a single-responsibility layered structure:

- `zshenv`: universal shell (all zsh processes)
  - The sole authority for `PATH`
  - Basic locale and other universal environment variables
- `zprofile`: login shell
  - Login-time initialization (e.g. `brew shellenv`)
- `zshrc`: interactive shell
  - Orchestrates load order and module sourcing

## Module Responsibilities in zshrc.d

- `env.zsh` (Pre-OMZ): Interactive env vars and runtime strategy (does not manage PATH)
- `plugins.zsh` (Pre-OMZ): Only defines `plugins=(...)`
- `aliases.zsh` (Post-OMZ): Aliases
- `completion.zsh` (Post-OMZ): Completion and fzf-tab behavior
- `tools.zsh` (Post-OMZ): Tool initialization (lazy-load wherever possible)
- `local/*.zsh` (Post-OMZ): Machine-specific or local extensions

## Runtime Strategy

- `mise` is the primary runtime manager (via `~/.local/share/mise/shims`)
- `nvm` is an on-demand fallback, lazy-loaded only on the first invocation of `nvm`
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
✅ Put: the most fundamental environment needed by all zsh processes (primary PATH, `LANG`, locale).
❌ Don't put: aliases, plugins, prompt, any slow commands (heavy `eval` / external probing).

**zprofile**
✅ Put: one-time login-shell initialization (e.g. `brew shellenv`).
❌ Don't put: interactive-experience config (completion, aliases, prompt, plugins).

**zshrc**
✅ Put: the interactive shell "load orchestrator" (module order, profile switch).
❌ Don't put: heavy business config — push those down into the zshrc.d modules.

**env.zsh**
✅ Put: interactive-shell-specific env vars and runtime strategy (nvm lazy loading).
❌ Don't put: PATH ownership (that lives in `zshenv` now).

**tools.zsh**
✅ Put: tool initialization and hooks (starship, optional mise activation, thefuck lazy-load).
❌ Don't put: unrelated env vars, aliases, or completion rules.
