if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Add deno completions to search path
# (fish uses fish_complete_path, not FPATH)
if not contains /Users/allen/completions $fish_complete_path
    set -U fish_complete_path /Users/allen/completions $fish_complete_path
end

# custom scripts to path
fish_add_path -p $HOME/.local/bin

# mise en place (fish)
mise activate fish | source

# QOL aliases
alias ls="eza -la"
alias gsm="git checkout main && git pull"
alias tree="tre"
alias lg="lazygit"
alias cat="bat"
alias c="claude --dangerously-skip-permissions"

# Daily notes (zk)
source /Users/allen/dev/notes/.zk/daily-note.fish

# Init zoxide (interactive shells only)
if status is-interactive
    zoxide init --cmd cd fish | source
end

# Init Starship prompt
starship init fish | source

# PATH exports
fish_add_path -p /opt/homebrew/opt/postgresql@17/bin

# editor vars
set -gx EDITOR hx
set -gx VISUAL hx

# AWS / migration aliases
alias aws-qa="aws sso login --profile=QA"
alias aws-prod="aws sso login --profile=PRODUCTION"
alias migrate-qa="AWS_PROFILE=PRODUCTION DOPPLER_ENV=prd bun run db:migrate"
alias migrate-prod="AWS_PROFILE=PRODUCTION DOPPLER_ENV=prd bun run db:migrate"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
