-- ===========================================================================
-- Trentrouls, the Ultimate Possessor
-- Third playable Una Court civilization. Centrelink is shared with the
-- Freehold and Dominion through the one definition in 00_UnaCourt_Core.sql.
-- ===========================================================================

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'EVENTS_GAME_SAVE';

INSERT OR REPLACE INTO Colors (Type, Red, Green, Blue, Alpha) VALUES
('COLOR_ULTIMATE_POSSESSION_PRIMARY',   0.20, 0.07, 0.30, 1.0),
('COLOR_ULTIMATE_POSSESSION_SECONDARY', 0.91, 0.70, 0.24, 1.0);

INSERT OR REPLACE INTO PlayerColors (Type, PrimaryColor, SecondaryColor, TextColor)
VALUES ('PLAYERCOLOR_ULTIMATE_POSSESSION', 'COLOR_ULTIMATE_POSSESSION_PRIMARY',
        'COLOR_ULTIMATE_POSSESSION_SECONDARY', 'COLOR_PLAYER_WHITE_TEXT');

INSERT INTO Traits (Type, Description, ShortDescription)
VALUES ('TRAIT_ULTIMATE_TWO_POSSESSIONS',
        'TXT_KEY_TRAIT_ULTIMATE_TWO_POSSESSIONS_HELP',
        'TXT_KEY_TRAIT_ULTIMATE_TWO_POSSESSIONS_SHORT');

INSERT INTO Leaders
    (Type, Description, Civilopedia, CivilopediaTag, ArtDefineTag,
     PrimaryVictoryPursuit, SecondaryVictoryPursuit,
     VictoryCompetitiveness, WonderCompetitiveness, MinorCivCompetitiveness,
     Boldness, DiploBalance, WarmongerHate, DoFWillingness, DenounceWillingness,
     WorkWithWillingness, WorkAgainstWillingness, Loyalty, Forgiveness, Neediness,
     Meanness, Chattiness, PortraitIndex, IconAtlas)
SELECT
    'LEADER_ULTIMATE_TRENTROULS', 'TXT_KEY_LEADER_ULTIMATE_TRENTROULS',
    'TXT_KEY_LEADER_ULTIMATE_TRENTROULS_PEDIA', 'TXT_KEY_CIVILOPEDIA_LEADERS_ULTIMATE_TRENTROULS',
    ArtDefineTag, 'VICTORY_PURSUIT_DOMINATION', 'VICTORY_PURSUIT_DIPLOMACY',
    9, 6, 7, 9, 5, 3, 5, 8, 4, 8, 7, 4, 6, 8, 6,
    0, 'ULTIMATE_TRENT_LEADER_ATLAS'
FROM Leaders WHERE Type = 'LEADER_WASHINGTON';

INSERT INTO Leader_Traits (LeaderType, TraitType)
VALUES ('LEADER_ULTIMATE_TRENTROULS', 'TRAIT_ULTIMATE_TWO_POSSESSIONS');

INSERT INTO Leader_MajorCivApproachBiases (LeaderType, MajorCivApproachType, Bias)
SELECT 'LEADER_ULTIMATE_TRENTROULS', MajorCivApproachType, Bias
FROM Leader_MajorCivApproachBiases WHERE LeaderType = 'LEADER_WASHINGTON';

INSERT INTO Leader_MinorCivApproachBiases (LeaderType, MinorCivApproachType, Bias)
SELECT 'LEADER_ULTIMATE_TRENTROULS', MinorCivApproachType, Bias
FROM Leader_MinorCivApproachBiases WHERE LeaderType = 'LEADER_WASHINGTON';

INSERT INTO Leader_Flavors (LeaderType, FlavorType, Flavor)
SELECT 'LEADER_ULTIMATE_TRENTROULS', FlavorType, Flavor
FROM Leader_Flavors WHERE LeaderType = 'LEADER_WASHINGTON';

UPDATE Leader_Flavors SET Flavor = 11
WHERE LeaderType = 'LEADER_ULTIMATE_TRENTROULS'
  AND FlavorType IN ('FLAVOR_OFFENSE', 'FLAVOR_MOBILE', 'FLAVOR_MILITARY_TRAINING');
UPDATE Leader_Flavors SET Flavor = 9
WHERE LeaderType = 'LEADER_ULTIMATE_TRENTROULS'
  AND FlavorType IN ('FLAVOR_GOLD', 'FLAVOR_HAPPINESS', 'FLAVOR_EXPANSION');

