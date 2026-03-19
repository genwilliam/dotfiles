#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

# bootstrap.sh
# Validate that the dotfiles are loaded correctly and perform environment
# initialization steps that should run after `install.sh`.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
  printf '\n==> %s\n' "$1"
}

error() {
  printf '\n==> ERROR: %s\n' "$1" >&2
  exit 1
}

# Check whether a file is a symlink pointing to the expected target.
is_symlink_to() {
  local path="$1" expected="$2"
  [[ -L "$path" ]] && [[ "$(readlink "$path")" == "$expected" ]]
}

ensure_symlink() {
  local src="$1" dest="$2"

  if is_symlink_to "$dest" "$src"; then
    return 0
  fi

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    log "Backing up existing $dest -> ${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  log "Linked $dest -> $src"
}

validate_dotfiles_links() {
  log "Validating dotfile symlinks"

  ensure_symlink "$REPO_ROOT/git/gitconfig" "$HOME/.gitconfig"
  ensure_symlink "$REPO_ROOT/git/gitignore_global" "$HOME/.gitignore_global"

  ensure_symlink "$REPO_ROOT/zsh/zshenv" "$HOME/.zshenv"
  ensure_symlink "$REPO_ROOT/zsh/zprofile" "$HOME/.zprofile"
  ensure_symlink "$REPO_ROOT/zsh/zshrc" "$HOME/.zshrc"
  ensure_symlink "$REPO_ROOT/zsh/zlogin" "$HOME/.zlogin"
  ensure_symlink "$REPO_ROOT/zsh/zlogout" "$HOME/.zlogout"
  ensure_symlink "$REPO_ROOT/zsh/zshrc.d" "$HOME/.zshrc.d"

  ensure_symlink "$REPO_ROOT/nvim" "$HOME/.config/nvim"
  ensure_symlink "$REPO_ROOT/config/starship.toml" "$HOME/.config/starship.toml"
  ensure_symlink "$REPO_ROOT/config/thefuck" "$HOME/.config/thefuck"
  ensure_symlink "$REPO_ROOT/config/aria2" "$HOME/.config/aria2"
}

ensure_default_shell() {
  if [[ "$(basename "$SHELL")" != "zsh" ]]; then
    log "Your login shell is not zsh (current: $SHELL)"
    if command -v chsh >/dev/null 2>&1; then
      log "To set zsh as your default shell, run: chsh -s $(command -v zsh)"
    else
      log "Install chsh or change your login shell via system settings."
    fi
  fi
}

warm_zsh_cache() {
  # Run an interactive zsh once to warm up completion caches and ensure the
  # configuration loads without errors.
  if command -v zsh >/dev/null 2>&1; then
    log "Warming up zsh startup (this may take a few seconds)"
    env ZSH_STARTUP_PROFILE=0 zsh -i -c 'exit' 2>/dev/null || true
  fi
}

main() {
  validate_dotfiles_links
  ensure_default_shell
  warm_zsh_cache

  log "Bootstrap complete"
  printf 'Run: source ~/.zshrc\n'
}

main "$@"
