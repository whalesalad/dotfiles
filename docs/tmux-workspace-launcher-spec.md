# Tmux Workspace Launcher Specification

## Purpose

Provide a small, host-local tmux workspace launcher for Lucifer. Remote clients use the existing `lu` command as the public interface; Lucifer uses `t` as the local interface. The launcher creates a named session on first use, prepares a session-wide project environment, and attaches or switches to an existing session on subsequent use.

The durable core depends only on Bash and tmux. `fzf` is an optional interface dependency used only by picker mode.

## Goals

- Preserve the existing `lu <name>` muscle memory for remote access to Lucifer.
- Add `lu` with no arguments to open a mobile-friendly picker on Lucifer.
- Add the equivalent local commands `t <name>` and `t` on Lucifer.
- Create configured workspaces at a declared root directory.
- Create unconfigured names as plain sessions rooted at the invocation directory.
- Automatically load a root directory's `.env` when it exists.
- Apply project and pyenv variables to the entire tmux session so future windows and panes inherit them.
- Prevent a workspace from inheriting an unrelated virtualenv from the tmux server.
- Keep workspace definitions small, public, version-controlled, and specific to each host.
- Rehydrate configured sessions lazily when selected after a reboot.

## Non-goals

- Declaring window or pane layouts.
- Starting all configured sessions at boot or through a bulk command.
- Capturing or restoring arbitrary running process state.
- Replacing tmux with another multiplexer.
- Parsing dotenv syntax or adding a dotenv dependency.
- Providing a general initialization hook in v1.
- Creating an arbitrary new name from inside the picker in v1.
- Synchronizing workspace definitions or runtime state between hosts.

## Repository Layout

```text
dotfiles/
├── bin/
│   └── t
├── tests/
│   └── t_test.sh
├── workspaces/
│   └── lucifer.sh
└── zsh/
    ├── base.zsh
    └── hosts/
        └── lucifer.zshrc
```

- `bin/t` is a standalone Bash program containing workspace discovery, validation, environment preparation, tmux creation, picker, and attach/switch behavior.
- `workspaces/<hostname>.sh` contains that host's workspace definitions. The hostname is obtained with `hostname -s`.
- `zsh/base.zsh` contains the remote `lu` function shared by clients.
- `zsh/hosts/lucifer.zshrc` exposes the local `t` shorthand for the harness.
- `tests/t_test.sh` exercises the harness against an isolated tmux server.

The harness is invoked directly from its repository path. It is not copied or symlinked into `~/.local/bin`.

## Commands

```text
t                 Open the local picker.
t <name>          Locally create or attach/switch to a session.
lu                Open Lucifer's picker over SSH.
lu <name>         Remotely create or attach to a Lucifer session.
```

Both commands accept zero or one argument. A session name must match:

```text
^[A-Za-z0-9_-]+$
```

Invalid names and extra arguments produce a usage error without invoking tmux. This validation occurs in `t`; `lu` also validates before constructing its remote command.

`lu` allocates a remote TTY and invokes this explicit Lucifer path:

```text
$HOME/code/dotfiles/bin/t
```

It does not depend on remote aliases, interactive shell startup, or the remote `PATH`.

## Workspace Configuration

Lucifer loads `workspaces/lucifer.sh`. A host without a matching file has no configured workspaces but can still list, create, and attach to plain sessions.

The configuration file is trusted Bash using a small registration function:

```bash
workspace titan \
  root_dir="$HOME/code/ocean/t3" \
  pyenv="titan"

workspace pipeline \
  root_dir="$HOME/code/ocean/data-pipeline" \
  pyenv="pipeline"
```

Supported properties in v1:

- `root_dir` is required and must resolve to an existing directory when the workspace is created.
- `pyenv` is optional. When present, it names the pyenv or pyenv-virtualenv environment to activate.

Unknown properties, duplicate workspace names, missing required values, and invalid names are configuration errors. Configuration contains metadata only; `.env` values and other secrets do not belong in this public file.

The launcher does not inspect or depend on `.python-version`. An explicit `pyenv=` property is the only pyenv instruction in the workspace registry.

## Session Resolution

