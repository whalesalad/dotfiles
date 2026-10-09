# Voxtype assets

`config.toml.example` and `voxtype-journal` remain the shared local baseline.
The October 9 YOLO trial adds remote transcription without changing that file:

- `remote-fallback.py`: loopback multipart transcription API, encrypted remote
  path through an SSH tunnel, notified local CLI fallback, bounded waits and
  a retry cooldown. Requires Python 3 and a verified Voxtype 0.7.5 local CLI.
- `voxtype-yolo-tunnel.service`: persistent key-only SSH forwarding to `yolo`.
- `voxtype-fallback.service`: adapter service; override `--local-binary` when
  the client does not use Chewy's `/usr/lib/voxtype/voxtype-vulkan` path.
- `yolo-whisper-start`: pinned Docker Vulkan server deployment on YOLO;
  requires model weights at `~/.local/share/whisper-server/models`.
- `test_remote_fallback.py`: deterministic failure/recovery tests, without
  desktop notifications, clipboard changes or recording actual speech.

Run tests from this repository:

```bash
python -B -m unittest discover -s voxtype -p test_remote_fallback.py
```

The canonical installed configuration, performance evidence, maintenance,
rollback, deferred quality tuning and Lucifer/Viper rollout procedure are in
[Chewy's runbook](https://github.com/whalesalad/chewy/blob/main/docs/voxtype.md).
Eager processing was tried and disabled: whole-recording GPU inference is
already fast, and chunking reduced reported quality. No other clients have
been migrated yet.
