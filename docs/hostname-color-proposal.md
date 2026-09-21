# Hostname color proposal

Status: approved and implemented on 2026-09-21.

## Problem

The previous shared helper normalized the short hostname, computed POSIX `cksum`,
and selected one of 12 colors by remainder. Several palette entries were similar
reds and pinks. Lucifer and Chewy both selected 135; Viper selected orange-red 202.
The collision alone is not evidence of a defective checksum.

## Alternatives

1. Recommended: use a balanced palette and a single fixed seed, selected to give
   the current machines distinct, preferred colors. Keep deterministic local
   calculation and no host inventory or hostname-specific branches.
2. Generate a larger range of colors from the hash. This permits more distinct
   outputs, but neighboring shades can still look alike and require additional
   contrast and terminal compatibility constraints.
3. Allocate colors across a shared host inventory. This can explicitly separate
   known machines, but requires maintaining shared state and collision rules.

## Approved calculation

Preserve lowercase short-hostname normalization and POSIX `cksum`. Hash the exact
bytes `host-color:251:<normalized hostname>` without a trailing newline. Use the
checksum modulo 7 as a zero-based index into this fixed xterm palette:

| Index | Color | xterm index |
| --- | --- | --- |
| 0 | Purple | 135 |
| 1 | Pink | 205 |
| 2 | Orange | 208 |
| 3 | Yellow | 220 |
| 4 | Lime | 82 |
| 5 | Cyan | 45 |
| 6 | Blue | 75 |

Seed 251 was selected by trying nonnegative integers from zero until the three
sample hosts received the requested colors. It is a global tuning parameter,
not a promise of better statistical distribution or collision avoidance.
Seven slots allow more exact collisions than twelve slots under a uniform hash;
the intended improvement is the balance of visible hues and the separation of
the current machines. Keep the seed and palette order fixed for stable colors.

Verified results: Lucifer 135 (purple), Chewy 208 (orange), Viper 82 (lime).
New names use the same rule automatically; arbitrary names can still collide.
No hardware role or semantic interpretation of names is involved.

## Integration and validation

Update `bin/host-color`, retaining orange 208 for empty input, missing `cksum`,
and invalid checksum output. Both zsh and tmux already consume this helper.
Update palette expectations and representative-host checks in the existing
helper and zsh tests, including short-name/case equivalence and repeatability.
Run those tests, the tmux host-context test, and shell syntax checks. Update the
existing host-context documentation to match the approved palette and seed.
Reload local tmux after implementation; existing shells pick up the change when
their prompt setup is reloaded or a new shell starts.
