"""Validate Phone Stealer SQL, CP inheritance, art, UI and project wiring."""
from pathlib import Path
import re
import sqlite3
import xml.etree.ElementTree as ET

from PIL import Image

from validate_mod import ROOT, find_vp_debug_database, validate_project


SCRIPTS = ("90_PhoneStealer_Inherit.sql", "91_PhoneStealer_Core.sql", "92_PhoneStealer_Text.sql")


def database():
    source = sqlite3.connect(find_vp_debug_database())
    db = sqlite3.connect(":memory:")
    source.backup(db)
    source.close()
    db.row_factory = sqlite3.Row
    db.execute("CREATE TABLE IF NOT EXISTS Language_en_US (Tag TEXT PRIMARY KEY, Text TEXT)")
    db.execute("CREATE TABLE IF NOT EXISTS CustomModOptions (Name TEXT PRIMARY KEY, Value INTEGER)")
    assert not db.execute(
        "SELECT 1 FROM Civilizations WHERE Type='CIVILIZATION_TRENT_PHONE_STEALER'"
    ).fetchone()
    centrelink_before = tuple(db.execute(
        "SELECT * FROM Buildings WHERE Type='BUILDING_UNA_CENTRELINK'"
    ).fetchone() or ())
    for name in SCRIPTS:
        db.executescript((ROOT / "SQL" / name).read_text(encoding="utf-8"))

    worker = db.execute("SELECT * FROM Units WHERE Type='UNIT_WORKER'").fetchone()
    butler = db.execute("SELECT * FROM Units WHERE Type='UNIT_TRENT_UNA_COURT_BUTLER'").fetchone()
    allowed = {"ID", "Type", "Description", "Civilopedia", "Strategy", "Help", "Cost", "PortraitIndex", "IconAtlas"}
    for column in worker.keys():
        if column not in allowed:
            assert worker[column] == butler[column], (column, worker[column], butler[column])
    assert butler["Cost"] == (worker["Cost"] * 120 + 99) // 100
    promotion = db.execute(
        "SELECT WorkRateMod,CannotBeCaptured FROM UnitPromotions WHERE Type='PROMOTION_TRENT_LOYALTY_TO_UNA_COURT'"
    ).fetchone()
    assert tuple(promotion) == (25, 1)
    assert db.execute(
        "SELECT COUNT(*) FROM Civilization_UnitClassOverrides WHERE CivilizationType='CIVILIZATION_TRENT_PHONE_STEALER' AND UnitClassType='UNITCLASS_WORKER' AND UnitType='UNIT_TRENT_UNA_COURT_BUTLER'"
    ).fetchone()[0] == 1
    assert db.execute(
        "SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType='CIVILIZATION_TRENT_PHONE_STEALER' AND BuildingClassType='BUILDINGCLASS_BANK'"
    ).fetchone()[0] == "BUILDING_UNA_CENTRELINK"
    centrelink_after = tuple(db.execute(
        "SELECT * FROM Buildings WHERE Type='BUILDING_UNA_CENTRELINK'"
    ).fetchone() or ())
    assert centrelink_after == centrelink_before

    assert db.execute(
        "SELECT COUNT(*) FROM Buildings WHERE Type LIKE 'BUILDING_TRENT_PHONE_STASH_%'"
    ).fetchone()[0] == 21
    for count in range(1, 22):
        building = f"BUILDING_TRENT_PHONE_STASH_{count}"
        row = db.execute("SELECT Happiness FROM Buildings WHERE Type=?", (building,)).fetchone()
        assert row[0] == count // 3
        yields = dict(db.execute(
            "SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?", (building,)
        ).fetchall())
        assert yields == {"YIELD_SCIENCE": count * 2, "YIELD_GOLD": count * 2, "YIELD_CULTURE": count}
    diplo = db.execute(
        "SELECT Description,ToCivilizationType FROM DiploModifiers WHERE Type='DIPLOMODIFIER_TRENT_STOLE_PHONE'"
    ).fetchone()
    assert tuple(diplo) == ("TXT_KEY_PHONE_STEALER_DIPLO_MODIFIER", "CIVILIZATION_TRENT_PHONE_STEALER")
    assert db.execute(
        "SELECT COUNT(*) FROM Civilization_CityNames WHERE CivilizationType='CIVILIZATION_TRENT_PHONE_STEALER'"
    ).fetchone()[0] == 20
    assert db.execute(
        "SELECT COUNT(*) FROM Civilization_SpyNames WHERE CivilizationType='CIVILIZATION_TRENT_PHONE_STEALER'"
    ).fetchone()[0] == 10

    tags = {row[0] for row in db.execute("SELECT Tag FROM Language_en_US")}
    referenced = set()
    for name in ("91_PhoneStealer_Core.sql", "92_PhoneStealer_Text.sql"):
        referenced |= set(re.findall(r"'(TXT_KEY_[A-Z0-9_]+)'", (ROOT / "SQL" / name).read_text(encoding="utf-8")))
    assert not referenced - tags, sorted(referenced - tags)
    for prefix, sections in (("TXT_KEY_CIV5_PHONE_STEALER", 6), ("TXT_KEY_CIV5_PHONE_STEALER_LEADER", 4)):
        for index in range(1, sections + 1):
            assert f"{prefix}_HEADING_{index}" in tags and f"{prefix}_TEXT_{index}" in tags
    print("Database passed: CP Worker inherited, Butler loyalty, 21 Stash tiers, Centrelink reuse and localization verified")


def art_ui_and_project():
    validate_project()
    project = ET.parse(ROOT / "UnaCourt.civ5proj")
    ns = {"m": "http://schemas.microsoft.com/developer/msbuild/2003"}
    actions = {node.text for node in project.findall(".//m:ModActions/m:Action/m:FileName", ns)}
    assert {"Art/PhoneStealer_IconAtlases.xml", *[f"SQL/{name}" for name in SCRIPTS]} <= actions
    addins = {node.text for node in project.findall(".//m:ModContent/m:Content/m:FileName", ns)}
    assert "UI/TrentPhoneStealer_UI.xml" in addins
    assert 'UnaInclude("TrentPhoneStealer_Gameplay.lua")' in (ROOT / "Lua/UnaCourtLoader.lua").read_text(encoding="utf-8")

    atlas = ET.parse(ROOT / "Art/PhoneStealer_IconAtlases.xml")
    for row in atlas.findall(".//Row"):
        size = int(row.findtext("IconSize"))
        with Image.open(ROOT / row.findtext("Filename")) as image:
            expected = (size * int(row.findtext("IconsPerRow")), size * int(row.findtext("IconsPerColumn")))
            assert image.size == expected, (row.findtext("Filename"), image.size, expected)
            assert image.convert("RGBA").getchannel("A").getextrema() == (0, 255)
    for name, dimensions in (("DawnOfMan.dds", (1024, 768)), ("LeaderScene.dds", (1600, 900)), ("MapImage.dds", (360, 412))):
        with Image.open(ROOT / "Art/PhoneStealer" / name) as image:
            assert image.size == dimensions

    tree = ET.parse(ROOT / "UI/TrentPhoneStealer_UI.xml")
    ids = {node.get("ID") for node in tree.iter() if node.get("ID")}
    code = (ROOT / "UI/TrentPhoneStealer_UI.lua").read_text(encoding="utf-8")
    controls = set(re.findall(r"Controls\.(\w+)", code))
    assert not controls - ids, sorted(controls - ids)
    assert "SetNumRealBuilding" not in code
    print("Project, art dimensions/transparency, gameplay loader and isolated UI controls passed")


if __name__ == "__main__":
    database()
    art_ui_and_project()
