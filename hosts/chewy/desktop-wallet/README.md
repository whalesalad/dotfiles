# Chewy: KDE Wallet across Wayland desktops

Applied November 7, 2026 on Fedora 45. User selected KDE Wallet and deferred oo7.
Current KDE provider is ksecretd and kdewallet is unlocked. Browser recovery was
accepted before these integration changes. KDE-to-GNOME login accepted with GitHub session and history preserved;
Niri has never been launched interactively.

## Files and behavior

`home/` mirrors only configuration installed under the user home:

- `.local/share/dbus-1/services/org.freedesktop.secrets.service`: pins D-Bus
  activation to ksecretd and desktop-ksecretd.service.
- `.config/systemd/user/desktop-ksecretd.service`: on-demand Type=dbus fallback;
  Wayland Qt backend. It is not enabled as a pre-desktop daemon. Normal login
  uses the existing PAM-spawned ksecretd instead.
- `dbus-org.freedesktop.secrets.service` alias selects that fallback rather than
  Fedora's oo7 alias. Masks defer oo7-daemon, oo7-portal and GNOME Keyring's
  daemon/socket. Packages and stored data are retained.
- `.config/autostart/gnome-keyring-secrets.desktop`: hides its competing secrets
  startup. Other GNOME Keyring components are not deliberately selected as
  credential providers.
- `.config/autostart/pam_kwallet_init.desktop`: enables the distro's existing
  unlock helper outside KDE through XDG autostart. KDE retains its native
  plasma-kwallet-pam.service. No duplicate unlock helper in Plasma.
- `.config/xdg-desktop-portal/{kde,gnome,niri}-portals.conf`: preserve each
  desktop's existing portal selections but choose kwallet for the Secret portal.
- `.local/bin/chromium-browser`: terminal launcher pins --password-store=kwallet6.
- `.local/share/applications/chromium-browser.desktop`: menu/default-browser
  launcher and actions pin the same backend while retaining distro flags.
  Direct absolute invocation of /usr/bin/chromium-browser still requires the
  flag. An already-running browser retains the first process's options.

`plasmalogin` is the installed `/etc/pam.d/plasmalogin` override, derived from
Fedora 45's `/usr/lib/pam.d/plasmalogin` by removing only optional
pam_gnome_keyring.so and pam_oo7.so auth/session hooks. Required authentication,
account/session policy and KDE wallet hooks are unchanged. No password is stored
in these files. A different display manager or future desktop requires its own
login/portal audit; this is not a promise that arbitrary sessions need no setup.

No SSH-agent, Git credential-helper, 1Password, Toshy or credential database
configuration was changed. No provider was killed/restarted during application.

## Replay and undo

Review differences against the installed vendor PAM, portal and Chromium files
first; these are Fedora 45 snapshots and do not automatically track package
updates. Back up every target, including pre-existing symlinks. Install home
files preserving symlinks and executable mode on `.local/bin/chromium-browser`.
Install reviewed plasmalogin as root with mode 0644 and restorecon. Run
`systemctl --user daemon-reload` and `update-desktop-database ~/.local/share/applications`.
Do not restart the display manager or user bus during a working session.

For the actual Chewy application, every old target was saved privately in:

`~/.local/state/desktop-setup/kde-wallet-global-20261107-002200/`

Undo as the normal user (sudo is needed only to restore/remove the PAM override):

```bash
python3 ~/.local/state/desktop-setup/kde-wallet-global-20261107-002200/undo.py
```

Undo restores previous file/symlink states and reloads systemd without terminating
providers. Log out/in when convenient to exercise the restored login setup.
The original browser-cookie recovery copies remain private and separate.

## Acceptance

Service syntax and desktop-file validation pass. systemd regenerated the unlock
helper with NotShowIn KDE (GNOME and Niri allowed). Current Secret Service still
belongs to ksecretd and the wallet remains unlocked. KDE-to-GNOME test passed: ksecretd owns Secret Service, kdewallet unlocked,
PAM helper success, browser login/history preserved, no failed user units.
Reverse transition and Niri remain untested.

Close Chromium before each desktop transition. Verify provider ownership and
wallet unlock before starting it, then verify browser sessions, Git and SSH.
Test KDE to GNOME and back first; Niri's first session adds display, Toshy,
launcher, switching and logout checks. Lingering PAM processes and the existing
KDE logout-cleanup behavior remain issues to watch; do not terminate the whole
user manager to clean them up. An on-demand fallback may prompt for a wallet
password if PAM unlock did not complete; do not create a replacement wallet.

References:
- https://github.com/KDE/kwallet/blob/master/README.md
- https://github.com/KDE/kwallet-pam

## GNOME login delay investigation and scoped mitigation

November 7 return from Niri to GNOME showed about 25 seconds of post-auth startup
waiting. Authentication succeeded at monotonic 3528.78; GNOME initialized near
3530.36, then Online Accounts cleanup timed out near 3555.94. Wallet fallback
readiness was delayed until 3557.14; GNOME portal until 3558.16. An earlier GNOME
login had the same pattern. No failed user units remained afterward.

PAM ksecretd loaded Qt's GTK3 platform theme. A credential/GTK/Online Accounts/
portal startup cycle is suspected, not fully reproduced. Isolated private-bus
probes with empty config/data did not reproduce the 25-second loop. A generic
Qt theme did demonstrate no GTK plugin loaded and provider readiness near 0.05s
in that isolated test; this is not proof of actual login improvement.

Applied process-scoped QT_QPA_PLATFORMTHEME=generic and
QT_NO_XDG_DESKTOP_PORTAL=1 to the non-KDE PAM environment helper, on-demand
desktop-ksecretd service, and a local kwallet Secret-portal activation descriptor.
The helper forwards these only to the PAM wallet daemon. Normal apps do not
inherit them; KDE's native plasma-kwallet-pam service is unchanged. This bypasses
GTK theme initialization and Qt's automatic portal probing for the provider;
it does not disable the Secret Service or its implemented Secret portal. Wallet
prompts in the affected path may use generic Qt styling. No wallet data or
provider selection changed, and the current daemon was not restarted.

Service/desktop validation passes; current wallet remains unlocked. Actual next
GNOME login timing and credential continuity are pending. Undo just this step:

```bash
python3 ~/.local/state/desktop-setup/wallet-startup-20261107-010700/undo.py
```

The original full-policy undo manifest was also extended to cover the added
kwallet portal descriptor. Neither undo terminates the current provider.

Source checks:
- https://raw.githubusercontent.com/qt/qtbase/v6.11.2/src/gui/platform/unix/qgenericunixtheme.cpp
- https://raw.githubusercontent.com/qt/qtbase/v6.11.2/src/gui/platform/unix/qdesktopunixservices.cpp
- https://raw.githubusercontent.com/qt/qtbase/v6.11.2/src/plugins/platformthemes/gtk3/qgtk3theme.cpp
