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
