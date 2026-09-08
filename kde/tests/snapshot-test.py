#!/usr/bin/python3
"""Verify snapshot payloads and link handling using isolated XDG directories."""
import json
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile

script = Path(__file__).resolve().parents[1]/'snapshot.py'
with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    cfg, data = root/'cfg', root/'data'
    cfg.mkdir(); data.mkdir()
    (cfg/'kdeglobals').write_text('[General]\nColorScheme=Example\n')
    os.link(cfg/'kdeglobals', cfg/'kwinrc')
    (data/'icons').mkdir()
    (data/'icons'/'test.svg').write_text('<svg/>')
    (data/'icons'/'alias.svg').symlink_to('test.svg')
    result = subprocess.run([str(script), '--output-dir', str(root/'out')],
                            env=dict(os.environ, XDG_CONFIG_HOME=str(cfg), XDG_DATA_HOME=str(data)),
                            text=True, capture_output=True)
    assert result.returncode == 0, result.stderr
    archive = next((root/'out').glob('*.tar.gz'))
    with tarfile.open(archive) as tar:
        manifest = json.load(tar.extractfile('manifest.json'))
        for name in ['kdeglobals', 'kwinrc']:
            assert tar.extractfile('config/'+name).read() == (cfg/name).read_bytes()
        assert manifest['files']['data/icons/alias.svg']['symlink'] == 'test.svg'
    assert archive.stat().st_mode & 0o777 == 0o600
    subprocess.run(['sha256sum', '-c', archive.name+'.sha256'], cwd=archive.parent, check=True)
    print('PASS snapshot payload recovery, hardlinks, symlinks, checksums and private permissions')
