# 环境变量（PATH、LANG、NVM_DIR 等）

# ========= 基础环境 =========
# 自动去重 PATH，防止每次 source 时路径无限叠加导致搜索变慢
typeset -U path PATH

export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export LANG=en_US.UTF-8
export PATH="$HOME/.local/share/mise/shims:$PATH"

# pnpm begin
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# colima begin
export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"
# colima end

# nvm begin
export NVM_DIR="$HOME/.nvm"
source "$(brew --prefix nvm)/nvm.sh"
source "$(brew --prefix nvm)/etc/bash_completion.d/nvm"
# nvm end


# JAVA_HOME
# export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
# export PATH="$JAVA_HOME/bin:$PATH"
# export DYLD_LIBRARY_PATH=/opt/homebrew/lib:$DYLD_LIBRARY_PATH

# Go 环境
# 优化：直接指定静态路径，避免调用 $(go env) 产生的外部进程耗时
# export GOPATH="$HOME/go"
# GOROOT 通常不需要手动 export，除非你安装了多个 Go 版本
# export GOROOT="$(go env GOROOT)" 

# Go bin 加入 PATH
# export PATH="$PATH:$GOPATH/bin"
