# Tmux Host Overrides

## Goal

Keep `tmux.conf` as the shared baseline while allowing small, tracked tmux
customizations for individual machines.

## Configuration layout

The shared config will quietly source one optional file beneath the standard
dotfiles checkout based on tmux's short hostname:

```text
~/code/dotfiles/tmux/hosts/<hostname>.conf
```

Hosts without a matching file will use only the shared configuration. Host
files load after the baseline so they can override shared bindings or append
host-specific status content.

## Initial host overrides

### Lucifer

Lucifer will override the shared copy-mode mouse bindings so each wheel event
scrolls three lines. The shared configuration will retain its current one-line
bindings for Viper and all other hosts.

### Viper

Viper will append battery information to `status-right` by invoking a small
helper. The helper will use UPower and emit:

- `72% 7:42` when discharging, using UPower's estimated time to empty;
- `72% charging` when charging;
- `100% full` when fully charged;
- no output when a battery is absent or UPower does not provide all data needed
  for the applicable format (including a time estimate while discharging).

The status command will run on tmux's existing 15-second status interval.

## Failure behavior

The optional host source must not report an error when a host file is absent.
The battery helper must fail quietly so missing UPower, missing hardware, or
incomplete estimates do not add error text to the status bar.

## Validation

- Parse the shared config and both host files with tmux.
- Exercise the battery helper against representative UPower output for
  discharging, charging, full, missing-time, and missing-battery cases.
- Verify the host source path expands from tmux's `host_short` format.
