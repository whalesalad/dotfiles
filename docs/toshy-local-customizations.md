# Toshy Local Customizations Replay Runbook

This workstation keeps its live Toshy configuration at:

```text
~/.config/toshy/toshy_config.py
```

As verified on 2026-07-15, the complete local delta from Toshy's bundled default consists of
three application-class entries:

- Ghostty and WezTerm are added to `terminals_lod`, which opts them into Toshy's **General
  Terminals** mappings.
- Zed is added to `vscodes`, which opts it into Toshy's VS Code-like mappings.

The safe archive below contains the Ghostty and Zed changes, but predates the WezTerm entry:

```text
~/Desktop/toshy-backup-safe-working-2026-07-14.tar.gz
SHA-256: b97ea502247c3ced1c5e5b57ec91f99572486073770ed03004dc9f2a61cf3962
```

Therefore, the only live Toshy change made after that archive was created is the WezTerm line.

## Replay the customizations

### 1. Make a small, immediately accessible backup

Before editing, preserve the current configuration as a plain file:

```bash
cp --preserve=all \
  "$HOME/.config/toshy/toshy_config.py" \
  "$HOME/Desktop/toshy_config.py.before-local-edits.$(date +%Y%m%d-%H%M%S)"
```

Keep the full safe archive as the larger parachute; this extra copy just makes a one-file
rollback easy.

### 2. Add Ghostty and WezTerm to the terminal application list

Open `~/.config/toshy/toshy_config.py`, find `terminals_lod`, and insert the two local entries
between the existing GNOME Terminal and Guake entries:

```python
    {clas:"^gnome-terminal-server$"     },
    {clas:".*ghostty.*"                   },
    {clas:".*wezterm.*"                   },
    {clas:"^guake$"                     },
```

The important additions are exactly:

```python
    {clas:".*ghostty.*"                   },
    {clas:".*wezterm.*"                   },
```

These match the applications' window classes and activate Toshy's existing terminal-specific
Cmd mappings. The terminal key behavior itself remains defined in Toshy's `General Terminals`
keymap; no application-specific keymap is added here.

### 3. Add Zed to the VS Code-like application list

Find the existing `vscodes = [` list and add Zed after the Code variants:

```python
vscodes = [
    "code",
    "vscodium",
    "code - oss",
    "dev.zed.Zed",      # Zed editor - treat as VSCode
]
```

If a future Toshy version removes or renames this list, do not recreate a dead `vscodes`
variable blindly. Add `dev.zed.Zed` to that version's documented VS Code application-class
list instead.

### 4. Validate before restarting Toshy

This checks Python syntax without writing a `__pycache__` file:

```bash
python3 -c 'from pathlib import Path; p = Path.home() / ".config/toshy/toshy_config.py"; compile(p.read_text(), str(p), "exec"); print("Toshy config syntax OK")'
```

Optionally inspect the complete local delta. `diff` returning status 1 is normal when it finds
the expected differences:

```bash
diff -u \
  "$HOME/.config/toshy/toshy-default-config/toshy_config.py" \
  "$HOME/.config/toshy/toshy_config.py"
```

The meaningful output should be limited to the two terminal entries and the one Zed entry
shown above. Stop and investigate if unrelated changes appear unexpectedly.

### 5. Restart and inspect Toshy

```bash
systemctl --user restart toshy-config.service
systemctl --user --no-pager --full status toshy-config.service
```

The service should report `active (running)`. If it does not, inspect its recent log:

```bash
journalctl --user -u toshy-config.service -n 50 --no-pager
```

### 6. Smoke-test the behavior

- In WezTerm, verify Cmd+T, Cmd+W, and Cmd+1 through Cmd+9.
- In Ghostty, verify the normal macOS-style terminal shortcuts still route through Toshy's
  General Terminals mapping.
- In Zed, verify the expected macOS/VS Code-like editing shortcuts.
- Check at least one unrelated application to ensure its key behavior did not change.

## Rollback

### Restore the one-file backup made in step 1

The following selects the newest matching one-file backup. Review the printed path before
allowing the copy to run:

```bash
BACKUP="$(ls -1t "$HOME"/Desktop/toshy_config.py.before-local-edits.* | head -n 1)"
printf 'Restoring: %s\n' "$BACKUP"
cp --preserve=all \
  "$BACKUP" \
  "$HOME/.config/toshy/toshy_config.py"
systemctl --user restart toshy-config.service
```

### Restore the known-safe archived config

First extract it to `/tmp` for inspection instead of overwriting the live file directly:

```bash
tar -xOzf "$HOME/Desktop/toshy-backup-safe-working-2026-07-14.tar.gz" \
  .config/toshy/toshy_config.py > /tmp/toshy_config.safe-working.py
diff -u "$HOME/.config/toshy/toshy_config.py" /tmp/toshy_config.safe-working.py
```

If the diff is the rollback desired, install it and restart Toshy:

```bash
cp --preserve=all \
  /tmp/toshy_config.safe-working.py \
  "$HOME/.config/toshy/toshy_config.py"
systemctl --user restart toshy-config.service
systemctl --user --no-pager --full status toshy-config.service
```

This archived configuration retains the Ghostty and Zed customizations and removes the later
WezTerm addition. To return all the way to Toshy's bundled default instead, first make another
backup, then copy `~/.config/toshy/toshy-default-config/toshy_config.py` over the live config
and restart the service.
