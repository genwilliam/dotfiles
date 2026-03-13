#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OH_MY_ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}"
PROMPT_FLAVOR="${PROMPT_FLAVOR:-starship}"

log() {
	printf '\n==> %s\n' "$1"
}

link_path() {
	local source_path="$1"
	local target_path="$2"

	mkdir -p "$(dirname "$target_path")"
	ln -sfn "$source_path" "$target_path"
	printf 'linked %s -> %s\n' "$target_path" "$source_path"
}

clone_or_update_repo() {
	local repo_url="$1"
	local destination="$2"

	if [[ -d "$destination/.git" ]]; then
		git -C "$destination" pull --ff-only
	else
		git clone --depth=1 "$repo_url" "$destination"
	fi
}

install_homebrew() {
	log "Installing Homebrew if needed"

	if ! command -v brew >/dev/null 2>&1; then
		NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi

	if command -v brew >/dev/null 2>&1; then
		eval "$("$(command -v brew)" shellenv)"
	elif [[ -x /opt/homebrew/bin/brew ]]; then
		eval "$(/opt/homebrew/bin/brew shellenv)"
	elif [[ -x /usr/local/bin/brew ]]; then
		eval "$(/usr/local/bin/brew shellenv)"
	else
		echo "Homebrew installation failed" >&2
		exit 1
	fi
}

install_packages() {
	log "Installing packages from Brewfile"
	brew bundle --file="$DOTFILES/Brewfile"
}

install_oh_my_zsh() {
	log "Installing Oh My Zsh if needed"

	if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
		RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	fi
}

install_zsh_plugins() {
	log "Installing custom Zsh plugins"

	mkdir -p "$ZSH_CUSTOM_DIR/plugins" "$ZSH_CUSTOM_DIR/themes"

	clone_or_update_repo "https://github.com/zsh-users/zsh-autosuggestions.git" \
		"$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
	clone_or_update_repo "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" \
		"$ZSH_CUSTOM_DIR/plugins/fast-syntax-highlighting"
	clone_or_update_repo "https://github.com/Aloxaf/fzf-tab.git" \
		"$ZSH_CUSTOM_DIR/plugins/fzf-tab"
	clone_or_update_repo "https://github.com/MichaelAquilina/zsh-you-should-use.git" \
		"$ZSH_CUSTOM_DIR/plugins/you-should-use"
	clone_or_update_repo "https://github.com/zthxxx/zsh-history-enquirer.git" \
		"$ZSH_CUSTOM_DIR/plugins/zsh-history-enquirer"

	if [[ "$PROMPT_FLAVOR" == "p10k" ]]; then
		clone_or_update_repo "https://github.com/romkatv/powerlevel10k.git" \
			"$ZSH_CUSTOM_DIR/themes/powerlevel10k"
	fi
}

link_dotfiles() {
	log "Linking dotfiles"

	mkdir -p "$HOME/.config" "$HOME/.local/bin"

	link_path "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"
	link_path "$DOTFILES/git/gitignore_global" "$HOME/.gitignore_global"

	link_path "$DOTFILES/zsh/zshenv" "$HOME/.zshenv"
	link_path "$DOTFILES/zsh/zprofile" "$HOME/.zprofile"
	link_path "$DOTFILES/zsh/zshrc" "$HOME/.zshrc"
	link_path "$DOTFILES/zsh/zshrc.d" "$HOME/.zshrc.d"

	link_path "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"
	link_path "$DOTFILES/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"

	link_path "$DOTFILES/nvim" "$HOME/.config/nvim"

	if [[ -f "$DOTFILES/starship.toml" ]]; then
		link_path "$DOTFILES/starship.toml" "$HOME/.config/starship.toml"
	fi

	if [[ "$PROMPT_FLAVOR" == "p10k" ]]; then
		link_path "$DOTFILES/p10k/p10k.zsh" "$HOME/.p10k.zsh"
	fi

	if [[ -d "$DOTFILES/bin" ]]; then
		while IFS= read -r script_path; do
			link_path "$script_path" "$HOME/.local/bin/$(basename "$script_path")"
		done < <(find "$DOTFILES/bin" -maxdepth 1 -type f)
	fi
}

print_next_steps() {
	log "Setup complete"
	printf 'Prompt flavor: %s\n' "$PROMPT_FLAVOR"
	printf 'Run: source ~/.zshrc\n'
}

install_homebrew
install_packages
install_oh_my_zsh
install_zsh_plugins
link_dotfiles
print_next_steps

