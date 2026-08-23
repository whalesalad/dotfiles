# Whalesalad Neovim guide

This is a quiet, project-scoped Neovim setup for WezTerm, tmux, and Toshy.
It keeps the familiar parts of Zed or Sublime—open-file tabs, a sidebar,
fuzzy finders, mouse support, and Mac-style shortcuts—while leaving normal Vim
behavior available underneath.

For implementation details and future changes, see
[`DEVELOPING.md`](DEVELOPING.md).

## Start a project

The directory where Neovim starts is the project root. Always enter the
top-level directory first:

```sh
cd ~/code/homelab
nvim
```

The sidebar, file finder, text search, and Git review stay scoped to that
directory. This is intentional: the config does not silently guess or change
projects.

If the scope is wrong, quit and restart Neovim from the correct directory.

## Physical Mac-style shortcuts

These are the keys to press on the physical keyboard. Toshy translates them
for WezTerm, and Neovim maps the resulting terminal keys.

| Physical key | Action |
| --- | --- |
| `Command-B` | Toggle the project sidebar |
| `Command-P` | Find a file in the project |
| `Command-Shift-P` | Find and run an editor command |
| `Command-S` | Save the current file |
| `Control-Tab` | Move to the next open file |
| `Control-Shift-Tab` | Move to the previous open file |

`Command-W` remains a WezTerm shortcut and is deliberately not used to close
an editor buffer. Use `Space` then `w` so an accidental keypress cannot close
the terminal.

## Space commands

Space is the Neovim **leader** key. Press the keys in sequence, not at the
same time. Pausing briefly after Space opens a WhichKey reminder.

| Key sequence | Action |
| --- | --- |
| `Space` then `p` | Command palette |
| `Space` then `b` | Find an already-open file |
| `Space` then `g` | Review changed Git files and their diffs |
| `Space` then `/` | Search text throughout the project |
| `Space` then `?` | Search all described key mappings |
| `Space` then `e` | Toggle the project sidebar |
| `Space` then `w` | Safely close the current file |

The close command refuses to discard unsaved changes. Save the file or use
`:bdelete!` only when discarding those changes is intentional.

## Fuzzy finders

The file finder and command palette open near the center of the screen. The
Git review and project-text search use a larger view with previews.

| Key | Action inside a finder |
| --- | --- |
| Type | Filter the list |
| `Up` / `Down` | Move through results |
| `Enter` | Open or run the selected result |
| `Escape` | Close the finder |

`Command-P` includes hidden files but respects `.gitignore`. Project text
search requires `rg` (ripgrep).

### Review changed files

Press `Space` then `g` to see added, removed, renamed, and modified files in
the current Git repository. The selected file's diff appears in the preview.
Press Enter to open it as a normal buffer/tab.

This picker is review-only. Telescope normally uses Tab to stage files; that
behavior is explicitly disabled here. Tab only marks a result.

## Project sidebar

Press `Command-B` to open or close the left sidebar. It always uses the launch
directory as its root and shows Git state next to files and folders.

| Key | Action in the sidebar |
| --- | --- |
| `Up` / `Down` or `j` / `k` | Move |
| `Enter` or double-click | Open a file or expand a directory |
| `Backspace` | Collapse a directory or move to its parent |
| `Tab` | Preview without leaving the sidebar |
| `q` or `Command-B` | Close the sidebar |
| `R` | Refresh |
| `H` | Toggle hidden dotfiles |
| `I` | Toggle Git-ignored files |
| `g?` | Show every sidebar command |

The sidebar also supports creating, renaming, and deleting files. Use `g?` to
discover those operations when needed; destructive operations ask for
confirmation.

## Open files and tabs

Every listed buffer appears as a tab across the top. Click a tab with the
mouse, use `Control-Tab`, or use these Vim-friendly alternatives:

| Key | Action |
| --- | --- |
| `]` then `b` | Next open file |
| `[` then `b` | Previous open file |
| `Alt-Right` / `Alt-Left` | Next / previous open file |
| `Space` then `b` | Fuzzy-find an open file |
| `Space` then `w` | Close the current file safely |

These are buffers presented like GUI-editor tabs. They are not Vim tabpages,
which have different semantics.

## Completion

Completion uses Blink. It currently suggests words from open buffers, file
paths, and snippets, and it is ready to accept language-server results when
language support is added later.

| Key | Action while completion is visible |
| --- | --- |
| `Up` / `Down` | Select a suggestion |
| `Enter` | Accept the selected suggestion |
| `Escape` | Dismiss the menu |
| `Control-Space` | Show completion or its documentation |
| `Tab` / `Shift-Tab` | Move through snippet placeholders |

There are no language servers configured yet. Missing code-aware completion
or diagnostics is expected, not a broken installation.

