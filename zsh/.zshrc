# Add deno completions to search path
if [[ ":$FPATH:" != *":/Users/allen/completions:"* ]]; then export FPATH="/Users/allen/completions:$FPATH"; fi

# custom scripts to path
export PATH="$HOME/.local/bin:$PATH"

# Load `config` helper so config reload/open runs in the current shell
if [[ -f "$HOME/.local/bin/config" ]]; then
    source "$HOME/.local/bin/config"
fi

# Worktree manager wrapper - handles directory changes
wt() {
  case "$1" in
    new|move)
      # Use a temp file to capture the path
      local tmpfile="/tmp/wt-path-$$"

      # Run the command directly (not in subshell) and redirect output to temp file
      "$HOME/.local/bin/wt" "$@" > "$tmpfile"
      local exit_code=$?

      if [[ $exit_code -eq 0 && -s "$tmpfile" ]]; then
        local path=$(tail -n 1 "$tmpfile")
        rm -f "$tmpfile"
        if [[ -d "$path" ]]; then
          cd "$path"
        fi
      else
        rm -f "$tmpfile"
        return $exit_code
      fi
      ;;
    *)
      # For other commands (list, clean, help), run normally
      "$HOME/.local/bin/wt" "$@"
      ;;
  esac
}

# mise en place
eval "$(mise activate zsh)"

# QOL alias
alias ls="eza -la"
alias gsm="git checkout main && git pull"
alias tree="tre"
alias lg="lazygit"
alias cat="bat"

# Init zoxide to jump directories
if [[ $- == *i* ]]; then
  # Use `z` command (recommended; don't override cd)
  eval "$(zoxide init zsh --cmd cd)"
fi

# Init StarShip prompt
eval "$(starship init zsh)"

# PATH exports
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

export EDITOR="hx"
export VISUAL="hx"

alias aws-qa="aws sso login --profile=QA"
alias aws-prod="aws sso login --profile=PRODUCTION"
alias migrate-qa="AWS_PROFILE=PRODUCTION DOPPLER_ENV=prd bun run db:migrate"
alias migrate-prod="AWS_PROFILE=PRODUCTION DOPPLER_ENV=prd bun run db:migrate"
. "/Users/allen/.deno/env"
# Initialize zsh completions (added by deno install script)
autoload -Uz compinit
compinit

# bun completions
[ -s "/Users/allen/.bun/_bun" ] && source "/Users/allen/.bun/_bun"
