# Maintaining the Whalesalad Neovim configuration

This document explains how the configuration is organized, how to change it
safely, and how to keep it small. The end-user workflow lives in
[`README.md`](README.md).

## Design principles

Changes should preserve these choices unless there is a deliberate reason to
revisit them:

1. **The launch directory is the project.** No automatic root detection or
   silent directory switching.
2. **Startup stays calm.** No dashboard, news screen, automatic update check,
   or routine progress display.
3. **Familiar keys coexist with Vim.** Toshy/WezTerm shortcuts handle common
   entry points without replacing modal editing.
4. **Plugins earn their place.** Prefer Neovim itself or an existing plugin
   before adding another dependency.
5. **Updates are reviewed and locked.** Plugin revisions are reproducible and
   change only through an explicit update.
6. **The configuration remains readable.** Keep responsibilities separated
   and give every custom mapping a description.

## Files and responsibilities

```text
nvim/
├── init.lua                         boot order and immutable project root
├── colors/
│   └── whalesalad.lua               editor, plugin, and syntax highlights
├── lua/whalesalad/
│   ├── options.lua                  built-in Neovim behavior
│   ├── plugins.lua                  package specs and plugin configuration
│   ├── pickers.lua                  project-scoped Telescope entry points
│   └── keymaps.lua                  user-facing key bindings
├── nvim-pack-lock.json              exact plugin revisions
├── README.md                        human usage guide
└── DEVELOPING.md                    this maintainer guide
```

The startup sequence in `init.lua` is intentional:

1. Set Space as leader and capture `vim.fn.getcwd()` in
   `vim.g.whalesalad_project_root`.
2. Apply built-in options.
3. Load the local colorscheme before plugin setup so plugins can derive it.
4. Install/load and configure plugins.
5. Define picker functions.
6. Define mappings after their targets exist.

## Runtime locations

| Item | Location |
| --- | --- |
| Tracked configuration | `~/code/dotfiles/nvim` |
| Active configuration | `~/.config/nvim` symlink |
| Installed packages | `~/.local/share/nvim/site/pack/core/opt` |
| Plugin revision lock | `nvim/nvim-pack-lock.json` in this repository |
| Persistent undo and state | Neovim's standard XDG state directory |

The symlink is the deployment mechanism. Editing either
`~/.config/nvim/...` or `~/code/dotfiles/nvim/...` changes the same files, but
repository paths are preferred in documentation and commits.

## Dependency management

The configuration automates plugin and declared language-parser installation.
Installing Neovim itself and its external tools still requires machine setup.
Updating dotfiles or plugins does not upgrade the Neovim executable.

| Layer | Manager and source of truth | Installation and updates |
| --- | --- | --- |
| Neovim executable | Machine installation; version must meet the requirements below | Installed and upgraded separately; Lucifer currently uses a manual installation in `/usr/local` |
| Editor plugins | Built-in `vim.pack`; specs in `lua/whalesalad/plugins.lua`, exact Git revisions in `nvim-pack-lock.json` | Missing plugins install at startup; `:PackUpdate` reviews explicit updates |
| Language parsers and highlighting queries | `nvim-treesitter`; required languages in its `install` list in `plugins.lua` | Missing declared languages install automatically; `:TSUpdate` synchronizes installed parsers with the revisions selected by the plugin |
| External tools | System packages or a separate tool installation | Git, ripgrep, clipboard tools, C compiler, curl, tar, and Tree-sitter CLI are provisioned separately |

The plugin lockfile belongs in Git. It also pins the `nvim-treesitter` version
that selects parser revisions, but it does not pin Neovim, the compiler, or
the Tree-sitter CLI. Parser updates are a separate step after updating that
plugin; they are not currently connected to an automatic update hook.

