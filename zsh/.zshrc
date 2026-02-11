eval "$(fnm env --use-on-cd)"
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"
export JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk-11.jdk/Contents/Home

alias ls="exa -la"
alias fcc="code ~/d/w/fe"
alias be="code ~/d/w/be"

export PATH=${PATH}:`go env GOPATH`/bin

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/allen/d/p/python/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/allen/d/p/python/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/allen/d/p/python/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/allen/d/p/python/google-cloud-sdk/completion.zsh.inc'; fi

# bit
case ":$PATH:" in
  *":/Users/allen/bin:"*) ;;
  *) export PATH="$PATH:/Users/allen/bin" ;;
esac
# bit end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/allen/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/allen/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/allen/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/allen/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH="/usr/local/mysql/bin:$PATH"


# pnpm
export PNPM_HOME="/Users/allen/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH="$HOME/.local/bin:$PATH"
