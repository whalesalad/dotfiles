#!/usr/bin/python3
"""Exercise the real Plasma mutation script against a mock panel, without D-Bus."""
import ast
import json
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
TREE = ast.parse((ROOT/'panel-widgets.py').read_text())
# Extract the literal passed through placeholder substitutions to Plasma.
SCRIPT = next(node.value for node in ast.walk(TREE) if isinstance(node, ast.Constant)
              and isinstance(node.value, str) and 'const remove = REMOVE;' in node.value)
PROFILE = json.loads((ROOT/'panel-profile.json').read_text())
MOCK = r'''
const assert = require('node:assert/strict');
const profile = PROFILE;
let added=0;
function widget(id, role) {
  return {id, type:'org.kde.plasma.systemmonitor', currentConfigGroup:[], values:{},
    readConfig(k,d) { return k==='profile' ? (role?'dotfiles-lucifer-panel-v1':'') : k==='role'?role:d; },
    writeConfig(k,v) {this.values[this.currentConfigGroup.join('/')+':'+k]=v;},
    reloadConfig(){}, remove(){items=items.filter(w=>w.id!==id);}};
}
let items=[widget(1,''),widget(2,'cpu'),widget(3,'gpu')];
const p={id:8, currentConfigGroup:[], widgets(){return items.slice();},
 readConfig(){return '1;2;3';},
 addWidget(plugin){const w=widget(10+added++,'');w.type=plugin;items.push(w);return w;}};
function panelById(id){assert.equal(id,8);return p;}
const knownWidgetTypes=['org.kde.plasma.systemmonitor','org.kde.plasma.digitalclock'];
let result;
function print(s){result=JSON.parse(s);}
'''

class PanelProfileTest(unittest.TestCase):
    def run_script(self, remove, assertions):
        script = SCRIPT.replace('PANEL','8').replace('SPECS',json.dumps(PROFILE['widgets'])).replace('REMOVE',str(remove).lower())
        subprocess.run(['node','-e',MOCK.replace('PROFILE',json.dumps(PROFILE))+ '\n{'+script+'}\n'+assertions],check=True)

    def test_upgrade_preserves_unmanaged_and_removes_retired_gpu(self):
        self.run_script(False,r'''
assert(items.some(w=>w.id===1));
assert(!items.some(w=>w.id===3));
assert.equal(added,3); // Existing CPU reused, three missing widgets created.
assert.equal(result.order.at(-1),1);
assert.equal(result.order.length,5);
const cpu=items.find(w=>w.id===2);
assert.equal(cpu.values['Appearance:title'],'CPU/GPU Usage');
assert.equal(cpu.values['Appearance:chartFace'],'org.kde.ksysguard.linechart');
assert.equal(cpu.values[':popupWidth'],'560');
const sensors=JSON.parse(cpu.values['Sensors:highPrioritySensorIds']);
assert(new RegExp('^'+sensors[1]+'$').test('gpu/gpu0/usage'));
assert(new RegExp('^'+sensors[1]+'$').test('gpu/gpu12/usage'));
''')

    def test_removal_preserves_unmanaged(self):
        self.run_script(True,"assert.deepEqual(items.map(w=>w.id),[1]); assert.equal(added,0);")

if __name__ == '__main__': unittest.main()
