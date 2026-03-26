# Let fzf-tab take over tab completion and enter interactive selection mode
zstyle ':completion:*' menu select
bindkey '^I' expand-or-complete

# fzf-tab Group switching and interactive behavior
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-flags '--ansi --height 40% --reverse --border'
if command -v eza >/dev/null 2>&1; then
	zstyle ':fzf-tab:complete:*' fzf-preview 'eza -1 --color=always $realpath'
else
	zstyle ':fzf-tab:complete:*' fzf-preview 'ls -1 $realpath'
fi

# rules: ignore case, ignore separators (.-_)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'

# 中文路径友好
zstyle ':completion:*' file-sort modification
if [[ -n "${LS_COLORS:-}" ]]; then
	zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
fi

if command -v fzf >/dev/null 2>&1; then
  # Set up fzf key bindings and fuzzy completion
  source <(fzf --zsh)
fi
