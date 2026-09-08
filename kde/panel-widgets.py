#!/usr/bin/python3
"""Add/remove Lucifer-inspired stock Plasma 6 panel widgets in the live session."""
import argparse
import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess
from gi.repository import Gio, GLib

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--apply', action='store_true', help='apply and reload the Plasma shell (default is preview)')
parser.add_argument('--remove', action='store_true', help='remove only widgets managed by this script')
parser.add_argument('--panel', type=int, help='panel ID; required if multiple horizontal panels exist')
parser.add_argument('--gpu', default='gpu/all/usage', help='GPU utilization sensor ID')
args = parser.parse_args()
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
specs = []
def monitor(key, title, high, low, total, face, colors):
    specs.append(dict(key=key, plugin='org.kde.plasma.systemmonitor', groups={
        'Appearance': {'title': title, 'chartFace': 'org.kde.ksysguard.' + face},
        'Sensors': {'highPrioritySensorIds': json.dumps(high), 'lowPrioritySensorIds': json.dumps(low), 'totalSensors': json.dumps(total)},
        'SensorColors': colors}))
if not args.remove:
    sensors = call('org.kde.ksystemstats1', '/org/kde/ksystemstats1', 'org.kde.ksystemstats1', 'allSensors')
    required = ['cpu/all/usage', 'memory/physical/used', 'memory/physical/total', 'memory/physical/usedPercent', args.gpu]
    missing = [s for s in required if s not in sensors]
    if missing:
        raise SystemExit('Missing sensors: ' + ', '.join(missing) + '; choose --gpu from ksystemstats sensor IDs.')
    specs.append(dict(key='world-clock', plugin='org.kde.plasma.digitalclock', groups={
        'Appearance': {'selectedTimeZones': ['America/Los_Angeles', 'America/Vancouver', 'America/Phoenix', 'Local', 'Etc/UTC', 'Europe/London', 'Asia/Jerusalem'],
                       'lastSelectedTimezone': 'Etc/UTC', 'showDate': False, 'wheelChangesTimezone': True, 'showLocalTimezone': True}}))
    monitor('cpu', 'Total CPU Use', ['cpu/all/usage'], [], ['cpu/all/usage'], 'piechart', {'cpu/all/usage': '197,14,210'})
    monitor('memory', 'Memory Usage', ['memory/physical/used'], ['memory/physical/total'], ['memory/physical/usedPercent'], 'piechart', {'memory/physical/used': '14,210,179'})
    monitor('gpu', 'GPU Usage', [args.gpu], [], [args.gpu], 'piechart', {args.gpu: '255,85,0'})
    temps = [s for s in ['cpu/all/averageTemperature', 'cpu/all/maximumTemperature'] if s in sensors]
    if temps:
        monitor('cpu-temperature', 'CPU Temp', temps, [s for s in ['cpu/all/averageFrequency'] if s in sensors], [], 'linechart', {'cpu/all/averageTemperature': '210,105,14', 'cpu/all/maximumTemperature': '210,14,186'})

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
    for (const s of specs) {
        const w = managed[s.key] || p.addWidget(s.plugin);
        w.currentConfigGroup = ["Dotfiles"];
        w.writeConfig("profile", tag); w.writeConfig("role", s.key);
        for (const group in s.groups) {
            w.currentConfigGroup = group.split("/");
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