-- Reusing Washington's complete response set avoids missing-response assertions
-- when the Community Patch opens diplomacy with this static leader scene.
INSERT INTO Diplomacy_Responses (LeaderType, ResponseType, Response, Bias)
SELECT 'LEADER_ULTIMATE_TRENTROULS', ResponseType, Response, Bias
FROM Diplomacy_Responses WHERE LeaderType = 'LEADER_WASHINGTON';

INSERT INTO Civilizations
    (Type, Description, Civilopedia, CivilopediaTag, Strategy, Playable, AIPlayable,
     ShortDescription, Adjective, DefaultPlayerColor, ArtDefineTag, ArtStyleType,
     ArtStyleSuffix, ArtStylePrefix, PortraitIndex, IconAtlas, AlphaIconAtlas,
     MapImage, DawnOfManQuote, DawnOfManImage, DawnOfManAudio, SoundtrackTag)
SELECT
    'CIVILIZATION_ULTIMATE_POSSESSION', 'TXT_KEY_CIV_ULTIMATE_POSSESSION_DESC',
    'TXT_KEY_CIV_ULTIMATE_POSSESSION_PEDIA', 'TXT_KEY_CIV5_ULTIMATE_POSSESSION',
    'TXT_KEY_CIV_ULTIMATE_POSSESSION_STRATEGY', 1, 0,
    'TXT_KEY_CIV_ULTIMATE_POSSESSION_SHORT_DESC', 'TXT_KEY_CIV_ULTIMATE_POSSESSION_ADJECTIVE',
    'PLAYERCOLOR_ULTIMATE_POSSESSION', ArtDefineTag, ArtStyleType, ArtStyleSuffix, ArtStylePrefix,
    0, 'ULTIMATE_CIV_ATLAS', 'ULTIMATE_CIV_ALPHA_ATLAS', 'Art/DawnOfMan/UnaCourtMap.dds',
    'TXT_KEY_CIV5_DOM_ULTIMATE_POSSESSION_TEXT', 'Art/UltimateDawnOfMan/UltimateDawnOfMan.dds', '', SoundtrackTag
FROM Civilizations WHERE Type = 'CIVILIZATION_AMERICA';

INSERT INTO Civilization_Leaders (CivilizationType, LeaderheadType)
VALUES ('CIVILIZATION_ULTIMATE_POSSESSION', 'LEADER_ULTIMATE_TRENTROULS');

INSERT INTO Civilization_FreeBuildingClasses (CivilizationType, BuildingClassType)
VALUES ('CIVILIZATION_ULTIMATE_POSSESSION', 'BUILDINGCLASS_PALACE');

INSERT INTO Civilization_FreeTechs (CivilizationType, TechType)
VALUES ('CIVILIZATION_ULTIMATE_POSSESSION', 'TECH_AGRICULTURE');

INSERT INTO Civilization_Start_Region_Priority (CivilizationType, RegionType)
VALUES ('CIVILIZATION_ULTIMATE_POSSESSION', 'REGION_GRASS');

INSERT INTO Civilization_CityNames (CivilizationType, CityName) VALUES
('CIVILIZATION_ULTIMATE_POSSESSION', 'TXT_KEY_CITY_NAME_ULTIMATE_UNA_COURT'),
('CIVILIZATION_ULTIMATE_POSSESSION', 'TXT_KEY_CITY_NAME_ULTIMATE_PURPLE_COURT'),
('CIVILIZATION_ULTIMATE_POSSESSION', 'TXT_KEY_CITY_NAME_ULTIMATE_MANY_BODIES'),
('CIVILIZATION_ULTIMATE_POSSESSION', 'TXT_KEY_CITY_NAME_ULTIMATE_GOLDEN_HALL'),
('CIVILIZATION_ULTIMATE_POSSESSION', 'TXT_KEY_CITY_NAME_ULTIMATE_CENTRELINK'),
('CIVILIZATION_ULTIMATE_POSSESSION', 'TXT_KEY_CITY_NAME_ULTIMATE_GOOD_BOY'),
('CIVILIZATION_ULTIMATE_POSSESSION', 'TXT_KEY_CITY_NAME_ULTIMATE_THRONE'),
('CIVILIZATION_ULTIMATE_POSSESSION', 'TXT_KEY_CITY_NAME_ULTIMATE_LAST_WILL');

INSERT INTO Civilization_SpyNames (CivilizationType, SpyName) VALUES
('CIVILIZATION_ULTIMATE_POSSESSION', 'TXT_KEY_SPY_NAME_ULTIMATE_VESSEL'),
('CIVILIZATION_ULTIMATE_POSSESSION', 'TXT_KEY_SPY_NAME_ULTIMATE_HANDLER'),
('CIVILIZATION_ULTIMATE_POSSESSION', 'TXT_KEY_SPY_NAME_ULTIMATE_GOOD_BOY');

