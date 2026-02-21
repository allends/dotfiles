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
brew bundle install --file="$DOTFILES/Brewfile" || true

# ---------- 4. Stow dotfiles ----------
echo "==> Linking dotfiles with stow..."
cd "$DOTFILES"
for dir in fish git helix ssh claude zed; do
    if [ -d "$dir" ]; then
        echo "    stow $dir"
        stow -v --restow --target="$HOME" "$dir" 2>&1 || true
    fi
done

# ---------- 5. Set fish as default shell ----------
FISH_PATH="$(which fish 2>/dev/null || true)"
if [ -n "$FISH_PATH" ]; then
    # Add fish to /etc/shells if not already there (requires sudo)
    if ! grep -qF "$FISH_PATH" /etc/shells 2>/dev/null; then
        echo "==> Adding fish to /etc/shells (needs sudo)..."
        echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null 2>&1 || true
    fi

    # Change default shell if possible
    if command -v chsh &>/dev/null; then
        echo "==> Setting fish as default shell..."
        sudo chsh -s "$FISH_PATH" "$(whoami)" 2>/dev/null || true
    fi

    # Fallback: add fish exec to .bashrc if chsh failed
    if [ "$(getent passwd "$(whoami)" | cut -d: -f7)" != "$FISH_PATH" ]; then
        if ! grep -q "exec fish" "$HOME/.bashrc" 2>/dev/null; then
            echo "==> Adding fish auto-launch to .bashrc (no sudo for chsh)..."
            cat >> "$HOME/.bashrc" <<'BASH'

# Launch fish for interactive sessions
if [ -t 1 ] && [ -z "$FISH_LAUNCHED" ] && command -v fish >/dev/null 2>&1; then
    export FISH_LAUNCHED=1
    exec fish
fi
BASH
        fi
    fi
fi

# ---------- 6. Setup gh auth (interactive) ----------
if command -v gh &>/dev/null && ! gh auth status &>/dev/null 2>&1; then
    echo "==> GitHub CLI not authenticated. Run 'gh auth login' to set up."
fi

echo ""
echo "==> Done! Open a new terminal or run 'fish' to get started."
