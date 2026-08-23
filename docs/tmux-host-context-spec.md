# Tmux Host Context

## Decision

Make the tmux status bar use the same deterministic hostname identity as the
Agnoster prompt. Extract hostname color selection into a shared helper so both
consumers always map a host to the same approved 256-color foreground.

## Display Rules

| Current user | `status-left` identity |
| --- | --- |
| `michael` | `hostname` |
| Any other user | `user@hostname` |

The hostname is always present. The complete visible identity uses the
host-derived bright foreground on tmux's existing `colour235` status
background.

## Shared Color Helper

- Add `bin/host-color`, which accepts a hostname and prints one xterm 256-color
  index followed by a newline.
- Normalize input to the lowercased short hostname before hashing it with POSIX
  `cksum`.
- Select from the approved palette: `196`, `197`, `198`, `201`, `202`, `208`,
  `214`, `220`, `135`, `39`, `45`, and `82`.
- Use bright orange (`208`) when input is empty, `cksum` is unavailable, or its
  output is invalid.
- Keep the helper independent of zsh and tmux presentation details.

## Integration

- Replace the inline hashing in `zsh/prompt.zsh` with one helper invocation at
  shell startup while retaining the local fallback color.
- Replace tmux's green `user@host` status-left value with a native tmux format
  that suppresses `michael@` and always includes `#{host_short}`.
- Use tmux's `#()` status command expansion to obtain the shared color. It runs
  on the existing 15-second status interval alongside the current system
  metric commands.
- Keep host-specific files under `tmux/hosts/` unchanged.

## Failure Behavior

If the helper is absent or produces no usable output, zsh uses orange `208`.
The tmux status must continue showing an uncolored hostname rather than hiding
the identity or displaying command errors.

## Verification

- Test helper normalization, deterministic selection, palette membership,
  representative host distinction, and fallback behavior.
- Retain the existing zsh prompt behavior tests using the shared helper.
- Parse the shared configuration in an isolated tmux server.
- Verify tmux expands the username condition correctly for `michael` and a
  representative different username.
- Verify the resolved local status-left always contains the short hostname and
  uses the helper's expected foreground color.
- Run zsh syntax checks and all affected test scripts.
