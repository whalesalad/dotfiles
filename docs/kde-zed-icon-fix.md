# KDE Task Switcher Showing Wrong Icon for Zed (Wayland)

**Symptom**: After a Zed update, the taskbar icon looks fine but alt-tab task switcher shows
the generic Wayland app icon instead of the Zed icon.

**Platform**: Debian 12, KDE Plasma, Wayland

---

## Root Cause

The mismatch comes from stale KWin window rules pointing to a `.desktop` file that doesn't
exist.

### How KDE resolves app icons on Wayland

Wayland apps report an `app_id` to the compositor. KDE uses this to find the matching
`.desktop` file (by filename, without the `.desktop` extension), then reads the `Icon=` field
to resolve the actual icon.

For Zed:
- Wayland app_id / resourceClass: `dev.zed.Zed`
- Desktop file: `/usr/share/applications/dev.zed.Zed.desktop`
- Icon name: `zed` (resolves to `/usr/share/icons/hicolor/*/apps/zed.png`)

When this chain is intact and there are no overriding KWin rules, everything works
automatically.

### Why the taskbar works but alt-tab doesn't

The Plasma task manager widget (taskbar) has fallback logic: if the forced `desktopFile`
property doesn't resolve to a real file, it falls back to matching by raw app_id. So it finds
`dev.zed.Zed.desktop` and gets the correct icon regardless.

KWin's task switcher (alt-tab) does **not** have this fallback — it only uses the `desktopFile`
window property. If that doesn't point to a real `.desktop` file, it falls back to the generic
Wayland icon.

### How stale rules accumulate

Over multiple Zed updates, the app_id has changed (e.g. `zed-editor` → `dev.zed.Zed`) and the
`.desktop` filename has changed accordingly. Each time the icon broke, a KWin rule was added to
fix it, but all rules referenced `desktopfile=zed` — a file that has never existed. Example of
the accumulated mess in `~/.config/kwinrulesrc`:

```ini
[1]
wmclass=dev.zed.Zed
desktopfile=zed        ← zed.desktop doesn't exist
desktopfilerule=2      ← Force

[2]
wmclass=zed-editor     ← old app_id, no longer used
desktopfile=zed

[c031d43f-...]         ← orphaned duplicate, not in [General] count
wmclass=dev.zed.Zed
desktopfile=zed

[24dedbe1-...]         ← another orphaned duplicate
wmclass=zed-editor
desktopfile=zed
```

---

## Diagnosis Commands

```bash
# Find all Zed desktop files
find /usr/share/applications ~/.local/share/applications -name "*zed*" -o -name "*Zed*"

# Check icon files
find /usr/share/icons -name "zed*"

# See current KWin window rules
cat ~/.config/kwinrulesrc

# Get live window info from KWin (run this, then click the Zed window)
qdbus org.kde.KWin /KWin org.kde.KWin.queryWindowInfo
# Key fields to check:
#   resourceClass  → the Wayland app_id
#   resourceName   → the instance name
#   desktopFile    → what KWin has resolved (may be forced by a rule)
```

The `desktopFile` value from `queryWindowInfo` should match a real file in
`/usr/share/applications/`. If it doesn't, that's the bug.

---

## Fix

**Remove all KWin window rules for Zed.** As of Zed 0.225+, the app_id (`dev.zed.Zed`)
matches `dev.zed.Zed.desktop` exactly — no rules needed. KDE auto-matching handles everything.

1. Open **System Settings → Window Management → Window Rules**
2. Delete any rules mentioning Zed (`dev.zed.Zed`, `zed-editor`, etc.)
3. Restart Zed (the old rules remain applied to already-open windows until they're killed)

After restarting Zed, both the taskbar and alt-tab task switcher should show the correct icon.

---

## If It Breaks Again After a Future Zed Update

Check whether Zed's app_id changed:

```bash
# With Zed open, run and click the Zed window:
qdbus org.kde.KWin /KWin org.kde.KWin.queryWindowInfo
# Note the resourceClass value
```

Then check whether a matching `.desktop` file exists:

```bash
find /usr/share/applications -name "<resourceClass>.desktop"
```

If the `.desktop` file is missing or has a different name, Zed's package is broken — file a bug.
If the file exists and icons are in `/usr/share/icons/hicolor/`, the auto-matching should work
with no KWin rules needed. Do **not** add a KWin rule with a hardcoded `desktopfile=` value
unless you verify the exact filename first.
