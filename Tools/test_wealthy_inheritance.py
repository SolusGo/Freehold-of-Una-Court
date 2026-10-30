"""CP v151 generator/schema regression tests; never mutate the game's cache."""
from pathlib import Path
import hashlib
import json
import sqlite3
import tempfile
import xml.etree.ElementTree as ET
from build_wealthy_inheritance import (add_schema_arguments,render,audit_schema,schema_sources,
    CONTRACT_PATH,SQL_PATH)
from princedom_db import database
from validate_mod import find_vp_debug_database


def run(args):
    source=args.baseline_db or find_vp_debug_database()
    before=hashlib.sha256(source.read_bytes()).hexdigest()
    db=database(source,args.cp_root)
    sql,contract,count=render(db,args.game_assets,args.cp_root)
    assert count==296
    assert sql==SQL_PATH.read_text(encoding='utf-8')
    assert contract==CONTRACT_PATH.read_text(encoding='utf-8')
    assert (sql,contract,count)==render(db,args.game_assets,args.cp_root)
    print('PASS: SQL and schema contract exactly reproducible, 296 clones')

    db.execute('CREATE TABLE Building_OptionalOtherMod (BuildingType TEXT,Yield INTEGER)')
    db.execute("INSERT INTO Building_OptionalOtherMod VALUES ('BUILDING_PALACE',99)")
    db.commit()
    assert (sql,contract,count)==render(db,args.game_assets,args.cp_root)
    with tempfile.TemporaryDirectory(prefix='wealthy-schema-') as folder:
        snapshot=Path(folder)/'baseline.db'
        output=sqlite3.connect(snapshot);db.backup(output);output.close()
        copied=database(snapshot,args.cp_root)
        assert (sql,contract,count)==render(copied,args.game_assets,args.cp_root)
    print('PASS: absolute input paths and optional debug tables do not affect generation')

    schema=json.loads(contract)
    audit_schema(db,schema)
    table='Building_YieldChanges'
    db.execute(f'ALTER TABLE {table} RENAME TO MissingFromCP')
    try:audit_schema(db,schema)
    except ValueError as e:assert table in str(e)
    else:raise AssertionError('missing required table accepted')
    db.execute(f'ALTER TABLE MissingFromCP RENAME TO {table}')
    db.execute(f'ALTER TABLE {table} RENAME COLUMN Yield TO MissingYield')
    try:audit_schema(db,schema)
    except ValueError as e:assert 'Building_YieldChanges.Yield' in str(e)
    else:raise AssertionError('missing required column accepted')
    bad=sqlite3.connect(':memory:')
    bad.execute('CREATE TABLE Buildings (Happiness TEXT)')
    try:audit_schema(bad,{'tables':{'Buildings':{'Happiness':'INTEGER'}}})
    except ValueError as e:assert 'Buildings.Happiness' in str(e)
    else:raise AssertionError('non-numeric Happiness accepted')
    print('PASS: absent tables, absent fields and wrong scalar types fail explicitly')
    with tempfile.TemporaryDirectory(prefix='wealthy-cp-manifest-') as folder:
        cp=Path(folder);changes=cp/'Database Changes';changes.mkdir()
        (cp/'fixture.modinfo').write_text('''<Mod id="d1b6328c-ff44-4b0d-aad7-c657f83610cd" version="151">
<Actions><OnModActivated><UpdateDatabase>Database Changes/Active.xml</UpdateDatabase></OnModActivated></Actions></Mod>''',encoding='utf-8')
        active=changes/'Active.xml'
        text='''<GameData><!-- CP-style -- inside comments. -->
<Table name="Building_ActiveFixture"><Column name="BuildingType" type="text"/></Table></GameData>'''
        active.write_text(text,encoding='utf-8')
        (changes/'Inactive.xml').write_text('<GameData><Table name="Building_InactiveFixture"/></GameData>',encoding='utf-8')
        known,digest=schema_sources(args.game_assets,cp)
        assert 'Building_ActiveFixture' in known and 'Building_InactiveFixture' not in known
        active.write_bytes(text.replace('\n','\r\n').encode('utf-8'))
        assert schema_sources(args.game_assets,cp)==(known,digest)
        active.write_text('<GameData><Table broken</GameData>',encoding='utf-8')
        try:schema_sources(args.game_assets,cp)
        except ET.ParseError:pass
        else:raise AssertionError('malformed active schema silently skipped')
    print('PASS: only activated schema files count; line endings are stable; malformed schema fails')
    assert hashlib.sha256(source.read_bytes()).hexdigest()==before
    print('PASS: source database bytes unchanged')


if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser();add_schema_arguments(parser)
    run(parser.parse_args())
