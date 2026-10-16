#!/usr/bin/env bash
#
# install.sh -- install the configuration files in this repository.
#
# Supported platforms:
#   * macOS  -- full support (Homebrew, Brewfile, zsh, dotfiles, tmux, nvim)
#   * Linux  -- dotfiles + zsh only; Homebrew/Brewfile/macOS steps are skipped
#   * Windows/WSL -- not supported; link the files manually (see README.md)
#
# Requirements: bash >= 3.2 (the version shipped with macOS), zsh >= 5.0, git.
#
# How the mapping works:
#   `link_dotfiles` below is the single source of truth for what gets installed
#   and where. Every entry maps one repository path to one absolute target.
#   When you add a new configuration file, add it there and document it in
#   README.md; `./bootstrap.sh` verifies that every mapping is in place.
#
# Safety:
#   * Linking is idempotent. A correct symlink is left untouched.
#   * Any pre-existing regular file or directory at a target path is moved to
#     "<target>.bak.<timestamp>" before the symlink is created, never deleted.
#   * Nothing in this script runs `sudo` except `chsh`/`/etc/shells` handling,
#     which is reported when it cannot be done automatically.
#   * Failures of a step are collected and reported at the end instead of
#     silently aborting the remaining, independent steps.

set -Eeuo pipefail
IFS=$'\n\t'

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$DOTFILES/Brewfile"
OS_TYPE="$(uname -s)"

REMOVE_READMES=0
ASSUME_YES=0
DRY_RUN=0
LINK_ONLY=0
MAP_ONLY=0
UNINSTALL=0
PROMPT_FORCED=0
PROMPT_FLAVOR="starship"
LINUX_PKG_MANAGER=""

COUNT_LINKED=0
COUNT_UNCHANGED=0
COUNT_BACKED_UP=0
COUNT_SKIPPED=0
COUNT_REMOVED=0
declare -a STEP_FAILURES=()

# ---------------------------------------------------------------------------
# platform helpers
# ---------------------------------------------------------------------------

is_windows() {
  [[ "${OS:-}" == "Windows_NT" ]] || [[ "$OS_TYPE" =~ ^(MINGW|MSYS|CYGWIN) ]]
}

is_macos() {
  [[ "$OS_TYPE" == "Darwin" ]]
}

is_linux() {
  [[ "$OS_TYPE" == "Linux" ]]
}

get_linux_pkg_manager() {
  if [[ -n "$LINUX_PKG_MANAGER" ]]; then
    printf '%s' "$LINUX_PKG_MANAGER"
    return 0
  fi

  local manager
  for manager in apt-get dnf yum pacman zypper apk; do
    if command -v "$manager" >/dev/null 2>&1; then
      LINUX_PKG_MANAGER="$manager"
      printf '%s' "$manager"
      return 0
    fi
  done

  return 1
}

run_with_sudo() {
  if command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    "$@"
  fi
}

linux_install_pkg() {
  local pkg="$1"
  local manager
  manager="$(get_linux_pkg_manager)" || {
    printf '\n==> ERROR: Linux detected, but no supported package manager (apt-get/dnf/yum/pacman/zypper/apk) was found\n' >&2
    return 1
  }

  log "Installing '$pkg' via $manager"
  case "$manager" in
    apt-get)
      run_with_sudo apt-get update || return 1
      run_with_sudo apt-get install -y "$pkg"
      ;;
    dnf)    run_with_sudo dnf install -y "$pkg" ;;
    yum)    run_with_sudo yum install -y "$pkg" ;;
    pacman) run_with_sudo pacman -S --noconfirm "$pkg" ;;
    zypper) run_with_sudo zypper --non-interactive install "$pkg" ;;
    apk)    run_with_sudo apk add "$pkg" ;;
    *)
      printf '\n==> ERROR: unsupported package manager: %s\n' "$manager" >&2
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# output helpers
# ---------------------------------------------------------------------------

# Human-readable progress goes to stderr; stdout is reserved for
# machine-readable output (--print-map, consumed by bootstrap.sh).
log() {
  printf '\n==> %s\n' "$1" >&2
}

# Fatal, unrecoverable problem: stop right now.
error() {
  printf '\n==> ERROR: %s\n' "$1" >&2
  exit 1
}

# Non-fatal problem: remember it, keep going, report at the end.
record_failure() {
  STEP_FAILURES+=("$1")
  printf '    [FAILED] %s\n' "$1" >&2
}

# Run a step, record a clean failure message if it returns non-zero, continue.
attempt() {
  local name="$1"
  shift

  if "$@"; then
    return 0
  fi

  record_failure "$name"
  return 0
}

# Print a command instead of running it, when --dry-run is active.
# Note: "$*" cannot be used here, because IFS is set to newline/tab above.
run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    local arg
    printf '    [dry-run] would run:' >&2
    for arg in "$@"; do
      printf ' %s' "$arg" >&2
    done
    printf '\n' >&2
    return 0
  fi

  "$@"
}

