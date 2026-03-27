# Tool initialization
# initialize only once to avoid repeated eval

# starship begin
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
# starship end

# direnv begin
# Load direnv hook if installed (allows per-project envrc)
# if command -v direnv >/dev/null 2>&1; then
#   eval "$(direnv hook zsh)"
# fi
# direnv end

# thefuck begin (lazy, no .zshrc changes)
# I use uv install thefuck: `uv tool install --python 3.11 thefuck`
if command -v thefuck >/dev/null 2>&1; then
  fuck() {
      unfunction fuck
      eval "$(thefuck --alias fuck)"
      fuck "$@"
  }
fi
# thefuck end

# nvm begin
# keep nvm as on-demand fallback for projects that require it
export NVM_DIR="$HOME/.nvm"
typeset -g _NVM_LOADED=0

_load_nvm() {
  [[ "$_NVM_LOADED" == "1" ]] && return 0

  local nvm_prefix=""

  if [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
    nvm_prefix="/opt/homebrew/opt/nvm"
  elif [[ -s "/usr/local/opt/nvm/nvm.sh" ]]; then
    nvm_prefix="/usr/local/opt/nvm"
  else
    return 1
  fi

  source "$nvm_prefix/nvm.sh"

  # Try to expose a default node binary quickly (without forcing nvm use on every cd)
  if ! command -v node >/dev/null 2>&1 && [[ -r "$NVM_DIR/alias/default" ]]; then
    local default_alias
    default_alias="$(<"$NVM_DIR/alias/default")"
    default_alias="${default_alias//$'\r'/}"
    default_alias="${default_alias//$'\n'/}"

    if [[ -x "$NVM_DIR/versions/node/$default_alias/bin/node" ]]; then
      path=("$NVM_DIR/versions/node/$default_alias/bin" $path)
      export PATH
    fi
  fi

  # If default alias is not configured, use the latest installed Node in NVM_DIR
  if ! command -v node >/dev/null 2>&1 && [[ -d "$NVM_DIR/versions/node" ]]; then
    local latest_installed
    latest_installed="$(command ls -1 "$NVM_DIR/versions/node" 2>/dev/null | command sort -V | command tail -n 1)"
    if [[ -n "$latest_installed" && -x "$NVM_DIR/versions/node/$latest_installed/bin/node" ]]; then
      path=("$NVM_DIR/versions/node/$latest_installed/bin" $path)
      export PATH
    fi
  fi

  _NVM_LOADED=1
  return 0
}

_prepend_nvm_node_bin_if_needed() {
  # If node binary already exists in PATH, do nothing
  whence -p node >/dev/null 2>&1 && return 0

  # Prefer .nvmrc in current project when it points to an installed version
  if [[ -f .nvmrc ]]; then
    local requested
    requested="$(tr -d '[:space:]' < .nvmrc)"
    if [[ -n "$requested" && -x "$NVM_DIR/versions/node/$requested/bin/node" ]]; then
      path=("$NVM_DIR/versions/node/$requested/bin" $path)
      export PATH
      return 0
    fi
  fi

  # Then try alias/default
  if [[ -r "$NVM_DIR/alias/default" ]]; then
    local default_alias
    default_alias="$(<"$NVM_DIR/alias/default")"
    default_alias="${default_alias//$'\r'/}"
    default_alias="${default_alias//$'\n'/}"
    if [[ -x "$NVM_DIR/versions/node/$default_alias/bin/node" ]]; then
      path=("$NVM_DIR/versions/node/$default_alias/bin" $path)
      export PATH
      return 0
    fi
  fi

  # Last fast fallback: latest installed version under NVM_DIR
  if [[ -d "$NVM_DIR/versions/node" ]]; then
    local latest_installed
    latest_installed="$(command ls -1 "$NVM_DIR/versions/node" 2>/dev/null | command sort -V | command tail -n 1)"
    if [[ -n "$latest_installed" && -x "$NVM_DIR/versions/node/$latest_installed/bin/node" ]]; then
      path=("$NVM_DIR/versions/node/$latest_installed/bin" $path)
      export PATH
      return 0
    fi
  fi

  return 1
}

nvm() {
  _load_nvm || {
    echo "nvm failed to load (expected: /opt/homebrew/opt/nvm/nvm.sh or /usr/local/opt/nvm/nvm.sh)" >&2
    return 127
  }

  # nvm.sh defines the real nvm function; do not unfunction it here.
  nvm "$@"
}

node() {
  whence -p node >/dev/null 2>&1 || _prepend_nvm_node_bin_if_needed || true
  command node "$@"
}

npm() {
  whence -p npm >/dev/null 2>&1 || _prepend_nvm_node_bin_if_needed || true
  command npm "$@"
}

npx() {
  whence -p npx >/dev/null 2>&1 || _prepend_nvm_node_bin_if_needed || true
  command npx "$@"
}
# nvm end

# mise begin
if command -v mise >/dev/null 2>&1; then
  mise() {
    unfunction mise
    eval "$(command mise activate zsh)"
    mise "$@"
  }
fi
# mise end

# android begin
export ANDROID_HOME=$HOME/Developer/tools/Android/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME

typeset -gU path
path=(
  $ANDROID_HOME/cmdline-tools/latest/bin
  $ANDROID_HOME/platform-tools
  $ANDROID_HOME/emulator
  $path
)
export PATH
# android end