## Rich Markdown

Markdown is rendered directly inside Neovim. Headings, code blocks, bullets,
checkboxes, and pipe tables receive a richer presentation using the
`whalesalad` palette.

- Normal mode shows the rendered document.
- Insert mode reveals the source around the cursor so it remains editable.
- `:RenderMarkdown toggle` toggles rendering globally.
- `:RenderMarkdown buf_toggle` toggles only the current buffer.
- `:RenderMarkdown config` shows how this setup differs from plugin defaults.

Example source:

```markdown
| Service | State |
| --- | --- |
| DNS | Healthy |
| Storage | Degraded |
```

## Mouse and clipboard

Mouse support is enabled everywhere:

- Drag inside Neovim to create a Vim visual selection. Press `y` to copy it;
  the default register is connected to the Wayland desktop clipboard.
- Physical `Control-C` also copies a Vim visual selection.
- Physical `Control-X` cuts a Vim visual selection, and `Control-V` pastes
  while in insert mode.
- Hold Shift while dragging for WezTerm's raw terminal selection, then use
  `Command-C` to copy it.
- `Command-V` remains WezTerm's normal terminal paste shortcut.

This distinction matters because Toshy deliberately routes `Command-C` and
`Command-V` through WezTerm rather than through Neovim.

## Sixty-second Vim survival guide

Neovim is modal. Insert and replace modes are identified near the lower-left;
when uncertain, Escape always returns to normal mode.

| Key | Action |
| --- | --- |
| `i` | Enter insert mode before the cursor |
| `a` | Enter insert mode after the cursor |
| `o` | Create a new line and enter insert mode |
| `Escape` | Return to normal mode |
| `u` | Undo |
| `Control-R` | Redo |
| `dd` | Delete the current line |
| `yy` | Copy the current line |
| `p` | Paste after the cursor |
| `/text` then Enter | Search forward |
| `n` / `N` | Next / previous search result |
| `:q` | Quit the current window |
| `:qa` | Quit Neovim |
| `:qa!` | Quit and intentionally discard unsaved changes |

Run `:Tutor` for Neovim's interactive tutorial. `Space` then `?` is the most
useful escape hatch when a custom key is forgotten.

## What powers each feature

| Experience | Implementation | Configuration |
| --- | --- | --- |
| Project file, command, buffer, text, and Git finders | Telescope | `lua/whalesalad/pickers.lua` |
| Project sidebar | nvim-tree | `lua/whalesalad/plugins.lua` |
| Open-file tabs | bufferline | `lua/whalesalad/plugins.lua` |
| Completion | Blink | `lua/whalesalad/plugins.lua` |
| Git gutter marks | Gitsigns | `lua/whalesalad/plugins.lua` |
| Rich Markdown | render-markdown | `lua/whalesalad/plugins.lua` |
| Shortcut reminders | WhichKey | `lua/whalesalad/plugins.lua` |
| Mac-style entry points | Toshy, tmux extended keys, and Neovim mappings | `lua/whalesalad/keymaps.lua` |
| Visual design | Local `whalesalad` colorscheme ported from Zed | `colors/whalesalad.lua` |

## Updating plugins

Plugins never check for updates during startup. Their exact revisions live in
`nvim-pack-lock.json`.

When you intentionally want updates:

1. Run `:PackUpdate`.
2. Review the proposed changes. Use `]]` and `[[` to move between plugins.
3. Run `:write` to apply all proposed updates, or `:quit` to decline them.
4. Run `:restart` so every updated plugin is loaded cleanly.
5. Exercise `Command-P`, `Command-B`, `Space` then `g`, and a Markdown file.
6. Commit the changed `nvim-pack-lock.json` if the update is good.

For adding, removing, pinning, or rolling back plugins, see
[`DEVELOPING.md`](DEVELOPING.md).

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Wrong project files appear | Quit and launch from the intended top-level directory |
| `Command-B` does nothing | Run `:verbose nmap <C-b>` and confirm Toshy sees WezTerm as a terminal |
| `Command-Shift-P` opens files instead of commands | Reload tmux with `Control-A` then `r`; confirm `tmux show-options -s extended-keys` says `on` |
| File or text search fails | Run `rg --version` outside Neovim |
| Desktop clipboard fails | Run `:checkhealth vim.provider`; confirm `wl-copy` is installed |
| Markdown looks raw | Confirm the filetype with `:set filetype?`, then run `:RenderMarkdown enable` |
| A plugin behaves strangely | Run `:checkhealth`, then `:messages` |
| Configuration will not start | Run `nvim --clean` to open Neovim without this config |

The configuration is symlinked from `~/.config/nvim` to this repository. A
normal restart is preferred after configuration changes; the setup optimizes
for predictable startup rather than clever hot reloading.
