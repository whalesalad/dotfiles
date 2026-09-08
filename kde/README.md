# Lucifer-style Plasma 6 panel widgets

Run from a logged-in Plasma 6 desktop, as your normal user:

```sh
~/code/dotfiles/kde/panel-widgets.py --capture # save GUI edits into panel-profile.json
~/code/dotfiles/kde/panel-widgets.py          # preview the saved profile
~/code/dotfiles/kde/panel-widgets.py --apply
~/code/dotfiles/kde/panel-widgets.py --remove --apply  # undo our additions
```

Requires Python 3 with PyGObject/Gio (`python3-gobject` on Fedora,
`python3-gi` on Debian), `kwriteconfig6`, systemd's active user service
`plasma-plasmashell.service`, KDE System Monitor widgets and ksystemstats.
No third-party widget download is needed. The executable uses `/usr/bin/python3`
to access distribution Python bindings. Missing required sensors stop installation.
For multiple panels, choose a horizontal panel with `--panel ID`; preview lists
IDs when selection is ambiguous. Use `--gpu gpu/gpu0/usage` to select a particular
GPU instead of the captured all-device pattern `gpu/gpu\d+/usage`.

Apply briefly stops/restarts **plasmashell**, which redraws panels and the desktop;
applications remain open and there is no logout/reboot. This avoids a live
reordering failure observed on Plasma 6.7.4. It writes panel order only while
plasmashell is stopped, so the live panel cannot overwrite it. Backups of
`plasma-org.kde.plasma.desktop-appletsrc` and `plasmashellrc` are saved under
`${XDG_STATE_HOME:-~/.local/state}/dotfiles/kde-panel/TIMESTAMP/` before changes.
Do not restore these whole files while Plasma is running. Prefer `--remove`
for rollback; whole-file restoration would also revert later desktop changes.

The installer prepends these widgets and preserves the relative order and
configuration of existing widgets, including your original local clock and
launchers. Managed widgets are tagged in their `Dotfiles` configuration group;
rerunning updates their settings without duplicates. It resets managed-widget
settings to `panel-profile.json` and restores their left-side placement. Managed
roles absent from the saved profile are removed (for example the old separate
GPU widget). Unmanaged widgets are preserved.

After adjusting widgets in the GUI, run `--capture` and review/commit the JSON
diff. Capture reads current configuration through Plasma, preserving KConfig
escaping, nested face settings, popup sizes, colors, labels and managed order.
It excludes bookkeeping and settings-dialog dimensions. Capture neither applies
settings nor restarts the shell. It saves the prior profile to an ignored
`.json.bak` file. Use `--profile /path/to/profile.json` for an alternate profile.
Only widgets tagged by this installer are captured; it is not a full-panel
export. Newly added untagged widgets belong in a broader desktop snapshot.

- World clock: Los Angeles, Vancouver, Phoenix, local timezone, UTC, London,
  Jerusalem. UTC initially selected, date hidden, scroll to switch timezone.
- CPU/GPU usage: combined line graph, CPU label, magenta CPU and captured GPU colors; matches individual GPU utilization sensors.
- Memory usage: teal line graph, used/total details.
- CPU temperature: average/maximum line chart, frequency in details; omitted
  if those temperature sensor IDs are unavailable.

[Reference export](reference/lucifer-plasma5-2026-09-08.json) contains only the
five relevant widget sections from Lucifer's Plasma 5.27.5 configuration,
captured read-only over SSH on 2026-09-08. Unrelated taskbar/desktop configuration
is excluded. Clock zone `UTC+00:00` is normalized to IANA `Etc/UTC`.
Lucifer's GPU graph shows temperature/power/fan, not utilization. Chewy's
Intel GPU reports live utilization but zero temperature/power and no fan sensor;
the portable profile therefore uses utilization. Sensor existence alone does
not prove a reading is usable on another GPU; inspect the live values there.

Uses KDE's [Plasma scripting API](https://develop.kde.org/docs/plasma/scripting/api/)
and built-in sensor faces. Validated on Chewy Plasma 6.7.4: saved order, rendered
left-side widgets, live CPU/memory/GPU/temperature samples, removal of managed
widgets, and repeat installation without duplicate IDs. Clock interaction,
subsequent login persistence and other KDE machines still need acceptance.


## Desktop snapshots and replay

```sh
~/code/dotfiles/kde/snapshot.py
```

Creates a private archive plus SHA-256 sidecar under
`${XDG_STATE_HOME:-~/.local/state}/dotfiles/kde-snapshots/`. `--output-dir PATH`
chooses another location. Every regular file in the archive is checked against
its recorded SHA-256 before success is reported. Nothing is restored or restarted.
Copy the archive and sidecar to your backed-up storage; a local snapshot alone
will not survive loss of this disk. No scheduled/off-machine copy is configured
by this helper. Raw snapshots stay outside Git; they can contain personal paths,
autostart commands and other private settings.

Contents are deliberately a **desktop settings snapshot**, not an entire home
or OS backup: core Plasma/KWin settings, shortcuts, input/display/power settings,
GTK integration, autostart/environment configuration, user Plasma widgets,
KWin scripts/effects, themes, icons, fonts, local Konsole profiles and active
wallpaper files. `manifest.json` records source paths, versions/package inventory,
checksums, symlinks, missing optional paths and hardware-specific files.
System-installed assets are represented by the package inventory rather than
copied. Symlinks are preserved; external targets may need to be installed or
copied separately. Wallets, KDE Connect pairing keys, mail, application data,
activity databases, system-wide settings, login-manager settings and open
sessions are outside this scope. For complete recovery retain your home/system
backup as well.

The helper reads saved files while KDE runs. It is not an atomic filesystem
snapshot and may miss unsaved settings. For the most consistent recovery copy,
run it from a TTY after logging out of Plasma; no logout is performed automatically.

To inspect a snapshot:

```sh
cd ~/.local/state/dotfiles/kde-snapshots
sha256sum -c HOST-TIMESTAMP.tar.gz.sha256
tar -tzf HOST-TIMESTAMP.tar.gz
mkdir -m 700 /tmp/kde-restore-review
tar -xzf HOST-TIMESTAMP.tar.gz -C /tmp/kde-restore-review
```

Use your actual filename and a fresh review directory. Restore only your trusted
archive. `config/` maps to `$XDG_CONFIG_HOME` (normally `~/.config`), `data/` to
`$XDG_DATA_HOME` (normally `~/.local/share`); `wallpaper-files/` maps via the
manifest. Inspect absolute paths and symlinks before copying.

For recovery on the same machine, back up the destination first, log out of
Plasma, and restore the reviewed files from a TTY before signing in. Full-copy
restore has not been tested here. For another machine, install compatible
Plasma/widgets/themes/fonts first and migrate selectively: usually appearance,
shortcuts and the panel profile. Do not blindly restore output topology,
rotation, touchpad or power settings. `kwinrc` also mixes portable preferences
with host-specific settings and must be reviewed. Application launchers and
wallpaper paths can need adjustment. KDE 5 → 6 is a migration, not a guaranteed
whole-config clone.

KDE also supports [scripted layout templates](https://develop.kde.org/docs/plasma/scripting/templates/)
for repeatable panels/widgets. Keep intentional cross-machine preferences in
Git (as with the captured panel profile); use the private snapshot for recovery
and as source material for expanding that portable configuration.
