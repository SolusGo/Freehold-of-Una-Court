"""Read-only BNW debug DB plus schema from the user's installed CP v151.

This is schema/inheritance validation, not an assertion that the game loaded
these mods. No source database or game installation is changed.
"""
import re
import sqlite3
import xml.etree.ElementTree as ET
from validate_mod import find_vp_debug_database, GAME_USER_ROOT

CP=GAME_USER_ROOT/'MODS/(1) Community Patch'


def database():
    source=sqlite3.connect(f'file:{find_vp_debug_database().as_posix()}?mode=ro',uri=True)
    db=sqlite3.connect(':memory:')
    source.backup(db);source.close()
    db.row_factory=sqlite3.Row
    # CP recreates these tables rather than ALTER-adding its victory fields.
    leader_columns={r[1] for r in db.execute('PRAGMA table_info(Leaders)')}
    if 'PrimaryVictoryPursuit' not in leader_columns:
        db.executescript((CP/'Database Changes/AI/LeaderTableChanges.sql').read_text(encoding='utf-8-sig'))
    tables={r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    for path in (CP/'Database Changes').rglob('*.xml'):
        try: tree=ET.parse(path)
        except ET.ParseError: continue
        for table in tree.iter('Table'):
            name=table.get('name')
            if not name or name in tables:continue
            columns=[]
            for column in table.findall('Column'):
                definition='"'+column.get('name')+'" '+column.get('type','text')
                if column.get('default') is not None:definition+=' DEFAULT '+column.get('default')
                columns.append(definition)
            if columns:
                db.execute(f'CREATE TABLE "{name}" ({",".join(columns)})')
                tables.add(name)
    for path in (CP/'Database Changes').rglob('*.sql'):
        sql=path.read_text(encoding='utf-8-sig')
        for table,column,definition in re.findall(r'ALTER TABLE\s+(\w+)\s+ADD\s+(?:COLUMN\s+)?(\w+)\s+([^;]+);',sql,re.I):
            if table not in tables:continue
            columns={r[1] for r in db.execute(f'PRAGMA table_info("{table}")')}
            if column not in columns:db.execute(f'ALTER TABLE "{table}" ADD "{column}" {definition}')
    db.execute('CREATE TABLE IF NOT EXISTS Language_en_US (Tag TEXT PRIMARY KEY,Text TEXT)')
    db.execute('CREATE TABLE IF NOT EXISTS CustomModOptions (Name TEXT PRIMARY KEY,Value INTEGER)')
    options=ET.parse(CP/'Database Changes/NewCustomModOptions.xml')
    columns={r[1] for r in db.execute('PRAGMA table_info(CustomModOptions)')}
    for row in options.findall('.//CustomModOptions/Row'):
        values={k:v for k,v in row.attrib.items() if k in columns}
        keys=','.join('"'+k+'"' for k in values)
        placeholders=','.join('?' for _ in values)
        db.execute(f'INSERT OR IGNORE INTO CustomModOptions ({keys}) VALUES ({placeholders})',tuple(values.values()))
    return db
