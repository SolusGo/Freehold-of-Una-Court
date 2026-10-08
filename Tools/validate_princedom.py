"""Validate real SQL against installed CP schema, DDS and both manifests."""
from collections import Counter
from pathlib import Path
import hashlib
import re
import struct
import xml.etree.ElementTree as ET
from PIL import Image
from princedom_db import database
from validate_mod import ROOT


def validate_database():
    db=database()
    # Activate the original six first, in exactly the manifest's order. Freeze
    # their real rows before adding the seventh to detect collection regressions.
    for action in ET.parse(ROOT/'UnaCourt.modinfo').findall('./Actions/OnModActivated/UpdateDatabase'):
        path=Path(action.text)
        if path.suffix=='.sql' and path.parts[0]!='Princedom':
            db.executescript((ROOT/path).read_text(encoding='utf-8'))
    bases={table:tuple(db.execute(f'SELECT * FROM {table} WHERE Type=?',(kind,)).fetchone())
           for table,kind in (('Units','UNIT_WARRIOR'),('Buildings','BUILDING_MONUMENT'))}
    existing_civs=Counter(tuple(r) for r in db.execute('SELECT * FROM Civilizations'))
    for path in sorted((ROOT/'Princedom/SQL').glob('*.sql')):db.executescript(path.read_text(encoding='utf-8'))
    for option in ('EVENTS_UNIT_CONVERTS','EVENTS_UNIT_CREATED','EVENTS_UNIT_UPGRADES','EVENTS_UNIT_PREKILL',
                   'EVENTS_COMMAND','EVENTS_CAN_MOVE_INTO','EVENTS_UNIT_ACTIONS','EVENTS_UNIT_RANGEATTACK',
                   'EVENTS_BATTLES','EVENTS_BATTLES_DAMAGE','EVENTS_GAME_SAVE','EVENTS_CITY','EVENTS_PLAYER_TURN',
                   'EVENTS_WAR_AND_PEACE','EVENTS_MINORS_INTERACTION'):
        assert db.execute('SELECT Value FROM CustomModOptions WHERE Name=?',(option,)).fetchone()[0]==1,option
    for table,kind in (('Units','UNIT_WARRIOR'),('Buildings','BUILDING_MONUMENT')):
        assert bases[table]==tuple(db.execute(f'SELECT * FROM {table} WHERE Type=?',(kind,)).fetchone())
    assert not (existing_civs-Counter(tuple(r) for r in db.execute('SELECT * FROM Civilizations')))
    warrior=db.execute("SELECT * FROM Units WHERE Type='UNIT_WARRIOR'").fetchone()
    trent=db.execute("SELECT * FROM Units WHERE Type='UNIT_PRINCE_TRENT'").fetchone()
    assert trent['Combat']==(warrior['Combat']*150+50)//100 and trent['Moves']==2
    assert trent['Cost']==trent['FaithCost']==-1
    assert trent['Class']=='UNITCLASS_WARRIOR'
    militia=db.execute("SELECT * FROM Units WHERE Type='UNIT_PRINCE_MILITIA'").fetchone()
    for column in warrior.keys():
        if column not in {'ID','Type','Class'}: assert warrior[column]==militia[column],column
    for original,clone in (('UNIT_WARRIOR','UNIT_PRINCE_TRENT'),('UNIT_WARRIOR','UNIT_PRINCE_MILITIA'),
                           ('BUILDING_MONUMENT','BUILDING_PRINCE_FANFIC')):
        key='UnitType' if original.startswith('UNIT_') else 'BuildingType'
        for table, in db.execute("SELECT name FROM sqlite_master WHERE type='table'"):
            columns=[r[1] for r in db.execute(f'PRAGMA table_info("{table}")')]
            if key not in columns or not table.startswith(('Unit_','Building_')):continue
            compare=[c for c in columns if c not in {'ID',key}]
            old=Counter(tuple(r[c] for c in compare) for r in db.execute(f'SELECT * FROM "{table}" WHERE {key}=?',(original,)))
            new=Counter(tuple(r[c] for c in compare) for r in db.execute(f'SELECT * FROM "{table}" WHERE {key}=?',(clone,)))
            assert old==new,(table,clone)
    monument=db.execute("SELECT * FROM Buildings WHERE Type='BUILDING_MONUMENT'").fetchone()
    fanfic=db.execute("SELECT * FROM Buildings WHERE Type='BUILDING_PRINCE_FANFIC'").fetchone()
    allowed={'ID','Type','Description','Civilopedia','Strategy','Help','PortraitIndex','IconAtlas'}
    for column in monument.keys():
        if column not in allowed:assert monument[column]==fanfic[column],column
    assert db.execute("SELECT Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_PRINCE_FANFIC_ACTIVE' AND YieldType='YIELD_CULTURE'").fetchone()[0]==2
    assert tuple(db.execute("SELECT GoldMaintenance,Cost,IsDummy,ShowInPedia FROM Buildings WHERE Type='BUILDING_PRINCE_FANFIC_ACTIVE'").fetchone())==(0,-1,1,0)
    for n in (80,82,85,88,90):
        assert db.execute('SELECT DamageTakenMod FROM UnitPromotions WHERE Type=?',(f'PROMOTION_PRINCE_RESIST_{n}',)).fetchone()[0]==-n
    assert db.execute("SELECT COUNT(*) FROM Civilization_CityNames WHERE CivilizationType='CIVILIZATION_PRINCE_UNA'").fetchone()[0]==20
    tags={r[0] for r in db.execute('SELECT Tag FROM Language_en_US')}
    references=set()
    for path in (ROOT/'Princedom').rglob('*'):
        if path.suffix in {'.sql','.xml','.lua'}:
            references.update(re.findall(r'\bTXT_KEY_PRINCE_[A-Z_0-9]+',path.read_text(encoding='utf-8')))
    # Prefixes assembled in SQL are deliberately not literal localization keys.
    references.discard('TXT_KEY_PRINCE_CITY_');references.discard('TXT_KEY_PRINCE_DIPLO_')
    assert not references-tags,sorted(references-tags)
    print('PASS: SQL, independent civilization, all baseline inheritance, 5 native resistance promotions and localization')


