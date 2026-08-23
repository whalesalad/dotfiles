# Preserve Agnoster's prompt while skipping unused, synchronous VCS probes.
# Mercurial and Bazaar startup checks noticeably delay every prompt redraw.
if [[ "${ZSH_THEME:-}" == "agnoster" ]] && (( $+functions[build_prompt] )); then
  # Pick a stable, high-contrast foreground from the short hostname. Keep the
  # palette intentionally bright so every entry remains legible on dark themes.
  _agnoster_host_foreground() {
    local normalized_host="${(L)${1%%.*}}"
    local checksum_output checksum
    local -a palette=(196 197 198 201 202 208 214 220 135 39 45 82)

    if (( $+commands[cksum] )); then
      checksum_output=$(print -rn -- "$normalized_host" | command cksum 2>/dev/null) || checksum_output=''
      checksum=${checksum_output%%[[:space:]]*}
    fi

    if [[ "$checksum" == <-> ]]; then
      REPLY=${palette[$((checksum % ${#palette} + 1))]}
    else
      REPLY=208
    fi
  }

  # Return the Agnoster prompt escape for the requested user/session. A local
  # shell as michael has no context segment; SSH still shows the destination.
  _agnoster_context_text() {
    local username="$1"
    local ssh_client="$2"

    if [[ "$username" == "michael" ]]; then
      [[ -n "$ssh_client" ]] || return 1
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

    if _agnoster_context_text "$USERNAME" "${SSH_CLIENT:-}"; then
      context=$REPLY
      prompt_segment "$AGNOSTER_CONTEXT_BG" "$AGNOSTER_CONTEXT_HOST_FG" "$context"
    fi
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
