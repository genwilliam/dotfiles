# Tool related environment variables

# docker / colima
export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"

# runtime policy: mise is primary runtime manager via shims in ~/.zshenv
# keep nvm as on-demand fallback for projects that require it
export NVM_DIR="$HOME/.nvm"
typeset -g _NVM_LOADED=0

_load_nvm() {
  [[ "$_NVM_LOADED" == "1" ]] && return 0

  if ! command -v brew >/dev/null 2>&1; then
    return 1
  fi

  local nvm_prefix
  nvm_prefix="$(brew --prefix nvm 2>/dev/null)"
  [[ -s "$nvm_prefix/nvm.sh" ]] || return 1

  source "$nvm_prefix/nvm.sh"
  [[ -s "$nvm_prefix/etc/bash_completion.d/nvm" ]] && source "$nvm_prefix/etc/bash_completion.d/nvm"
  _NVM_LOADED=1
  return 0
}

nvm() {
  unfunction nvm
  _load_nvm

  if ! command -v nvm >/dev/null 2>&1; then
    echo "nvm failed to load from Homebrew (expected: \$(brew --prefix nvm)/nvm.sh)" >&2
    return 127
  fi

  nvm "$@"
}


# uv python version manager
export PATH="$HOME/.local/share/uv/python/cpython-3.11-macos-aarch64-none/bin:$PATH"