#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ZSH_PKG_URL="https://mirror.msys2.org/msys/x86_64/zsh-5.9-5-x86_64.pkg.tar.zst"
OS_TYPE="$(uname -s)"
REMOVE_READMES=0
ASSUME_YES=0
WINDOWS_PKG_MANAGER=""

log() {
  printf '\n==> %s\n' "$1"
}

error() {
  printf '\n==> ERROR: %s\n' "$1" >&2
  exit 1
}

on_err() {
  local exit_code=$?
  error "Command failed (exit ${exit_code}) at line ${BASH_LINENO[0]}: ${BASH_COMMAND}"
}

trap on_err ERR

is_windows() {
  [[ "${OS:-}" == "Windows_NT" ]] || [[ "$OS_TYPE" =~ ^(MINGW|MSYS|CYGWIN) ]]
}

get_windows_pkg_manager() {
  if [[ -n "$WINDOWS_PKG_MANAGER" ]]; then
    printf '%s' "$WINDOWS_PKG_MANAGER"
    return 0
  fi

  local manager
  for manager in winget choco scoop; do
    if command -v "$manager" >/dev/null 2>&1; then
      WINDOWS_PKG_MANAGER="$manager"
      printf '%s' "$manager"
      return 0
    fi
  done

  return 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || error "Required command not found: $1"
}

install_git_windows() {
  local manager
  manager="$(get_windows_pkg_manager || true)"
  [[ -n "$manager" ]] || error "git is required, and no supported package manager (winget/choco/scoop) was found"

  case "$manager" in
    winget)
      log "Installing git via winget"
      winget install --id Git.Git --accept-package-agreements --accept-source-agreements
      ;;
    choco)
      log "Installing git via choco"
      choco install -y git
      ;;
    scoop)
      log "Installing git via scoop"
      scoop install git
      ;;
  esac
}

ensure_git_installed() {
  if command -v git >/dev/null 2>&1; then
    log "git already installed"
    return
  fi

  install_git_windows
  command -v git >/dev/null 2>&1 || error "git installation finished but git was still not found"
}

get_git_install_dir() {
  if [[ -d "/c/Program Files/Git" ]]; then
    printf '%s\n' "/c/Program Files/Git"
    return
  fi

  local git_bin
  git_bin="$(command -v git)"
  cd -- "$(dirname "$git_bin")/.." && pwd
}

install_zstd_windows() {
  if command -v unzstd >/dev/null 2>&1 || command -v zstd >/dev/null 2>&1; then
    return
  fi

  local manager
  manager="$(get_windows_pkg_manager || true)"
  [[ -n "$manager" ]] || error "zstd/unzstd is required, and no supported package manager was found"

  case "$manager" in
    winget)
      log "Installing zstd via winget"
      winget install --id Facebook.Zstandard --accept-package-agreements --accept-source-agreements
      ;;
    choco)
      log "Installing zstd via choco"
      choco install -y zstandard
      ;;
    scoop)
      log "Installing zstd via scoop"
      scoop install zstd
      ;;
  esac
}

install_zsh_into_git_dir() {
  local git_dir tmp_dir pkg_file pkg_tar extract_dir
  git_dir="$(get_git_install_dir)"

  local confirm="n"
  if [[ "$ASSUME_YES" -eq 1 ]]; then
    confirm="y"
  elif [[ -t 0 ]]; then
    printf 'zsh not found. Download and install now? [y/N]: '
    read -r confirm
  fi

  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    error "zsh installation was not confirmed"
  fi

  require_cmd curl
  require_cmd tar

  install_zstd_windows
  command -v unzstd >/dev/null 2>&1 || command -v zstd >/dev/null 2>&1 || error "zstd/unzstd installation finished but command still missing"

  tmp_dir="$(mktemp -d)"
  pkg_file="$tmp_dir/zsh.pkg.tar.zst"
  pkg_tar="$tmp_dir/zsh.pkg.tar"
  extract_dir="$tmp_dir/extracted"

  mkdir -p "$extract_dir"

  log "Downloading zsh package"
  curl -fL "$ZSH_PKG_URL" -o "$pkg_file"

  log "Decompress pass #1 (.zst -> .tar)"
  if command -v unzstd >/dev/null 2>&1; then
    unzstd -f -k "$pkg_file"
  else
    zstd -d -f -k "$pkg_file"
  fi

  [[ -f "$pkg_tar" ]] || error "First decompress failed: $pkg_tar not found"

  log "Decompress pass #2 (.tar -> files)"
  tar -xf "$pkg_tar" -C "$extract_dir"

  if [[ ! -d "$extract_dir/usr" ]]; then
    error "Unexpected package layout: $extract_dir/usr not found"
  fi

  log "Moving extracted zsh files to git install directory without overwriting: $git_dir"
  cp -an "$extract_dir/." "$git_dir/"

  rm -rf "$tmp_dir"
}

