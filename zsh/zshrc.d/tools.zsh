# Tool initialization 
# initialize only once to avoid repeated eval

# starship begin
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
# starship end

# mise begin (optional hook; shims path is configured in ~/.zshenv)
# if command -v mise >/dev/null 2>&1; then
#   : "${MISE_SHELL_ACTIVATE:=0}"
#   if [[ "$MISE_SHELL_ACTIVATE" == "1" ]]; then
#     eval "$(mise activate zsh)"
#   fi
# fi
# mise end

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
