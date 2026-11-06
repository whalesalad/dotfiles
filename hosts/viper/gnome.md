# Viper GNOME rollout checklist

Status: planned, not installed or remotely verified by this work.

Use the shared [Fedora GNOME runbook](../../docs/fedora-gnome.md). Keep KDE and
its existing login manager available; preserve the existing Toshy installation.
Niri is a Chewy-only experiment and is not included here.

1. Verify Fedora release, current login manager, backup and existing Toshy status.
2. Preview/install the GNOME package list from the shared runbook.
3. Install Extension Manager; install a GNOME-version-compatible Xremap extension.
4. Inspect the existing overview shortcut, then add Toshy's launcher output as needed.
5. Configure Viper's own display in GNOME Settings. Do not copy Chewy's rotation,
   panel identity, 150% scaling, monitor file or tablet-service condition.
6. Review the shared KDE logout-cleanup drop-in if using lingering and switching
   desktops. It solved an observed issue on Chewy, not yet reproduced on Viper.
7. Use an independent tmux scope if sessions must survive logout; lingering alone
   does not detach a server from its terminal's service.
8. Test GNOME login, Toshy shortcuts, WezTerm, lock/unlock, suspend/resume,
   brightness, audio, file chooser and existing Chromium logins. Inspect fresh
   crash timestamps and failed user units before declaring success.

Record actual Viper results here after the guided rollout. Do not copy private
logs, keyrings, browser data, Toshy preferences or backup manifests into the repo.
