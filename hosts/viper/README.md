# viper system config

**Host-specific: only for `viper.mk3.dev`** (Framework Laptop 13 Pro, Intel Core
Ultra Series 3 / Panther Lake, Fedora 44, KDE Plasma, FreeIPA domain login via
SSSD in realm `QUAD5.NET`). Do not install these on other machines; the SSSD
file in particular names the `quad5.net` domain and server.

Files under `etc/` mirror their real paths under `/etc`. They are root-owned
system config, so they are copied into place, not symlinked.

| File | Purpose |
|---|---|
| `etc/sssd/conf.d/50-roaming-offline.conf` | Login never waits long on IPA. Short network timeouts (~10s worst case), a single `ipa_server`, and `cached_auth_timeout = 43200` so for 12h after an online login, passwords are checked against the local cache without touching the network. |
| `etc/sysctl.d/90-sysrq-debug.conf` | Magic SysRq limited to task dumps, sync, read-only remount, and reboot. |
| `etc/tmpfiles.d/90-pm-debug.conf` | Verbose suspend/resume kernel logging (`/sys/power/pm_debug_messages`). |
| `etc/systemd/journald.conf.d/90-sync-often.conf` | Flush the journal every 15s so logs survive a hard power-off. |

None of the debug settings ever reboot or panic the machine on their own.

## Install

Copy into place, then reload:

```sh
cd ~/code/dotfiles/hosts/viper
sudo install -Dm600 etc/sssd/conf.d/50-roaming-offline.conf /etc/sssd/conf.d/50-roaming-offline.conf
sudo install -Dm644 etc/sysctl.d/90-sysrq-debug.conf /etc/sysctl.d/90-sysrq-debug.conf
sudo install -Dm644 etc/tmpfiles.d/90-pm-debug.conf /etc/tmpfiles.d/90-pm-debug.conf
sudo install -Dm644 etc/systemd/journald.conf.d/90-sync-often.conf /etc/systemd/journald.conf.d/90-sync-often.conf

sudo sssctl config-check            # must report 0 issues before restarting SSSD
sudo systemctl restart sssd
sudo sysctl -p /etc/sysctl.d/90-sysrq-debug.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/90-pm-debug.conf
sudo systemctl restart systemd-journald
```

SSSD requires `0600` root-owned files in `conf.d`, or it refuses to start. Keep
a root shell or `sudo` session open when changing SSSD config, so a bad file
cannot lock you out.

## Verify

```sh
sudo sssctl domain-status quad5.net    # Online status, single server ipa.quad5.net
id michael                             # groups resolve, including admins
cat /sys/power/pm_debug_messages       # 1
sysctl kernel.sysrq                    # 184
systemd-analyze cat-config systemd/journald.conf | grep SyncInterval
```

Offline test: turn on airplane mode, lock the screen, unlock with the password.
It should unlock immediately.

SysRq test: hold Alt + Fn+S and tap H, then `sudo dmesg | tail -3` should show
`sysrq: HELP`.

To compare the repo with what is installed:

```sh
cd ~/code/dotfiles/hosts/viper
for f in $(find etc -type f); do sudo cmp -s "$f" "/$f" && echo "ok  /$f" || echo "DIFF /$f"; done
```

## When the machine hangs

Before holding the power button, hold **Alt + Fn+S** (SysRq on the Framework
keyboard) and tap, about a second apart:

1. **W**: dump stuck tasks with backtraces (the evidence)
2. **S**: sync disks
3. **U**: remount read-only
4. **B**: reboot

After rebooting, read the previous boot:

```sh
sudo journalctl -b -1 -k --no-pager | grep -E 'sysrq|blocked|PM:' | tail -100
```

## Remove

```sh
sudo rm /etc/sssd/conf.d/50-roaming-offline.conf \
        /etc/sysctl.d/90-sysrq-debug.conf \
        /etc/tmpfiles.d/90-pm-debug.conf \
        /etc/systemd/journald.conf.d/90-sync-often.conf
sudo systemctl restart sssd systemd-journald
sudo sysctl kernel.sysrq=16            # Fedora default
echo 0 | sudo tee /sys/power/pm_debug_messages
```

The pre-change SSSD config is backed up on viper at
`/etc/sssd/sssd.conf.bak-20261105` (the main file was not modified; the
drop-in above is the only SSSD change).

## Background (2026-11-05)

- Two hard hangs (Oct 26, Nov 5) were the kernel stalling while entering
  s2idle suspend, both within 10–20s of a previous wake. No log trace survived;
  the debug settings above exist to catch the next one.
- Offline login already worked when the network was fully down. The SSSD
  drop-in covers a half-up network (captive portal, Tailscale not yet up),
  where default timeouts and a duplicate server entry could stall login.
- BIOS was updated 03.02 → 03.04 the same day.
- The 2026-11-02 fingerprint experiment (Plasma Login PAM override and resume
  helper) was removed; see commit `bb46e07`.
