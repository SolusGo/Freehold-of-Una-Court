"""Dry-run the full manifest against installed BNW + CP v151 schema.

The source debug database is read-only. This does not assert that Civilization
V has loaded the new mod. --loaded-db validates an actual modded cache if supplied.
"""
from collections import Counter
from pathlib import Path
import argparse
import hashlib
import json
import re
import sqlite3
import struct
import xml.etree.ElementTree as ET
from PIL import Image
from princedom_db import database
from validate_mod import ROOT, validate_project
from build_wealthy_inheritance import (CIV,BANK,PALACE,SCALARS,BENEFITS,
    add_schema_arguments,build,audit_schema,CONTRACT_PATH,DEFAULT_CP)


def check_identity(db):
    civ=db.execute('SELECT * FROM Civilizations WHERE Type=?',(CIV,)).fetchone()
    assert civ and (civ['Playable'],civ['AIPlayable'])==(1,0)
    assert db.execute('SELECT LeaderheadType FROM Civilization_Leaders WHERE CivilizationType=?',(CIV,)).fetchone()[0]=='LEADER_TRENT_WEALTHY'
    assert db.execute("SELECT TraitType FROM Leader_Traits WHERE LeaderType='LEADER_TRENT_WEALTHY'").fetchone()[0]=='TRAIT_TRENT_WEALTHY'
    assert tuple(db.execute("SELECT PrimaryVictoryPursuit,SecondaryVictoryPursuit FROM Leaders WHERE Type='LEADER_TRENT_WEALTHY'").fetchone())==('VICTORY_PURSUIT_DIPLOMACY','VICTORY_PURSUIT_SCIENCE')
    overrides=dict(db.execute('SELECT BuildingClassType,BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=?',(CIV,)))
    assert overrides=={'BUILDINGCLASS_BANK':BANK,'BUILDINGCLASS_PALACE':PALACE}
    assert not db.execute('SELECT * FROM Civilization_UnitClassOverrides WHERE CivilizationType=?',(CIV,)).fetchall()
    assert db.execute('SELECT BuildingClassType FROM Civilization_FreeBuildingClasses WHERE CivilizationType=?',(CIV,)).fetchone()[0]=='BUILDINGCLASS_PALACE'
    assert tuple(db.execute('SELECT UnitClassType,Count FROM Civilization_FreeUnits WHERE CivilizationType=?',(CIV,)).fetchone())==('UNITCLASS_SETTLER',1)
    expected={'CIVILIZATION_UNA_COURT','CIVILIZATION_DOMINION_UNA_COURT','CIVILIZATION_ULTIMATE_POSSESSION',
              'CIVILIZATION_TRENT_SOFT_KITTY','CIVILIZATION_TRENT_LIBRARY_EXILE',
              'CIVILIZATION_TRENT_PHONE_STEALER','CIVILIZATION_PRINCE_UNA',CIV}
    existing={r[0] for r in db.execute('SELECT Type FROM Civilizations')}
    assert expected <= existing, expected-existing
    for path in (ROOT/'SQL').glob('*Core.sql'):
        for value in re.findall(r"'(CIVILIZATION_[A-Z0-9_]+)'",path.read_text(encoding='utf-8')):
            if value!='CIVILIZATION_AMERICA': assert value in existing,value
    assert db.execute("SELECT Value FROM CustomModOptions WHERE Name='EVENTS_NEW_ERA'").fetchone()[0]==1
    assert db.execute('SELECT COUNT(*) FROM Civilization_CityNames WHERE CivilizationType=?',(CIV,)).fetchone()[0]==20
    assert db.execute('SELECT Text FROM Language_en_US WHERE Tag=(SELECT CityName FROM Civilization_CityNames WHERE CivilizationType=? ORDER BY rowid LIMIT 1)',(CIV,)).fetchone()[0]=='Freehold of Una Court'