ensure_zsh_installed() {
  local git_dir
  git_dir="$(get_git_install_dir)"

  if [[ -x "$git_dir/usr/bin/zsh.exe" || -x "$git_dir/usr/bin/zsh" ]] || command -v zsh >/dev/null 2>&1; then
    log "zsh already installed"
    return
  fi

  install_zsh_into_git_dir

  if [[ ! -x "$git_dir/usr/bin/zsh.exe" && ! -x "$git_dir/usr/bin/zsh" ]]; then
    log "zsh files copied but zsh executable not found in $git_dir/usr/bin"
  fi
}

configure_bashrc_for_zsh() {
  local bashrc="$HOME/.bashrc"
  touch "$bashrc"

  local chcp_line="/c/Windows/System32/chcp.com 65001 > /dev/null 2>&1"
  if ! grep -Fqx "$chcp_line" "$bashrc"; then
    printf '\n%s\n' "$chcp_line" >> "$bashrc"
    log "Added UTF-8 code page fix to $bashrc"
  fi

  if ! grep -Fq "exec zsh" "$bashrc"; then
    cat >> "$bashrc" <<'EOF'

if [ -t 1 ]; then
  exec zsh
fi
EOF
    log "Added default zsh block to $bashrc"
  fi
}

verify_zsh_version() {
  if command -v zsh >/dev/null 2>&1; then
    log "Verifying zsh version"
    zsh --version || true
  fi
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

  if ! ln -sfn "$src" "$dest"; then
    error "Failed to create symbolic link: $dest -> $src. On Windows, run terminal as Administrator or enable Developer Mode (Settings -> Privacy & security -> For developers -> Developer Mode)."
  fi
  log "Linked $dest -> $src"
}

clone_or_update_repo() {
  local repo_url="$1"
  local dest="$2"

  require_cmd git

  if [[ -d "$dest/.git" ]]; then
    log "Updating $(basename "$dest")"

    if [[ -n "$(git -C "$dest" status --porcelain=1)" ]]; then
      log "Local changes detected in $dest; skipping update"
      return
    fi

    git -C "$dest" pull --ff-only --quiet || log "Failed to update $dest; skipping"
    return
  fi

  git clone --depth=1 "$repo_url" "$dest"
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

install_zsh_plugins() {
  local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
  local custom_dir="${ZSH_CUSTOM:-$zsh_dir/custom}"

  log "Installing Zsh plugins"
  mkdir -p "$custom_dir/plugins" "$custom_dir/themes"

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
    while IFS= read -r -d '' script; do
      link_dotfile "$script" "$HOME/.local/bin/$(basename "$script")"
    done < <(find "$DOTFILES/bin" -maxdepth 1 -type f -print0)
  fi
}

remove_readmes() {
  log "Removing README* files from home"
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
  log "Done"
  cat <<'EOF'
Next steps:
 1) Restart your terminal
 2) zsh should start by default from ~/.bashrc
 3) Verify with: zsh --version
 4) For powerlevel10k, install Meslo Nerd Font:
    https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k
 5) If you use powerlevel10k: run `p10k configure`
EOF
}

usage() {
  cat <<'EOF'
Usage: ./install-for-windows.sh [options]

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

main() {
  parse_args "$@"

  is_windows || error "This script is for Windows environments only"

  log "Step 1/3: Ensure Git (Bash terminal support)"
  ensure_git_installed

  log "Step 2/3: Ensure zsh (download + double extract if missing)"
  ensure_zsh_installed

  log "Step 3/3: Configure Bash -> zsh and install Oh My Zsh"
  configure_bashrc_for_zsh
  install_oh_my_zsh
  install_zsh_plugins
  verify_zsh_version
  link_dotfiles

  if [[ "$REMOVE_READMES" -eq 1 ]]; then
    remove_readmes
  fi

  print_next_steps
}

main "$@"
