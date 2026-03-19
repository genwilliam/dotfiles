#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$DOTFILES/Brewfile"

log() {
  printf '\n==> %s\n' "$1"
}

error() {
  printf '\n==> ERROR: %s\n' "$1" >&2
  exit 1
}

# Ensure a command exists (or error out)
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || error "Required command not found: $1"
}

# Create a symlink; backup existing non-symlink targets.
link_dotfile() {
  local src="$1"
  local dest="$2"

  [[ -e "$src" || -L "$src" ]] || return 0

  mkdir -p "$(dirname "$dest")"

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    local backup="${dest}.bak.$(date +%s)"
    log "Backing up existing $dest -> $backup"
    mv "$dest" "$backup"
  fi

  ln -sfn "$src" "$dest"
  log "Linked $dest -> $src"
}

# Keep Homebrew available in the current shell
eval_homebrew_shellenv() {
  if command -v brew >/dev/null 2>&1; then
    eval "$(command -v brew) shellenv"
    return 0
  fi

  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$candidate" ]]; then
      eval "$("$candidate" shellenv)"
      return 0
    fi
  done

  return 1
}

install_homebrew() {
  log "Ensuring Homebrew is installed"

  if command -v brew >/dev/null 2>&1; then
    log "Homebrew already installed"
    eval_homebrew_shellenv
    return
  fi

  require_cmd curl

  log "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if ! eval_homebrew_shellenv; then
    error "Homebrew was installed but could not be initialized"
  fi
}

install_brew_packages() {
  [[ -f "$BREWFILE" ]] || {
    log "No Brewfile found at $BREWFILE; skipping Homebrew bundle"
    return
  }

  log "Installing Homebrew packages from Brewfile"
  brew bundle --file="$BREWFILE" --no-upgrade
}

install_oh_my_zsh() {
  local oh_my_zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"

  log "Ensuring Oh My Zsh is installed"
  if [[ -d "$oh_my_zsh_dir" ]]; then
    log "Oh My Zsh already installed"
    return
  fi

  require_cmd curl

  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

clone_or_update_repo() {
  local repo_url="$1"
  local dest="$2"

  if [[ -d "$dest/.git" ]]; then
    log "Updating $(basename "$dest")"

    # If there are local changes, keep them and skip pull
    if [[ -n "$(git -C "$dest" status --porcelain=1)" ]]; then
      log "Local changes detected in $dest; skipping update"
      return
    fi

    git -C "$dest" pull --ff-only --quiet || log "Failed to update $dest; skipping"
    return
  fi

  git clone --depth=1 "$repo_url" "$dest"
}

install_zsh_plugins() {
  local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
  local custom_dir="${ZSH_CUSTOM:-$zsh_dir/custom}"

  log "Installing Zsh plugins"
  mkdir -p "$custom_dir/plugins" "$custom_dir/themes"

  if ! command -v git >/dev/null 2>&1; then
    log "Installing git (required to clone Zsh plugins)"
    brew install git
  fi

  clone_or_update_repo "https://github.com/zsh-users/zsh-autosuggestions.git" "$custom_dir/plugins/zsh-autosuggestions"
  clone_or_update_repo "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" "$custom_dir/plugins/fast-syntax-highlighting"
  clone_or_update_repo "https://github.com/Aloxaf/fzf-tab.git" "$custom_dir/plugins/fzf-tab"
  clone_or_update_repo "https://github.com/MichaelAquilina/zsh-you-should-use.git" "$custom_dir/plugins/you-should-use"
  clone_or_update_repo "https://github.com/zthxxx/zsh-history-enquirer.git" "$custom_dir/plugins/zsh-history-enquirer"

  if [[ "${PROMPT_FLAVOR:-starship}" == "p10k" ]]; then
    clone_or_update_repo "https://github.com/romkatv/powerlevel10k.git" "$custom_dir/themes/powerlevel10k"
  fi
}

link_dotfiles() {
  log "Linking dotfiles"

  mkdir -p "$HOME/.config" "$HOME/.local/bin"

  link_dotfile "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"
  link_dotfile "$DOTFILES/git/gitignore_global" "$HOME/.gitignore_global"

  link_dotfile "$DOTFILES/zsh/zshenv" "$HOME/.zshenv"
  link_dotfile "$DOTFILES/zsh/zprofile" "$HOME/.zprofile"
  link_dotfile "$DOTFILES/zsh/zshrc" "$HOME/.zshrc"
  link_dotfile "$DOTFILES/zsh/zlogin" "$HOME/.zlogin"
  link_dotfile "$DOTFILES/zsh/zlogout" "$HOME/.zlogout"
  link_dotfile "$DOTFILES/zsh/zshrc.d" "$HOME/.zshrc.d"

  link_dotfile "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"
  link_dotfile "$DOTFILES/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"

  link_dotfile "$DOTFILES/nvim" "$HOME/.config/nvim"

  link_dotfile "$DOTFILES/config/starship.toml" "$HOME/.config/starship.toml"
  link_dotfile "$DOTFILES/config/thefuck" "$HOME/.config/thefuck"
  link_dotfile "$DOTFILES/config/aria2" "$HOME/.config/aria2"

  if [[ -d "$DOTFILES/bin" ]]; then
    while IFS= read -r script; do
      link_dotfile "$script" "$HOME/.local/bin/$(basename "$script")"
    done < <(find "$DOTFILES/bin" -maxdepth 1 -type f -print)
  fi
}

remove_readmes() {
  log "Removing README* files from home"
  # shellcheck disable=SC2034
  local -a files
  shopt -s nullglob
  for f in "$HOME"/README*; do
    [[ -e "$f" && ! -d "$f" ]] || continue
    rm -f "$f"
    log "Removed $f"
  done
  shopt -u nullglob
}

print_next_steps() {
  log "Done"
  cat <<'EOF'
Next steps:
 1) Restart your terminal (or run: source ~/.zshrc)
 2) If you use powerlevel10k: run `p10k configure` to regenerate prompt config
EOF
}

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --remove-readmes    Remove README* files from $HOME after install
  -h, --help          Show this help message
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --remove-readmes)
        REMOVE_READMES=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        error "Unknown option: $1"
        ;;
    esac
  done
}

main() {
  local REMOVE_READMES=0
  parse_args "$@"

  install_homebrew
  install_brew_packages
  install_oh_my_zsh
  install_zsh_plugins
  link_dotfiles

  if [[ "$REMOVE_READMES" -eq 1 ]]; then
    remove_readmes
  fi

  print_next_steps
}

main "$@"

