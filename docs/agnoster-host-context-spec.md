# Agnoster Host Context

## Decision

Make remote hosts visually distinct in the Agnoster prompt by assigning the
context text a deterministic bright foreground color derived from the short
hostname. Keep the context segment's existing dark background. Keep the
implementation in `zsh/prompt.zsh`, alongside the existing Agnoster override,
and compute the color once when the shell starts.

## Display Rules

| Session | Current user | Context segment |
| --- | --- | --- |
| Local | `michael` | Hidden |
| SSH | `michael` | `hostname` |
| Local or SSH | Any other user | `user@hostname` |

The literal username `michael` is omitted because it is implied. The complete
visible context string uses the host-derived foreground color on Agnoster's
existing dark context background.

## Color Selection

- Hash the lowercased short hostname with POSIX `cksum`.
- Use the checksum to select from this curated foreground palette of bright
  xterm 256-color indexes: `196`, `197`, `198`, `201`, `202`, `208`, `214`,
  `220`, `135`, `39`, `45`, and `82`.
- The palette is deliberately weighted toward red, orange, gold, and pink, with
  a smaller number of bright violet, blue, cyan, and lime options.
- Every palette entry must remain legible against the repo's dark terminal
  backgrounds (`#101010` and `#0f0b15`) and Agnoster's black context segment.
  Do not select from the full terminal color space.
- Color collisions are acceptable; the goal is quick visual distinction, not a
  globally unique host identifier.
- If `cksum` is unavailable or hashing fails, use bright orange (`208`) so
  prompt rendering still succeeds.

## Integration

Override Agnoster's `prompt_context` only after Oh My Zsh loads the theme. Keep
the existing optimized `build_prompt` override unchanged. Do not modify the
vendored or installed Oh My Zsh theme.

## Verification

- Test all three display rules with a stubbed `prompt_segment`.
- Verify the same hostname always selects the same palette entry.
- Verify representative different hostnames can select different entries.
- Verify every selected value belongs to the approved bright palette.
- Verify the fallback color when checksum generation is unavailable or invalid.
- Run `zsh -n` against the changed configuration.
