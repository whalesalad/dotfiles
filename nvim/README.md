# Neovim

Requires Neovim 0.12 or newer, Git, and `rg` (ripgrep). `wl-copy` provides the
desktop clipboard on Wayland.

The directory where Neovim starts is the project root. Start it from a single
top-level project directory:

```sh
cd ~/code/homelab
nvim
```

## Everyday controls

| Key | Action |
| --- | --- |
| `Ctrl-P` | Find a project file |
| `Space` then `p` | Find and run an editor command |
| `Space` then `g` | Review changed files with a diff preview |
| `Space` then `b` | Find an already-open file |
| `Space` then `/` | Search text in the project |
| `Space` then `?` | Search available key commands |
| `[` then `b` / `]` then `b` | Previous / next open file |
| `Space` then `w` | Close the current file safely |
| `Ctrl-S` | Save |

Mouse dragging creates a normal Neovim visual selection. Press `Ctrl-C` to
copy it to the desktop clipboard. Hold `Shift` while dragging when you want
the terminal's raw text selection instead.

Plugins never update on startup. Run `:PackUpdate` to open Neovim's review
buffer when you intentionally want to update them.