For `t <name>`:

1. Validate the name.
2. If the tmux session already exists, immediately attach or switch to it. Do not load configuration, `.env`, or pyenv again.
3. Otherwise, load the host workspace registry.
4. If the name is configured, use its `root_dir` and optional `pyenv`.
5. If the name is not configured, use the current directory as its root and use no pyenv.
6. Prepare and validate the complete environment before creating the user-facing shell.
7. Create the session transactionally.
8. Attach or switch to it.

For `lu <unknown-name>`, the remote invocation directory is Lucifer's home directory, so a newly created plain session is rooted there.

Configuration is creation-only. Changes to a workspace definition or `.env` do not alter a running session; the session must be destroyed and recreated to receive them.

## Picker

Picker mode merges:

- all running tmux sessions, including unconfigured ones; and
- all configured host workspaces, including ones that are not running.

Duplicate names collapse into one row. Rows are sorted alphabetically by name. A fixed prefix column contains `*` when the tmux session currently exists and a space otherwise:

```text
* fparse
  pipeline
* titan
```

The star says only that the session exists. Attachment counts are neither queried nor displayed.

Below 80 columns, each row contains only the prefix and name. At 80 columns or wider, each row also displays the window count when running and the configured root directory when available. Names remain the first textual field, output does not wrap, and the picker has no preview pane, icon font requirement, or decorative Unicode dependency.

Typing in `fzf` filters existing rows. Unmatched query text is not interpreted as a new session name. Arbitrary session creation uses `t <name>` or `lu <name>`.

Canceling the picker with Escape or Ctrl-C exits without making changes. If `fzf` is unavailable, picker mode prints a concise error and known names, then exits nonzero. Named operation continues to work without `fzf`.

## Environment Contract

Every newly created session starts from a Python-neutral state. Virtualenv state inherited from the launcher or tmux server must not leak into it.

Environment preparation occurs in an isolated Bash process in this order:

1. Change to the resolved root directory.
2. Remove inherited virtualenv-specific state, including `PYENV_VERSION`, `PYENV_ACTIVATE_SHELL`, `PYENV_VIRTUAL_ENV`, `VIRTUAL_ENV`, and stale activation bookkeeping. Remove an inherited virtualenv `bin` entry from `PATH` when present while preserving the normal pyenv shims and pyenv installation paths.
3. If `<root_dir>/.env` exists, enable automatic exporting and source it as trusted shell syntax.
4. If `pyenv=` is configured, verify that `pyenv` is installed and that the named environment exists, then evaluate pyenv's own shell activation output.
5. Capture the project and pyenv environment changes for the tmux session.

A missing `.env` is normal and does nothing. A present `.env` must be readable and valid sourceable shell syntax. Any uncaught error while sourcing it aborts session creation. The launcher does not implement dotenv parsing.

If `pyenv=` is absent, the session remains Python-neutral except for variables deliberately established by the project's `.env`. If `pyenv=` is present, its activation takes precedence over conflicting inherited or `.env` pyenv activation state.

Only project and pyenv changes become session overrides. Dynamic values such as `SSH_AUTH_SOCK`, `DISPLAY`, terminal variables, and tmux client metadata remain under tmux's normal environment-update behavior.

## Transactional Tmux Creation

Tmux maintains a global server environment plus a per-session environment. New windows merge the two, with session values taking precedence. The launcher uses the session environment so every future window and pane receives the workspace environment.

Creation uses this transaction:

1. Resolve and validate the root, `.env`, and optional pyenv activation before changing tmux state.
2. Create a detached named session whose initial pane runs a temporary finite sleep command.
3. Mark inherited virtualenv variables as removed in the session environment.
4. Stream project and pyenv environment assignments to tmux over standard input, without persistent temporary files or values in tmux command-line arguments.
5. Respawn the initial pane with the user's normal shell and configured root directory.
6. Attach from outside tmux or switch clients from inside tmux.

The temporary process is never presented as the user's shell. If any operation fails after the detached session is created, a cleanup trap removes the incomplete session and reports the failure.

This approach uses tmux's native `new-session`, `set-environment`, and `respawn-pane` operations. It avoids starting the first real shell with a partial environment.