confirm_step() {
  local message="$1"
  local confirm=""

  if [[ "$ASSUME_YES" -eq 1 ]] || [[ ! -t 0 ]]; then
    return 0
  fi

  printf '%s [y/N]: ' "$message"
  read -r confirm || true

  [[ "$confirm" =~ ^[Yy]$ ]]
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf '\n==> ERROR: required command not found: %s\n' "$1" >&2
    return 1
  fi
  return 0
}

on_err() {
  local exit_code=$?
  printf '\n==> UNEXPECTED ERROR (exit %d) at %s line %d: %s\n' \
    "$exit_code" "${BASH_SOURCE[0]}" "${BASH_LINENO[0]}" "$BASH_COMMAND" >&2
}

on_exit() {
  local exit_code=$?

  if [[ "$MAP_ONLY" -eq 1 ]]; then
    return 0
  fi

  printf '\n==> Result\n' >&2

  if [[ "$UNINSTALL" -eq 1 ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf '    would remove    : %d symlink(s) owned by this repository\n' "$COUNT_REMOVED" >&2
    else
      printf '    removed         : %d symlink(s) owned by this repository\n' "$COUNT_REMOVED" >&2
    fi
    if [[ "$COUNT_SKIPPED" -gt 0 ]]; then
      printf '    left alone      : %d (not linked to this repository)\n' "$COUNT_SKIPPED" >&2
    fi
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    printf '    would link      : %d\n' "$COUNT_LINKED" >&2
    printf '    already correct : %d\n' "$COUNT_UNCHANGED" >&2
    printf '    would skip      : %d\n' "$COUNT_SKIPPED" >&2
    if [[ "$COUNT_BACKED_UP" -gt 0 ]]; then
      printf '    would back up   : %d (would be moved to *.bak.*)\n' "$COUNT_BACKED_UP" >&2
    fi
    if [[ "$COUNT_REMOVED" -gt 0 ]]; then
      printf '    would remove    : %d stale symlink(s) owned by this repository\n' "$COUNT_REMOVED" >&2
    fi
  else
    printf '    linked          : %d\n' "$COUNT_LINKED" >&2
    printf '    already correct : %d\n' "$COUNT_UNCHANGED" >&2
    printf '    skipped         : %d\n' "$COUNT_SKIPPED" >&2
    if [[ "$COUNT_BACKED_UP" -gt 0 ]]; then
      printf '    backed up       : %d (look for *.bak.* next to the target path)\n' "$COUNT_BACKED_UP" >&2
    fi
    if [[ "$COUNT_REMOVED" -gt 0 ]]; then
      printf '    removed         : %d stale symlink(s) owned by this repository\n' "$COUNT_REMOVED" >&2
    fi
  fi

  if [[ "${#STEP_FAILURES[@]}" -gt 0 ]]; then
    printf '    failed steps    : %d\n' "${#STEP_FAILURES[@]}" >&2
    local step
    for step in "${STEP_FAILURES[@]}"; do
      printf '        - %s\n' "$step" >&2
    done
  fi

  if [[ "$exit_code" -ne 0 ]]; then
    printf '\n==> Installation did not finish successfully (exit %d).\n' "$exit_code" >&2
    printf '    Re-run the same command after fixing the reported problem.\n' >&2
  fi
}

# ---------------------------------------------------------------------------
# shell environment
# ---------------------------------------------------------------------------

# Keep Homebrew available in the current shell (the script's own PATH is not
# affected by ~/.zprofile yet).
eval_homebrew_shellenv() {
  local brew_bin

  if command -v brew >/dev/null 2>&1; then
    brew_bin="$(command -v brew)"
    eval "$("$brew_bin" shellenv)"
    return 0
  fi

  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$candidate" ]]; then
      eval "$("$candidate" shellenv)"
      return 0
    fi
  done

  return 1
}

# ---------------------------------------------------------------------------
# Homebrew / Brewfile
# ---------------------------------------------------------------------------

install_homebrew() {
  if ! is_macos; then
    log "Not macOS; skipping Homebrew"
    return 0
  fi

  if eval_homebrew_shellenv; then
    log "Homebrew already installed: $(command -v brew)"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '    [dry-run] would download and run the official Homebrew installer\n' >&2
    return 0
  fi

  require_cmd curl || return 1
  log "Installing Homebrew (downloads and runs the official installer script)"
  printf '    source: https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh\n' >&2

  local installer
  if ! installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    printf '\n==> ERROR: could not download the Homebrew installer (network or curl problem)\n' >&2
    return 1
  fi

  if ! /bin/bash -c "$installer"; then
    printf '\n==> ERROR: the Homebrew installer exited with a non-zero status\n' >&2
    return 1
  fi

  if ! eval_homebrew_shellenv; then
    printf '\n==> ERROR: Homebrew installed but could not be initialised; open a new shell and re-run\n' >&2
    return 1
  fi

  log "Homebrew installed: $(command -v brew)"
}

install_brew_packages() {
  if ! is_macos; then
    log "Not macOS; skipping Brewfile"
    return 0
  fi

  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew is not available; skipping Brewfile (install Homebrew, then re-run)"
    return 0
  fi

  if [[ ! -f "$BREWFILE" ]]; then
    log "No Brewfile found at $BREWFILE; skipping"
    return 0
  fi

  log "Installing Homebrew packages from $BREWFILE (this is the slow step)"
  printf '    review and trim %s before running this for the first time\n' "$BREWFILE" >&2
  run_cmd brew bundle --file="$BREWFILE" --no-upgrade
}

# ---------------------------------------------------------------------------
# zsh + Oh My Zsh + plugins
# ---------------------------------------------------------------------------

install_oh_my_zsh() {
  local oh_my_zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"

  if [[ -d "$oh_my_zsh_dir" ]]; then
    log "Oh My Zsh already installed at $oh_my_zsh_dir"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '    [dry-run] would install Oh My Zsh into %s\n' "$oh_my_zsh_dir" >&2
    return 0
  fi

  require_cmd curl || return 1
  log "Installing Oh My Zsh (RUNZSH=no CHSH=no KEEP_ZSHRC=yes)"

  local installer
  if ! installer="$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
    printf '\n==> ERROR: could not download the Oh My Zsh installer\n' >&2
    return 1
  fi

  if ! RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$installer"; then
    printf '\n==> ERROR: the Oh My Zsh installer exited with a non-zero status\n' >&2
    return 1
  fi

  if [[ ! -d "$oh_my_zsh_dir" ]]; then
    printf '\n==> ERROR: Oh My Zsh installer finished but %s is missing\n' "$oh_my_zsh_dir" >&2
    return 1
  fi
}

clone_or_update_repo() {
  local repo_url="$1"
  local dest="$2"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '    [dry-run] would clone/update %s -> %s\n' "$repo_url" "$dest" >&2
    return 0
  fi

  require_cmd git || return 1

  if [[ -d "$dest/.git" ]]; then
    if [[ -n "$(git -C "$dest" status --porcelain)" ]]; then
      log "Local changes in $dest; leaving it untouched"
      return 0
    fi

    log "Updating $(basename "$dest")"
    if ! git -C "$dest" pull --ff-only --quiet; then
      log "Could not fast-forward $dest; keeping the current checkout"
    fi
    return 0
  fi

  if [[ -e "$dest" ]]; then
    log "SKIP: $dest exists but is not a git checkout"
    COUNT_SKIPPED=$(( COUNT_SKIPPED + 1 ))
    return 0
  fi

  log "Cloning $(basename "$dest")"
  git clone --depth=1 -- "$repo_url" "$dest"
}

# The plugin list in zsh/zshrc.d/plugins.zsh is the source of truth. Only the
# plugins that are NOT bundled with Oh My Zsh have to be cloned here.
install_zsh_plugins() {
  local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
  local custom_dir="${ZSH_CUSTOM:-$zsh_dir/custom}"

  log "Installing external zsh plugins into $custom_dir/plugins"

  if [[ "$DRY_RUN" -ne 1 ]]; then
    mkdir -p -- "$custom_dir/plugins" "$custom_dir/themes"
  fi

  if ! command -v git >/dev/null 2>&1; then
    log "git is missing; it is required to clone zsh plugins"
    if is_macos; then
      attempt "install git via Homebrew" run_cmd brew install git
    elif is_linux; then
      attempt "install git via the system package manager" linux_install_pkg git
    fi
    require_cmd git || return 1
  fi

  clone_or_update_repo \
    "https://github.com/zsh-users/zsh-autosuggestions.git" \
    "$custom_dir/plugins/zsh-autosuggestions"
  clone_or_update_repo \
    "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" \
    "$custom_dir/plugins/fast-syntax-highlighting"
  clone_or_update_repo \
    "https://github.com/MichaelAquilina/zsh-you-should-use.git" \
    "$custom_dir/plugins/you-should-use"

  if [[ "$PROMPT_FLAVOR" == "p10k" ]]; then
    clone_or_update_repo \
      "https://github.com/romkatv/powerlevel10k.git" \
      "$custom_dir/themes/powerlevel10k"
  fi
}

install_zsh_unix() {
  if is_macos; then
    if ! command -v brew >/dev/null 2>&1; then
      printf '\n==> ERROR: Homebrew is required to install zsh on macOS; install Homebrew first\n' >&2
      return 1
    fi
    log "Installing zsh via Homebrew"
    run_cmd brew install zsh
    return $?
  fi

  if is_linux; then
    linux_install_pkg zsh
    return $?
  fi

  printf '\n==> ERROR: cannot install zsh automatically on %s\n' "$OS_TYPE" >&2
  return 1
}

ensure_zsh_installed() {
  if command -v zsh >/dev/null 2>&1; then
    log "zsh already available: $(command -v zsh) ($(zsh --version))"
    return 0
  fi

  install_zsh_unix || return 1

  if ! command -v zsh >/dev/null 2>&1; then
    printf '\n==> ERROR: the zsh installation step finished, but zsh is still not in PATH\n' >&2
    return 1
  fi
  return 0
}

set_default_shell_to_zsh() {
  local current_shell="${SHELL:-}"
  local current_shell_name zsh_path

  current_shell_name="$(basename "$current_shell")"
  log "Current login shell: ${current_shell:-unknown}"

  if [[ "$current_shell_name" == "zsh" ]]; then
    log "Login shell is already zsh"
    return 0
  fi

  if ! command -v zsh >/dev/null 2>&1; then
    printf '\n==> ERROR: zsh is not installed; cannot change the login shell\n' >&2
    return 1
  fi

  zsh_path="$(command -v zsh)"

  if ! command -v chsh >/dev/null 2>&1; then
    log "chsh not found; set the login shell manually: chsh -s $zsh_path"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '    [dry-run] would register %s in /etc/shells (if missing) and run chsh -s %s\n' "$zsh_path" "$zsh_path" >&2
    return 0
  fi

  # macOS requires the shell to be listed in /etc/shells before chsh accepts it.
  if [[ -f /etc/shells ]] && ! grep -qx -- "$zsh_path" /etc/shells; then
    log "$zsh_path is not listed in /etc/shells; adding it (needs sudo)"
    if ! run_with_sudo tee -a /etc/shells >/dev/null <<< "$zsh_path"; then
      log "Could not update /etc/shells. Add this line manually, then re-run: $zsh_path"
      return 0
    fi
  fi

  if [[ ! -t 0 ]]; then
    log "Not an interactive terminal; skipping 'chsh' (it needs a password). Run manually: chsh -s $zsh_path"
    return 0
  fi

  if chsh -s "$zsh_path"; then
    log "Login shell changed to $zsh_path"
  else
    log "chsh failed. Run it manually: chsh -s $zsh_path"
  fi
  return 0
}

ensure_zsh_as_default_shell() {
  log "Ensuring zsh is installed and set as the login shell"
  ensure_zsh_installed || return 1
  set_default_shell_to_zsh
}

# ---------------------------------------------------------------------------
# symlink helpers
# ---------------------------------------------------------------------------

# Print the target of a symlink with trailing slashes removed, so that
# ".../nvim/" and ".../nvim" compare equal. Prints nothing for non-symlinks.
#
# `readlink` is only called for real symlinks and its failure is neutralised
# with `|| true`: under `set -E` the ERR trap is inherited by the command
# substitution subshell, so a bare `$(readlink ...)` on a missing path trips
# the trap even though the assignment itself sits in a `||` list.
normalize_link_target() {
  local target

  if [[ ! -L "$1" ]]; then
    return 0
  fi

  target="$(readlink "$1" 2>/dev/null || true)"

  while [[ "$target" == */ && "$target" != "/" ]]; do
    target="${target%/}"
  done

  printf '%s' "$target"
}

# Build an unused "<path>.bak.<timestamp>" name; never overwrites an existing
# backup.
make_backup_path() {
  local dest="$1"
  local stamp candidate n

  stamp="$(date +%Y%m%d%H%M%S)"
  candidate="${dest}.bak.${stamp}"
  n=1

  while [[ -e "$candidate" || -L "$candidate" ]]; do
    candidate="${dest}.bak.${stamp}.${n}"
    n=$(( n + 1 ))
  done

  printf '%s' "$candidate"
}

# Point $dest at $src. Idempotent; backs up (never deletes) anything else that
# already occupies $dest.
#
# $3 may be "optional": the mapping is still reported by --print-map, but a
# missing source is expected (machine-local files that are gitignored) rather
# than an error. A missing *required* source means this script references a
# file that was renamed or deleted, and is reported as a failure.
link_dotfile() {
  local src="$1"
  local dest="$2"
  local mode="${3:-required}"
  local current backup dest_dir

  # --print-map: emit "src<TAB>dest<TAB>mode" on stdout and touch nothing. The
  # mapping is printed before the existence check on purpose, so bootstrap.sh
  # can detect a mapping whose source file was renamed or deleted.
  if [[ "$MAP_ONLY" -eq 1 ]]; then
    printf '%s\t%s\t%s\n' "$src" "$dest" "$mode"
    return 0
  fi

  # --uninstall: remove the link only if it is ours. A target that is a real
  # file (or points somewhere else) is never touched, so this cannot destroy
  # user data.
  if [[ "$UNINSTALL" -eq 1 ]]; then
    if [[ ! -L "$dest" ]]; then
      return 0
    fi

    current="$(normalize_link_target "$dest")"
    if [[ "$current" != "$src" ]]; then
      log "SKIP (not linked to this repository): $dest"
      COUNT_SKIPPED=$(( COUNT_SKIPPED + 1 ))
      return 0
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf '    [dry-run] would remove %s\n' "$dest" >&2
      COUNT_REMOVED=$(( COUNT_REMOVED + 1 ))
      return 0
    fi

    if rm -f -- "$dest"; then
      log "Removed $dest"
      COUNT_REMOVED=$(( COUNT_REMOVED + 1 ))
    else
      record_failure "remove $dest"
    fi
    return 0
  fi

  if [[ ! -e "$src" && ! -L "$src" ]]; then
    if [[ "$mode" == "optional" ]]; then
      log "SKIP (optional file, not present): ${src#"$DOTFILES"/} -- see README.md"
      COUNT_SKIPPED=$(( COUNT_SKIPPED + 1 ))
    else
      record_failure "install.sh maps a source that does not exist: ${src#"$DOTFILES"/}"
    fi
    return 0
  fi

  current="$(normalize_link_target "$dest")"
  if [[ -n "$current" && "$current" == "$src" ]]; then
    COUNT_UNCHANGED=$(( COUNT_UNCHANGED + 1 ))
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ -e "$dest" && ! -L "$dest" ]]; then
      printf '    [dry-run] would back up %s, then link it to %s\n' "$dest" "$src" >&2
      COUNT_BACKED_UP=$(( COUNT_BACKED_UP + 1 ))
    else
      printf '    [dry-run] would link %s -> %s\n' "$dest" "$src" >&2
    fi
    COUNT_LINKED=$(( COUNT_LINKED + 1 ))
    return 0
  fi

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    backup="$(make_backup_path "$dest")"
    log "Backing up existing $dest -> $backup"
    if ! mv -- "$dest" "$backup"; then
      record_failure "back up $dest"
      return 1
    fi
    COUNT_BACKED_UP=$(( COUNT_BACKED_UP + 1 ))
  fi

  dest_dir="$(dirname -- "$dest")"
  if [[ ! -d "$dest_dir" ]] && ! mkdir -p -- "$dest_dir"; then
    record_failure "create directory $dest_dir"
    return 1
  fi

  if ln -sfn -- "$src" "$dest"; then
    log "Linked $dest -> $src"
    COUNT_LINKED=$(( COUNT_LINKED + 1 ))
    return 0
  fi

  record_failure "link $dest -> $src"
  return 1
}

