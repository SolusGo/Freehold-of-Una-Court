"""Validate Library Exile SQL, inherited CP baselines, art and project wiring."""
from pathlib import Path
import re
import sqlite3
import xml.etree.ElementTree as ET
from PIL import Image
from validate_mod import GAME_USER_ROOT, ROOT, validate_project


def database():
    source_path = GAME_USER_ROOT / "cache/Civ5DebugDatabase.db"
    source = sqlite3.connect(f"file:{source_path.as_posix()}?mode=ro", uri=True)
    db = sqlite3.connect(":memory:")
    source.backup(db)
    source.close()
    db.row_factory = sqlite3.Row
    db.execute("CREATE TABLE IF NOT EXISTS Language_en_US (Tag TEXT PRIMARY KEY, Text TEXT)")
    db.execute("CREATE TABLE IF NOT EXISTS CustomModOptions (Name TEXT PRIMARY KEY, Value INTEGER)")
    assert not db.execute("SELECT 1 FROM Civilizations WHERE Type='CIVILIZATION_TRENT_LIBRARY_EXILE'").fetchone()
    for name in ("80_LibraryExile_Inherit.sql", "81_LibraryExile_Core.sql", "82_LibraryExile_Text.sql"):
        db.executescript((ROOT / "SQL" / name).read_text(encoding="utf-8"))

    allowed_building = {"ID","Type","Description","Civilopedia","Strategy","Help","GoldMaintenance",
                        "SpecialistType","GreatPeopleRateChange","GreatWorkSlotType","GreatWorkCount",
                        "PortraitIndex","IconAtlas"}
    allowed_unit = {"ID","Type","Description","Civilopedia","Strategy","Help","PortraitIndex","IconAtlas"}
    for table, base, clone, allowed in (
        ("Buildings","BUILDING_LIBRARY","BUILDING_TRENT_SCHOOL_LIBRARY",allowed_building),
        ("Units","UNIT_WRITER","UNIT_TRENT_IPAD_READER",allowed_unit),
    ):
        old = db.execute(f"SELECT * FROM {table} WHERE Type=?", (base,)).fetchone()
        new = db.execute(f"SELECT * FROM {table} WHERE Type=?", (clone,)).fetchone()
        assert old is not None and new is not None
        for column in old.keys():
            if column not in allowed:
                assert old[column] == new[column], (table, column, old[column], new[column])
    school = db.execute("SELECT * FROM Buildings WHERE Type='BUILDING_TRENT_SCHOOL_LIBRARY'").fetchone()
    library = db.execute("SELECT * FROM Buildings WHERE Type='BUILDING_LIBRARY'").fetchone()
    assert school["Cost"] == library["Cost"] and school["GoldMaintenance"] == 1
    assert school["GreatPeopleRateChange"] == (library["GreatPeopleRateChange"] or 0) + 1
    assert school["SpecialistType"] == "SPECIALIST_WRITER"
    assert school["GreatWorkSlotType"] == "GREAT_WORK_SLOT_LITERATURE"
    assert school["GreatWorkCount"] == (library["GreatWorkCount"] or 0) + 1
    culture = db.execute("SELECT COALESCE(SUM(Yield),0) FROM Building_YieldChanges WHERE BuildingType='BUILDING_TRENT_SCHOOL_LIBRARY' AND YieldType='YIELD_CULTURE'").fetchone()[0]
    base_culture = db.execute("SELECT COALESCE(SUM(Yield),0) FROM Building_YieldChanges WHERE BuildingType='BUILDING_LIBRARY' AND YieldType='YIELD_CULTURE'").fetchone()[0]
    assert culture == base_culture + 1
    assert [tuple(row) for row in db.execute("SELECT YieldType,Yield FROM Building_YieldChangesPerPop WHERE BuildingType='BUILDING_TRENT_SCHOOL_LIBRARY' ORDER BY YieldType")] == [tuple(row) for row in db.execute("SELECT YieldType,Yield FROM Building_YieldChangesPerPop WHERE BuildingType='BUILDING_LIBRARY' ORDER BY YieldType")]
    writer_names = db.execute("SELECT COUNT(*) FROM Unit_UniqueNames WHERE UnitType='UNIT_TRENT_IPAD_READER'").fetchone()[0]
    assert writer_names == db.execute("SELECT COUNT(*) FROM Unit_UniqueNames WHERE UnitType='UNIT_WRITER'").fetchone()[0] and writer_names > 0
    for stack, modifier in ((1,3),(2,6),(3,9)):
        rows = dict(db.execute("SELECT YieldType,Yield FROM Building_YieldModifiers WHERE BuildingType=?", (f"BUILDING_TRENT_EXILE_{stack}",)).fetchall())
        assert rows == {"YIELD_SCIENCE":modifier,"YIELD_CULTURE":modifier}
    assert db.execute("SELECT Happiness FROM Buildings WHERE Type='BUILDING_TRENT_VISITOR_HAPPINESS'").fetchone()[0] == 2
    assert db.execute("SELECT Modifier FROM Building_SpecificGreatPersonRateModifier WHERE BuildingType='BUILDING_TRENT_VISITOR_WRITER' AND SpecialistType='SPECIALIST_WRITER'").fetchone()[0] == 15
    assert db.execute("SELECT COUNT(*) FROM Civilization_CityNames WHERE CivilizationType='CIVILIZATION_TRENT_LIBRARY_EXILE'").fetchone()[0] == 20
    tags = {row[0] for row in db.execute("SELECT Tag FROM Language_en_US")}
    referenced = set()
    for name in ("81_LibraryExile_Core.sql", "82_LibraryExile_Text.sql"):
        referenced |= set(re.findall(r"'(TXT_KEY_[A-Z0-9_]+)'", (ROOT / "SQL" / name).read_text(encoding="utf-8")))
    assert not referenced - tags, sorted(referenced - tags)
    for prefix, sections in (("TXT_KEY_CIV5_LIBRARY_EXILE",6),("TXT_KEY_CIV5_LIBRARY_EXILE_LEADER",4)):
        for index in range(1, sections + 1):
            assert f"{prefix}_HEADING_{index}" in tags and f"{prefix}_TEXT_{index}" in tags
    print(f"Database passed: CP Library/Writer inherited, {writer_names} writer names, Visitor and Exile values verified")


