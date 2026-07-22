#!/usr/bin/env bash
set -euo pipefail

mode="${1:---user}"

if [[ "$mode" == "--system" ]]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get upgrade -y
    apt-get install -y build-essential ca-certificates curl file fish git procps stow unzip
    apt-get autoremove -y
    apt-get clean
    install -m 0644 "$script_dir/wsl.conf" /etc/wsl.conf
    exit 0
fi

source_root="${2:-}"
dotfiles="$HOME/dotfiles"

if [[ -n "$source_root" ]]; then
    if [[ "$source_root" == /* ]]; then
        source_linux="$source_root"
    else
        source_linux="$(wslpath -a "$source_root")"
    fi
fi

if [[ ! -d "$dotfiles/.git" ]]; then
    if [[ -n "${source_linux:-}" ]]; then
        git clone "$source_linux" "$dotfiles"
    else
        git clone https://github.com/allends/dotfiles "$dotfiles"
    fi
elif [[ -n "${source_linux:-}" ]]; then
    source_branch="$(git -C "$source_linux" branch --show-current)"
    git -C "$dotfiles" fetch "$source_linux" "$source_branch"
    git -C "$dotfiles" merge --ff-only FETCH_HEAD
else
    git -C "$dotfiles" pull --ff-only
fi

if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Prefer Ubuntu's actively maintained trust store. This also avoids stale
# Homebrew CA bundles breaking GitHub access on upgraded, long-lived distros.
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export CURL_CA_BUNDLE="$SSL_CERT_FILE"
git config --global http.sslCAInfo /etc/ssl/certs/ca-certificates.crt

if ! brew update; then
    brew update-reset
    brew update
fi
NONINTERACTIVE=1 brew install fish starship zoxide eza bat fzf fd ripgrep gh git stow lazygit zellij helix

if [[ ! -x "$HOME/.bun/bin/bun" ]]; then
    curl -fsSL https://bun.sh/install | bash
fi
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
bun upgrade
bun add --global typescript typescript-language-server

cd "$dotfiles"
for package in fish helix; do
    while IFS= read -r -d '' source_file; do
        relative_path="${source_file#"$dotfiles/$package/"}"
        target_file="$HOME/$relative_path"
        if [[ -e "$target_file" && ! -L "$target_file" ]]; then
            backup_file="$target_file.pre-dotfiles-backup"
            if [[ ! -e "$backup_file" ]]; then
                cp -a -- "$target_file" "$backup_file"
            fi
            rm -f -- "$target_file"
        fi
    done < <(find "$dotfiles/$package" -type f -print0)
    stow --restow --target="$HOME" "$package"
done

# Older WSL installs used this one-line zsh hook. Fish is the default shell,
# but remove the hook too so falling back to zsh never starts tmux implicitly.
if [[ -f "$HOME/.zshrc" ]]; then
    sed -i '/^if \[ "\$TMUX" = "" \]; then tmux; fi$/d' "$HOME/.zshrc"
fi
if [[ -f "$HOME/.zshenv" ]]; then
    sed -i '/^\. "\$HOME\/\.cargo\/env"$/d' "$HOME/.zshenv"
fi

git config --global user.name 'Allen Davis-Swing'
git config --global user.email 'allen.davisswing@gmail.com'
git config --global core.editor hx
git config --global core.excludesFile "$dotfiles/git/.config/git/ignore"
git config --global push.autoSetupRemote true
git config --global commit.gpgsign false
git config --global alias.st 'status --short --branch'
git config --global alias.co checkout
git config --global alias.ci commit
git config --global alias.br branch
git config --global alias.unstage 'reset HEAD --'

echo '==> WSL2 development setup complete.'