There is no single manager for every layer. A common alternative for plugins
is [lazy.nvim](https://github.com/folke/lazy.nvim); LazyVim is a preconfigured
distribution built around it. This setup uses Neovim's native `vim.pack` for
plugins and [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
for parsers and queries. A distribution would still depend on a compatible
Neovim executable and external tools.

For a language that should be available on every machine, add it to the
`nvim-treesitter` install list in `plugins.lua` and commit that change. For a
local addition, use `:TSInstall <language>` and reopen the document after
installation finishes. That command alone does not record the language in
dotfiles. Python is currently the only language explicitly declared; Neovim
also ships a small set of parsers, including Markdown and Lua.

There is no complete machine bootstrap for this stack yet. The remaining
automation gap is checking and provisioning compatible Neovim and external
tool versions before linking the configuration. The plugin lockfile already
handles plugin revisions; replacing the plugin manager would not close the
machine-provisioning gap.

## External requirements

The current baseline is Neovim 0.12 or newer, Git, ripgrep, and a clipboard
provider. Installing language parsers also requires a C compiler, curl, tar,
and the Tree-sitter CLI (0.26.1 or newer). On Fedora:

```sh
sudo dnf install neovim git ripgrep wl-clipboard gcc curl tar tree-sitter-cli
```

WezTerm supplies true color and the configured Cascadia Code PL glyphs. Toshy
supplies the physical Mac-style modifier behavior. tmux is configured
separately in this repository with `tmux-256color` and extended keys enabled;
the latter keeps combinations such as `Control-Shift-P` distinct from
`Control-P`.

After changing or deploying `tmux.conf`, reload it and verify extended-key
forwarding:

```sh
tmux source-file ~/.tmux.conf
tmux show-options -s extended-keys
tmux list-panes -a -F '#{pane_current_command} #{pane_key_mode}'
```

An active Neovim pane should report an extended mode such as `Ext 2`.

## Plugin inventory

| Plugin | Responsibility |
| --- | --- |
| `plenary.nvim` | Shared Telescope dependency |
| `telescope.nvim` | File, command, buffer, text, keymap, and Git-status pickers |
| `guess-indent.nvim` | Detect indentation from each file |
| `gitsigns.nvim` | Git additions, changes, and deletions in the sign column |
| `which-key.nvim` | Discoverable Space-key menus |
| `bufferline.nvim` | GUI-like open-buffer tabs |
| `nvim-tree.lua` | Project-rooted sidebar |
| `mini.icons` | Icons for Markdown and compatible plugins |
| `nvim-treesitter` | Language parsers and queries for syntax colors in fenced code |
| `render-markdown.nvim` | In-editor Markdown presentation and tables |
| `blink.cmp` | Buffer, path, snippet, and future LSP completion |

`blink.cmp` is constrained to `1.*` because its v2 line is under active
development. Other plugins are locked to their installed commits by
`nvim-pack-lock.json`, even when their package spec follows the default branch.

## Project-scope invariant

`vim.g.whalesalad_project_root` is captured exactly once during startup. Any
feature that searches files or runs a project command must use it explicitly.

Current examples:

- Telescope passes it as `cwd`.
- the sidebar passes it as `path` and refuses root updates;
- Git review invokes Git with `-C <project-root>`;
- the top sidebar label is derived from it.

Do not introduce automatic `.git`, LSP, or marker-file root detection without
first deciding to change the product behavior. A user can still open an
explicit external path manually; the project tools remain scoped.

## Changing built-in behavior

Edit `lua/whalesalad/options.lua` for Neovim options. Prefer the Lua option API:

```lua
vim.opt.scrolloff = 8
```

Use buffer-local or filetype-specific options when a global default would be
wrong for other languages. `guess-indent.nvim` should remain responsible for
detecting indentation in existing files.

Provider warnings are disabled only for providers this configuration does not
use. Re-enable the relevant `loaded_*_provider` variable before adding a plugin
that depends on a Python, Node, Ruby, or Perl host.

## Adding or changing a key mapping

Mappings belong in `lua/whalesalad/keymaps.lua`. Use its `map` helper and
always include a short description:

```lua
map('n', '<leader>x', some_action, 'Describe the action')
```

Descriptions power WhichKey and the `Space` then `?` keymap finder. Check for
collisions before choosing a key:

```vim
:verbose nmap <leader>x
:verbose imap <C-x>
```

For physical Command-key mappings, inspect Toshy's live terminal rules before
assuming what Neovim receives:

```sh
rg 'RC-[A-Z]|RC-[a-z]' ~/.config/toshy/toshy_config.py
```

WezTerm may consume terminal-level shortcuts such as `Command-C`, `Command-V`,
and `Command-W` before Neovim sees them. Support the translated sequence and
keep a leader-key fallback when practical.

## Adding or changing a picker

Picker entry points belong in `lua/whalesalad/pickers.lua` and return through
the module table. Every project-oriented picker must pass
`vim.g.whalesalad_project_root` as its `cwd` or equivalent.

The Git-status picker is intentionally non-mutating. Its local Tab mapping
overrides Telescope's staging action. Preserve that safety property unless a
separate, explicitly named Git client is introduced.

## Adding a plugin

Neovim 0.12's native `vim.pack` manages packages; there is no external plugin
manager or distro layer.

1. Add the GitHub source to the `vim.pack.add` list in `plugins.lua`.
2. Add its `require(...).setup { ... }` below the package list.
3. Restart Neovim. Missing packages install once with no confirmation screen.
4. Inspect the new entry in `nvim-pack-lock.json`.
5. Run the plugin's health check when it provides one.
6. Perform a real tmux UI smoke test.
7. Commit the config and lockfile together.

Example default-branch package:

```lua
github 'owner/plugin.nvim',
```

Example stable-major constraint:

```lua
{
  src = github 'owner/plugin.nvim',
  version = vim.version.range '1.*',
},
```

Prefer a semantic version constraint when the plugin's default branch carries
breaking development. The lockfile still controls the exact installed commit.

## Updating plugins

Run `:PackUpdate`. Neovim downloads metadata and opens a confirmation buffer;
it does not silently apply updates.

- `]]` and `[[` navigate plugin sections.
- `:write` accepts the proposed set.
- `:quit` declines it.
- `:restart` loads the accepted revisions cleanly.

If `nvim-treesitter` changed, run `:TSUpdate` after that restart, wait for its
installations to finish, and restart again. This ensures the newly loaded
plugin chooses the parser revisions and the final session loads the rebuilt
parsers.

After an update, inspect and commit `nvim-pack-lock.json`. Run at least the
tests below and manually exercise the entry points affected by updated
plugins.

To inspect installed packages without fetching updates:

```vim
:lua vim.pack.update(nil, { offline = true })
```

## Removing a plugin

1. Remove its setup and any mappings or highlights that depend on it.
2. Remove its spec from `vim.pack.add`.
3. Restart Neovim so the package is no longer active.
4. Delete the inactive package explicitly:

```vim
:lua vim.pack.del({ 'plugin-directory-name' })
```

5. Review the lockfile change and commit it with the config change.

Use `:lua =vim.pack.get()` to inspect the resolved package names when unsure.

## Rolling back a plugin update

The lockfile is the source of truth. Restore `nvim-pack-lock.json` from a known
good Git commit, restart Neovim, and synchronize installed packages back to
the lockfile:

```vim
:lua vim.pack.update({ 'plugin-name' }, { offline = true, target = 'lockfile' })
```

Review the proposed rollback and write the confirmation buffer. Avoid editing
lockfile revisions by hand.

## Maintaining the theme

`colors/whalesalad.lua` is a local colorscheme ported from
`../zed/whalesalad.json`, which remains the visual source of truth.

Terminal cells do not support per-highlight alpha. The port flattens Zed's
translucent backgrounds into opaque colors while preserving its dark ink-blue
base, cyan cursor, blue variables, red keywords, green strings, and gold
functions.

When changing the theme:

1. Update the base palette table.
2. Update standard Vim groups first.
3. Keep Tree-sitter groups linked to standard groups where possible.
4. Update plugin-specific groups only when their UI needs different contrast.
5. Test an ordinary source file, Markdown, Telescope, the sidebar, Git diffs,
   visual selection, and completion menus.

Inspect any highlight under the cursor with:

```vim
:Inspect
:hi HighlightGroupName
```

## Markdown maintenance

`render-markdown.nvim` uses the system Markdown and Markdown-inline
Tree-sitter parsers. `nvim-treesitter` installs Python's parser and highlight
queries so language-tagged fences use the Whalesalad syntax colors. Add
languages to its `install` list in `plugins.lua` to include them on every
machine, or run `:TSInstall <language>` for a local addition. Follow
[Updating plugins](#updating-plugins) when updating the parser manager. HTML,
LaTeX, and YAML rendering are disabled because their parsers are not part of
the current scope.

A fenced block needs a language tag, that language's parser, and highlighting
queries to distinguish its tokens. The theme then supplies their colors.
The Markdown parser alone can identify the code block without understanding
the language inside it. If an entire block has one color, check the language
tag and parser installation before changing the theme. Language servers are
not required for this highlighting.

Useful diagnostics:

```vim
:checkhealth render-markdown
:RenderMarkdown config
:set filetype?
```

Reconsider the disabled components only when a real document requires them;
install their parsers and test health in the same change.

### Lucifer deployment and Python highlighting repair — 2026-09-09

Two separate gaps were found during deployment:

- Lucifer had LazyVim configuration and Neovim
  `v0.10.0-dev-1934+g031088fc0`, with a binary dated December 2023 in
  `/usr/local/bin`. The old configuration, plugins, cache, and state were
  removed. Neovim 0.12.5 was installed from the official release archive,
  verified against its published SHA-256 digest, and `~/.config/nvim` was
  linked to this repository. The original binary's installation history was
  not established; changing configuration does not upgrade an executable.
- Python fences remained solid purple because the dotfiles setup supplied
  Markdown support but no Python parser or queries. This was missing language
  support in the new configuration, independent of the old Neovim version.
  Adding `nvim-treesitter` and declaring Python fixed it without changing the
  Whalesalad theme.

The Tree-sitter CLI release binaries tried during installation required
`GLIBC_2.39`, which Lucifer's Debian 12 installation did not provide. CLI
0.26.1 was built with Cargo from the upstream `v0.26.1` source tag and
installed in `~/.local/bin/tree-sitter`. The system C library was unchanged.
This CLI remains a separately managed dependency.

Verification confirmed Python was parsed inside a Markdown fence and its
highlighting resolved to Whalesalad's red keywords (`#ff3854`), green strings
(`#8fff58`), and blue numbers (`#0a9cff`).

## Validation checklist

Run these checks from `~/code/dotfiles` before committing:

```sh
git diff --check
nvim --headless "+lua assert(vim.g.whalesalad_project_root == vim.fn.getcwd())" "+qa"
nvim --headless "+lua assert(vim.g.colors_name == 'whalesalad')" "+qa"
nvim --headless "+lua assert(vim.fn.maparg('<C-b>', 'n', false, true).desc == 'Toggle project sidebar')" "+qa"
nvim --headless "+checkhealth render-markdown" "+silent write! /tmp/nvim-markdown-health.txt" "+qa"
```

For startup regressions:

```sh
nvim --headless --startuptime /tmp/nvim-startup.log "+qa"
tail /tmp/nvim-startup.log
```

Then perform a real tmux smoke test:

1. Open `nvim nvim/README.md`.
2. Toggle the sidebar with `Command-B`.
3. Open a second file with `Command-P` and confirm both tabs appear.
4. Open `Space` then `g` and inspect a changed-file preview.
5. Confirm the Markdown table renders and returns to source while editing.
6. Mouse-select text and verify both Neovim and raw WezTerm clipboard paths.

## Keeping documentation accurate

Update `README.md` in the same commit whenever a user-visible mapping or
workflow changes. Update this file whenever module ownership, plugin lifecycle,
requirements, or validation steps change.

The documentation should describe physical keys for the user and Neovim key
notation for maintainers. That distinction prevents Toshy and WezTerm
translation details from leaking into everyday instructions.
