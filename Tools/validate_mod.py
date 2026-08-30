"""Static and database validation for the ModBuddy project."""

from pathlib import Path
import re
import sqlite3
import xml.etree.ElementTree as ET

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
GAME_USER_ROOT = Path(r"C:\Users\ThatOneYi\Documents\My Games\Sid Meier's Civilization 5")


def find_vp_debug_database() -> Path:
    fallback = GAME_USER_ROOT / "cache" / "Civ5DebugDatabase.db"
    for candidate in GAME_USER_ROOT.glob("*/Civ5DebugDatabase.db"):
        connection = sqlite3.connect(candidate)
        columns = {row[1] for row in connection.execute("PRAGMA table_info(Leaders)")}
        connection.close()
        if "PrimaryVictoryPursuit" in columns:
            return candidate
    assert fallback.exists(), "No Civ5DebugDatabase.db was found"
    return fallback


def validate_project() -> None:
    project_path = ROOT / "UnaCourt.civ5proj"
    tree = ET.parse(project_path)
    namespace = {"m": "http://schemas.microsoft.com/developer/msbuild/2003"}
    version = tree.findtext(".//m:ModVersion", namespaces=namespace)
    assert version == "3", f"ModVersion changed unexpectedly: {version}"

    missing = []
    for content in tree.findall(".//m:Content", namespace):
        include = content.attrib.get("Include")
        if include and not (ROOT / include).exists():
            missing.append(include)
    for file_node in tree.findall(".//m:FileName", namespace):
        if file_node.text and not (ROOT / file_node.text).exists():
            missing.append(file_node.text)
    assert not missing, "Missing project files: " + ", ".join(sorted(set(missing)))


def validate_xml() -> None:
    for path in (ROOT / "Art").glob("*.xml"):
        ET.parse(path)


def validate_art() -> None:
    expected = {
        ROOT / "Art" / "UltimateDawnOfMan" / "UltimateDawnOfMan.dds": (1024, 768),
    }
    for size in (256, 128, 80, 64, 45, 32):
        expected[ROOT / "Art" / "UltimateCivilization" / f"UltimateIcon{size}.dds"] = (size, size)
        expected[ROOT / "Art" / "UltimateTrentLeader" / f"UltimateTrentIcon{size}.dds"] = (size, size)
        expected[ROOT / "Art" / "Ultimate3UnaCourt" / f"ThreeUnaCourtIcon{size}.dds"] = (size, size)
    for size in (128, 80, 64, 45, 32):
        expected[ROOT / "Art" / "UltimateCivilization" / f"UltimateAlpha{size}.dds"] = (size, size)
    for path, size in expected.items():
        with Image.open(path) as image:
            assert image.size == size, f"Wrong dimensions for {path}: {image.size}"


def validate_database() -> None:
    debug_db = find_vp_debug_database()
    source = sqlite3.connect(debug_db)
    database = sqlite3.connect(":memory:")
    source.backup(database)
    source.close()

    # CustomModOptions is created by the Community Patch before this mod runs.
    # A menu-generated debug DB can omit it when VP was not the last activated
    # ruleset, so provide only the tiny compatibility stub needed by our SQL.
    if not database.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='CustomModOptions'"
    ).fetchone():
        database.executescript(
            "CREATE TABLE CustomModOptions (Name TEXT PRIMARY KEY, Value INTEGER);"
            "INSERT INTO CustomModOptions VALUES ('EVENTS_GAME_SAVE', 0);"
        )
    leader_columns = {row[1] for row in database.execute("PRAGMA table_info(Leaders)")}
    for column in ("PrimaryVictoryPursuit", "SecondaryVictoryPursuit"):
        if column not in leader_columns:
            database.execute(f"ALTER TABLE Leaders ADD COLUMN {column} TEXT")
    promotion_columns = {row[1] for row in database.execute("PRAGMA table_info(UnitPromotions)")}
    for column in (
        "CannotBeCaptured", "ShowInUnitPanel", "IsVisibleAboveFlag",
    ):
        if column not in promotion_columns:
            database.execute(f"ALTER TABLE UnitPromotions ADD COLUMN {column} INTEGER DEFAULT 0")
    building_columns = {row[1] for row in database.execute("PRAGMA table_info(Buildings)")}
    for column in ("ShowInPedia", "HappinessPerCity"):
        if column not in building_columns:
            database.execute(f"ALTER TABLE Buildings ADD COLUMN {column} INTEGER DEFAULT 0")
    if not database.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='Language_en_US'"
    ).fetchone():
        database.execute("CREATE TABLE Language_en_US (Tag TEXT PRIMARY KEY, Text TEXT)")

    already_present = database.execute(
        "SELECT COUNT(*) FROM Civilizations WHERE Type = 'CIVILIZATION_ULTIMATE_POSSESSION'"
    ).fetchone()[0]
    assert already_present == 0, "Debug DB already contains Ultimate Possession; clear the Civ V cache before validating"

    for filename in ("50_Ultimate_Core.sql", "60_Ultimate_Text.sql"):
        database.executescript((ROOT / "SQL" / filename).read_text(encoding="utf-8"))

    checks = {
        "civilization": "SELECT COUNT(*) FROM Civilizations WHERE Type='CIVILIZATION_ULTIMATE_POSSESSION'",
        "leader": "SELECT COUNT(*) FROM Leaders WHERE Type='LEADER_ULTIMATE_TRENTROULS'",
        "retriever": "SELECT COUNT(*) FROM Units WHERE Type='UNIT_ULTIMATE_GOLDEN_RETRIEVER'",
        "wonder": "SELECT COUNT(*) FROM Buildings WHERE Type='BUILDING_ULTIMATE_3_UNA_COURT'",
        "shared Centrelink": "SELECT COUNT(*) FROM Civilization_BuildingClassOverrides WHERE CivilizationType='CIVILIZATION_ULTIMATE_POSSESSION' AND BuildingType='BUILDING_UNA_CENTRELINK'",
    }
    for label, query in checks.items():
        count = database.execute(query).fetchone()[0]
        assert count == 1, f"Expected one {label} row, got {count}"

    happiness = database.execute(
        "SELECT HappinessPerCity FROM Buildings WHERE Type='BUILDING_ULTIMATE_3_UNA_COURT'"
    ).fetchone()[0]
    assert happiness == 1, "3 Una Court is missing empire-wide Happiness"
    database.close()


def validate_localization() -> None:
    core = (ROOT / "SQL" / "50_Ultimate_Core.sql").read_text(encoding="utf-8")
    text = (ROOT / "SQL" / "60_Ultimate_Text.sql").read_text(encoding="utf-8")
    references = set(re.findall(r"'(TXT_KEY_[A-Z0-9_]+)'", core))
    tags = set(re.findall(r"\('(TXT_KEY_[A-Z0-9_]+)'", text))
    missing = sorted(references - tags)
    assert not missing, "Missing Ultimate localization tags: " + ", ".join(missing)


if __name__ == "__main__":
    validate_project()
    validate_xml()
    validate_art()
    validate_database()
    validate_localization()
    print("Ultimate Possession validation passed")
