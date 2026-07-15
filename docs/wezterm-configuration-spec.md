# WezTerm Workstation Configuration

## Goal

Replace the unsuccessful Ghostty experiment with a clean WezTerm setup that preserves the live Alacritty appearance while adding reliable tabs and macOS-style shortcuts under Toshy.

## Scope

The implementation will change only:

- a new tracked WezTerm configuration under `wezterm/wezterm.lua`;
- the live WezTerm configuration path at `~/.config/wezterm/wezterm.lua`, implemented as a symlink to the tracked file;
- one Toshy terminal-class matcher for WezTerm in `~/.config/toshy/toshy_config.py`.

Ghostty, Alacritty, and all unrelated Toshy mappings remain unchanged.

## Appearance

The live Alacritty configuration and its imported Modus Vivendi theme are the source of truth:

- font family: `Cascadia Code PL`;
- font weight/style: Regular;
- dim/half-intensity text: retain Regular or Regular Italic rather than WezTerm's generated ExtraLight rule, while preserving dimmed color intensity;
- font size: 15 pt;
- initial terminal size: 120 columns by 40 rows;
- background opacity: 0.90;
- cell width and line height: WezTerm defaults, equivalent to Alacritty's zero offsets;
- foreground/background, cursor, selection, normal ANSI, and bright ANSI colors: exact values from `~/.config/alacritty-themes/themes/modus-vivendi.yaml`.

The tab bar is hidden while only one tab exists and becomes visible when a second tab opens. Its active, inactive, hover, and background colors are derived directly from the same Modus Vivendi palette. WezTerm's normal terminal type is retained rather than forcing Alacritty's `xterm-256color`, so WezTerm-specific terminal capabilities remain available.

The explicit half-intensity font rules prevent applications that mark status or placeholder text as dim from switching to Cascadia Code PL ExtraLight. This keeps stroke weight consistent with Alacritty; WezTerm still conveys the dim attribute through color intensity.

## Keyboard Behavior

Toshy currently treats WezTerm as a regular GUI application, which prevents both standard terminal controls and the desired Command shortcuts from behaving correctly. The implementation will add a single case-insensitive-style matcher, `.*wezterm.*`, to the existing `terminals_lod` list beside Ghostty. This gives WezTerm Toshy's established terminal modifier behavior without changing any global mapping.

WezTerm will explicitly provide:

- Command+T: open a new tab in the current pane domain;
- Command+W: close the current tab immediately, without confirmation; closing the final tab closes the window;
- Command+1 through Command+9: activate exact one-based tab indexes 1 through 9.

Because Toshy emits Control+Shift+T and Control+Shift+W for its terminal Command mappings, those are the WezTerm triggers for tab creation and closure. Toshy's Command+number path emits Control+number, so Control+1 through Control+9 are the WezTerm tab-selection triggers. Actual terminal Control behavior such as Control+C remains unchanged.

## Safety and Rollback

The verified archive `~/Desktop/toshy-backup-safe-working-2026-07-14.tar.gz` is the hard rollback point. Its SHA-256 checksum is:

`b97ea502247c3ced1c5e5b57ec91f99572486073770ed03004dc9f2a61cf3962`

Before restarting anything, implementation will:

1. inspect the complete Toshy diff and confirm it contains one added matcher only;
2. compile-check `toshy_config.py` for Python syntax;
3. parse the new WezTerm configuration with the installed WezTerm binary;
4. verify the live WezTerm symlink resolves to the tracked file.

If Toshy fails to restart or keyboard behavior regresses, restore `~/.config/toshy` and its integration files from the verified archive, then restart the prior services. The WezTerm configuration is independently reversible by removing its new symlink; no Alacritty state is altered.

## Verification

Static verification will confirm:

- WezTerm accepts the configuration without warnings or errors;
- Cascadia Code PL Regular is resolved by WezTerm;
- the effective key table contains the intended tab actions;
- Toshy's only behavioral diff is the WezTerm class matcher.

Interactive verification will then confirm:

1. a single-tab window has no tab bar;
2. Command+T opens a second tab and reveals the tab bar;
3. Command+1 through Command+9 select the corresponding tabs;
4. Command+W closes the current tab immediately and closes the window when used on its final tab;
5. terminal Control+C and other standard terminal controls still reach the shell;
6. colors, font, dimensions, and transparency visually match Alacritty.
