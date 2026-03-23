#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$DOTFILES/Brewfile"
OS_TYPE="$(uname -s)"
REMOVE_READMES=0
ASSUME_YES=0
LINUX_PKG_MANAGER=""
PROMPT_CHOICE=""
PROMPT_FLAVOR="starship"
declare -a ASYNC_PIDS=()
declare -a ASYNC_NAMES=()

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
  manager="$(get_linux_pkg_manager || true)"
  [[ -n "$manager" ]] || error "Linux detected by uname, but no supported package manager found"

  log "Installing $pkg via $manager"
  case "$manager" in
    apt-get)
      run_with_sudo apt-get update
      run_with_sudo apt-get install -y "$pkg"
      ;;
    dnf)
      run_with_sudo dnf install -y "$pkg"
      ;;
    yum)
      run_with_sudo yum install -y "$pkg"
      ;;
    pacman)
      run_with_sudo pacman -S --noconfirm "$pkg"
      ;;
    zypper)
      run_with_sudo zypper --non-interactive install "$pkg"
      ;;
    apk)
      run_with_sudo apk add "$pkg"
      ;;
    *)
      error "Unsupported package manager: $manager"
      ;;
  esac
}

log() {
  printf '\n==> %s\n' "$1"
}

error() {
  printf '\n==> ERROR: %s\n' "$1" >&2
  exit 1
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

run_async() {
  local task_name="$1"
  shift

  log "[START] $task_name"
  (
    "$@"
  ) &

  local pid=$!
  ASYNC_PIDS+=("$pid")
  ASYNC_NAMES+=("$task_name")
  log "[STARTED] $task_name (pid: $pid)"
}

wait_async_tasks() {
  local idx pid name failed=0

  for idx in "${!ASYNC_PIDS[@]}"; do
    pid="${ASYNC_PIDS[$idx]}"
    name="${ASYNC_NAMES[$idx]}"

    if wait "$pid"; then
      log "[DONE] $name"
    else
      log "[FAILED] $name"
      failed=1
    fi
  done

  ASYNC_PIDS=()
  ASYNC_NAMES=()

  if [[ "$failed" -ne 0 ]]; then
    error "One or more background tasks failed"
  fi
}

on_err() {
  local exit_code=$?
  error "Command failed (exit ${exit_code}) at line ${BASH_LINENO[0]}: ${BASH_COMMAND}"
}

trap on_err ERR

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

  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    log "Link unchanged $dest -> $src"
    return
  fi

  ln -sfn "$src" "$dest"
  log "Linked $dest -> $src"
}

# Keep Homebrew available in the current shell
eval_homebrew_shellenv() {
  local brew_bin

  if command -v brew >/dev/null 2>&1; then
    brew_bin="$(command -v brew)"
    eval "$($brew_bin shellenv)"
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
  if is_linux; then
    log "Linux detected; skipping Homebrew installation"
    return
  fi

  is_macos || return

  log "Ensuring Homebrew is installed"

  if command -v brew >/dev/null 2>&1; then
    log "Homebrew already installed"
    eval_homebrew_shellenv
    return
  fi

  require_cmd curl

  log "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if ! eval_homebrew_shellenv; then
    error "Homebrew was installed but could not be initialized"
  fi
}

install_brew_packages() {
  if is_linux; then
    log "Linux detected; skipping Homebrew bundle"
    return
  fi

  is_macos || return

  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew is not available; skipping Homebrew bundle"
    return
  fi

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

  require_cmd git

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
    if is_macos; then
      brew install git
    elif is_linux; then
      linux_install_pkg git
    else
      error "Unsupported platform for automatic git installation"
    fi
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

install_zsh_unix() {
  if is_macos; then
    if ! command -v brew >/dev/null 2>&1; then
      install_homebrew
    fi
    log "Installing zsh via Homebrew"
    brew install zsh
    return
  fi

  if is_linux; then
    local uname_kernel
    uname_kernel="$(uname -s)"
    [[ "$uname_kernel" == "Linux" ]] || error "Expected Linux from uname, got: $uname_kernel"

    linux_install_pkg zsh
    return
  fi

  error "Unsupported platform: this script supports macOS and Linux only"
}

ensure_zsh_installed() {
  if zsh --version >/dev/null 2>&1; then
    log "zsh already installed"
    return
  fi

  install_zsh_unix

  command -v zsh >/dev/null 2>&1 || error "zsh installation step finished, but zsh was still not found"
}

set_default_shell_to_zsh() {
  local current_shell current_shell_name zsh_path
  current_shell="${SHELL:-}"
  current_shell_name="$(basename "$current_shell")"

  log "Current default shell: ${current_shell:-unknown}"

  if [[ "$current_shell_name" == "zsh" ]]; then
    log "Default shell is already zsh"
    return
  fi

  if ! zsh --version >/dev/null 2>&1; then
    log "zsh not found via zsh --version; installing zsh"
    install_zsh_unix
  fi

  zsh_path="$(command -v zsh || true)"
  [[ -n "$zsh_path" ]] || error "zsh installed but executable not found in PATH"

  if ! command -v chsh >/dev/null 2>&1; then
    log "chsh not found; cannot auto-set default shell. Please set it manually to: $zsh_path"
    return
  fi

  if [[ -f /etc/shells ]] && ! grep -qx "$zsh_path" /etc/shells; then
    log "$zsh_path not found in /etc/shells; trying to add it"
    if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
      run_with_sudo tee -a /etc/shells <<< "$zsh_path" >/dev/null || true
    fi
  fi

  if chsh -s "$zsh_path" "$USER"; then
    log "Default shell changed to zsh: $zsh_path"
  else
    log "Failed to change default shell automatically; please run: chsh -s $zsh_path"
  fi
}

ensure_zsh_as_default_shell() {
  log "Ensuring zsh is installed and set as default shell"
  ensure_zsh_installed
  set_default_shell_to_zsh
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

  if [[ "$PROMPT_FLAVOR" == "p10k" ]]; then
    link_dotfile "$DOTFILES/p10k/zshrc" "$HOME/.zshrc"
    link_dotfile "$DOTFILES/p10k/zshrc.d" "$HOME/.zshrc.d"
    link_dotfile "$DOTFILES/p10k/p10k.zsh" "$HOME/.p10k.zsh"
  else
    link_dotfile "$DOTFILES/config/starship.toml" "$HOME/.config/starship.toml"
  fi

  link_dotfile "$DOTFILES/config/thefuck" "$HOME/.config/thefuck"
  link_dotfile "$DOTFILES/config/aria2" "$HOME/.config/aria2"

  if [[ -d "$DOTFILES/bin" ]]; then
    while IFS= read -r -d '' script; do
      link_dotfile "$script" "$HOME/.local/bin/$(basename "$script")"
    done < <(find "$DOTFILES/bin" -maxdepth 1 -type f -print0)
  fi
}

remove_readmes() {
  log "Removing README* files from home"
  # shellcheck disable=SC2034
  local -a files
  shopt -s nullglob
  for f in "$HOME"/README*; do
    [[ -e "$f" && ! -d "$f" ]] || continue
    [[ "$f" == "$HOME"/README* ]] || continue
    rm -f "$f"
    log "Removed $f"
  done
  shopt -u nullglob
}

print_next_steps() {
  local linux_manager
  linux_manager="$(get_linux_pkg_manager || true)"

  log "Done"
  cat <<EOF
Next steps:
 1) Restart your terminal (or run: source ~/.zshrc)
 2) If you use powerlevel10k: run `p10k configure` to regenerate prompt config

