# Agnoster Prompt Performance

## Decision

Keep the Agnoster prompt and its Git status segment, but omit its synchronous
Mercurial and Bazaar probes. The override lives in `zsh/prompt.zsh` and is
loaded after Oh My Zsh initializes the theme.

## Acceptance

- The prompt retains its existing appearance and Git branch/status display.
- Prompt rendering does not invoke `prompt_hg` or `prompt_bzr`.
- The configuration passes `zsh -n` and works both with and without Oh My Zsh.
