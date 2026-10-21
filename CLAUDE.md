# allends/dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Each top-level directory is a stow package that maps to `$HOME`:

- `zsh/` — Zsh login and interactive shell config (`~/.zprofile`, `~/.zshenv`, `~/.zshrc`)
- `git/` — Git config and global ignore (`~/.gitconfig`, `~/.config/git/ignore`)
- `helix/` — Helix editor config (`~/.config/helix/`)
- `ssh/` — SSH config (`~/.ssh/config`)
- `claude/` — Claude Code settings (`~/.claude/settings.json`)
- `zed/` — Zed editor settings (`~/.config/zed/`)
- `pi/` — Pi agent config (`~/.pi/agent/{settings,models}.json`, `~/.pi/agent/extensions/`). Auth tokens, sessions, and backups stay local and are not tracked.
- `fish/` — Archived Fish config; not installed or linked by setup
- `zellij/` — Zellij layouts (`~/.config/zellij/layouts/`)

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

`setup.sh` works out of the box. Homebrew installs to `/opt/homebrew`, `setup.sh` keeps or selects Zsh as the login shell, and Brewfile casks (zed, 1password, orbstack, keepingyouawake) install normally. Obsidian and its notesmd-cli tooling are excluded. Install Apple’s Command Line Tools first (`xcode-select --install`) if Git is not yet available.

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
- **Brewfile casks**: The macOS-only casks (zed, 1password, orbstack, keepingyouawake) are silently skipped on Linux.
- **Zsh shell**: Setup keeps an existing Zsh login shell. If another shell is configured, `chsh` selects Zsh and may prompt for your password. On Linux, adding a new Zsh path to `/etc/shells` requires sudo. Fish is not installed, linked, or launched.
- **Outdated Homebrew**: If Homebrew was previously installed but is old, run `brew update` before `setup.sh` to avoid compatibility issues with `brew bundle`.
- **SSH keys**: The `ssh/` stow package only links `~/.ssh/config`. Existing keys in `~/.ssh/` are not touched and must be copied or generated manually.

## Agent instructions

When setting up a new machine with this repo:

1. On Linux, install build dependencies and back up any conflicting dotfiles first (see platform notes above)
2. Run `./setup.sh` — it handles Homebrew, packages, stow linking, and Zsh shell setup
3. If sudo is unavailable, install Homebrew to `~/.linuxbrew` and set Zsh as your login shell manually when administrator access becomes available
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

All installed via `Brewfile`: zsh, starship, zoxide, eza, bat, fzf, fd, ripgrep, helix, mise, lazygit, gh, zk, tre-command.

The default setup excludes Fish, Obsidian, and notesmd-cli; no Obsidian tap is needed.