def validate_assets_and_wiring():
    mod=ET.parse(ROOT/'UnaCourt.modinfo')
    listed={f.text:f.attrib for f in mod.findall('./Files/File')}
    for filename,attrs in listed.items():
        path=ROOT/filename
        assert path.is_file(),filename
        assert hashlib.md5(path.read_bytes()).hexdigest()==attrs['md5'],filename
    for path in (ROOT/'Princedom').rglob('*.xml'):ET.parse(path)
    for path in (ROOT/'Princedom/Art').glob('*.dds'):
        header=path.read_bytes()[:128]
        assert header[:4]==b'DDS ' and struct.unpack_from('<I',header,28)[0]>1,path
        with Image.open(path) as im:
            im.load()
            if 'Alpha' in path.name:
                assert im.convert('RGBA').getchannel('A').getextrema()==(0,255)
    for row in ET.parse(ROOT/'Princedom/Art/PrinceAtlases.xml').findall('.//Row'):
        filename=row.findtext('Filename');size=int(row.findtext('IconSize'))
        with Image.open(ROOT/filename) as im:
            assert im.size==(size*int(row.findtext('IconsPerRow')),size*int(row.findtext('IconsPerColumn')))
        assert listed[filename]['import']=='1',filename
    for entry in mod.findall('./EntryPoints/EntryPoint'):assert entry.get('file') in listed
    for action in mod.findall('./Actions/OnModActivated/*'):assert action.text in listed
    for path in (ROOT/'Princedom').rglob('*'):
        if path.suffix in {'.sql','.xml','.lua','.dds'}:assert path.relative_to(ROOT).as_posix() in listed,path
    ui=(ROOT/'Princedom/UI/PrincePanel.lua').read_text(encoding='utf-8')
    assert 'SetUpdate(' not in ui
    loader=(ROOT/'Lua/UnaCourtLoader.lua').read_text(encoding='utf-8')
    assert 'UnaInclude("PrinceMain.lua")' in loader
    assert len(listed)==len(mod.findall('./Files/File'))
    assert len(mod.findall('./EntryPoints/EntryPoint'))==5
    print('PASS: DDS mipmaps, transparency, XML, exact manifest hashes, 5 UI contexts and event-driven panel')


if __name__=='__main__':
    validate_database()
    validate_assets_and_wiring()
