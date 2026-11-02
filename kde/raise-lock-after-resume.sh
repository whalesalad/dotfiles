#!/usr/bin/env bash
# Ask Plasma's existing lock screen to show its authentication UI after wake.
set -euo pipefail

# The compositor and locker need a moment to reconnect after suspend.
sleep 2

session=$(loginctl show-seat seat0 --property=ActiveSession --value)
[[ -n $session ]] || exit 0
[[ $(loginctl show-session "$session" --property=Class --value) == user ]] || exit 0
[[ $(loginctl show-session "$session" --property=Type --value) == wayland ]] || exit 0

user=$(loginctl show-session "$session" --property=Name --value)
uid=$(loginctl show-session "$session" --property=User --value)
[[ -n $user && -n $uid && -S /run/user/$uid/bus ]] || exit 0

timeout 5s runuser -u "$user" -- env \
    XDG_RUNTIME_DIR="/run/user/$uid" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
    dbus-send --session --type=method_call \
        --dest=org.freedesktop.ScreenSaver /ScreenSaver \
        org.freedesktop.ScreenSaver.SimulateUserActivity
