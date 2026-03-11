if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Homebrew — cached shellenv (avoid running brew shellenv on every shell)
set -gx HOMEBREW_PREFIX /opt/homebrew
set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
set -gx HOMEBREW_REPOSITORY /opt/homebrew
fish_add_path -gP /opt/homebrew/bin /opt/homebrew/sbin

# custom scripts to path
fish_add_path -p $HOME/.local/bin
fish_add_path -p $HOME/.npm-global/bin
fish_add_path -p $HOME/.bun/bin

# mise en place — shims mode (faster than hook-env activation)
fish_add_path -p ~/.local/share/mise/shims

# QOL aliases
alias ls="eza -la"
alias gsm="git checkout main && git pull"
alias lg="lazygit"
alias cat="bat"
alias c="claude --dangerously-skip-permissions"
alias cde="zellij --layout claude"

# Init zoxide (interactive shells only)
if status is-interactive; and command -q zoxide
    zoxide init --cmd cd fish | source
end

# fzf key bindings (Ctrl+R for history, Ctrl+T for files)
if command -q fzf
    fzf --fish | source
end

# Init Starship prompt
if command -q starship
    starship init fish | source
end

# editor vars
set -gx EDITOR hx
set -gx VISUAL hx
set -gx BUN_INSTALL $HOME/.bun

# Greeting
set -g fish_greeting ""

# macOS-only
if test (uname) = Darwin
    fish_add_path -p /opt/homebrew/opt/postgresql@17/bin

    alias aws-qa="aws sso login --profile=QA"
    alias aws-prod="aws sso login --profile=PRODUCTION"
    alias aws-infra="aws sso login --profile=INFRA"
    alias migrate-qa="AWS_PROFILE=PRODUCTION DOPPLER_ENV=prd bun run db:migrate"
    alias migrate-prod="AWS_PROFILE=PRODUCTION DOPPLER_ENV=prd bun run db:migrate"

    # OrbStack
    source ~/.orbstack/shell/init2.fish 2>/dev/null; or :

    # Daily notes (zk)
    if test -f $HOME/dev/notes/.zk/daily-note.fish
        source $HOME/dev/notes/.zk/daily-note.fish
    end

    # Deno completions
    if not contains $HOME/completions $fish_complete_path
        set -U fish_complete_path $HOME/completions $fish_complete_path
    end
end
