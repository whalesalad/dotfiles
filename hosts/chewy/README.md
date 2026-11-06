# Chewy desktop setup

GNOME is installed and login, panel geometry, Toshy shortcuts and WezTerm were
verified on 2026-11-05/06. KDE remains available. Follow the shared
[GNOME runbook](../../docs/fedora-gnome.md) for packages, extension integration,
logout cleanup, lingering, verification and recovery.

## Host-only files

`home/` mirrors paths below `$HOME`. Back up existing destinations, then copy:

```sh
cd ~/code/dotfiles
install -Dm644 hosts/chewy/home/.config/monitors.xml ~/.config/monitors.xml
install -Dm644 hosts/chewy/home/.config/systemd/user/chewy-tablet-mode.service.d/kde-only.conf \
  ~/.config/systemd/user/chewy-tablet-mode.service.d/kde-only.conf
systemctl --user daemon-reload
```

The monitor file is specific to Chewy's rotated internal panel; never install it
on Viper. The tablet drop-in skips the existing KDE-dependent tablet-rotation
service outside KDE. It does not add GNOME tablet rotation support or alter the
underlying tablet scripts. Verified: service skipped in GNOME, no failed user units.

## Niri experiment

See [the experiment runbook](experimental/README.md). Configuration is installed
and syntax-checked, but a Niri desktop login has not yet been tested. This is not
part of the Viper GNOME rollout. No third-party switcher or COPR was added.
