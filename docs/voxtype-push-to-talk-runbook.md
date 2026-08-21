# Voxtype Push-to-Talk Dictation Runbook

This runbook reproduces the shared Voxtype behavior on a Fedora workstation or laptop:

1. Focus any text field.
2. Hold **Insert** and speak.
3. Release **Insert** and wait for the completion notification.
4. Paste with the application's normal shortcut, usually **Ctrl+Shift+V** in a terminal and
   **Ctrl+V** elsewhere.

Voxtype transcribes locally with Whisper, places the completed text on the clipboard, and
appends it to a private journal. The shared profile deliberately does not synthesize the whole
transcript as keyboard input.

## Why clipboard-only is the shared default

Long synthetic typing caused a KDE Wayland terminal client to be disconnected, taking its GUI
tabs with it. Automatic paste mode later emitted numeric key codes instead of a paste shortcut.
In both cases the transcription itself was valid in the clipboard.

Clipboard-only mode keeps the risky input-injection path out of the workflow. Manual paste is
one extra chord, but it is predictable, reviewable, and portable between applications. Do not
change the shared profile to `type` or `paste` without testing long dictation in disposable
windows on every supported compositor.

## Repository assets

- `voxtype/config.toml.example` is the canonical, hardware-independent configuration.
- `voxtype/voxtype-journal` saves each completed transcript before returning it to Voxtype.

The tracked files contain no hostname, username, microphone identifier, transcript, API key, or
other secret. The local transcript journal is intentionally not part of this repository.

## Fedora installation from nothing

These instructions use Voxtype 0.7.5, the current stable release when this runbook was written.
Before changing that version, review the stable release notes and test the upgrade on one machine.
Avoid release candidates unless testing them is intentional.

### 1. Install runtime and diagnostic packages

```bash
sudo dnf install \
  curl evtest gnupg2 gtk4-layer-shell libnotify pipewire-alsa pulseaudio-utils wl-clipboard
```

`wtype`, `dotool`, and `ydotool` are not required for this clipboard-only profile.

### 2. Download and verify the Voxtype RPM

Work in a temporary directory so installer artifacts do not enter the dotfiles repository:

```bash
VOXTYPE_VERSION=0.7.5
VOXTYPE_DOWNLOAD_DIR=$(mktemp -d)
cd "$VOXTYPE_DOWNLOAD_DIR"

curl -fLO \
  "https://github.com/peteonrails/voxtype/releases/download/v${VOXTYPE_VERSION}/voxtype-${VOXTYPE_VERSION}-1.x86_64.rpm"
curl -fLO \
  "https://github.com/peteonrails/voxtype/releases/download/v${VOXTYPE_VERSION}/voxtype-${VOXTYPE_VERSION}-1.x86_64.rpm.asc"

gpg --keyserver hkps://keys.openpgp.org \
  --recv-keys 9CCF7915B750CAE8B095ED1AA3FC9F33FD209279
gpg --verify \
  "voxtype-${VOXTYPE_VERSION}-1.x86_64.rpm.asc" \
  "voxtype-${VOXTYPE_VERSION}-1.x86_64.rpm"
sudo dnf install "./voxtype-${VOXTYPE_VERSION}-1.x86_64.rpm"
voxtype --version
```

The verification must report a good signature made by the dedicated release-signing fingerprint
`9CCF7915B750CAE8B095ED1AA3FC9F33FD209279`. Upstream cross-signs that key with the offline
maintainer fingerprint `E79F5BAF8CD51A806AA27DBB7DA2709247D75BC6`. A warning that the key is
not personally certified is normal; a bad signature is not. Stop if the release-signing
fingerprint differs or the signature is bad.

The Fedora RPM does not currently contain the GTK OSD executables even though the shared profile
enables that frontend. Download, verify, and install the two matching release assets:

```bash
for VOXTYPE_OSD_ASSET in \
  "voxtype-${VOXTYPE_VERSION}-linux-x86_64-osd" \
  "voxtype-${VOXTYPE_VERSION}-linux-x86_64-osd-gtk4"
do
  curl -fLO \
    "https://github.com/peteonrails/voxtype/releases/download/v${VOXTYPE_VERSION}/${VOXTYPE_OSD_ASSET}"
  curl -fLO \
    "https://github.com/peteonrails/voxtype/releases/download/v${VOXTYPE_VERSION}/${VOXTYPE_OSD_ASSET}.asc"
  gpg --verify "${VOXTYPE_OSD_ASSET}.asc" "${VOXTYPE_OSD_ASSET}"
done

sudo install -m 0755 \
  "voxtype-${VOXTYPE_VERSION}-linux-x86_64-osd" \
  /usr/local/bin/voxtype-osd
sudo install -m 0755 \
  "voxtype-${VOXTYPE_VERSION}-linux-x86_64-osd-gtk4" \
  /usr/local/bin/voxtype-osd-gtk4
```

