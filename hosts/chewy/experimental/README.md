# Chewy Niri experiment

Status, 2026-11-06: Fedora packages and base configuration installed; `niri validate`
and systemd unit verification passed. No Niri login or interactive lock/suspend test
yet. GNOME is the working desktop. Do not describe this experiment as verified.

## Packages

Preview with `--assumeno`, review, then repeat without it:

```sh
sudo dnf install --assumeno niri waybar fuzzel swaylock swayidle mako brightnessctl \
  xdg-desktop-portal-gnome xdg-desktop-portal-gtk gnome-keyring nautilus
```

Reuse existing WezTerm, WirePlumber (`wpctl`) and the KDE polkit authentication
agent. The latter binary is `/usr/libexec/kf6/polkit-kde-authentication-agent-1`.
Fedora's Niri dependencies include Xwayland Satellite for legacy apps inside the
Wayland session. Use the packaged Niri login entry (`niri-session`), not a bare
compositor launch; its systemd integration publishes the environment and handles
session shutdown. Existing portal packages select Niri backends automatically.

## Install reviewed configuration

Back up existing destinations first. Copy these files; do not start the services
while in GNOME or KDE:

```sh
cd ~/code/dotfiles/hosts/chewy/experimental
install -Dm644 niri/config.kdl ~/.config/niri/config.kdl
install -Dm644 waybar/config.jsonc ~/.config/waybar/config.jsonc
install -Dm644 waybar/style.css ~/.config/waybar/style.css
install -Dm644 swaylock/config ~/.config/swaylock/config
for name in niri-idle niri-polkit niri-toshy-refresh; do
  install -Dm644 "systemd/user/$name.service" "$HOME/.config/systemd/user/$name.service"
done
install -Dm644 systemd/user/mako.service.d/niri-only.conf ~/.config/systemd/user/mako.service.d/niri-only.conf
systemctl --user daemon-reload
systemctl --user add-wants niri.service waybar.service mako.service \
  niri-idle.service niri-polkit.service niri-toshy-refresh.service
niri validate
systemd-analyze --user verify ~/.config/systemd/user/niri-{idle,polkit,toshy-refresh}.service
```

The startup links live under `~/.config/systemd/user/niri.service.wants/`; they
are deliberately not globally enabled under `graphical-session.target`.
Niri's config sets full-width windows, a small panel, the host's 150% display scale
and rotation. Small gaps remain. Dialog behavior and WezTerm's initial sizing
workaround still need interactive validation. Idle locks after 600 seconds and
powers off displays after 660 seconds; sleep also requests a lock.

`niri-toshy-refresh.service` restarts the existing wlroots bridge and keymapper
after Niri publishes its session environment. It does not edit/reinstall Toshy.
Authentication uses the existing KDE polkit agent in a Niri-only service.

## App versus window switching

GNOME's app switcher groups multiple windows of an app together. Niri 26.04's
built-in recent-windows switcher lists windows individually. With one window per
app, that difference is negligible. With three Chromium windows and one WezTerm
window, GNOME presents two app choices while Niri normally presents four windows.

The installed config now binds Alt-Tab and Alt-Shift-Tab to native recent-window
switching (Toshy's Cmd-Tab output). Cmd-backtick remains same-app switching.

Toshy already emits these combos for Cmd-Tab; no Toshy edit is needed. This is
an ordinary Niri config tweak, and a reasonable first trial. It does not enable
GNOME-style grouping: `filter="app-id"` means windows within the current app,
not one representative per app. True grouped switching needs another component
or compositor support. No external switcher was installed.

Current launcher is Fuzzel: app launch/search only, not a full indexed file-search
replacement for Spotlight. Bindings include Toshy's Alt-F1 launcher output,
Ctrl-Shift-Space fallback, Alt-Return for WezTerm, and Alt-F4 to close a window.
Test all shortcuts with the actual keyboard and Toshy active before relying on them.

## First login and rollback

Save work, log out normally, select Niri. Check display geometry, panel, launcher,
WezTerm, notifications, authentication prompts, keybindings and locking. Keep KDE
and GNOME available. Reattach tmux using its existing socket/session.

For rollback, log out of Niri and return to GNOME/KDE. Remove only the five added
Niri startup links, reload user units, and restore the backed-up destination files.
Do not globally disable shared Waybar/Mako units or remove shared portal packages.

## First Niri login (November 7)

Session reached; KDE wallet unlocked. KDE xwaylandvideobridge exposed a helper
window. A user drop-in for app-org.kde.xwaylandvideobridge@autostart.service
condition-skips it in Niri only. Current window removed; restart skipped. Remove
the drop-in and daemon-reload to undo. This does not disable xwayland-satellite.
Browser and physical shortcut acceptance in Niri remain pending.

## Launcher, switcher and Caps Lock (November 7)

Fuzzel uses Inter 13, a 90% opaque dark background, 18px corners, seven results
and softer selection/border colors. Install fuzzel/fuzzel.ini under
~/.config/fuzzel/. It appears on the next launcher invocation. Niri's native
recent-window switcher uses rounded 18px translucent highlights and compact
previews; its font is not configurable through the documented native options.
No replacement switcher or desktop-wide font change was introduced.

Niri keyboard xkb options include caps:escape. GNOME was set to the same option
with gsettings, preserving unrelated options; replay by adding caps:escape to
org.gnome.desktop.input-sources xkb-options. KDE already had that mapping.
Toshy preferences and WezTerm styling were not changed. Config validation passed;
physical Caps-Escape, switching and visual acceptance remain pending.

Private undo for this appearance/Caps change:
`python3 ~/.local/state/desktop-setup/niri-ui-20261107-004547/undo.py`.
The earlier unbound-switcher config is separately retained under
~/.local/state/desktop-setup/niri-switcher-20261107-004434/.
