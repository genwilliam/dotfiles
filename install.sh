#!/usr/bin/env bash

set -e

DOTFILES="$HOME/dotfiles"

echo "🔧 Installing Homebrew..."

if ! command -v brew &>/dev/null; then
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Apple Silicon path

eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "📦 Installing packages from Brewfile..."
brew bundle --file="$DOTFILES/Brewfile"

echo "🔗 Linking configs..."

ln -sf "$DOTFILES/git/.gitignore_global" "$HOME/.gitignore_global"
ln -sf "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES/zsh/.zshrc.d" "$HOME/.zshrc.d"

ln -sf "$DOTFILES/git/.gitconfig" "$HOME/.gitconfig"

ln -sf "$DOTFILES/config" "$HOME/.config"

echo "✅ Setup complete!"