def check_buildings(db):
    audit_schema(db,json.loads(CONTRACT_PATH.read_text(encoding='utf-8')))
    allowed={'ID','Type','Civilopedia','Strategy','Help'}
    for base,clone in [('BUILDING_UNA_CENTRELINK',BANK),('BUILDING_PALACE',PALACE)]:
        a=db.execute('SELECT * FROM Buildings WHERE Type=?',(base,)).fetchone()
        b=db.execute('SELECT * FROM Buildings WHERE Type=?',(clone,)).fetchone()
        for column in a.keys():
            skip=allowed|({'Description','PortraitIndex','IconAtlas'} if clone==PALACE else set())
            if column in skip:continue
            expected=a[column]
            if clone==BANK and column in SCALARS and expected>0:expected*=2
            assert b[column]==expected,(clone,column,b[column],expected)
        for table, in db.execute("SELECT name FROM sqlite_master WHERE type='table'"):
            if not table.startswith('Building_'):continue
            columns=[r[1] for r in db.execute(f'PRAGMA table_info("{table}")')]
            if 'BuildingType' not in columns:continue
            compare=[c for c in columns if c not in {'ID','BuildingType'}]
            positives=BENEFITS|({'Count'} if table=='Building_FreeSpecialistCounts' else set())
            old=db.execute(f'SELECT * FROM "{table}" WHERE BuildingType=?',(base,)).fetchall()
            new=db.execute(f'SELECT * FROM "{table}" WHERE BuildingType=?',(clone,)).fetchall()
            def expected(r):
                return tuple(r[c]*2 if clone==BANK and c in positives and r[c] is not None and r[c]>0 else r[c] for c in compare)
            assert Counter(map(expected,old))==Counter(tuple(r[c] for c in compare) for r in new),(table,clone)
    for tier in range(1,9):
        kind=f'BUILDING_TRENT_WEALTHY_LUXURY_{tier}'
        assert tuple(db.execute('SELECT UnmoddedHappiness,Happiness,Cost,FaithCost,IsDummy,ShowInPedia FROM Buildings WHERE Type=?',(kind,)).fetchone())==(tier,0,-1,-1,1,0)
        assert db.execute("SELECT Yield FROM Building_YieldChanges WHERE BuildingType=? AND YieldType='YIELD_GOLD'",(kind,)).fetchone()[0]==tier*2
    assert tuple(db.execute('SELECT BuildingClass,Capital,NeverCapture FROM Buildings WHERE Type=?',(PALACE,)).fetchone())==('BUILDINGCLASS_PALACE',1,1)
    assert db.execute("SELECT COUNT(*) FROM Buildings WHERE Type=?",(PALACE,)).fetchone()[0]==1
    assert db.execute("SELECT COUNT(*) FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType='BUILDINGCLASS_PALACE'",(CIV,)).fetchone()[0]==1


def localization_and_atlases(db):
    tags={r[0] for r in db.execute('SELECT Tag FROM Language_en_US')}
    references=set()
    for path in [ROOT/'Lua/TrentWealthy_Gameplay.lua',*sorted((ROOT/'SQL').glob('11*.sql'))]:
        references.update(re.findall(r'\bTXT_KEY_(?:CIV5_WEALTHY|CIVILOPEDIA_LEADERS_WEALTHY|WEALTHY)_[A-Z_0-9]+',path.read_text(encoding='utf-8')))
    references.discard('TXT_KEY_WEALTHY_CITY_')
    references.discard('TXT_KEY_CIV5_WEALTHY_LEADER') # CivilopediaTag prefix
    assert not references-tags,sorted(references-tags)
    atlases={}
    for action in ET.parse(ROOT/'UnaCourt.modinfo').findall('./Actions/OnModActivated/UpdateDatabase'):
        if action.text.endswith('.xml'):
            for row in ET.parse(ROOT/action.text).findall('./IconTextureAtlases/Row'):
                key=(row.findtext('Atlas'),int(row.findtext('IconSize')))
                assert key not in atlases,key
                atlases[key]=row
    for table in ('Civilizations','Leaders','Buildings'):
        for r in db.execute(f'SELECT * FROM {table} WHERE Type LIKE ?',('%TRENT_WEALTHY%',)):
            assert (r['IconAtlas'],64) in atlases,(table,r['Type'])
    print('PASS: Wealthy localization references, unique atlas keys and shared Centrelink art')


