# Tool related environment variables

# docker / colima begin
export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"
# docker / colima end

# ollama begin
export OLLAMA_API_KEY="ollama-local"
# ollama end

# brew begin
export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
# brew end

# nvm begin
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
# nvm end

# npm begin
# I download openclaw from npm
# Only add npm global bin when npm is available to avoid failing interactive shells
if command -v npm >/dev/null 2>&1; then
  export PATH="$(npm bin -g):$PATH"
fi
# npm end

# uv begin
# Only add uv-managed python shims when uv is installed (avoid startup errors)
# export PATH="$HOME/.local/bin:$PATH"
# uv end
