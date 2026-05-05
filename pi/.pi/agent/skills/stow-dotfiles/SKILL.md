---
name: stow-dotfiles
description: Sync Allen's personal dotfiles with GNU Stow. Use whenever the user asks to sync, restow, add, capture, inspect, or update dotfiles/stow-managed configuration, especially Pi, shell, git, editor, Claude, SSH, Zed, Helix, Fish, or Zsh config. Knows the GitHub repo is allends/dotfiles at ~/dotfiles and how to safely apply packages to $HOME.
---

# Stow Dotfiles

Use this skill for Allen's GNU Stow-managed personal configuration.

## Repository Facts

- Local repo: `~/dotfiles`
- GitHub repo: `https://github.com/allends/dotfiles` (`allends/dotfiles`)
- Git remote should be `origin`.
- Stow target: `$HOME`
- Top-level directories are stow packages. Current known packages:
  - `fish` -> `~/.config/fish/...`
  - `git` -> `~/.gitconfig`, `~/.config/git/ignore`
  - `helix` -> `~/.config/helix/...`
  - `ssh` -> `~/.ssh/config` only; never add private keys
  - `claude` -> `~/.claude/settings.json`
  - `zed` -> `~/.config/zed/...`
  - `pi` -> `~/.pi/agent/settings.json`, `~/.pi/agent/models.json`, extensions, and skills
  - `zsh` -> legacy zsh files
- Bootstrap script: `~/dotfiles/setup.sh`
- Repo notes/instructions: `~/dotfiles/CLAUDE.md`

## Safety Rules

1. Start by checking repo state:
   ```bash
   cd ~/dotfiles
   git status --short --branch
   git remote -v
   ```
2. Do not overwrite uncommitted user changes. Inspect diffs before editing files that already changed:
   ```bash
   git diff -- <path>
   ```
3. Do not add secrets or machine-local runtime data. In particular, never track:
   - `~/.pi/agent/auth.json`, backups, or sessions
   - SSH private keys or known-hosts material beyond the tracked SSH config
   - shell history, tokens, credentials, cache files
4. Before applying Stow links, prefer a dry run when conflicts are possible:
   ```bash
   cd ~/dotfiles
   stow -nv --restow --target="$HOME" <packages>
   ```
   If the dry run reports conflicts, stop, explain the conflict, and ask before moving/removing files.
5. Use exact package names; do not stow `.git`, hidden directories, or random folders.

## Sync Workflow

When asked to "sync stow", "sync dotfiles", "restow", or similar:

1. Load the repo status and remotes:
   ```bash
   cd ~/dotfiles
   git status --short --branch
   git remote -v
   ```
2. If asked to sync with GitHub or if remote freshness matters, run:
   ```bash
   git fetch origin
   git status --short --branch
   ```
   - If local branch is behind and there are no conflicting local edits, use `git pull --ff-only`.
   - If local edits exist, do not pull/rebase without explaining the situation.
3. Determine packages to apply. Default full set:
   ```bash
   packages=(fish git helix ssh claude zed pi zsh)
   ```
   Or enumerate safe top-level package directories:
   ```bash
   find . -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print | sed 's#^./##' | sort
   ```
4. Dry run, then apply:
   ```bash
   stow -nv --restow --target="$HOME" "${packages[@]}"
   stow -v --restow --target="$HOME" "${packages[@]}"
   ```
5. Verify important symlinks and status:
   ```bash
   ls -la ~/.pi/agent ~/.gitconfig ~/.zshrc 2>/dev/null || true
   git status --short
   ```
6. Summarize what changed, including any files that remain modified/untracked in `~/dotfiles`.

## Capturing New Config with Stow

When the user asks to capture a config file into dotfiles:

1. Choose or create the stow package under `~/dotfiles`.
2. Mirror the target path relative to `$HOME`. Example for `~/.config/example/config.toml`:
   ```bash
   mkdir -p ~/dotfiles/example/.config/example
   mv ~/.config/example/config.toml ~/dotfiles/example/.config/example/config.toml
   cd ~/dotfiles
   stow -v --restow --target="$HOME" example
   ```
3. If the target already exists and is not a symlink, back it up or move it only after user approval.
4. Check `git status --short` and tell the user what should be committed.

## Pi Configuration Notes

- Pi global settings are stowed from `~/dotfiles/pi/.pi/agent/settings.json` to `~/.pi/agent/settings.json`.
- User-level Pi skills are stored in `~/dotfiles/pi/.pi/agent/skills/` and applied to `~/.pi/agent/skills/` by stowing package `pi`.
- If adding skills outside the default discovery path, update `~/dotfiles/pi/.pi/agent/settings.json` under `skills` so the skill is captured in configuration.
- After changing Pi skills/settings in an active Pi session, tell the user to run `/reload` if they want the current TUI to discover the new skill commands.
