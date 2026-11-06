# Fedora GNOME alongside KDE

Manual replay runbook, recorded 2026-11-06. Verified on Chewy with Fedora 44,
GNOME 50.6, Plasma 6.8.2 and an existing Toshy installation. Viper replay is
planned, not verified. GNOME is the working desktop; Niri remains a Chewy experiment.

## Packages and login manager

Preview the transaction first, then repeat without `--assumeno` after reviewing it:

```sh
sudo dnf install --assumeno gnome-shell gnome-session-wayland-session \
  gnome-control-center gnome-settings-daemon gnome-keyring nautilus \
  gnome-extensions-app xdg-desktop-portal-gnome xdg-desktop-portal-gtk
```

These are Fedora repository packages. GNOME pulls in GDM and other dependencies;
do not enable GDM or replace the existing login manager as part of this setup.
Check before and after with `readlink -f /etc/systemd/system/display-manager.service`.
On Chewy, Plasma Login remained active. Do not copy the observed dependency count
as a guarantee: review the current transaction on each host.

Install Extension Manager separately (the packaged Extensions app manages installed
extensions; Extension Manager also browses and installs them):

```sh
flatpak install flathub com.mattjakeman.ExtensionManager
```

Review its runtime download and permissions. This uses the existing Flathub remote;
GNOME Platform 50 was required on Chewy. Do not add a starter extension bundle.

## Preserve existing Toshy

Do not reinstall Toshy or replace `~/.config/toshy/toshy_config.py` or its preferences
SQLite database. Existing mappings already produce Alt-Tab for Cmd-Tab and
Ctrl-Shift-Space for GNOME's Cmd-Space launcher.

Use Extension Manager to install **Xremap**, UUID `xremap@k0kubun.com`, from
<https://extensions.gnome.org/extension/5060/xremap/>. Check that the extension
explicitly supports the installed GNOME major version. Version 16 supports GNOME
50 and was tested on Chewy. This extension supplies focused-window information to
Toshy; it is not a second keymapper. Its upstream project is
<https://github.com/xremap/xremap-gnome>.

Alternatively, download the tested GNOME-50 archive for inspection:

```sh
curl --fail --location \
  'https://extensions.gnome.org/download-extension/xremap@k0kubun.com.shell-extension.zip?version_tag=76494' \
  --output /tmp/xremap-gnome50.zip
unzip -p /tmp/xremap-gnome50.zip metadata.json
# Only if UUID, version and shell-version match expectations and it isn't installed:
gnome-extensions install /tmp/xremap-gnome50.zip
```

Enable it from within GNOME using Extension Manager, or:

```sh
gnome-extensions enable xremap@k0kubun.com
```

A new extension may require another GNOME login before it is discovered. Do not
force-install an older incompatible extension or disable GNOME's version checks.
Toshy's bundled installer can fall back to an older GNOME version; that fallback
was deliberately avoided here.

Inspect before changing the launcher binding:

```sh
gsettings get org.gnome.shell.keybindings toggle-overview
# Chewy had no existing binding; preserve any existing bindings on another host.
gsettings set org.gnome.shell.keybindings toggle-overview "['<Control><Shift>space']"
```

Keep the normal GNOME app switcher: `switch-applications` includes Alt-Tab,
`switch-windows` is unbound, and `switch-group` includes Alt-Above_Tab.
Those settings already matched on Chewy; no rewrite was needed.

## Host display settings

Use the host's GNOME Settings display panel. Do not copy Chewy's panel identity,
rotation or scale to Viper. Chewy's reviewed `monitors.xml` is under
`hosts/chewy/home/.config/` and gives a rotated 1200x1920 panel, 150% scale,
1280x800 logical desktop. GNOME confirmed that configuration after login.

Chewy also enabled `scale-monitor-framebuffer` in
`org.gnome.mutter experimental-features` for fractional scaling. Inspect the
existing list and add only that entry if required; preserve other entries.
Do not blindly replace the list, and do not apply obsolete scaling flags to a
future GNOME release without checking its installed schema.

## KDE logout cleanup when lingering is enabled

Observed failure: KDE stopped its workspace but left `graphical-session.target`
active. GNOME's initializer aborted with "A graphical session is already running!".
The desktop portal could keep that target needed through its Requisite dependency.
A user drop-in makes KDE's stop explicitly propagate to the graphical target:

```sh
cd ~/code/dotfiles
install -Dm644 desktop/gnome/systemd/user/plasma-workspace.target.d/session-cleanup.conf \
  ~/.config/systemd/user/plasma-workspace.target.d/session-cleanup.conf
systemctl --user daemon-reload
systemctl --user show plasma-workspace.target -p PropagatesStopTo
```

This drop-in was verified on Chewy: the target stopped at logout and GNOME then
started successfully. Review it as a local workaround on Viper; do not assume
Viper has reproduced the same failure. Do not stop the target from inside a
working desktop merely to test it: that ends the graphical session.

## tmux and lingering

Lingering preserves the user manager, not an arbitrary process tree attached to
a terminal service. If desired, enable it for the current account:

```sh
sudo loginctl enable-linger "$(id -un)"
loginctl show-user "$(id -un)" -p Linger
```

This creates a per-user marker under `/var/lib/systemd/linger/`, starts the user
manager at boot and retains it after logout. For a NEW tmux server, start it in
an independent scope, for example:

```sh
systemd-run --user --scope --unit=tmux-work tmux -L work new-session -s work
```

The separate socket avoids attaching to an existing server still owned by a
terminal's service. Ordinary `tmux attach` does not move an existing server.
Chewy's existing server and descendants were migrated live into a transient
`tmux-persistent.scope`; that was a one-time runtime rescue, not a persistent
unit or automatic setup for future servers. Neither method preserves processes
across a reboot. See <https://www.freedesktop.org/software/systemd/man/latest/loginctl.html>.

## Verify and recover

Save work, log out normally, select GNOME, and test display, Cmd-Space, Cmd-Tab,
Cmd-Shift-Tab, Cmd-backtick, WezTerm editing, locking, suspend and audio.

```sh
gnome-extensions info xremap@k0kubun.com
systemctl --user --failed
journalctl --user -u toshy-config.service -n 40 --no-pager
```

If desktop switching leaves Toshy using the previous desktop, first verify that
`systemctl --user show-environment` has the CURRENT desktop and display values.
Then restart its existing services. Do not import values from an old tmux shell;
its environment may still describe the previous desktop. On Chewy an early
startup race required refreshing activation environment from running Plasma and
restarting services; the general Toshy startup-order race is not permanently fixed.

Old crash-report popups are not proof of new crashes: compare timestamps with
`coredumpctl list`. Chewy had no new core dumps during the successful GNOME login.
The KDE-only tablet service was a separate failure, handled by Chewy's host drop-in.

No battery comparison has been measured. Improved battery life under GNOME is a
user observation pending comparable workload/brightness measurements.

Chromium can use the same profile but a different desktop keyring backend may
affect encrypted cookies and saved logins. That possibility was not diagnosed;
do not delete profiles, copy credential databases or weaken password storage.

## Rollback and public-repository boundary

Back up destination files and record existing gsettings values before applying.
To undo a local drop-in, remove only that added file and reload user units.
Restore saved settings/files rather than removing KDE or uninstalling shared dependencies.

Keep cookie databases, browser profiles, keyrings, credentials, full dconf dumps,
Toshy preferences, runtime logs, crash dumps, private backups and full machine
inventories out of this public repository. Track only reviewed configuration and
manual replay instructions. Hostnames in this runbook are short labels, not
remote-access details. Nothing here installs remotely or changes Viper automatically.
