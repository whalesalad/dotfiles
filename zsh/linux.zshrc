export PATH="/home/michael/.local/bin:$PATH"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# macOS-compatible clipboard commands for Wayland and X11.
pbcopy() {
  if [[ -n "$WAYLAND_DISPLAY" ]] && (( $+commands[wl-copy] )); then
    command wl-copy "$@"
  elif [[ -n "$DISPLAY" ]] && (( $+commands[xclip] )); then
    command xclip -selection clipboard "$@"
  else
    print -u2 "pbcopy: no graphical clipboard available (need wl-copy on Wayland or xclip on X11)"
    return 1
  fi
}

pbpaste() {
  if [[ -n "$WAYLAND_DISPLAY" ]] && (( $+commands[wl-paste] )); then
    command wl-paste --no-newline "$@"
  elif [[ -n "$DISPLAY" ]] && (( $+commands[xclip] )); then
    command xclip -selection clipboard -o "$@"
  else
    print -u2 "pbpaste: no graphical clipboard available (need wl-paste on Wayland or xclip on X11)"
    return 1
  fi
}