def dry_run(baseline_db=None,cp_root=DEFAULT_CP):
    db=database(baseline_db,cp_root)
    if db.execute('SELECT 1 FROM Civilizations WHERE Type=?',(CIV,)).fetchone():
        raise ValueError('Dry-run needs a pre-collection cache; select --baseline-db. Use --loaded-db for a cache containing Wealthy Trent.')
    actions=[n.text for n in ET.parse(ROOT/'UnaCourt.modinfo').findall('./Actions/OnModActivated/UpdateDatabase')]
    before=None
    def snapshot():
        return {t:Counter(tuple(r) for r in db.execute(f'SELECT * FROM "{t}"'))
                for t, in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")}
    for action in actions:
        if not action.endswith('.sql'):continue
        if action=='SQL/110_Wealthy_Inherit.sql':before=snapshot()
        db.executescript((ROOT/action).read_text(encoding='utf-8'))
    assert before
    after=snapshot()
    for table,old in before.items():
        if table=='CustomModOptions':continue # explicitly enables CP event hooks
        assert not old-after[table],('modified existing rows',table)
    check_identity(db);check_buildings(db);localization_and_atlases(db)
    # Preserve active Palace/Bank requirements, plus positive/negative effects
    # from other mods at activation. These are injected only into this memory DB.
    db2=database(baseline_db,cp_root)
    for action in actions:
        if action=='SQL/110_Wealthy_Inherit.sql':break
        if action.endswith('.sql'):db2.executescript((ROOT/action).read_text(encoding='utf-8'))
    db2.execute("UPDATE Buildings SET GoldMaintenance=7,Cost=321,TradeRouteRecipientBonus=-2 WHERE Type='BUILDING_UNA_CENTRELINK'")
    db2.execute("INSERT INTO Building_YieldChanges VALUES ('BUILDING_UNA_CENTRELINK','YIELD_SCIENCE',-3)")
    db2.execute("INSERT INTO Building_FreeSpecialistCounts VALUES ('BUILDING_UNA_CENTRELINK','SPECIALIST_MERCHANT',2)")
    for action in actions[actions.index('SQL/110_Wealthy_Inherit.sql'):]:
        if action.endswith('.sql'):db2.executescript((ROOT/action).read_text(encoding='utf-8'))
    check_buildings(db2)
    print('PASS: all manifest SQL, eight civilizations, human-only flags, ordinary starts, Bank/Palace replacements')
    print('PASS: every pre-existing DB row preserved (apart from explicitly enabled CP event options)')
    print('PASS: full Palace inheritance; positive-only Centrelink doubling; costs/prerequisites/negative effects retained')
    print('PASS: eight hidden total Palace tiers, Ancient/Medieval/Information +1/+2, +3/+6, +8/+16')
    print('NOTE: schema dry-run using installed CP definitions; new content has not been loaded by the game.')


def assets():
    validate_project()
    mod=ET.parse(ROOT/'UnaCourt.modinfo')
    files={n.text:n.attrib for n in mod.findall('./Files/File')}
    assert len(files)==len(mod.findall('./Files/File'))
    assert mod.getroot().get('id')=='7ec83c11-5853-453c-9ca7-0b2cf85a2a48' and mod.getroot().get('version')=='3'
    for name,attrs in files.items():
        assert hashlib.md5((ROOT/name).read_bytes()).hexdigest()==attrs['md5'],name
    project=ET.parse(ROOT/'UnaCourt.civ5proj');ns={'m':'http://schemas.microsoft.com/developer/msbuild/2003'}
    entries=[n.get('Include').replace('\\','/') for n in project.findall('.//m:ItemGroup/m:Content',ns)]
    assert len(entries)==len(set(entries)) and set(entries)==set(files)
    actions=[n.text for n in mod.findall('./Actions/OnModActivated/UpdateDatabase')]
    project_actions=[n.text for n in project.findall('.//m:ModActions/m:Action/m:FileName',ns)]
    assert actions==project_actions and actions.index('SQL/00_UnaCourt_Core.sql')<actions.index('SQL/110_Wealthy_Inherit.sql')
    for path in (ROOT/'Art/WealthyTrent').glob('*.dds'):
        assert files[path.relative_to(ROOT).as_posix()]['import']=='1'
        data=path.read_bytes();assert data[:4]==b'DDS ' and struct.unpack_from('<I',data,28)[0]>1
        with Image.open(path) as im:im.load()
    for row in ET.parse(ROOT/'Art/WealthyTrent/WealthyAtlases.xml').findall('.//Row'):
        path=ROOT/row.findtext('Filename');size=int(row.findtext('IconSize'))
        with Image.open(path) as im:
            assert im.size==(size,size)
            assert im.convert('RGBA').getchannel('A').getextrema()==(0,255)
    assert len(mod.findall('./EntryPoints/EntryPoint'))==5
    assert 'UnaInclude("TrentWealthy_Gameplay.lua")' in (ROOT/'Lua/UnaCourtLoader.lua').read_text()
    assert files['Lua/TrentWealthy_Gameplay.lua']['import']=='1'
    print(f'PASS: {len(files)} exact manifest hashes, matching project/actions, DDS transparency/mipmaps, loader and unchanged GUID/version')


if __name__=='__main__':
    parser=argparse.ArgumentParser();add_schema_arguments(parser)
    parser.add_argument('--loaded-db',type=Path,help='Read-only actual game cache; validates without replaying mod SQL')
    args=parser.parse_args()
    build(args.baseline_db,args.game_assets,args.cp_root,check=True)
    if not args.loaded_db:dry_run(args.baseline_db,args.cp_root)
    assets()
    if args.loaded_db:
        db=sqlite3.connect(f'file:{args.loaded_db.resolve().as_posix()}?mode=ro',uri=True);db.row_factory=sqlite3.Row
        check_identity(db);check_buildings(db)
        print('PASS: supplied database identities/buildings; in-game behavior still requires manual verification')
