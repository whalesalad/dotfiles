# Clipboard copying from Lucifer through Mosh and tmux

Viper's WezTerm connects to Lucifer through Mosh for responsive typing on high-latency links. Remote applications and tmux copy mode use OSC 52, a terminal escape sequence carrying base64 text, to write Viper's system clipboard. Lucifer's tmux configuration names the clipboard explicitly so Mosh 1.4 forwards these writes. The same setting works over SSH.

## Connection path and configuration

```text
Viper: application clipboard ← WezTerm ← Mosh 1.4 client
                                      ↑
Lucifer:                    Mosh 1.4 server ← tmux 3.3a ← app or copy mode
```

The shared `tmux.conf` loads `tmux/hosts/lucifer.conf` last. These lines in that host file are the clipboard fix:

```tmux
set -s set-clipboard on
set -s terminal-overrides 'xterm-256color:Ms=\E]52;%p1%.0sc;%p2%s\7'
```

`set-clipboard on` lets tmux send its own copies to the outside terminal and lets applications inside tmux, including a TUI's `/copy`, request a clipboard write. The previous default, `external`, sent tmux's own copies but did not accept clipboard writes from applications inside tmux. This also means any process able to write to a tmux pane can set the local clipboard; see the [tmux clipboard guide](https://github.com/tmux/tmux/wiki/Clipboard).

`Ms` is tmux's terminal clipboard capability. Mosh 1.4's server recognizes `OSC 52;c;<base64>`, with the explicit `c` selector, while tmux's usual capability can emit an empty selector. The override consumes tmux's first parameter with `%p1%.0s`, supplies `c`, and writes the base64 payload from `%p2%s`. Consuming the parameter matters: dropping `%p1` entirely can make the capability fail to expand. The rule matches `xterm-256color`, the terminal type observed on the Lucifer Mosh session. SSH clients using that terminal type also send the clipboard selection explicitly. See [Mosh's OSC 52 parser](https://github.com/mobile-shell/mosh/blob/mosh-1.4.0/src/terminal/terminalfunctions.cc) and the [Mosh/tmux clipboard discussion](https://github.com/mobile-shell/mosh/pull/1054).

The host file uses `set` rather than append, so reloading it does not duplicate terminal overrides. It replaces Lucifer's currently empty `terminal-overrides` value. If other overrides are added later, merge this rule with them. The host file also appends to `status-right`, so repeatedly sourcing the whole file can duplicate status text. For an existing tmux server, apply only the two clipboard commands above; new tmux clients then pick up the capability. Existing attached clients may need to detach and reattach. No tmux server restart is required.

## Tests performed on October 23, 2026

| Path | Result |
| --- | --- |
| Local shell → WezTerm → Viper clipboard | A direct OSC 52 write copied a marker. |
| Lucifer shell → Mosh → WezTerm → Viper clipboard, outside tmux | A unique marker copied successfully. Both Mosh ends were 1.4.0. |
| Lucifer tmux → SSH → captured terminal output | A fresh SSH client received the exact `OSC 52;c;` sequence for a tmux buffer copy. |
| Lucifer tmux → Mosh → captured terminal output | A disposable Mosh session received the exact sequence for a tmux buffer copy. |
| App inside Lucifer tmux → Mosh → captured terminal output | A disposable Mosh session received the exact sequence for an app generated OSC 52 write. |

The SSH and Mosh capture tests used isolated tmux sessions and did not change Viper's clipboard or restart existing tmux sessions. They verify the transport and tmux configuration for small payloads. The actual `/copy` command and a manual tmux mouse selection were not exercised in those capture tests.

## Check each layer

Paste each marker into a local Viper application with the normal clipboard paste shortcut. The `printf` commands themselves show no visible text; a blank terminal line after running one is normal.

1. In a local WezTerm shell on Viper, outside tmux and Mosh, check WezTerm's OSC 52 support:

   ```sh
   printf '\033]52;c;%s\007' "$(printf 'local-osc52-ok' | base64 | tr -d '\n')"
   ```

2. In a Mosh shell on Lucifer, outside tmux, use a new marker on each attempt:

   ```sh
   token="mosh-$(date +%s)"
   printf '\033]52;c;%s\007' "$(printf %s "$token" | base64 | tr -d '\n')"
   printf 'Expected paste: %s\n' "$token"
   ```

3. Attach to tmux through Mosh and check tmux's clipboard path:

   ```sh
   tmux show -s set-clipboard
   tmux info | rg 'Ms:'
   printf 'tmux-osc52-%s' "$(date +%s)" | tmux load-buffer -w -
   ```

   `set-clipboard` should be `on`. The `Ms` value should contain `52;` followed by the explicit `c` override shown above. Paste the marker locally. Then try a normal tmux copy-mode selection and the application's `/copy` command.

A tmux copy-mode selection uses tmux's clipboard path; `tmux load-buffer -w` checks that path without exercising the mouse binding. A selection made by WezTerm itself is a separate local action. If only mouse dragging fails, determine which program owns the selection before changing OSC 52 settings.

If the local test fails, investigate WezTerm or the local clipboard. If the direct Mosh test fails, check both Mosh versions and confirm the command is outside tmux with `printf 'TMUX=%s\n' "$TMUX"`. Use `mosh --version` to check the installed version; `mosh-server -v` is not a version check and can start a detached server. If only the tmux test fails, check the running tmux server's options and reattach the client after changing terminal capabilities. If the marker tests pass but `/copy` fails, inspect that application's copy method and the amount of text it sends.

## Remaining Mosh behavior and alternative

Mosh models the clipboard as terminal state and may suppress a second write of **identical** text even after another local application changes the clipboard. This [known caching issue](https://github.com/mobile-shell/mosh/issues/1090) explains why a repeated `hello` probe can appear to fail while a new marker works. Large clipboard payloads can also fail at an OSC 52 or application limit; the small tests above do not establish a safe maximum size. For a large `/copy` failure, compare with the same action over SSH and use a file transfer for substantial text.

If these limits are unacceptable, [`tssh --kcp` with `tsshd`](https://github.com/trzsz/tsshd) is a UDP based alternative with roaming and [OSC 52 clipboard support](https://github.com/trzsz/trzsz-ssh/blob/main/README.en.md). Its maintainers do not plan Mosh-style predictive local echo, so typing across roughly 250 ms RTT will likely feel less immediate. Mosh remains the preferred connection when typing responsiveness matters.
