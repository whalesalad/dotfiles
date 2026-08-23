# Preserve Agnoster's prompt while skipping unused, synchronous VCS probes.
# Mercurial and Bazaar startup checks noticeably delay every prompt redraw.
if [[ "${ZSH_THEME:-}" == "agnoster" ]] && (( $+functions[build_prompt] )); then
  typeset -g AGNOSTER_HOST_COLOR_COMMAND="${${(%):-%N}:A:h:h}/bin/host-color"

  # Resolve the shared host color once at shell startup. Keep a local fallback
  # so a missing or broken helper can never prevent prompt rendering.
  _agnoster_host_foreground() {
    local color

    if [[ -x "$AGNOSTER_HOST_COLOR_COMMAND" ]]; then
      color=$("$AGNOSTER_HOST_COLOR_COMMAND" "$1" 2>/dev/null) || color=''
    fi

    if [[ "$color" == <-> ]] && (( color >= 0 && color <= 255 )); then
      REPLY=$color
    else
      REPLY=208
    fi
  }

  # Return the Agnoster prompt escape for the requested user. The hostname is
  # always present; michael is omitted because that username is implied.
  _agnoster_context_text() {
    local username="$1"

    if [[ "$username" == "michael" ]]; then
      REPLY='%m'
    else
      REPLY='%n@%m'
    fi
  }

  typeset -g AGNOSTER_CONTEXT_HOST_FG
  _agnoster_host_foreground "${HOST%%.*}"
  AGNOSTER_CONTEXT_HOST_FG=$REPLY

  prompt_context() {
    local context

    _agnoster_context_text "$USERNAME"
    context=$REPLY
    prompt_segment "$AGNOSTER_CONTEXT_BG" "$AGNOSTER_CONTEXT_HOST_FG" "$context"
  }

  build_prompt() {
    RETVAL=$?
    prompt_status
    prompt_virtualenv
    prompt_aws
    prompt_terraform
    prompt_context
    prompt_dir
    prompt_git
    prompt_end
  }
fi