# Earlier versions of install.sh linked tmux/tmux.conf to ~/.tmux.conf. tmux
# prefers ~/.tmux.conf over ~/.config/tmux/tmux.conf, which would silently keep
# the old layout (and drop the tmux.conf.local overrides). Remove only symlinks
# that point back into this repository; anything else is reported and kept.
cleanup_legacy_tmux_links() {
  local legacy target

  # Not a mapping: nothing to report in --print-map mode.
  if [[ "$MAP_ONLY" -eq 1 ]]; then
    return 0
  fi

  for legacy in "$HOME/.tmux.conf" "$HOME/.tmux.conf.local"; do
    if [[ ! -L "$legacy" ]]; then
      continue
    fi

    target="$(readlink "$legacy" 2>/dev/null || true)"
    case "$target" in
      "$DOTFILES"/*)
        if [[ "$DRY_RUN" -eq 1 ]]; then
          printf '    [dry-run] would remove legacy symlink %s -> %s\n' "$legacy" "$target" >&2
        else
          if rm -f -- "$legacy"; then
            log "Removed legacy symlink $legacy (tmux now uses ~/.config/tmux)"
            COUNT_REMOVED=$(( COUNT_REMOVED + 1 ))
          else
            record_failure "remove legacy symlink $legacy"
          fi
        fi
        ;;
      *)
        log "NOTE: $legacy is a symlink to $target (not managed by this repo); leaving it as is"
        ;;
    esac
  done
}

# Switching prompt flavour must not leave the other flavour's config behind: a
# leftover ~/.p10k.zsh (or ~/.config/starship.toml) makes it ambiguous which
# prompt is active, and bootstrap.sh correctly reports it as a stale link.
# Only symlinks pointing back into this repository are removed.
cleanup_other_flavor_links() {
  local stale target

  if [[ "$MAP_ONLY" -eq 1 ]]; then
    return 0
  fi

  if [[ "$PROMPT_FLAVOR" == "p10k" ]]; then
    stale="$HOME/.config/starship.toml"
  else
    stale="$HOME/.p10k.zsh"
  fi

  if [[ ! -L "$stale" ]]; then
    return 0
  fi

  target="$(readlink "$stale" 2>/dev/null || true)"

  case "$target" in
    "$DOTFILES"/*)
      if [[ "$DRY_RUN" -eq 1 ]]; then
        printf '    [dry-run] would remove %s (belongs to the other prompt flavour)\n' "$stale" >&2
      elif rm -f -- "$stale"; then
        log "Removed $stale (belongs to the other prompt flavour)"
        COUNT_REMOVED=$(( COUNT_REMOVED + 1 ))
      else
        record_failure "remove $stale"
      fi
      ;;
    *)
      log "NOTE: $stale is a symlink to $target (not managed by this repo); leaving it as is"
      ;;
  esac

  return 0
}

# Every executable file under bin/ becomes a command in ~/.local/bin.
# Files that are not executable (for example the READMEs) are skipped, so
# ~/.local/bin never receives documentation.
link_bin_scripts() {
  local script name

  if [[ ! -d "$DOTFILES/bin" ]]; then
    log "No bin/ directory; skipping"
    return 0
  fi

  if [[ "$MAP_ONLY" -eq 1 || "$UNINSTALL" -eq 1 ]]; then
    : # link_dotfile handles printing (map mode) or removal (uninstall mode)
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    printf '    [dry-run] would link the executable files under %s into %s\n' \
      "$DOTFILES/bin" "$HOME/.local/bin" >&2
  elif ! mkdir -p -- "$HOME/.local/bin"; then
    record_failure "create $HOME/.local/bin"
    return 1
  fi

  while IFS= read -r -d '' script; do
    case "$script" in
      *.md) continue ;;
    esac

    if [[ ! -x "$script" ]]; then
      name="${script##*/}"
      log "SKIP (not executable): bin/$name"
      COUNT_SKIPPED=$(( COUNT_SKIPPED + 1 ))
      continue
    fi

    name="${script##*/}"
    link_dotfile "$script" "$HOME/.local/bin/$name"
  done < <(find "$DOTFILES/bin" -type f -print0)

  return 0
}

