#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for allends/dotfiles
# Usage: curl -fsSL https://raw.githubusercontent.com/allends/dotfiles/main/setup.sh | bash
# Or:    git clone https://github.com/allends/dotfiles ~/dotfiles && ~/dotfiles/setup.sh

DOTFILES="$HOME/dotfiles"

echo "==> allends/dotfiles setup"

# ---------- 1. Clone if not already present ----------
if [ ! -d "$DOTFILES" ]; then
    echo "==> Cloning dotfiles..."
    git clone https://github.com/allends/dotfiles "$DOTFILES"
fi

cd "$DOTFILES"

# ---------- 2. Install Homebrew ----------
# A fresh terminal may not have loaded Homebrew's shell environment yet.
if ! command -v brew &>/dev/null; then
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
        eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
    fi
fi
if ! command -v brew &>/dev/null; then
    echo "==> Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to current shell PATH
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
fi

echo "==> Brew found at $(which brew)"

# ---------- 3. Install packages from Brewfile ----------
echo "==> Installing Brewfile packages..."
brew bundle install --file="$DOTFILES/Brewfile"

# ---------- 4. Stow dotfiles ----------
echo "==> Linking dotfiles with stow..."
cd "$DOTFILES"
for dir in zsh git helix ssh claude zed pi zellij; do
    if [ -d "$dir" ]; then
        echo "    stow $dir"
        stow -v --restow --target="$HOME" "$dir"
    fi
done

# ---------- 5. Use Zsh as the default shell ----------
# macOS ships /bin/zsh and already lists it in /etc/shells.
if [ "$(uname -s)" = Darwin ]; then
    ZSH_PATH=/bin/zsh
    LOGIN_SHELL="$(dscl . -read "/Users/$(id -un)" UserShell | awk '{print $2}')"
else
    ZSH_PATH="$(command -v zsh)"
    LOGIN_SHELL="$(getent passwd "$(id -un)" | cut -d: -f7)"
fi

if [ "${LOGIN_SHELL##*/}" != zsh ]; then
    if ! grep -qxF "$ZSH_PATH" /etc/shells; then
        printf '%s\n' "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    echo "==> Setting Zsh as default shell..."
    chsh -s "$ZSH_PATH"
fi

# ---------- 6. Setup gh auth (interactive) ----------
if command -v gh &>/dev/null && ! gh auth status &>/dev/null 2>&1; then
    echo "==> GitHub CLI not authenticated. Run 'gh auth login' to set up."
fi

echo ""
echo "==> Done! Open a new terminal or run 'zsh' to get started."
