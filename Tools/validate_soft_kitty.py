"""Validate the new civ against an in-memory copy of the active CP database."""
import re
import sqlite3
import xml.etree.ElementTree as ET
from PIL import Image
from validate_mod import GAME_USER_ROOT, ROOT, validate_project


def database():
    original = sqlite3.connect(f"file:{(GAME_USER_ROOT/'cache/Civ5DebugDatabase.db').as_posix()}?mode=ro", uri=True)
    db = sqlite3.connect(':memory:')
    original.backup(db)
    original.close()
    db.row_factory = sqlite3.Row
    db.execute('CREATE TABLE IF NOT EXISTS Language_en_US (Tag TEXT PRIMARY KEY, Text TEXT)')
    db.execute('CREATE TABLE IF NOT EXISTS CustomModOptions (Name TEXT PRIMARY KEY, Value INTEGER)')
    assert not db.execute("SELECT 1 FROM Civilizations WHERE Type='CIVILIZATION_TRENT_SOFT_KITTY'").fetchone(), 'Use a pre-Soft-Kitty cache for baseline comparison'
    for filename in ('70_SoftKitty_Inherit.sql','71_SoftKitty_Core.sql','72_SoftKitty_Text.sql'):
        db.executescript((ROOT/'SQL'/filename).read_text(encoding='utf-8'))
    allowed = {
        'Buildings': {'ID','Type','Description','Civilopedia','Strategy','Help','Happiness','PortraitIndex','IconAtlas'},
        'Units': {'ID','Type','Description','Civilopedia','Strategy','Help','PortraitIndex','IconAtlas'},
    }
    for table, base, clone in (
        ('Buildings','BUILDING_OPERA_HOUSE','BUILDING_TRENT_COMFORT_ROOM'),
        ('Units','UNIT_MUSICIAN','UNIT_TRENT_HOPELESS_ROMANTIC'),
    ):
        old = db.execute(f'SELECT * FROM {table} WHERE Type=?',(base,)).fetchone()
        new = db.execute(f'SELECT * FROM {table} WHERE Type=?',(clone,)).fetchone()
        assert new is not None
        for column in old.keys():
            if column not in allowed[table]:
                assert old[column] == new[column], (table,column,old[column],new[column])
    assert db.execute("SELECT Happiness FROM Buildings WHERE Type='BUILDING_TRENT_COMFORT_ROOM'").fetchone()[0] == db.execute("SELECT Happiness+1 FROM Buildings WHERE Type='BUILDING_OPERA_HOUSE'").fetchone()[0]
    for table,column,filter_column,filter_value,delta in (
        ('Building_YieldChanges','Yield','YieldType','YIELD_CULTURE',1),
        ('Building_SpecificGreatPersonRateModifier','Modifier','SpecialistType','SPECIALIST_MUSICIAN',10),
    ):
        values=[]
        for kind in ('BUILDING_OPERA_HOUSE','BUILDING_TRENT_COMFORT_ROOM'):
            values.append(db.execute(f'SELECT COALESCE(SUM({column}),0) FROM {table} WHERE BuildingType=? AND {filter_column}=?',(kind,filter_value)).fetchone()[0])
        assert values[1] == values[0]+delta, (table,values)
    names=db.execute("SELECT COUNT(*) FROM Unit_UniqueNames WHERE UnitType='UNIT_TRENT_HOPELESS_ROMANTIC'").fetchone()[0]
    assert names == db.execute("SELECT COUNT(*) FROM Unit_UniqueNames WHERE UnitType='UNIT_MUSICIAN'").fetchone()[0] and names > 0
    tags={r[0] for r in db.execute("SELECT Tag FROM Language_en_US")}
    for path in (ROOT/'SQL').glob('7*.sql'):
        referenced=set(re.findall(r"'(TXT_KEY_[A-Z0-9_]+)'",path.read_text(encoding='utf-8')))
        assert not referenced-tags, (path,referenced-tags)
    for prefix,sections in (('TXT_KEY_CIV5_SOFT_KITTY',6),('TXT_KEY_CIV5_SOFT_KITTY_LEADER',4)):
        for n in range(1,sections+1):
            assert f'{prefix}_HEADING_{n}' in tags and f'{prefix}_TEXT_{n}' in tags
    for n in range(1,16):
        row=db.execute('SELECT Yield FROM Building_YieldModifiers WHERE BuildingType=?',(f'BUILDING_TRENT_REPERCUSSION_PROD_{n}',)).fetchone()
        assert row[0] == -n
    print(f'Database passed: all baseline columns retained, {names} Great Work names, all penalties and Civilopedia sections')
    print('Dialogue categories:', ', '.join(r[0] for r in db.execute("SELECT DISTINCT ResponseType FROM Diplomacy_Responses WHERE LeaderType='LEADER_TRENT_SOFT_KITTY' ORDER BY ResponseType")))
    return db


def art_and_ui():
    validate_project()
    project = ET.parse(ROOT/'UnaCourt.civ5proj')
    ns = {'m':'http://schemas.microsoft.com/developer/msbuild/2003'}
    references = project.findall('.//m:ModReferences/m:Association', ns)
    assert any(r.findtext('m:Id', namespaces=ns) == 'd1b6328c-ff44-4b0d-aad7-c657f83610cd' for r in references), 'Missing CP load-order association'
    atlas=ET.parse(ROOT/'Art/SoftKitty_IconAtlases.xml')
    for row in atlas.findall('.//Row'):
        size=int(row.findtext('IconSize'))
        with Image.open(ROOT/row.findtext('Filename')) as im:
            assert im.size == (size*int(row.findtext('IconsPerRow')),size*int(row.findtext('IconsPerColumn')))
            assert im.convert('RGBA').getchannel('A').getextrema() == (0,255)
    tree=ET.parse(ROOT/'UI/TrentSoftKitty_UI.xml')
    ids={node.get('ID') for node in tree.iter() if node.get('ID')}
    code=(ROOT/'UI/TrentSoftKitty_UI.lua').read_text(encoding='utf-8')
    controls=set(re.findall(r'Controls\.(\w+)',code))
    assert not controls-ids, controls-ids
    assert 'SetNumRealBuilding' not in code and 'ChangeJONSCulture' not in code
    print('Project, atlas dimensions/transparency and UI control references passed')


if __name__=='__main__':
    database()
    art_and_ui()
