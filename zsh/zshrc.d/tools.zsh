# Tool initialization
# initialize only once to avoid repeated eval

# starship begin
# Only one prompt may be active. The p10k flavour sets ZSH_PROMPT_FLAVOR=p10k
# in p10k/zshrc, so starship stays out of the way there.
if [[ "${ZSH_PROMPT_FLAVOR:-starship}" == "starship" ]] && command -v starship >/dev/null 2>&1; then
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
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# PATH and path are tied in zsh. -U keeps path entries unique while preserving
# the first occurrence, so the startup Node path remains first in PATH. This
# exposes a binary path only; it does not activate NVM or set NVM_BIN.
typeset -gT -U PATH path

if [[ -d "$NVM_DIR/versions/node" ]]; then
  typeset -a _nvm_node_dirs=()
  typeset _nvm_default=""

  if [[ -r "$NVM_DIR/alias/default" ]]; then
    _nvm_default="$(<"$NVM_DIR/alias/default")"
    _nvm_default="${_nvm_default//$'\r'/}"
    _nvm_default="${_nvm_default//$'\n'/}"

    # Exact versions and major aliases can be resolved without nvm.sh.
    if [[ "$_nvm_default" == v<->.* ]]; then
      _nvm_node_dirs=("$NVM_DIR/versions/node/$_nvm_default"(N/))
    elif [[ "$_nvm_default" == <-> ]]; then
      _nvm_node_dirs=("$NVM_DIR/versions/node/v${_nvm_default}."*(Nn/))
    fi
  fi

  # Aliases such as "node" and "lts/*", or an unavailable default version,
  # cannot be resolved without nvm.sh. Keep Node usable by selecting the
  # newest installed version as a PATH fallback; this does not change NVM's
  # default alias or the project's selected version.
  if (( ${#_nvm_node_dirs[@]} == 0 )); then
    _nvm_node_dirs=("$NVM_DIR/versions/node/"v*(Nn/))
  fi

  if (( ${#_nvm_node_dirs[@]} > 0 )) && [[ -d "${_nvm_node_dirs[-1]}/bin" ]]; then
    path=("${_nvm_node_dirs[-1]}/bin" $path)
  fi

  unset _nvm_default _nvm_node_dirs
fi

# Load the full NVM implementation only when version management is requested.
# The wrapper remains defined if the script is missing or fails to load.
nvm() {
  local nvm_script=""

  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    nvm_script="$NVM_DIR/nvm.sh"
  elif [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
    nvm_script="/opt/homebrew/opt/nvm/nvm.sh"
  elif [[ -s "/usr/local/opt/nvm/nvm.sh" ]]; then
    nvm_script="/usr/local/opt/nvm/nvm.sh"
  else
    print -u2 "nvm: nvm.sh not found; checked NVM_DIR=$NVM_DIR and Homebrew paths"
    return 127
  fi

  # nvm.sh replaces this wrapper with the real nvm function.
  if ! source "$nvm_script"; then
    print -u2 "nvm: failed to load $nvm_script"
    return 127
  fi

  if (( ! $+functions[nvm] )); then
    print -u2 "nvm: $nvm_script loaded without defining nvm"
    return 127
  fi

  nvm "$@"
}

# Optional project version switching. The hook performs a local parent-directory
# search on chpwd; nvm.sh loads only when a .nvmrc is found and changes.
: "${NVM_AUTO_USE:=1}"
if [[ "$NVM_AUTO_USE" == 1 ]]; then
  autoload -Uz add-zsh-hook
  typeset -g _NVM_AUTO_USE_FILE=""
  typeset -g _NVM_AUTO_USE_VALUE=""
  typeset -g _NVM_AUTO_USE_FAILED_FILE=""
  typeset -g _NVM_AUTO_USE_FAILED_VALUE=""

  _nvm_auto_use() {
    local directory="$PWD"
    local nvmrc=""
    local nvmrc_value=""

    while [[ -n "$directory" ]]; do
      if [[ -f "$directory/.nvmrc" ]]; then
        nvmrc="$directory/.nvmrc"
        break
      fi
      [[ "$directory" == / ]] && break
      directory="${directory:h}"
    done

    # Leaving a project does not restore default: that could overwrite an
    # explicit version selected by the user. A later project can switch again.
    if [[ -z "$nvmrc" ]]; then
      _NVM_AUTO_USE_FILE=""
      _NVM_AUTO_USE_VALUE=""
      _NVM_AUTO_USE_FAILED_FILE=""
      _NVM_AUTO_USE_FAILED_VALUE=""
      return 0
    fi

    nvmrc_value="$(<"$nvmrc")"
    nvmrc_value="${nvmrc_value//$'\r'/}"
    nvmrc_value="${nvmrc_value//$'\n'/}"

    # Do not re-run nvm use for unchanged project metadata. This also leaves
    # an explicit manual nvm use untouched while staying in the same project.
    if [[ "$nvmrc" == "$_NVM_AUTO_USE_FILE" &&
          "$nvmrc_value" == "$_NVM_AUTO_USE_VALUE" ]]; then
      return 0
    fi

    # Avoid repeating the same failed lookup on every directory change. After
    # installing the requested version, run `nvm use` explicitly to retry.
    if [[ "$nvmrc" == "$_NVM_AUTO_USE_FAILED_FILE" &&
          "$nvmrc_value" == "$_NVM_AUTO_USE_FAILED_VALUE" ]]; then
      return 1
    fi

    if ! nvm use --silent >/dev/null; then
      print -u2 "nvm: failed to use version from $nvmrc"
      _NVM_AUTO_USE_FAILED_FILE="$nvmrc"
      _NVM_AUTO_USE_FAILED_VALUE="$nvmrc_value"
      return 1
    fi

    _NVM_AUTO_USE_FILE="$nvmrc"
    _NVM_AUTO_USE_VALUE="$nvmrc_value"
    _NVM_AUTO_USE_FAILED_FILE=""
    _NVM_AUTO_USE_FAILED_VALUE=""
  }

  add-zsh-hook chpwd _nvm_auto_use
  # Handle shells started inside a project as well as later directory changes.
  # This is the intentional startup exception when a parent .nvmrc is found.
  _nvm_auto_use
fi
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
