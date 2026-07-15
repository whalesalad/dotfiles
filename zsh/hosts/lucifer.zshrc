export MOZ_ENABLE_WAYLAND=1

alias s="kitty +kitten ssh"

export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

t() {
  "$HOME/code/dotfiles/bin/t" "$@"
}