# ---------------------------------------------------------------------------
# the mapping table (single source of truth)
# ---------------------------------------------------------------------------

link_dotfiles() {
  log "Linking configuration files into $HOME"

  # --- git ---------------------------------------------------------------
  link_dotfile "$DOTFILES/git/gitconfig"          "$HOME/.gitconfig"
  link_dotfile "$DOTFILES/git/gitignore_global"   "$HOME/.gitignore_global"
  # Machine-local identity (name/email). Gitignored, so on a fresh clone it does
  # not exist and is skipped; create it yourself and re-run to link it.
  link_dotfile "$DOTFILES/git/gitconfig.local"    "$HOME/.gitconfig.local" optional

  # --- editor ------------------------------------------------------------
  link_dotfile "$DOTFILES/editorconfig"           "$HOME/.editorconfig"

  # --- zsh ---------------------------------------------------------------
  link_dotfile "$DOTFILES/zsh/zshenv"             "$HOME/.zshenv"
  link_dotfile "$DOTFILES/zsh/zprofile"           "$HOME/.zprofile"
  link_dotfile "$DOTFILES/zsh/zlogin"             "$HOME/.zlogin"
  link_dotfile "$DOTFILES/zsh/zlogout"            "$HOME/.zlogout"
  # Shared modules; both prompt flavours use this directory.
  link_dotfile "$DOTFILES/zsh/zshrc.d"            "$HOME/.zshrc.d"

  # --- prompt flavour ----------------------------------------------------
  cleanup_other_flavor_links
  if [[ "$PROMPT_FLAVOR" == "p10k" ]]; then
    link_dotfile "$DOTFILES/p10k/zshrc"           "$HOME/.zshrc"
    link_dotfile "$DOTFILES/p10k/p10k.zsh"        "$HOME/.p10k.zsh"
  else
    link_dotfile "$DOTFILES/zsh/zshrc"            "$HOME/.zshrc"
    link_dotfile "$DOTFILES/config/starship.toml" "$HOME/.config/starship.toml"
  fi

  # --- tmux --------------------------------------------------------------
  # XDG layout. tmux >= 3.1 reads ~/.config/tmux/tmux.conf, and oh-my-tmux
  # derives its plugin directory (~/.config/tmux/plugins) from that path, so
  # the whole tmux/ directory is linked as one unit.
  cleanup_legacy_tmux_links
  link_dotfile "$DOTFILES/tmux"                   "$HOME/.config/tmux"

  # --- other tool configs ------------------------------------------------
  link_dotfile "$DOTFILES/config/thefuck"         "$HOME/.config/thefuck"
  link_dotfile "$DOTFILES/config/aria2"           "$HOME/.config/aria2"

  # --- neovim ------------------------------------------------------------
  link_dotfile "$DOTFILES/nvim"                   "$HOME/.config/nvim"

  # --- personal commands -------------------------------------------------
  link_bin_scripts

  return 0
}

