# KDE fingerprint unlock on Fedora 44

This machine uses Plasma 6.7, Plasma Login Manager, and an enrolled Goodix
fingerprint reader. The screen locker can authenticate by fingerprint, but
does not start checking until its UI receives activity. The installed systemd
unit calls Plasma's `SimulateUserActivity` after resume, so the standard lock
screen raises its prompt and starts fingerprint authentication on wake. It
does not activate the reader before suspend (which can interfere with s2idle).
Locking without suspending still follows Plasma's normal behavior and may need
an input event before fingerprint authentication starts.

Install the unit and helper:

```sh
sudo install -Dm755 kde/raise-lock-after-resume.sh /usr/local/libexec/dotfiles-kde-lock-raise
sudo install -Dm644 kde/fingerprint-resume.service /etc/systemd/system/dotfiles-kde-fingerprint-resume.service
sudo systemctl daemon-reload
sudo systemctl enable dotfiles-kde-fingerprint-resume.service
```

To remove it:

```sh
sudo systemctl disable dotfiles-kde-fingerprint-resume.service
sudo rm /etc/systemd/system/dotfiles-kde-fingerprint-resume.service /usr/local/libexec/dotfiles-kde-lock-raise
sudo systemctl daemon-reload
```

Plasma Login Manager 6.7 does not start biometric authentication automatically
at the boot greeter. A per-service PAM override can enable fingerprint login
after pressing Enter on the empty password field, while preserving password
fallback. This machine has that override at `/etc/pam.d/plasmalogin`; it is
separate from `authselect`'s generated files. It copies the vendor
`/usr/lib/pam.d/plasmalogin` file and adds this line immediately before the
`password-auth` substack:

```text
auth        sufficient    pam_fprintd.so timeout=5 max-tries=1
```

Because PAM runs these methods in sequence, password login can wait up to five
seconds for a fingerprint attempt to time out. To return to the vendor default,
run `sudo rm /etc/pam.d/plasmalogin`. After a Plasma Login Manager package
upgrade, compare the override against the new vendor file and carry forward
any upstream PAM changes. Fingerprint login will not automatically unlock an
encrypted KWallet, and the fingerprint reader cannot unlock LUKS before the
operating system starts.

After installation, suspend and wake once to test. The password field should
appear within about two seconds; then a fingerprint should unlock the session.
The resume service can be checked with
`journalctl -b -u dotfiles-kde-fingerprint-resume.service`.
