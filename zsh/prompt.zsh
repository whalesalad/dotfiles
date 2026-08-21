# Preserve Agnoster's prompt while skipping unused, synchronous VCS probes.
# Mercurial and Bazaar startup checks noticeably delay every prompt redraw.
if [[ "${ZSH_THEME:-}" == "agnoster" ]] && (( $+functions[build_prompt] )); then
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