# ---------------------------------------------------------------------------
# optional cleanup
# ---------------------------------------------------------------------------

remove_readmes() {
  local file
  local found=0

  log "Removing README* files from $HOME"

  shopt -s nullglob
  for file in "$HOME"/README*; do
    if [[ ! -e "$file" || -d "$file" ]]; then
      continue
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf '    [dry-run] would remove %s\n' "$file" >&2
      found=1
      continue
    fi

    if rm -f -- "$file"; then
      log "Removed $file"
      found=1
    else
      record_failure "remove $file"
    fi
  done
  shopt -u nullglob

  if [[ "$found" -eq 0 ]]; then
    log "No README* files found in $HOME"
  fi

  return 0
}

# ---------------------------------------------------------------------------
# interactive choices and final output
# ---------------------------------------------------------------------------

choose_prompt_flavor() {
  local choice=""

  if [[ "$PROMPT_FORCED" -eq 1 || ! -t 0 ]]; then
    log "Prompt flavour: $PROMPT_FLAVOR"
    return 0
  fi

  printf 'Choose prompt flavour -- Y = starship (default), n = powerlevel10k [Y/n]: ' >&2
  read -r choice || true

  case "$choice" in
    [Nn]) PROMPT_FLAVOR="p10k" ;;
    *)    PROMPT_FLAVOR="starship" ;;
  esac

  log "Prompt flavour: $PROMPT_FLAVOR"
}