Meslo Nerd Font (recommended for powerlevel10k):
EOF

  if is_macos; then
    cat <<'EOF'
 macOS:
  - Install with brew:
      brew tap homebrew/cask-fonts
      brew install --cask font-meslo-lg-nerd-font
  - Check installed fonts:
      brew list --cask | grep font
EOF
    return
  fi

  if is_linux; then
    cat <<EOF
 Linux:
  - Use your package manager to search/install Meslo Nerd Font or Nerd Fonts.
  - Detected package manager: ${linux_manager:-unknown}
EOF
    case "${linux_manager:-}" in
      apt-get)
        cat <<'EOF'
  - Example (Ubuntu/Debian):
      sudo apt-get update
      sudo apt-get install -y fonts-powerline
EOF
        ;;
      dnf|yum)
        cat <<'EOF'
  - Example (RHEL/Fedora):
      sudo dnf install -y powerline-fonts || sudo yum install -y powerline-fonts
EOF
        ;;
      pacman)
        cat <<'EOF'
  - Example (Arch):
      sudo pacman -S --noconfirm ttf-meslo-nerd-font-powerlevel10k
EOF
        ;;
      *)
        cat <<'EOF'
  - You can also download manually:
      https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k
EOF
        ;;
    esac
  fi
}

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --remove-readmes    Remove README* files from $HOME after install
  -y, --yes           Assume yes for interactive confirmations
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
      -y|--yes)
        ASSUME_YES=1
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

choose_prompt_flavor() {
  local choice=""

  if [[ -t 0 ]]; then
    printf 'Choose prompt (Y/n): [Y=starship, n=powerlevel10k] '
    read -r choice || true
  fi

  PROMPT_CHOICE="$choice"
  case "$PROMPT_CHOICE" in
    [Nn])
      PROMPT_FLAVOR="p10k"
      ;;
    *)
      PROMPT_FLAVOR="starship"
      ;;
  esac
}

main() {
  parse_args "$@"

  if is_windows; then
    error "Windows detected. Please use ./install-for-windows.sh"
  fi

  if confirm_step "Do you want to install Homebrew?"; then
    install_homebrew
  else
    log "Skipped: Installing Homebrew"
  fi

  if confirm_step "Do you want to install Homebrew packages from Brewfile?"; then
    run_async "Installing Homebrew packages from Brewfile" install_brew_packages
  else
    log "Skipped: Installing Homebrew packages from Brewfile"
  fi

  if confirm_step "Do you want to ensure zsh is installed and set as default shell?"; then
    ensure_zsh_as_default_shell
  else
    log "Skipped: Ensuring zsh is installed and set as default shell"
  fi

  if confirm_step "Do you want to install Oh My Zsh?"; then
    install_oh_my_zsh
  else
    log "Skipped: Installing Oh My Zsh"
  fi

  if confirm_step "Do you want to choose prompt flavor?"; then
    choose_prompt_flavor
  else
    log "Skipped: Choosing prompt flavor"
  fi

  if confirm_step "Do you want to install zsh plugins?"; then
    install_zsh_plugins
  else
    log "Skipped: Installing zsh plugins"
  fi

  if confirm_step "Do you want to link dotfiles?"; then
    link_dotfiles
  else
    log "Skipped: Linking dotfiles"
  fi

  if [[ "$REMOVE_READMES" -eq 1 ]]; then
    if confirm_step "Do you want to remove README* files from HOME?"; then
      remove_readmes
    else
      log "Skipped: Removing README* files from home"
    fi
  fi

  wait_async_tasks

  print_next_steps
}

main "$@"

