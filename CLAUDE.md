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
- `pi/` — Pi agent config (`~/.pi/agent/{settings,models}.json`, `~/.pi/agent/extensions/`). Auth tokens, sessions, and backups stay local and are not tracked.
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

On Windows, run PowerShell as your normal user:

```powershell
git clone https://github.com/allends/dotfiles "$HOME\dotfiles"
& "$HOME\dotfiles\setup.ps1"
```

Ghostty does not publish an official native Windows build. To explicitly install
the community `winghostty` port, pass `-IncludeCommunityGhostty`.

## Platform notes

### Windows

`setup.ps1` uses Winget to install or update Bun, Git, GitHub CLI, PowerShell,
Windows Terminal, Starship, Zoxide, eza, bat, fzf, fd, ripgrep, Helix, mise, and
lazygit. It installs TypeScript language tooling with Bun and copies Windows-safe
PowerShell, Helix, Ghostty, and Git configuration into the user profile. When an
Ubuntu WSL distribution is present, it also keeps it on WSL2 and configures a
Bun/TypeScript-focused Linux development shell. Pass `-SkipWSL` to omit that step.

The Ghostty-compatible config is written to winghostty's native Windows path,
`%LOCALAPPDATA%\winghostty\config.ghostty`. It launches Ubuntu WSL2 in the Linux
home directory by default. A `Ghostty` Start-menu shortcut is created because the
community port's package-owned shortcut is named `winghostty`.

Fish and Zellij remain Unix-only in this repository. The Windows profile uses
PowerShell with the same prompt and navigation tools instead. Existing config
files are backed up with a `.backup` suffix before replacement.

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

- Run independent checks, installations, and validations asynchronously or in parallel when doing so materially reduces elapsed time. Keep dependent, interactive, or destructive operations ordered, and verify completion before starting work that relies on them.

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
