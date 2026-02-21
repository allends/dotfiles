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

## Platform notes

### macOS

`setup.sh` works out of the box. Homebrew installs to `/opt/homebrew`, `chsh` sets fish as the login shell, and Brewfile casks (zed, obsidian, 1password, orbstack) install normally.

### Linux (Fedora / RHEL-based)

Homebrew installs to `/home/linuxbrew/.linuxbrew`. A few things to handle before or during setup:

- **Build dependencies**: Homebrew on Linux needs a C compiler and related tools. On Fedora, ensure they're present:
  ```bash
  sudo dnf groupinstall -y "Development Tools"
  sudo dnf install -y procps-ng curl file git
  ```
- **Existing config files**: Stow will fail if target files already exist as regular files (not symlinks). Before running `setup.sh`, back up and remove any conflicting files:
  ```bash
  mkdir -p ~/dotfiles-backup
  # Move any that exist — common conflicts:
  [ -f ~/.gitconfig ] && mv ~/.gitconfig ~/dotfiles-backup/
  [ -d ~/.config/helix ] && mv ~/.config/helix ~/dotfiles-backup/helix
  [ -f ~/.claude/settings.json ] && mv ~/.claude/settings.json ~/dotfiles-backup/claude-settings.json
  ```
- **Brewfile casks**: The macOS-only casks (zed, obsidian, 1password, orbstack) are silently skipped on Linux.
- **Fish shell**: `chsh` requires sudo. If sudo is unavailable or prompts for a password non-interactively, the script falls back to adding an `exec fish` block to `~/.bashrc` so fish launches automatically for interactive sessions.
- **Outdated Homebrew**: If Homebrew was previously installed but is old, run `brew update` before `setup.sh` to avoid compatibility issues with `brew bundle`.
- **SSH keys**: The `ssh/` stow package only links `~/.ssh/config`. Existing keys in `~/.ssh/` are not touched and must be copied or generated manually.

## Agent instructions

When setting up a new machine with this repo:

1. On Linux, install build dependencies and back up any conflicting dotfiles first (see platform notes above)
2. Run `./setup.sh` — it handles Homebrew, packages, stow linking, and fish shell setup
3. If sudo is unavailable, install Homebrew to `~/.linuxbrew` and skip chsh (the script falls back to .bashrc auto-launch)
4. After setup, authenticate GitHub: `gh auth login`
5. SSH keys must be manually copied or generated — they are not in this repo

## Adding new configs

```bash
cd ~/dotfiles
mkdir -p newpkg/.config/newpkg
# Add config files mirroring their $HOME-relative paths
stow newpkg
```

## Key tools

All installed via `Brewfile`: fish, starship, zoxide, eza, bat, fzf, fd, ripgrep, helix, mise, lazygit, gh, notesmd-cli, zk, tre-command.

The Brewfile uses the `yakitrak/yakitrak` tap for `notesmd-cli`.