print_next_steps() {
  log "Next steps"
  cat <<'EOF'
  1) Open a new terminal, or run: source ~/.zshrc
  2) Verify the installation: ./bootstrap.sh
EOF

  if [[ "$PROMPT_FLAVOR" == "p10k" ]]; then
    cat <<'EOF'
  3) powerlevel10k: run `p10k configure` if you want to regenerate ~/.p10k.zsh
EOF
  fi

  cat <<'EOF'

Meslo Nerd Font (recommended for both prompt flavours) and other manual steps
are documented in README.md. Note that this script does not run:

  * ./macos          -- changes system-wide preferences (needs sudo, log out/in)
  * ./defaults       -- a read-only backup of your machine's defaults, not a script
EOF

  if is_macos; then
    cat <<'EOF'

macOS:
  - Install the font with Homebrew (also listed in the Brewfile):
      brew install --cask font-meslo-lg-nerd-font
EOF
    return 0
  fi

  if is_linux; then
    local linux_manager
    linux_manager="$(get_linux_pkg_manager || true)"
    printf '\nLinux (detected package manager: %s):\n' "${linux_manager:-unknown}"
    case "${linux_manager:-}" in
      apt-get)
        printf '  - sudo apt-get install -y fonts-powerline\n'
        ;;
      dnf|yum)
        printf '  - sudo dnf install -y powerline-fonts\n'
        ;;
      pacman)
        printf '  - sudo pacman -S --noconfirm ttf-meslo-nerd-font-powerlevel10k\n'
        ;;
      *)
        printf '  - Install a Nerd Font with your package manager\n'
        ;;
    esac
  fi

  return 0
}

