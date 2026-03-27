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
  [[ -s "$nvm_prefix/etc/bash_completion.d/nvm" ]] && source "$nvm_prefix/etc/bash_completion.d/nvm"
  _NVM_LOADED=1
  return 0
}

_with_nvm() {
  local cmd="$1"
  shift

  _load_nvm
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd failed to load from nvm (expected: /opt/homebrew/opt/nvm/nvm.sh or /usr/local/opt/nvm/nvm.sh)" >&2
    return 127
  fi

  "$cmd" "$@"
}

nvm() {
  _with_nvm nvm "$@"
}

node() {
  _with_nvm node "$@"
}

npm() {
  _with_nvm npm "$@"
}

npx() {
  _with_nvm npx "$@"
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
