# Homebrew on Apple Silicon.
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# OrbStack adds its shell integration after installation.
if [[ -r "$HOME/.orbstack/shell/init.zsh" ]]; then
    source "$HOME/.orbstack/shell/init.zsh"
fi
