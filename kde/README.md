# Lucifer-style Plasma 6 panel widgets

Run from a logged-in Plasma 6 desktop, as your normal user:

```sh
~/code/dotfiles/kde/panel-widgets.py          # preview
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
GPU instead of the default aggregate `gpu/all/usage`.

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
settings to the profile and restores their left-side placement.

- World clock: Los Angeles, Vancouver, Phoenix, local timezone, UTC, London,
  Jerusalem. UTC initially selected, date hidden, scroll to switch timezone.
- CPU usage: magenta pie chart.
- Memory usage: teal pie chart, used/total details.
- GPU usage: orange pie chart, aggregate across GPUs by default.
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
