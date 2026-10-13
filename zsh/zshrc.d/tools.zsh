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
# Put the default Node binary on PATH without loading nvm.sh. This keeps
# node, npx, global npm CLIs, and /usr/bin/env shebangs available to children.
export NVM_DIR="$HOME/.nvm"
typeset -gU path PATH
typeset -a _nvm_node_dirs
typeset _nvm_default

if [[ -d "$NVM_DIR/versions/node" ]]; then
  if [[ -r "$NVM_DIR/alias/default" ]]; then
    _nvm_default="$(<"$NVM_DIR/alias/default")"
    _nvm_default="${_nvm_default//$'\r'/}"
    _nvm_default="${_nvm_default//$'\n'/}"

    if [[ "$_nvm_default" == v<->.* ]]; then
      _nvm_node_dirs=("$NVM_DIR/versions/node/$_nvm_default"(N))
    elif [[ "$_nvm_default" == <-> ]]; then
      _nvm_node_dirs=("$NVM_DIR/versions/node/v${_nvm_default}."*(N))
    fi
  fi

  # Aliases such as "node" or "lts/*" need nvm to resolve them. Use the
  # newest installed version as a usable startup fallback in that case.
  if (( ${#_nvm_node_dirs[@]} == 0 )); then
    _nvm_node_dirs=("$NVM_DIR/versions/node/"v*(Nn))
  fi

  if (( ${#_nvm_node_dirs[@]} > 0 )) && [[ -d "${_nvm_node_dirs[-1]}/bin" ]]; then
    path=("${_nvm_node_dirs[-1]}/bin" $path)
  fi
fi

unset _nvm_default _nvm_node_dirs

# Load the full NVM implementation only when version management is requested.
nvm() {
  unfunction nvm

  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
  elif [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
    source "/opt/homebrew/opt/nvm/nvm.sh"
  elif [[ -s "/usr/local/opt/nvm/nvm.sh" ]]; then
    source "/usr/local/opt/nvm/nvm.sh"
  else
    print -u2 "nvm.sh not found"
    return 127
  fi

  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
  nvm "$@"
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
# export ANDROID_HOME=$HOME/Developer/tools/Android/sdk
# export ANDROID_SDK_ROOT=$ANDROID_HOME

# typeset -gU path
# path=(
#   $ANDROID_HOME/cmdline-tools/latest/bin
#   $ANDROID_HOME/platform-tools
#   $ANDROID_HOME/emulator
#   $path
# )
# export PATH
# android end