print_uninstall_next_steps() {
  log "Next steps"
  cat <<'EOF' >&2
  The symlinks that pointed into this repository have been removed. Nothing was
  deleted except those symlinks.

  To restore a configuration that was replaced during install, look for the
  newest backup next to the original path and move it back:

      ls -d ~/.zshrc.bak.* 2>/dev/null        # find backups
      mv ~/.zshrc.bak.20260101120000 ~/.zshrc # restore one

  Your shell will keep using the currently loaded configuration until you open
  a new terminal.
EOF
  return 0
}

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Installs this repository's configuration into $HOME. Running it again is safe:
correct symlinks are left untouched and anything else at a target path is
moved aside to "<target>.bak.<timestamp>".

Options:
  -n, --dry-run         Show what would happen, change nothing
      --link-only       Only create symlinks; skip Homebrew/Brewfile/zsh/plugins
      --prompt FLAVOUR  Prompt flavour: starship (default) or p10k
      --print-map       Print "source<TAB>target<TAB>required|optional" for
                        every managed path and exit without changing anything
                        (used by bootstrap.sh)
      --uninstall       Remove the symlinks that point into this repository.
                        Real files are never touched, so backups stay in place.
                        Combine with --dry-run to preview.
      --remove-readmes  Remove README* files from $HOME after installing
  -y, --yes             Assume "yes" for all confirmations
  -h, --help            Show this help message

Not run by this script (run them manually, see README.md):
  ./macos             macOS system preferences (needs sudo and a re-login)
  ./defaults          a backup dump of this machine's defaults, not a script
  ./bootstrap.sh      verify the installation afterwards

