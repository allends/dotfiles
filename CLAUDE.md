# allends/dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Each top-level directory is a stow package that maps to `$HOME`:

- `fish/` — Fish shell config (`~/.config/fish/config.fish`)
- `git/` — Git config and global ignore (`~/.gitconfig`, `~/.config/git/ignore`)
- `helix/` — Helix editor config (`~/.config/helix/`)
- `ssh/` — SSH config (`~/.ssh/config`)
- `claude/` — Claude Code settings (`~/.claude/settings.json`)
- `zed/` — Zed editor settings (`~/.config/zed/`)
- `zsh/` — Zsh config (legacy, kept for compatibility)

## Quick setup

```bash
# On a fresh machine:
curl -fsSL https://raw.githubusercontent.com/allends/dotfiles/main/setup.sh | bash

# Or manually:
git clone https://github.com/allends/dotfiles ~/dotfiles
cd ~/dotfiles
./setup.sh
```

## Agent instructions

When setting up a new machine with this repo:

1. Run `./setup.sh` — it handles Homebrew, packages, stow linking, and fish shell setup
2. If sudo is unavailable, install Homebrew to `~/.linuxbrew` and skip chsh (the script falls back to .bashrc auto-launch)
3. After setup, authenticate GitHub: `gh auth login`
4. SSH keys must be manually copied or generated — they are not in this repo

## Adding new configs

```bash
cd ~/dotfiles
mkdir -p newpkg/.config/newpkg
# Add config files mirroring their $HOME-relative paths
stow newpkg
```

## Key tools

All installed via `Brewfile`: fish, starship, zoxide, eza, bat, fzf, fd, ripgrep, helix, mise, lazygit, gh.
