#!/usr/bin/python3
"""Add/remove Lucifer-inspired stock Plasma 6 panel widgets in the live session."""
import argparse
import datetime
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
from gi.repository import Gio, GLib

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--apply', action='store_true', help='apply and reload the Plasma shell (default is preview)')
parser.add_argument('--remove', action='store_true', help='remove only widgets managed by this script')
parser.add_argument('--panel', type=int, help='panel ID; required if multiple horizontal panels exist')
parser.add_argument('--gpu', help='override GPU usage sensor ID in the captured profile')
parser.add_argument('--profile', type=Path, default=Path(__file__).with_name('panel-profile.json'))
parser.add_argument('--capture', action='store_true', help='save current managed widgets to --profile without changing the desktop')
args = parser.parse_args()
if args.capture and (args.apply or args.remove or args.gpu):
    parser.error('--capture cannot be combined with --apply, --remove or --gpu')
version = subprocess.check_output(['plasmashell', '--version'], text=True).strip()
if not version.startswith('plasmashell 6.'):
    raise SystemExit('This installer requires Plasma 6.')
bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
def call(service, path, interface, method, params=None):
    return bus.call_sync(service, path, interface, method, params, None,
                         Gio.DBusCallFlags.NONE, 15000, None).unpack()[0]
def evaluate(script):
    result = call('org.kde.plasmashell', '/PlasmaShell', 'org.kde.PlasmaShell',
                  'evaluateScript', GLib.Variant('(s)', (script,)))
    try:
        return json.loads(result)
    except ValueError:
        raise RuntimeError('Plasma script failed: ' + result)

panels = evaluate('print(JSON.stringify(panels().map(p=>({id:p.id,location:p.location}))));')
candidates = [p for p in panels if p['id'] == args.panel] if args.panel is not None else [p for p in panels if p['location'] in ('top', 'bottom')]
if len(candidates) != 1:
    raise SystemExit('Select one horizontal panel using --panel: ' + json.dumps(panels))
panel = candidates[0]['id']
# Read configuration through Plasma to decode KConfig escaping correctly.
if args.capture:
    captured = evaluate(r'''
const p = panelById(PANEL);
p.currentConfigGroup = ["General"];
const order = String(p.readConfig("AppletOrder", "")).split(";").map(Number);
const widgets = [];
function readGroups(w, path, groups) {
    w.currentConfigGroup = path;
    const keys = w.configKeys.slice();
    const children = w.configGroups.slice();
    const values = {};
    for (const key of keys) {
        if (path.length === 0 && ["PreloadWeight", "CurrentPreset"].indexOf(key)>=0) continue;
        values[key] = w.readConfig(key);
    }
    if (Object.keys(values).length) groups[path.join("/")] = values;
    for (const child of children) {
        if (path.length === 0 && ["Dotfiles", "ConfigDialog"].indexOf(child)>=0) continue;
        readGroups(w, path.concat([child]), groups);
    }
}
for (const id of order) {
    const w = p.widgetById(id);
    if (!w) continue;
    w.currentConfigGroup = ["Dotfiles"];
    if (w.readConfig("profile", "") !== "dotfiles-lucifer-panel-v1") continue;
    const role = w.readConfig("role", "");
    const groups = {};
    readGroups(w, [], groups);
    widgets.push({key:role,plugin:w.type,groups:groups});
}
print(JSON.stringify({schema:1,widgets:widgets}));
'''.replace('PANEL', str(panel)))
    if not captured['widgets']:
        raise SystemExit('No managed widgets found; refusing to overwrite the profile.')
    captured['source'] = {'plasma': version,
                          'captured': datetime.datetime.now().astimezone().isoformat()}
    args.profile.parent.mkdir(parents=True, exist_ok=True)
    if args.profile.exists():
        shutil.copy2(args.profile, args.profile.with_suffix('.json.bak'))
    temporary = args.profile.with_suffix('.json.tmp')
    temporary.write_text(json.dumps(captured, indent=2) + '\n')
    temporary.replace(args.profile)
    print('Captured:', args.profile)
    raise SystemExit()