-- Golden Retriever owns the visible aura marker. A hidden receiver promotion
-- is maintained by Lua, so multiple dogs never stack the effect.
INSERT INTO UnitPromotions
     (Type, Description, Help, CannotBeChosen, LostWithUpgrade, CannotBeCaptured,
     CombatPercent, FriendlyHealChange, NeutralHealChange, EnemyHealChange,
     PortraitIndex, IconAtlas, PediaType, PediaEntry, ShowInUnitPanel, IsVisibleAboveFlag)
VALUES
('PROMOTION_ULTIMATE_GOOD_BOY', 'TXT_KEY_PROMOTION_ULTIMATE_GOOD_BOY',
 'TXT_KEY_PROMOTION_ULTIMATE_GOOD_BOY_HELP', 1, 0, 1,
 0, 0, 0, 0, 0, 'UNA_BUDDY_ATLAS', 'PEDIA_ATTRIBUTES',
 'TXT_KEY_PROMOTION_ULTIMATE_GOOD_BOY', 1, 1),
('PROMOTION_ULTIMATE_GOOD_BOY_AURA', 'TXT_KEY_PROMOTION_ULTIMATE_GOOD_BOY_AURA',
 'TXT_KEY_PROMOTION_ULTIMATE_GOOD_BOY_AURA_HELP', 1, 1, 1,
 10, 5, 5, 5, 0, 'UNA_BUDDY_ATLAS', 'PEDIA_SHARED',
 'TXT_KEY_PROMOTION_ULTIMATE_GOOD_BOY_AURA', 0, 0),
('PROMOTION_ULTIMATE_POSSESSED', 'TXT_KEY_PROMOTION_ULTIMATE_POSSESSED',
 'TXT_KEY_PROMOTION_ULTIMATE_POSSESSED_HELP', 1, 1, 1,
 0, 0, 0, 0, 58, 'ABILITY_ATLAS', 'PEDIA_SHARED',
 'TXT_KEY_PROMOTION_ULTIMATE_POSSESSED', 1, 1);

-- More expensive than a Scout, with +1 Movement and +1 maintenance.
INSERT INTO Units
    (Type, Description, Civilopedia, Strategy, Help, Combat, RangedCombat, Cost,
     FaithCost, RequiresFaithPurchaseEnabled, Moves, BaseSightRange, Class,
     CombatClass, Domain, DefaultUnitAI, MilitarySupport, MilitaryProduction,
     Pillage, PrereqTech, ObsoleteTech, GoodyHutUpgradeUnitClass,
     HurryCostModifier, ExtraMaintenanceCost, UnitArtInfo,
     UnitArtInfoCulturalVariation, UnitArtInfoEraVariation, UnitFlagIconOffset,
     PortraitIndex, IconAtlas, UnitFlagAtlas, ShowInPedia)
SELECT
    'UNIT_ULTIMATE_GOLDEN_RETRIEVER', 'TXT_KEY_UNIT_ULTIMATE_GOLDEN_RETRIEVER',
    'TXT_KEY_UNIT_ULTIMATE_GOLDEN_RETRIEVER_PEDIA',
    'TXT_KEY_UNIT_ULTIMATE_GOLDEN_RETRIEVER_STRATEGY',
    'TXT_KEY_UNIT_ULTIMATE_GOLDEN_RETRIEVER_HELP', Combat, RangedCombat, 45,
    FaithCost, RequiresFaithPurchaseEnabled, 3, BaseSightRange, 'UNITCLASS_SCOUT',
    CombatClass, Domain, DefaultUnitAI, MilitarySupport, MilitaryProduction,
    Pillage, PrereqTech, ObsoleteTech, GoodyHutUpgradeUnitClass,
    HurryCostModifier, 1, UnitArtInfo, UnitArtInfoCulturalVariation,
    UnitArtInfoEraVariation, UnitFlagIconOffset, 0, 'UNA_BUDDY_ATLAS',
    UnitFlagAtlas, 1
FROM Units WHERE Type = 'UNIT_SCOUT';

INSERT INTO Unit_AITypes (UnitType, UnitAIType)
SELECT 'UNIT_ULTIMATE_GOLDEN_RETRIEVER', UnitAIType
FROM Unit_AITypes WHERE UnitType = 'UNIT_SCOUT';

