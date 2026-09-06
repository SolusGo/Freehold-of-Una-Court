"""Read the currently loaded CP baseline without changing the game database."""
import sqlite3
from validate_mod import GAME_USER_ROOT

db = sqlite3.connect(f"file:{(GAME_USER_ROOT / 'cache/Civ5DebugDatabase.db').as_posix()}?mode=ro", uri=True)
db.row_factory = sqlite3.Row
for table, kind in (("Buildings", "BUILDING_OPERA_HOUSE"), ("Units", "UNIT_MUSICIAN")):
    row = db.execute(f"SELECT * FROM {table} WHERE Type=?", (kind,)).fetchone()
    print(table, {key: row[key] for key in row.keys() if row[key] not in (None, 0, '', -1)})
for (table,) in db.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"):
    columns = [row[1] for row in db.execute(f'PRAGMA table_info("{table}")')]
    for column, kind in (("BuildingType", "BUILDING_OPERA_HOUSE"), ("UnitType", "UNIT_MUSICIAN")):
        if column in columns:
            rows = db.execute(f'SELECT * FROM "{table}" WHERE {column}=?', (kind,)).fetchall()
            if rows:
                print(table, [dict(row) for row in rows][:8])