specs = []
if not args.remove:
    profile = json.loads(args.profile.read_text())
    if profile.get('schema') != 1:
        raise SystemExit('Unsupported panel profile schema.')
    sensors = call('org.kde.ksystemstats1', '/org/kde/ksystemstats1', 'org.kde.ksystemstats1', 'allSensors')
    missing = []
    for spec in profile['widgets']:
        sensor_groups = spec['groups'].get('Sensors', {})
        for key in ['highPrioritySensorIds', 'lowPrioritySensorIds', 'totalSensors']:
            ids = json.loads(sensor_groups.get(key, '[]'))
            if args.gpu:
                ids = [args.gpu if sid.startswith('gpu/') and sid.endswith('/usage') else sid for sid in ids]
                if key in sensor_groups:
                    sensor_groups[key] = json.dumps(ids)
            unavailable = [sid for sid in ids if sid not in sensors and not any(re.fullmatch(sid, available) for available in sensors)]
            if spec['key'] == 'cpu-temperature':
                if key in sensor_groups:
                    sensor_groups[key] = json.dumps([sid for sid in ids if sid not in unavailable])
            else:
                missing.extend(unavailable)
        if spec['key'] == 'cpu-temperature' and not json.loads(sensor_groups.get('highPrioritySensorIds', '[]')):
            continue
        if args.gpu:
            for group in ['SensorColors', 'SensorLabels']:
                values = spec['groups'].get(group, {})
                for key in list(values):
                    if key.startswith('gpu/') and key.endswith('/usage'):
                        values[args.gpu] = values.pop(key)
        specs.append(spec)
    if missing:
        raise SystemExit('Missing sensors: ' + ', '.join(sorted(set(missing))) + '; use --gpu for another GPU sensor.')

script = r'''
const p = panelById(PANEL);
const specs = SPECS;
const remove = REMOVE;
const tag = "dotfiles-lucifer-panel-v1";
const managed = {};
for (const w of p.widgets()) {
    w.currentConfigGroup = ["Dotfiles"];
    if (w.readConfig("profile", "") === tag) managed[w.readConfig("role", "")] = w;
}
for (const s of specs) {
    if (knownWidgetTypes.indexOf(s.plugin) < 0) throw new Error("Missing widget: " + s.plugin);
}
p.currentConfigGroup = ["General"];
let order = String(p.readConfig("AppletOrder", "")).split(";").filter(Boolean).map(Number);
const existing = p.widgets().map(w=>w.id);
order = order.filter(id=>existing.indexOf(id)>=0);
for (const id of existing) if (order.indexOf(id)<0) order.push(id);
if (remove) {
    for (const key in managed) managed[key].remove();
    print(JSON.stringify({panel:p.id,removed:Object.keys(managed)}));
} else {
    const ids = [];
    const obsolete = [];
    for (const key in managed) {
        if (!specs.some(s=>s.key===key)) {
            obsolete.push(managed[key].id);
            managed[key].remove();
        }
    }
    order = order.filter(id=>obsolete.indexOf(id)<0);
    for (const s of specs) {
        const w = managed[s.key] || p.addWidget(s.plugin);
        w.currentConfigGroup = ["Dotfiles"];
        w.writeConfig("profile", tag); w.writeConfig("role", s.key);
        for (const group in s.groups) {
            w.currentConfigGroup = group ? group.split("/") : [];
            for (const key in s.groups[group]) w.writeConfig(key, s.groups[group][key]);
        }
        w.reloadConfig();
        ids.push(w.id);
    }
    const finalOrder = ids.concat(order.filter(id=>ids.indexOf(id)<0));
    print(JSON.stringify({panel:p.id,widgets:ids,order:finalOrder}));
}
'''.replace('PANEL', str(panel)).replace('SPECS', json.dumps(specs)).replace('REMOVE', str(args.remove).lower())
if not args.apply:
    print(json.dumps({'version': version, 'panel': panel, 'remove': args.remove, 'widgets': specs}, indent=2))
    raise SystemExit()
if not shutil.which('kwriteconfig6'):
    raise SystemExit('Install kwriteconfig6 before applying.')
subprocess.run(['systemctl', '--user', 'is-active', '--quiet', 'plasma-plasmashell.service'], check=True)
config = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config'))
state = Path(os.environ.get('XDG_STATE_HOME', Path.home() / '.local/state'))
backup = state / 'dotfiles/kde-panel' / datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
backup.mkdir(parents=True, mode=0o700)
for name in ['plasma-org.kde.plasma.desktop-appletsrc', 'plasmashellrc']:
    if (config / name).exists():
        shutil.copy2(config / name, backup / name)
print('Backup:', backup)
result = evaluate(script)
print(json.dumps(result, indent=2))
# The running panel can overwrite AppletOrder, and Plasma 6.7's widget index
# setter does not work here. Stop only the desktop shell before ordering.
subprocess.run(['systemctl', '--user', 'stop', 'plasma-plasmashell.service'], check=True)
try:
    if not args.remove:
        subprocess.run(['kwriteconfig6', '--file', str(config / 'plasma-org.kde.plasma.desktop-appletsrc'),
                        '--group', 'Containments', '--group', str(panel), '--group', 'General',
                        '--key', 'AppletOrder', ';'.join(map(str, result['order']))], check=True)
finally:
    subprocess.run(['systemctl', '--user', 'start', 'plasma-plasmashell.service'], check=True)
print('Plasma shell reloaded; applications remain open.')
