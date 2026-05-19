# Completion behavior and keybinding
# zstyle ':completion:*' menu no
zstyle ':completion:*' menu select

# Keep Tab on standard completion (do not use fzf-tab behavior)
# bindkey '^I' expand-or-complete

# rules: ignore case, ignore separators (.-_)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'

# 中文路径友好
zstyle ':completion:*' file-sort modification
if [[ -n "${LS_COLORS:-}" ]]; then
	zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
fi

autoload -Uz compinit
if (( ! ${+_comps} )); then
	compinit -C -d "$ZSH_COMPDUMP"
fi
	# Completion init strategy (default = A)
	# A) Default (recommended): compinit -C -d
	#    Prioritizes startup speed by using the dump cache;
	#    suitable for day-to-day use on personal machines.
	# B) More conservative: full check on first run, cache afterward.
	#    if [[ ! -s "$ZSH_COMPDUMP" ]]; then
	#      compinit -d "$ZSH_COMPDUMP"
	#    else
	#      compinit -C -d "$ZSH_COMPDUMP"
	#    fi
	# C) Aggressive mode: skip security checks
	#    (use at your own risk; not recommended as default).
	#    compinit -u -C -d "$ZSH_COMPDUMP"
	#    Note: this may suppress warnings for insecure directory
	#    permissions and can increase completion script injection risk.


