# 工具初始化（只初始化一次，避免重复 eval）

# starship（如果已安装）
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# mise（如果已安装）
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# thefuck（如果已安装）
if command -v thefuck >/dev/null 2>&1; then
  eval "$(thefuck --alias)"
fi
