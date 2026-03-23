#!/bin/bash
# Hyprland keybind cheat sheet
# Opens in a floating terminal via: bind = $mod, slash, exec, ghostty --class=cheatsheet -e ~/.config/hypr/cheatsheet.sh

decode_mods() {
    local mask=$1
    local mods=""
    (( mask & 64  )) && mods+="SUPER+"
    (( mask & 1   )) && mods+="SHIFT+"
    (( mask & 4   )) && mods+="CTRL+"
    (( mask & 8   )) && mods+="ALT+"
    echo "${mods%+}"
}

echo ""
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║            HYPRLAND KEYBINDS — jackal               ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo ""

hyprctl binds -j 2>/dev/null | jq -r '.[] | [.modmask, .key, .dispatcher, .arg] | @tsv' | \
while IFS=$'\t' read -r mask key dispatcher arg; do
    mods=$(decode_mods "$mask")
    if [[ -n "$mods" ]]; then
        combo="$mods + $key"
    else
        combo="$key"
    fi
    printf "  %-28s  %s %s\n" "$combo" "$dispatcher" "$arg"
done

echo ""
echo "  Press q or Escape to close"
echo ""

read -rsn1 key
