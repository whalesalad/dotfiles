#!/usr/bin/python3
"""Create a private, checksummed snapshot of KDE desktop settings and user assets."""
import argparse
import datetime
import hashlib
import io
import json
import os
from pathlib import Path
import socket
import subprocess
import tarfile
from urllib.parse import unquote, urlparse

CONFIG_NAMES = '''kdeglobals plasmarc plasmashellrc plasma-org.kde.plasma.desktop-appletsrc
kwinrc kwinrulesrc kglobalshortcutsrc kshortcutsrc kcminputrc kxkbrc kaccessrc
kscreenlockerrc ksmserverrc kded6rc plasma-localerc plasmanotifyrc
breezerc oxygenrc konsolerc dolphinrc kactivitymanagerdrc
powerdevilrc powermanagementprofilesrc kwinoutputconfig.json touchpadxlibinputrc
gtkrc gtkrc-2.0 gtk-3.0 gtk-4.0 fontconfig kdedefaults autostart environment.d'''.split()
DATA_NAMES = '''plasma kwin aurorae color-schemes icons wallpapers fonts
kscreen konsole kxmlgui5 kxmlgui6 sounds'''.split()
HARDWARE = ['config/kwinoutputconfig.json', 'data/kscreen', 'config/kcminputrc',
            'config/touchpadxlibinputrc', 'config/powerdevilrc',
            'config/powermanagementprofilesrc']
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output-dir', type=Path, default=Path(os.environ.get('XDG_STATE_HOME', Path.home()/'.local/state'))/'dotfiles/kde-snapshots')
args = parser.parse_args()
home = Path.home()
config = Path(os.environ.get('XDG_CONFIG_HOME', home/'.config'))
data = Path(os.environ.get('XDG_DATA_HOME', home/'.local/share'))
args.output_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
now = datetime.datetime.now().astimezone()
archive = args.output_dir / (socket.gethostname() + '-' + now.strftime('%Y%m%d-%H%M%S-%f') + '.tar.gz')
manifest = {'schema': 1, 'created': now.isoformat(), 'host': socket.gethostname(),
            'source_home': str(home), 'source_config': str(config), 'source_data': str(data),
            'consistency': 'Live saved files; not an atomic snapshot of running services.',
            'hardware_specific': HARDWARE, 'files': {}, 'missing': [], 'wallpapers': {}}
def output(command):
    try:
        return subprocess.check_output(command, text=True, stderr=subprocess.DEVNULL, timeout=30)
    except (FileNotFoundError, subprocess.SubprocessError):
        return None
manifest['plasma'] = output(['plasmashell', '--version'])
manifest['packages'] = output(['rpm', '-qa', '--qf', '%{NAME} %{VERSION}-%{RELEASE}.%{ARCH}\n']) or output(['dpkg-query', '-W'])
manifest['flatpaks'] = output(['flatpak', 'list', '--app', '--columns=application,version'])
# Include wallpaper files even when the current wallpaper lives outside XDG data.
wallpapers = set()
layout = config/'plasma-org.kde.plasma.desktop-appletsrc'
if layout.exists():
    for line in layout.read_text().splitlines():
        if line.startswith('Image='):
            value = line.partition('=')[2]
            parsed = urlparse(value)
            if parsed.scheme in ('', 'file'):
                path = Path(unquote(parsed.path)).expanduser()
                if path.is_file():
                    wallpapers.add(path)

with archive.open('xb') as archive_file:
    os.chmod(archive, 0o600)
    with tarfile.open(fileobj=archive_file, mode='w:gz', compresslevel=1, dereference=False) as tar:
        def add(path, name):
            if path.is_symlink():
                manifest['files'][name] = {'symlink': os.readlink(path)}
                tar.add(path, arcname=name, recursive=False)
            elif path.is_dir():
                tar.add(path, arcname=name, recursive=False)
                for child in sorted(path.iterdir()):
                    add(child, name + '/' + child.name)
            elif path.is_file():
                # Hash and archive the same bytes, even if a service updates the file.
                payload = path.read_bytes()
                manifest['files'][name] = {'sha256': hashlib.sha256(payload).hexdigest(), 'size': len(payload)}
                info = tar.gettarinfo(str(path), arcname=name)
                # Store independent file bytes even when the source has hardlinks.
                info.type = tarfile.REGTYPE
                info.linkname = ""
                info.size = len(payload)
                tar.addfile(info, io.BytesIO(payload))
        for base, prefix, names in [(config, 'config', CONFIG_NAMES), (data, 'data', DATA_NAMES)]:
            for name in names:
                path = base/name
                if path.exists() or path.is_symlink():
                    add(path, prefix+'/'+name)
                else:
                    manifest['missing'].append(prefix+'/'+name)
        for index, path in enumerate(sorted(wallpapers)):
            name = f'wallpaper-files/{index}-{path.name}'
            manifest['wallpapers'][str(path)] = name
            add(path.resolve(), name)
        payload = (json.dumps(manifest, indent=2) + '\n').encode()
        info = tarfile.TarInfo('manifest.json'); info.size = len(payload); info.mode = 0o600
        tar.addfile(info, io.BytesIO(payload))
# Verify every archived file against the manifest, without restoring anything.
with tarfile.open(archive, 'r:gz') as tar:
    recorded = json.load(tar.extractfile('manifest.json'))
verified = set()
with tarfile.open(archive, 'r|gz') as tar:
    for member in tar:
        entry = recorded['files'].get(member.name, {})
        if 'sha256' in entry:
            with tar.extractfile(member) as source:
                digest = hashlib.file_digest(source, 'sha256').hexdigest()
            if digest != entry['sha256']:
                raise SystemExit('Archive verification failed: ' + member.name)
            verified.add(member.name)
expected = {name for name, entry in recorded['files'].items() if 'sha256' in entry}
if verified != expected:
    raise SystemExit('Archive verification failed: missing members')
with archive.open('rb') as source:
    digest = hashlib.file_digest(source, 'sha256').hexdigest()
checksum = archive.with_suffix(archive.suffix+'.sha256')
with checksum.open('x') as target:
    os.chmod(checksum, 0o600)
    target.write(digest + '  ' + archive.name + '\n')
print(archive)
print(f'Verified {len(recorded["files"])} entries; archive size {archive.stat().st_size:,} bytes.')
print('Live saved-state snapshot; no desktop restart. See kde/README.md before restoration.')
