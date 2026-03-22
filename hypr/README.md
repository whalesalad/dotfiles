# Hyprland

Config for Hyprland on **jackal** (MacBookPro15,1 / T2), running CachyOS.

## Required Packages

```bash
sudo pacman -S \
  hyprland \
  waybar \
  hyprpaper \
  wofi \
  ghostty \
  mako \
  network-manager-applet \
  brightnessctl \
  pamixer \
  grim \
  slurp \
  wl-clipboard \
  polkit-kde-agent
```

### Optional but recommended

```bash
# Key remapper — makes Cmd behave like macOS (copy/paste/etc.)
yay -S toshy

# Idle management / screen lock
sudo pacman -S hypridle hyprlock
```

## Setup

```bash
mkdir -p ~/.config/hypr
ln -sf ~/code/dotfiles/hypr/hyprland.conf ~/.config/hypr/hyprland.conf
ln -sf ~/code/dotfiles/hypr/hyprpaper.conf ~/.config/hypr/hyprpaper.conf
```

Set a wallpaper in `hyprpaper.conf` before first launch or the background will be black:

```ini
preload = ~/Pictures/wallpaper.jpg
wallpaper = ,~/Pictures/wallpaper.jpg
```

Log out → select **Hyprland** from the SDDM session menu → log in.

## Key Bindings

`$mod` = **Super** (Command key on MBP)

| Binding | Action |
|---|---|
| `$mod + Return` | Open terminal (ghostty) |
| `$mod + D` | App launcher (wofi) |
| `$mod + Q` | Close window |
| `$mod + F` | Fullscreen |
| `$mod + Shift + Space` | Toggle floating |
| `$mod + Shift + E` | Exit Hyprland |
| `$mod + H/J/K/L` | Move focus (vim keys) |
| `$mod + Shift + H/J/K/L` | Move window |
| `$mod + Ctrl + H/J/K/L` | Resize window |
| `$mod + 1–5` | Switch workspace |
| `$mod + Shift + 1–5` | Move window to workspace |
| `Print` | Screenshot selection → clipboard |
| `Shift + Print` | Screenshot fullscreen → `~/Pictures/` |

### MBP Function Keys

| Key | Action |
|---|---|
| `F1 / F2` | Brightness down / up |
| `F10 / F11 / F12` | Mute / Volume down / Volume up |
| `F5 / F6` | Keyboard backlight down / up |

## Display Scaling

The config defaults to `2x` for the Retina display:

```ini
monitor=,preferred,auto,2
```

Adjust to `1.5` if 2x feels too large.

## Touchpad Notes

`disable_while_typing` is implemented at the **compositor level** in Hyprland —
it works regardless of what libinput reports. This is a meaningful improvement
over KDE Plasma 6 on this hardware.

Palm detection (`palm_size_threshold`) is best-effort — the T2 trackpad presents
as a USB HID device so libinput has limited visibility into contact size/pressure.
Tune `scroll_factor` and `sensitivity` to taste.

## SSH / Terminal

Add to `~/.ssh/config` to avoid terminfo issues on remote hosts:

```
Host *
    SetEnv TERM=xterm-256color
```

## Toshy (macOS-like keybindings)

Toshy supports Hyprland via its IPC socket. After install it runs as user systemd services.

```bash
# Check it's running
systemctl --user status toshy-config.service toshy-kbd-mode.service

# Make sure you're in the input group
groups | grep input
# If not: sudo usermod -aG input $USER  (then log out/in)
```
