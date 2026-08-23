export MOZ_ENABLE_WAYLAND=1

alias s="kitty +kitten ssh"

# User-installed command-line tools on Lucifer.
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"

export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# Kubernetes configuration and local command-name compatibility.
export KUBECONFIG="$HOME/Nextcloud/kubeconfig"
alias k=kubectl
alias bat=batcat

t() {
  "$HOME/code/dotfiles/bin/t" "$@"
}