## Attach and Switch Behavior

- Outside tmux, `t` replaces itself with `tmux attach-session -t <name>`.
- Inside tmux, `t` uses `tmux switch-client -t <name>` rather than nesting clients.
- Selecting or naming the currently active session is harmless.
- Existing sessions never rerun initialization.

## Error Handling

Session creation is all-or-nothing. Before creating a user shell, the launcher rejects:

- unsupported or injection-shaped session names;
- malformed or duplicate workspace definitions;
- a configured root that does not exist;
- an unreadable or failing `.env`;
- a configured pyenv that is unavailable; and
- failures from tmux environment or pane operations.

Errors identify the workspace, failing phase, path, or variable name when useful, but never print environment values. Existing sessions remain attachable without reinitialization. A failed creation does not leave a partial named session behind.

## Security and Public Repository Constraints

- Host configuration may contain only non-secret names, paths, and pyenv identifiers.
- `.env` files remain in their projects and are never copied into the dotfiles repository.
- Shell tracing is disabled while environment files and pyenv output are processed.
- Environment values are not logged, printed in errors, placed in persistent temporary files, or passed as tmux command-line arguments.
- Workspace files and `.env` are trusted code because the harness sources them.
- Resolved values live in tmux's per-session environment and can be inspected by the same operating-system user with `tmux show-environment`; this is considered trusted runtime state.
- A private, untracked workspace overlay may be added later without changing the public workspace format, but it is not part of v1.

## Reboot Behavior

The launcher provides declarative, lazy rehydration rather than live process restoration:

- After a reboot, configured workspaces appear in the picker without a star.
- Selecting one creates it with its root and complete environment.
- Unconfigured sessions disappear after reboot and cannot be reconstructed automatically.
- No session starts at boot, and v1 has no bulk start command.

Tmux Resurrect, Continuum, tmuxp, Sesh, and similar third-party managers are not dependencies of this design. They may be evaluated independently without becoming part of the launcher's core contract.

## Testing

`tests/t_test.sh` uses plain Bash assertions, temporary project directories, and a uniquely named isolated tmux server socket. It never reads or mutates the user's real tmux server.

The suite covers:

1. Configured workspace creation at `root_dir`.
2. Successful creation when `.env` is absent.
3. Propagation of valid `.env` values to the first shell and later windows.
4. Failure of invalid `.env` without a leftover session.
5. Activation of an explicit `pyenv=` environment.
6. Removal of leaked global virtualenv state when `pyenv=` is absent.
7. Plain session creation at the invocation directory.
8. Rejection of invalid and injection-shaped names.
9. Alphabetical merging of running and configured sessions.
10. Picker cancellation without state changes.
11. Named operation without `fzf`.
12. Existing-session operation without reinitialization.
13. Cleanup of an incomplete session after a forced tmux-operation failure.

A final manual smoke test on Lucifer verifies `t`, `t <name>`, `lu`, and `lu <name>` through real terminals, including a narrow mobile-sized terminal.

## Acceptance Criteria

V1 is complete when:

- `t` and `lu` expose the documented picker and named interfaces.
- A configured workspace can be selected while absent, created at its root, and attached.
- A plain unknown name can be created without first editing configuration.
- `.env` and explicit pyenv activation are present in the initial shell and a subsequently created tmux window.
- A session without `pyenv=` does not inherit Lucifer's globally active `titan` virtualenv.
- Existing sessions attach or switch immediately without initialization.
- The picker is alphabetized, uses only the `*` existence marker, and remains usable in a narrow terminal.
- Named operation succeeds when `fzf` is unavailable.
- Automated tests pass against an isolated tmux server.

## Future Extensions

The following may be added only in response to demonstrated need:

- an `init=` sourced or executable hook;
- declared windows or panes;
- an explicit picker action for arbitrary new names;
- private workspace overlays;
- host definitions such as `workspaces/airlock.sh` or `workspaces/framework.sh`;
- a bulk start command; or
- an independent snapshot/recovery tool.

These extensions must preserve the core guarantee that `t <name>` works with Bash and tmux alone.