Both detached signatures must be good signatures from the same release-signing fingerprint.

### 3. Grant access to the push-to-talk key

Voxtype reads the keyboard through Linux input events so it can catch **Insert** globally:

```bash
sudo usermod -aG input "$USER"
```

Fully log out of the desktop session and log back in. Opening another terminal is insufficient.
Then verify that the new session has the group:

```bash
id -nG | tr ' ' '\n' | grep -qx input && echo "input access OK"
```

If **Insert** does not register later, run `sudo evtest`, select the keyboard, and press Insert.
The event should be reported as `KEY_INSERT`. Exit `evtest` with Ctrl+C.

### 4. Download the local transcription model

```bash
voxtype setup --download --model base.en
voxtype setup check
```

The shared baseline uses the English-only `base.en` model on CPU. GPU acceleration is optional
and machine-specific; do not enable it merely to reproduce the behavior.

### 5. Install the shared configuration and journal helper

Set `DOTFILES_DIR` to this repository's checkout. The example below assumes the normal location:

```bash
DOTFILES_DIR="$HOME/code/dotfiles"
mkdir -p "$HOME/.config/voxtype"

if test -f "$HOME/.config/voxtype/config.toml"; then
  cp --preserve=all \
    "$HOME/.config/voxtype/config.toml" \
    "$HOME/.config/voxtype/config.toml.before-shared-profile.$(date +%Y%m%d-%H%M%S)"
fi

install -m 0644 \
  "$DOTFILES_DIR/voxtype/config.toml.example" \
  "$HOME/.config/voxtype/config.toml"
sudo install -Dm755 \
  "$DOTFILES_DIR/voxtype/voxtype-journal" \
  /usr/local/bin/voxtype-journal

voxtype --config "$HOME/.config/voxtype/config.toml" config
```

The last command must parse the file and show `INSERT`, `push_to_talk`, `base.en`, and
`clipboard`. It may also show defaults omitted from the canonical file.

#### Viper hotkey override

The shared configuration keeps `INSERT` so Lucifer retains its established behavior. Viper's
Framework Laptop 13 Pro gear key emits Linux input event `KEY_MEDIA`; override only Viper's live
configuration after installing the shared file:

```bash
sed -i 's/^key = "INSERT"$/key = "MEDIA"/' "$HOME/.config/voxtype/config.toml"
voxtype --config "$HOME/.config/voxtype/config.toml" config
```

The resolved configuration must show `MEDIA` on Viper. Toshy exclusively grabs Viper's physical
keyboard and forwards unhandled keys through its XWayKeyz virtual keyboard, so validate the gear
key with Toshy running during acceptance. Do not change the tracked shared key to `MEDIA` or copy
Viper's live override onto Lucifer.

### 6. Select the microphone without hard-coding hardware

The canonical config uses `device = "default"`. Choose the desired input in the desktop audio
settings, or inspect and change PipeWire's default source:

```bash
pactl list short sources
pactl get-default-source
```

Choose an actual input source, not one whose name ends in `.monitor`. To change it from the
terminal, copy the exact source name from the first command:

```bash
pactl set-default-source alsa_input.example_device.analog-stereo
pactl get-default-source
```

The source in that example is intentionally fictitious. Do not commit a real hardware source;
the laptop and workstation should each maintain their own system default.

### 7. Install and start the user service

```bash
systemctl --user daemon-reload
systemctl --user enable --now voxtype.service
systemctl --user --no-pager --full status voxtype.service
```

The final command should report `active (running)`.

### 8. Run the acceptance test

Open a disposable text field and perform the normal workflow: hold Insert, say a short sentence,
release Insert, wait for the notification, and paste manually.

Then verify both durable copies:

```bash
printf 'Clipboard:\n'
wl-paste
printf '\nJournal tail:\n'
tail -n 8 "$HOME/.local/share/voxtype/transcripts/transcripts.log"
```

Repeat with a one- to two-minute dictation before relying on the setup for important work. The
shared safety limit is ten minutes (`max_duration_secs = 600`).

## Daily operation and recovery

The service starts automatically with the user session. Useful checks are:

```bash
systemctl --user is-active voxtype.service
voxtype status
pactl get-default-source
journalctl --user -u voxtype.service -n 100 --no-pager
```

