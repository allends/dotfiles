if status is-interactive
    # Commands to run in interactive sessions can go here
end

function __dotfiles_add_path
    for path in $argv
        if test -d $path; and not contains -- $path $PATH
            set -gx PATH $path $PATH
        end
    end
end

# Homebrew — cached shellenv (avoid running brew shellenv on every shell)
if test (uname) = Darwin
    set -gx HOMEBREW_PREFIX /opt/homebrew
else
    set -gx HOMEBREW_PREFIX /home/linuxbrew/.linuxbrew
end
set -gx HOMEBREW_CELLAR $HOMEBREW_PREFIX/Cellar
set -gx HOMEBREW_REPOSITORY $HOMEBREW_PREFIX/Homebrew
__dotfiles_add_path $HOMEBREW_PREFIX/sbin $HOMEBREW_PREFIX/bin

# custom scripts to path
__dotfiles_add_path $HOME/.local/bin
__dotfiles_add_path $HOME/.npm-global/bin
__dotfiles_add_path $HOME/.bun/bin

# mise en place — shims mode (faster than hook-env activation)
__dotfiles_add_path $HOME/.local/share/mise/shims

# QOL aliases
alias ls="eza -la"
alias exa="eza"
alias gsm="git checkout main && git pull"
alias lg="lazygit"
alias cat="bat"
alias c="claude --dangerously-skip-permissions"
alias cde="zellij --layout claude"

# fnm (fast node manager)
if command -q fnm
    fnm env --use-on-cd --shell fish | source
end

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

# OpenAI API key from pi's extension auth.
if not set -q OPENAI_API_KEY
    set -l pi_openai_auth $HOME/.pi/agent/extensions/openai-api-key/auth.json
    if test -f $pi_openai_auth; and command -q python3
        set -l openai_api_key (python3 -c 'import json, sys; data = json.load(open(sys.argv[1])); print(data.get("openai-api-key", {}).get("apiKey") or data.get("openai", {}).get("apiKey") or "", end="")' $pi_openai_auth 2>/dev/null)
        if test -n "$openai_api_key"
            set -gx OPENAI_API_KEY $openai_api_key
        end
    end
end

# Greeting
set -g fish_greeting ""

# macOS-only
if test (uname) = Darwin
    __dotfiles_add_path /opt/homebrew/opt/postgresql@17/bin

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

# Multiplexers are available on demand; never auto-launch tmux or zellij.
functions -e __dotfiles_add_path

# Connect to the agency prod DB via lazysql.
# Spins up the kubectl port-forward proxy (scripts/db-gui-proxy.sh) in the
# background, waits for localhost:5435, then launches lazysql. Cleanup runs on
# normal return, on SIGINT/SIGTERM to the shell, and on shell exit — so the
# proxy is always torn down (its own bash trap then deletes the k8s job).
function agency-db-prod
    set -l scripts_dir $HOME/dev/agency/scripts
    set -l port 5435

    if not test -x $scripts_dir/db-gui-proxy.sh
        echo "db-gui-proxy.sh not found at $scripts_dir" >&2
        return 1
    end

    if not command -q lazysql
        echo "lazysql not found on PATH (install: brew install lazysql)" >&2
        return 1
    end

    # Kill leftover kubectl port-forwards on this port from previous runs,
    # otherwise nc -z passes instantly against a stale tunnel and the new
    # script's orphan cleanup rips the old pod out from under dblab.
    if pgrep -f "kubectl port-forward.*$port:5432" >/dev/null 2>&1
        echo "Killing stale kubectl port-forward on :$port..."
        pkill -f "kubectl port-forward.*$port:5432" 2>/dev/null
        while pgrep -f "kubectl port-forward.*$port:5432" >/dev/null 2>&1
            sleep 0.2
        end
    end

    pushd $scripts_dir >/dev/null
    ./db-gui-proxy.sh &
    set -g __agency_db_prod_proxy_pid $last_pid
    popd >/dev/null

    # Idempotent cleanup — safe to call multiple times.
    # Signals the proxy and waits briefly. The bash script's trap runs
    # `kubectl delete job --wait=true`, which can block for a while; we
    # cap our wait and let the rest finish in the background, since the
    # next invocation's `cleanup_orphan_pods` will mop up any residue.
    function __agency_db_prod_cleanup
        if set -q __agency_db_prod_proxy_pid; and test -n "$__agency_db_prod_proxy_pid"
            if kill -0 $__agency_db_prod_proxy_pid 2>/dev/null
                echo "Stopping DB proxy (pid $__agency_db_prod_proxy_pid)..."
                kill -INT $__agency_db_prod_proxy_pid 2>/dev/null
                set -l deadline (math (date +%s) + 3)
                while kill -0 $__agency_db_prod_proxy_pid 2>/dev/null
                    if test (date +%s) -ge $deadline
                        echo "Proxy still cleaning up in background; moving on." >&2
                        break
                    end
                    sleep 0.2
                end
            end
            set -e __agency_db_prod_proxy_pid
        end
    end

    # Per fish `trap` docs, trap wraps the event system. INT/TERM catch
    # signals delivered to the shell; EXIT covers the case where the shell
    # itself is closed while the proxy is still running.
    trap __agency_db_prod_cleanup INT TERM EXIT

    echo "Waiting for localhost:$port..."
    while not nc -z localhost $port 2>/dev/null
        if not kill -0 $__agency_db_prod_proxy_pid 2>/dev/null
            echo "Proxy exited before port was ready" >&2
            __agency_db_prod_cleanup
            return 1
        end
        sleep 1
    end

    set -l db_password (doppler run --config=prd --project=agency-data -- printenv RDS_PASSWORD)
    if test -z "$db_password"
        echo "Failed to fetch RDS_PASSWORD from Doppler" >&2
        __agency_db_prod_cleanup
        return 1
    end

    set -l encoded (printf '%s' "$db_password" | python3 -c 'import urllib.parse, sys; print(urllib.parse.quote(sys.stdin.read(), safe=""))')

    lazysql "postgres://chief:$encoded@localhost:$port/agency_core?sslmode=disable"

    __agency_db_prod_cleanup
end

# Start the reverse SSH tunnel from this MacBook to Fedora home.
# Equivalent to:
# ssh -N -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -R 2223:localhost:22 -p 2222 allen@71.105.200.114
alias home-tunnel="ssh -N home-reverse-tunnel"
alias home-tunnel-bg="ssh -fN home-reverse-tunnel"

# Load machine-local secrets that should not be committed.
if test -f ~/.config/fish/private.fish
    source ~/.config/fish/private.fish
end

# Hermes agent bridge
set -gx HERMES_BRIDGE_AGENT mbp-work
set -gx HERMES_BRIDGE_HOST home-vps-bastion
