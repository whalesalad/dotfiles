#!/bin/bash
# focus-tracker.sh — daemon that tracks the two most recently focused window addresses.
# Run via exec-once in hyprland.conf.
# Writes to /tmp/hypr-focus-history: line 1 = current, line 2 = previous.

HISTORY="/tmp/hypr-focus-history"
SIG="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls -t /run/user/1000/hypr/ | head -1)}"
SOCK="/run/user/1000/hypr/$SIG/.socket2.sock"

socat - "UNIX-CONNECT:$SOCK" | while IFS= read -r line; do
    if [[ "$line" == "activewindowv2>>"* ]]; then
        addr="${line#activewindowv2>>}"
        # strip any trailing whitespace/CR
        addr="${addr%%[[:space:]]*}"
        [[ -z "$addr" ]] && continue
        prev=$(head -1 "$HISTORY" 2>/dev/null)
        if [[ "$addr" != "$prev" ]]; then
            printf '%s\n%s\n' "$addr" "$prev" > "${HISTORY}.tmp" && mv "${HISTORY}.tmp" "$HISTORY"
        fi
    fi
done
