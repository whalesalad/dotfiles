#!/bin/bash
# focus-last.sh — focus the previously active window (cross-workspace).
# Bound to ALT+Tab in hyprland.conf (Toshy maps Cmd+Tab → Alt+Tab).

HISTORY="/tmp/hypr-focus-history"
prev=$(sed -n '2p' "$HISTORY" 2>/dev/null)
[[ -n "$prev" ]] && hyprctl dispatch focuswindow "address:0x${prev}"
