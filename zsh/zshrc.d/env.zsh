# Tool related environment variables.
#
# Loaded *before* Oh My Zsh (see zsh/zshrc). Only interactive-shell settings
# belong here. PATH is composed with the zsh `path` array so that the
# `typeset -gU path` uniqueness set up in .zshrc is honoured and directories
# containing spaces keep working.

# docker / colima begin
export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"
# docker / colima end

# ollama begin
export OLLAMA_API_KEY="ollama-local"
# ollama end

# brew begin
# One assignment: two separate assignments silently dropped --appdir, because
# the second one replaced the first.
# export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications --require-sha"
export HOMEBREW_UPDATE_TO_TAG=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_INSECURE_REDIRECT=1
# brew end

# zoxide begin
export _ZO_FZF_OPTS="--height 40% --layout=reverse --border"
export _ZO_EXCLUDE_DIRS="$HOME:$HOME/Downloads"
# zoxide end

# rust begin
# rustup installs into ~/.cargo/bin; only prepend it when it exists.
if [[ -d "$HOME/.cargo/bin" ]]; then
  path=("$HOME/.cargo/bin" $path)
fi
# rust end

# jdk begin
# Homebrew's openjdk is keg-only, so it is not linked into PATH automatically.
# Check both the Apple Silicon and the Intel prefix.
typeset -a _openjdk_bins=(
  /opt/homebrew/opt/openjdk@17/bin
  /usr/local/opt/openjdk@17/bin
)

typeset _openjdk_bin
for _openjdk_bin in "${_openjdk_bins[@]}"; do
  if [[ -d "$_openjdk_bin" ]]; then
    path=("$_openjdk_bin" $path)
  fi
done

unset _openjdk_bins _openjdk_bin
# jdk end

# maven begin
# apache-maven-* is unpacked by hand under ~/Developer/tools, so resolve the
# newest installation instead of hard-coding a version that will go stale.
typeset -a _maven_dirs=("$HOME/Developer/tools"/apache-maven-*(Nom))

if (( ${#_maven_dirs[@]} > 0 )); then
  export MAVEN_HOME="${_maven_dirs[-1]}"
  if [[ -d "$MAVEN_HOME/bin" ]]; then
    path=("$MAVEN_HOME/bin" $path)
  fi
fi

unset _maven_dirs
# maven end