def full_mod_database():
    source_path = GAME_USER_ROOT / "cache/Civ5DebugDatabase.db"
    source = sqlite3.connect(f"file:{source_path.as_posix()}?mode=ro", uri=True)
    db = sqlite3.connect(":memory:")
    source.backup(db)
    source.close()
    db.execute("CREATE TABLE IF NOT EXISTS Language_en_US (Tag TEXT PRIMARY KEY, Text TEXT)")
    db.execute("CREATE TABLE IF NOT EXISTS CustomModOptions (Name TEXT PRIMARY KEY, Value INTEGER)")
    # Exercise the last two additions together when Soft Kitty is not already
    # present in the active debug DB; then apply Library Exile in real order.
    scripts = []
    if not db.execute("SELECT 1 FROM Civilizations WHERE Type='CIVILIZATION_TRENT_SOFT_KITTY'").fetchone():
        scripts += ["70_SoftKitty_Inherit.sql","71_SoftKitty_Core.sql","72_SoftKitty_Text.sql"]
    scripts += ["80_LibraryExile_Inherit.sql","81_LibraryExile_Core.sql","82_LibraryExile_Text.sql"]
    for name in scripts:
        db.executescript((ROOT / "SQL" / name).read_text(encoding="utf-8"))
    civs = ("CIVILIZATION_UNA_COURT","CIVILIZATION_DOMINION_UNA_COURT",
            "CIVILIZATION_ULTIMATE_POSSESSION","CIVILIZATION_TRENT_SOFT_KITTY",
            "CIVILIZATION_TRENT_LIBRARY_EXILE")
    for civ in civs:
        if db.execute("SELECT COUNT(*) FROM Civilizations WHERE Type=?", (civ,)).fetchone()[0]:
            assert db.execute("SELECT COUNT(*) FROM Civilization_Leaders WHERE CivilizationType=?", (civ,)).fetchone()[0] == 1
    assert db.execute("SELECT COUNT(*) FROM Civilizations WHERE Type IN ('CIVILIZATION_TRENT_SOFT_KITTY','CIVILIZATION_TRENT_LIBRARY_EXILE')").fetchone()[0] == 2
    print("Full activation-order database passed for all five civilizations")


def art_and_project():
    validate_project()
    project = ET.parse(ROOT / "UnaCourt.civ5proj")
    ns = {"m":"http://schemas.microsoft.com/developer/msbuild/2003"}
    assert project.findtext(".//m:ModVersion", namespaces=ns) == "3"
    actions = {node.text for node in project.findall(".//m:ModActions/m:Action/m:FileName", ns)}
    assert {"Art/LibraryExile_IconAtlases.xml","SQL/80_LibraryExile_Inherit.sql","SQL/81_LibraryExile_Core.sql","SQL/82_LibraryExile_Text.sql"} <= actions
    atlas = ET.parse(ROOT / "Art/LibraryExile_IconAtlases.xml")
    for row in atlas.findall(".//Row"):
        size = int(row.findtext("IconSize"))
        with Image.open(ROOT / row.findtext("Filename")) as image:
            assert image.size == (size * int(row.findtext("IconsPerRow")), size * int(row.findtext("IconsPerColumn")))
            extrema = image.convert("RGBA").getchannel("A").getextrema()
            assert extrema == (0,255), (row.findtext("Filename"), extrema)
    for name, dimensions in (("DawnOfMan.dds",(1024,768)),("LeaderScene.dds",(1600,900)),("MapImage.dds",(360,412))):
        with Image.open(ROOT / "Art/LibraryExile" / name) as image:
            assert image.size == dimensions
    assert 'UnaInclude("TrentLibraryExile_Gameplay.lua")' in (ROOT / "Lua/UnaCourtLoader.lua").read_text(encoding="utf-8")
    print("Project version/actions, icon transparency/dimensions, Dawn, map and gameplay loader passed")


if __name__ == "__main__":
    database()
    full_mod_database()
    art_and_project()