If text is not pasted, check the clipboard first with `wl-paste`, then inspect the transcript
journal. Clipboard history in the desktop environment may also retain a recent transcription.

The journal contains only completed transcriptions. It cannot recover speech if recording never
finished, the daemon crashed before post-processing, or Whisper failed to produce text. Raw audio
retention is deliberately disabled. For irreplaceable long dictation, pause periodically and paste
completed sections instead of making one very long recording.

The journal is private (`0700` directory and `0600` log) but may contain passwords, private
messages, or client data spoken aloud. Review and delete it according to the sensitivity of the
work:

```bash
less "$HOME/.local/share/voxtype/transcripts/transcripts.log"
```

## Troubleshooting

### Insert does nothing

```bash
id -nG
sudo evtest
journalctl --user -u voxtype.service -f
```

Confirm membership in `input`, confirm `KEY_INSERT` in `evtest`, and ensure only one Voxtype
daemon is running. Group changes require a full logout and login.

### The wrong microphone records

```bash
pactl get-default-source
pactl list short sources
```

Set the desired system default, unmute the microphone in hardware and software, and retry. Leave
the shared config set to `device = "default"`.

### Transcription completes but no text appears

This profile never inserts text automatically. Wait for the completion notification, inspect
`wl-paste`, and use the destination application's own paste shortcut.

### Numeric codes or unstable applications return

```bash
grep -A8 '^\[output\]' "$HOME/.config/voxtype/config.toml"
```

Confirm `mode = "clipboard"`. Restore the canonical config if the mode was changed, then restart
the service. Do not experiment with synthetic input in windows containing important work.

### The daemon is unhealthy

```bash
voxtype setup check
systemctl --user restart voxtype.service
systemctl --user --no-pager --full status voxtype.service
journalctl --user -u voxtype.service -n 200 --no-pager
```

## Keeping machines unified

Treat the two tracked assets as the source of truth. Shared behavior changes should follow this
order:

1. Update `voxtype/config.toml.example`, the helper, or this runbook.
2. Review the diff for hostnames, hardware identifiers, transcripts, secrets, and private paths.
3. Apply the tracked files to one machine and complete the acceptance test.
4. Commit the change, apply the same revision to the other machine, and test again.

Keep audio source selection, GPU tuning, and other hardware-specific decisions outside the shared
file. Compare a live configuration before replacing it:

```bash
DOTFILES_DIR="$HOME/code/dotfiles"
diff -u \
  "$DOTFILES_DIR/voxtype/config.toml.example" \
  "$HOME/.config/voxtype/config.toml"
```

## Updating Voxtype

The manually installed RPM is not tied to a third-party package repository. Check the
[official releases](https://github.com/peteonrails/voxtype/releases), read the stable release
notes, download that release's RPM and detached signature, and repeat the verification procedure
with the new version number.

Before installing an update:

```bash
cp --preserve=all \
  "$HOME/.config/voxtype/config.toml" \
  "$HOME/.config/voxtype/config.toml.before-update.$(date +%Y%m%d-%H%M%S)"
systemctl --user stop voxtype.service
```

Set `VOXTYPE_VERSION` to the reviewed stable version, install the verified RPM with
`sudo dnf install "./voxtype-${VOXTYPE_VERSION}-1.x86_64.rpm"`, reapply the tracked config and
helper, then run:

```bash
voxtype setup check
systemctl --user daemon-reload
systemctl --user restart voxtype.service
voxtype --version
systemctl --user --no-pager --full status voxtype.service
```

Complete both short and long acceptance tests. Keep the previously verified RPM until the new
version has been proven on both machines.

To roll back a bad package update, stop the service, set `VOXTYPE_VERSION` to the retained
known-good version, run
`sudo dnf downgrade "./voxtype-${VOXTYPE_VERSION}-1.x86_64.rpm"`, reinstall the last known-good
config and helper, and restart the service.

## Debian 12 compatibility note

The configuration and helper are distribution-independent, but the current upstream package is
not: Voxtype 0.7.5 requires Debian 13 or newer according to its installation guide. Do not blindly
replace a working Debian 12 installation with that package.

The known-good Debian 12 workstation currently runs Voxtype 0.7.1. Keep it pinned until an upgrade
has been tested for glibc compatibility, or follow the upstream source-build instructions for an
older distribution. Apply the same tracked configuration and helper so the user-facing behavior
remains unified even when package versions differ.

Primary references: [Voxtype installation](https://voxtype.io/docs/),
[configuration](https://voxtype.io/docs/CONFIGURATION), and
[troubleshooting](https://voxtype.io/docs/TROUBLESHOOTING).