INSERT INTO Unit_Flavors (UnitType, FlavorType, Flavor)
SELECT 'UNIT_ULTIMATE_GOLDEN_RETRIEVER', FlavorType, Flavor
FROM Unit_Flavors WHERE UnitType = 'UNIT_SCOUT';

INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
SELECT 'UNIT_ULTIMATE_GOLDEN_RETRIEVER', PromotionType
FROM Unit_FreePromotions WHERE UnitType = 'UNIT_SCOUT';

INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
VALUES ('UNIT_ULTIMATE_GOLDEN_RETRIEVER', 'PROMOTION_ULTIMATE_GOOD_BOY');

-- Unique national wonder: its class has no default, making it available only
-- through the Ultimate Possession civilization override below.
INSERT INTO BuildingClasses
    (Type, DefaultBuilding, Description, MaxPlayerInstances)
VALUES
    ('BUILDINGCLASS_ULTIMATE_3_UNA_COURT', NULL,
     'TXT_KEY_BUILDING_ULTIMATE_3_UNA_COURT', 1);

INSERT INTO Buildings
    (Type, BuildingClass, Description, Civilopedia, Strategy, Help,
     GoldMaintenance, Cost, FaithCost, PrereqTech, HurryCostModifier,
     MinAreaSize, ConquestProb, NeverCapture, NukeImmune, PortraitIndex,
     IconAtlas, ArtDefineTag, ShowInPedia)
VALUES
    ('BUILDING_ULTIMATE_3_UNA_COURT', 'BUILDINGCLASS_ULTIMATE_3_UNA_COURT',
     'TXT_KEY_BUILDING_ULTIMATE_3_UNA_COURT',
     'TXT_KEY_BUILDING_ULTIMATE_3_UNA_COURT_PEDIA',
     'TXT_KEY_BUILDING_ULTIMATE_3_UNA_COURT_STRATEGY',
     'TXT_KEY_BUILDING_ULTIMATE_3_UNA_COURT_HELP',
     0, 250, -1, 'TECH_CIVIL_SERVICE', 15,
     -1, 0, 1, 1, 0, 'ULTIMATE_3_UNA_COURT_ATLAS',
     'ART_DEF_BUILDING_PALACE', 1);

INSERT INTO Building_GlobalYieldModifiers (BuildingType, YieldType, Yield)
VALUES ('BUILDING_ULTIMATE_3_UNA_COURT', 'YIELD_GOLD', 5);

UPDATE Buildings
SET HappinessPerCity = 1
WHERE Type = 'BUILDING_ULTIMATE_3_UNA_COURT';

INSERT INTO Building_SpecialistYieldChanges
    (BuildingType, SpecialistType, YieldType, Yield)
VALUES
    ('BUILDING_ULTIMATE_3_UNA_COURT', 'SPECIALIST_CITIZEN', 'YIELD_CULTURE', 1);

INSERT INTO Building_Flavors (BuildingType, FlavorType, Flavor) VALUES
('BUILDING_ULTIMATE_3_UNA_COURT', 'FLAVOR_HAPPINESS', 20),
('BUILDING_ULTIMATE_3_UNA_COURT', 'FLAVOR_GOLD', 18),
('BUILDING_ULTIMATE_3_UNA_COURT', 'FLAVOR_CULTURE', 12),
('BUILDING_ULTIMATE_3_UNA_COURT', 'FLAVOR_WONDER', 16);

INSERT INTO Civilization_UnitClassOverrides (CivilizationType, UnitClassType, UnitType)
VALUES ('CIVILIZATION_ULTIMATE_POSSESSION', 'UNITCLASS_SCOUT', 'UNIT_ULTIMATE_GOLDEN_RETRIEVER');

INSERT INTO Civilization_BuildingClassOverrides
    (CivilizationType, BuildingClassType, BuildingType)
VALUES
('CIVILIZATION_ULTIMATE_POSSESSION', 'BUILDINGCLASS_BANK', 'BUILDING_UNA_CENTRELINK'),
('CIVILIZATION_ULTIMATE_POSSESSION', 'BUILDINGCLASS_ULTIMATE_3_UNA_COURT', 'BUILDING_ULTIMATE_3_UNA_COURT');

INSERT INTO Civilization_FreeUnits (CivilizationType, UnitClassType, UnitAIType, Count) VALUES
('CIVILIZATION_ULTIMATE_POSSESSION', 'UNITCLASS_SETTLER', 'UNITAI_SETTLE', 1),
('CIVILIZATION_ULTIMATE_POSSESSION', 'UNITCLASS_WARRIOR', 'UNITAI_ATTACK', 1);