Rollback: re-point or delete the symlinks listed by `./bootstrap.sh`, and
restore the newest "<target>.bak.<timestamp>" file that was moved aside.
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --remove-readmes)
        REMOVE_READMES=1
        shift
        ;;
      -y|--yes)
        ASSUME_YES=1
        shift
        ;;
      -n|--dry-run)
        DRY_RUN=1
        shift
        ;;
      --link-only)
        LINK_ONLY=1
        shift
        ;;
      --print-map)
        MAP_ONLY=1
        shift
        ;;
      --uninstall)
        UNINSTALL=1
        shift
        ;;
      --prompt)
        if [[ $# -lt 2 ]]; then
          error "--prompt requires an argument: starship or p10k"
        fi
        case "$2" in
          starship|p10k)
            PROMPT_FLAVOR="$2"
            PROMPT_FORCED=1
            ;;
          *)
            error "invalid --prompt value: $2 (expected starship or p10k)"
            ;;
        esac
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        error "unknown option: $1 (try --help)"
        ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# entry point
# ---------------------------------------------------------------------------

main() {
  parse_args "$@"

  if is_windows; then
    error "Windows is not supported: this repository manages POSIX home-directory paths. Use WSL, or link the files manually (see README.md)."
  fi

  if ! is_macos && ! is_linux; then
    error "unsupported platform: $OS_TYPE (macOS and Linux are supported)"
  fi

  # --print-map: emit the mapping and stop. No trap, no logging, no changes --
  # stdout must contain nothing but "source<TAB>target" lines.
  if [[ "$MAP_ONLY" -eq 1 ]]; then
    link_dotfiles
    return 0
  fi

  trap on_err ERR
  trap on_exit EXIT

  log "Repository : $DOTFILES"
  log "Home       : $HOME"
  log "Platform   : $OS_TYPE ($(uname -m))"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY RUN: nothing will be modified"
  fi

  # Uninstall is a separate, deliberately narrow operation: it only removes
  # symlinks that point back into this repository.
  if [[ "$UNINSTALL" -eq 1 ]]; then
    log "UNINSTALL: removing the symlinks that point into $DOTFILES"
    if confirm_step "Remove the symlinks installed by this repository?"; then
      attempt "remove installed symlinks" link_dotfiles
      if [[ "${#STEP_FAILURES[@]}" -eq 0 ]]; then
        print_uninstall_next_steps >&2
      fi
    else
      log "Skipped: uninstall"
    fi

    if [[ "${#STEP_FAILURES[@]}" -gt 0 ]]; then
      return 1
    fi
    return 0
  fi

  if [[ "$LINK_ONLY" -eq 1 ]]; then
    log "LINK-ONLY: skipping Homebrew, Brewfile, zsh, Oh My Zsh and plugins"
  else
    if confirm_step "Install Homebrew (macOS only)?"; then
      attempt "install Homebrew" install_homebrew
    else
      log "Skipped: install Homebrew"
    fi

    if confirm_step "Install the packages listed in the Brewfile?"; then
      printf '    this can take a long time; review %s first\n' "$BREWFILE" >&2
      attempt "install Brewfile packages" install_brew_packages
    else
      log "Skipped: install Brewfile packages"
    fi

    if confirm_step "Ensure zsh is installed and set as the login shell?"; then
      attempt "ensure zsh is installed and is the login shell" ensure_zsh_as_default_shell
    else
      log "Skipped: ensure zsh is installed and is the login shell"
    fi

    if confirm_step "Install Oh My Zsh?"; then
      attempt "install Oh My Zsh" install_oh_my_zsh
    else
      log "Skipped: install Oh My Zsh"
    fi
  fi

  # The prompt flavour decides which zshrc and which extra theme are used, so
  # it has to be known before installing plugins and before linking.
  if [[ "$LINK_ONLY" -eq 0 ]]; then
    if confirm_step "Choose the prompt flavour now?"; then
      choose_prompt_flavor
    else
      log "Skipped: choosing the prompt flavour; using $PROMPT_FLAVOR"
    fi
  else
    choose_prompt_flavor
  fi

  if [[ "$LINK_ONLY" -eq 0 ]]; then
    if confirm_step "Install external zsh plugins?"; then
      attempt "install external zsh plugins" install_zsh_plugins
    else
      log "Skipped: install external zsh plugins"
    fi
  fi

  if confirm_step "Link configuration files into \$HOME?"; then
    attempt "link configuration files" link_dotfiles
  else
    log "Skipped: link configuration files"
  fi

  if [[ "$REMOVE_READMES" -eq 1 ]]; then
    if confirm_step "Remove README* files from \$HOME?"; then
      attempt "remove README* files from \$HOME" remove_readmes
    else
      log "Skipped: remove README* files from \$HOME"
    fi
  fi

  print_next_steps >&2

  if [[ "${#STEP_FAILURES[@]}" -gt 0 ]]; then
    return 1
  fi
  return 0
}

main "$@"
