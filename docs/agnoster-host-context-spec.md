# Agnoster Host Context

## Decision

Make remote hosts visually distinct in the Agnoster prompt by assigning the
context segment a deterministic bright color derived from the short hostname.
Keep the implementation in `zsh/prompt.zsh`, alongside the existing Agnoster
override, and compute the color once when the shell starts.

## Display Rules

| Session | Current user | Context segment |
| --- | --- | --- |
| Local | `michael` | Hidden |
| SSH | `michael` | `hostname` |
| Local or SSH | Any other user | `user@hostname` |

The literal username `michael` is omitted because it is implied. The complete
visible context string uses the host-derived background color and a contrasting
foreground color.

## Color Selection

- Hash the lowercased short hostname with POSIX `cksum`.
- Use the checksum to select from a curated palette of bright 256-color values.
- Restrict the palette to colors that remain legible with a fixed contrasting
  foreground instead of selecting from the full terminal color space.
- Color collisions are acceptable; the goal is quick visual distinction, not a
  globally unique host identifier.
- If `cksum` is unavailable or hashing fails, use a fixed bright fallback color
  so prompt rendering still succeeds.

## Integration

Override Agnoster's `prompt_context` only after Oh My Zsh loads the theme. Keep
the existing optimized `build_prompt` override unchanged. Do not modify the
vendored or installed Oh My Zsh theme.

## Verification

- Test all three display rules with a stubbed `prompt_segment`.
- Verify the same hostname always selects the same palette entry.
- Verify representative different hostnames can select different entries.
- Verify the fallback color when checksum generation is unavailable or invalid.
- Run `zsh -n` against the changed configuration.
