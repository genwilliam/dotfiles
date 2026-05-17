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

# zoxide begin
export _ZO_FZF_OPTS="--height 40% --layout=reverse --border"
export _ZO_EXCLUDE_DIRS="$HOME:$HOME/Downloads"
# zoxide end

# rust begin
export PATH="$HOME/.cargo/bin:$PATH"
# rust end

# jdk begin
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
# jdk end

# openclaw begin
# OpenClaw Completion
[ -f "/Users/genwilliam/.openclaw/completions/openclaw.zsh" ] && source "/Users/genwilliam/.openclaw/completions/openclaw.zsh"
# openclaw end
