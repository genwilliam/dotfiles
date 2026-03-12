# 补全 / fzf-tab 行为（原来放在 ~/.zshrc 末尾）

# 让 fzf-tab 接管 Tab 补全并进入交互选择模式
zstyle ':completion:*' menu select
bindkey '^I' expand-or-complete  # 绑定 Tab 键

# fzf-tab 分组切换与交互行为
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-flags '--ansi --height 40% --reverse --border'
zstyle ':fzf-tab:complete:*' fzf-preview 'ls --color=always --group-directories-first $realpath'

# 匹配规则（忽略大小写、支持模糊匹配）
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'

# 中文路径友好
zstyle ':completion:*' file-sort modification
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
