-- ===========================================================================
-- The Freehold of Una Court - Core database definitions
-- Target: Civilization V BNW with the Community Patch / Vox Populi DLL
-- Art is deliberately borrowed from base-game records for the first playable
-- build. Custom atlases can replace these references without changing gameplay.
-- ===========================================================================

-- Player colours
INSERT OR REPLACE INTO Colors (Type, Red, Green, Blue, Alpha) VALUES
('COLOR_UNA_COURT_PRIMARY',   0.62, 0.20, 0.12, 1.0),
('COLOR_UNA_COURT_SECONDARY', 0.92, 0.78, 0.28, 1.0);

INSERT OR REPLACE INTO PlayerColors (Type, PrimaryColor, SecondaryColor, TextColor)
VALUES ('PLAYERCOLOR_UNA_COURT', 'COLOR_UNA_COURT_PRIMARY', 'COLOR_UNA_COURT_SECONDARY', 'COLOR_PLAYER_WHITE_TEXT');

-- Trait and leader
INSERT INTO Traits (Type, Description, ShortDescription)
VALUES ('TRAIT_UNA_COURT_LIVES_THROUGH_HIM',
        'TXT_KEY_TRAIT_UNA_COURT_LIVES_THROUGH_HIM_HELP',
        'TXT_KEY_TRAIT_UNA_COURT_LIVES_THROUGH_HIM_SHORT');

INSERT INTO Leaders
    (Type, Description, Civilopedia, CivilopediaTag, ArtDefineTag,
     PrimaryVictoryPursuit, SecondaryVictoryPursuit,
     VictoryCompetitiveness, WonderCompetitiveness, MinorCivCompetitiveness,
     Boldness, DiploBalance, WarmongerHate, DoFWillingness, DenounceWillingness,
     WorkWithWillingness, WorkAgainstWillingness, Loyalty, Forgiveness, Neediness,
     Meanness, Chattiness, PortraitIndex, IconAtlas)
SELECT
    'LEADER_UNA_TRENTROULS', 'TXT_KEY_LEADER_UNA_TRENTROULS',
    'TXT_KEY_LEADER_UNA_TRENTROULS_PEDIA', 'TXT_KEY_CIVILOPEDIA_LEADERS_UNA_TRENTROULS',
    ArtDefineTag, 'VICTORY_PURSUIT_DOMINATION', 'VICTORY_PURSUIT_SCIENCE',
    8, 4, 4, 8, 5, 3, 5, 7, 4, 7, 8, 3, 4, 6, 5, 0, 'UNA_TRENT_LEADER_ATLAS'
FROM Leaders WHERE Type = 'LEADER_WASHINGTON';

INSERT INTO Leader_Traits (LeaderType, TraitType)
VALUES ('LEADER_UNA_TRENTROULS', 'TRAIT_UNA_COURT_LIVES_THROUGH_HIM');

INSERT INTO Leader_MajorCivApproachBiases (LeaderType, MajorCivApproachType, Bias)
SELECT 'LEADER_UNA_TRENTROULS', MajorCivApproachType, Bias
FROM Leader_MajorCivApproachBiases WHERE LeaderType = 'LEADER_WASHINGTON';

INSERT INTO Leader_MinorCivApproachBiases (LeaderType, MinorCivApproachType, Bias)
SELECT 'LEADER_UNA_TRENTROULS', MinorCivApproachType, Bias
FROM Leader_MinorCivApproachBiases WHERE LeaderType = 'LEADER_WASHINGTON';

INSERT INTO Leader_Flavors (LeaderType, FlavorType, Flavor)
SELECT 'LEADER_UNA_TRENTROULS', FlavorType, Flavor
FROM Leader_Flavors WHERE LeaderType = 'LEADER_WASHINGTON';

UPDATE Leader_Flavors SET Flavor = 10
WHERE LeaderType = 'LEADER_UNA_TRENTROULS' AND FlavorType IN ('FLAVOR_OFFENSE', 'FLAVOR_MOBILE');
UPDATE Leader_Flavors SET Flavor = 9
WHERE LeaderType = 'LEADER_UNA_TRENTROULS' AND FlavorType IN ('FLAVOR_DEFENSE', 'FLAVOR_SCIENCE');

-- Civilization
INSERT INTO Civilizations
    (Type, Description, Civilopedia, CivilopediaTag, Strategy, Playable, AIPlayable,
     ShortDescription, Adjective, DefaultPlayerColor, ArtDefineTag, ArtStyleType,
     ArtStyleSuffix, ArtStylePrefix, PortraitIndex, IconAtlas, AlphaIconAtlas,
     MapImage, DawnOfManQuote, DawnOfManImage, DawnOfManAudio, SoundtrackTag)
SELECT
    'CIVILIZATION_UNA_COURT', 'TXT_KEY_CIV_UNA_COURT_DESC',
    'TXT_KEY_CIV_UNA_COURT_PEDIA', 'TXT_KEY_CIV5_UNA_COURT',
    'TXT_KEY_CIV_UNA_COURT_STRATEGY', 1, 1,
    'TXT_KEY_CIV_UNA_COURT_SHORT_DESC', 'TXT_KEY_CIV_UNA_COURT_ADJECTIVE',
    'PLAYERCOLOR_UNA_COURT', ArtDefineTag, ArtStyleType, ArtStyleSuffix, ArtStylePrefix,
    0, 'UNA_CIV_ATLAS', 'UNA_CIV_ALPHA_ATLAS', 'Art/DawnOfMan/UnaCourtMap.dds',
    'TXT_KEY_CIV5_DOM_UNA_COURT_TEXT', 'Art/DawnOfMan/UnaCourtDawnOfMan.dds', '', SoundtrackTag
FROM Civilizations WHERE Type = 'CIVILIZATION_AMERICA';

INSERT INTO Civilization_Leaders (CivilizationType, LeaderheadType)
VALUES ('CIVILIZATION_UNA_COURT', 'LEADER_UNA_TRENTROULS');

INSERT INTO Civilization_FreeBuildingClasses (CivilizationType, BuildingClassType)
VALUES ('CIVILIZATION_UNA_COURT', 'BUILDINGCLASS_PALACE');

INSERT INTO Civilization_FreeTechs (CivilizationType, TechType)
VALUES ('CIVILIZATION_UNA_COURT', 'TECH_AGRICULTURE');

INSERT INTO Civilization_Start_Region_Priority (CivilizationType, RegionType)
VALUES ('CIVILIZATION_UNA_COURT', 'REGION_GRASS');

INSERT INTO Civilization_CityNames (CivilizationType, CityName) VALUES
('CIVILIZATION_UNA_COURT', 'TXT_KEY_CITY_NAME_UNA_COURT'),
('CIVILIZATION_UNA_COURT', 'TXT_KEY_CITY_NAME_UNA_BUDDY_PARK'),
('CIVILIZATION_UNA_COURT', 'TXT_KEY_CITY_NAME_UNA_FREEHOLD'),
('CIVILIZATION_UNA_COURT', 'TXT_KEY_CITY_NAME_UNA_GOLDEN_FIELDS'),
('CIVILIZATION_UNA_COURT', 'TXT_KEY_CITY_NAME_UNA_CENTRELINK'),
('CIVILIZATION_UNA_COURT', 'TXT_KEY_CITY_NAME_UNA_GREEN'),
('CIVILIZATION_UNA_COURT', 'TXT_KEY_CITY_NAME_UNA_RULERS_REST'),
('CIVILIZATION_UNA_COURT', 'TXT_KEY_CITY_NAME_UNA_COMPANION_HILL');

INSERT INTO Civilization_SpyNames (CivilizationType, SpyName) VALUES
('CIVILIZATION_UNA_COURT', 'TXT_KEY_SPY_NAME_UNA_BUDDY'),
('CIVILIZATION_UNA_COURT', 'TXT_KEY_SPY_NAME_UNA_COURTIER'),
('CIVILIZATION_UNA_COURT', 'TXT_KEY_SPY_NAME_UNA_KEEPER');

-- Unique classes
INSERT INTO UnitClasses
    (Type, Description, MaxGlobalInstances, MaxTeamInstances, MaxPlayerInstances, DefaultUnit)
VALUES
('UNITCLASS_UNA_TRENTROULS', 'TXT_KEY_UNIT_UNA_TRENTROULS', -1, -1, 1, 'UNIT_UNA_TRENTROULS'),
('UNITCLASS_UNA_BUDDY', 'TXT_KEY_UNIT_UNA_BUDDY', -1, -1, 1, NULL);

-- Core promotions. Era promotions are hidden and mutually managed by Lua.
INSERT INTO UnitPromotions
    (Type, Description, Help, CannotBeChosen, LostWithUpgrade, CannotBeCaptured,
     NoSupply, CombatPercent, PortraitIndex, IconAtlas, PediaType, PediaEntry, Sound,
     ShowInUnitPanel, IsVisibleAboveFlag)
VALUES
('PROMOTION_UNA_ONE_TRUE_RULER', 'TXT_KEY_PROMOTION_UNA_ONE_TRUE_RULER',
 'TXT_KEY_PROMOTION_UNA_ONE_TRUE_RULER_HELP', 1, 0, 1, 1, 0,
 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ONE_TRUE_RULER', 'AS2D_IF_LEVELUP', 1, 1),
('PROMOTION_UNA_BELOVED_COMPANION', 'TXT_KEY_PROMOTION_UNA_BELOVED_COMPANION',
 'TXT_KEY_PROMOTION_UNA_BELOVED_COMPANION_HELP', 1, 0, 1, 1, 0,
 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_BELOVED_COMPANION', 'AS2D_IF_LEVELUP', 1, 1),
('PROMOTION_UNA_BUDDY_IS_HERE', 'TXT_KEY_PROMOTION_UNA_BUDDY_IS_HERE',
 'TXT_KEY_PROMOTION_UNA_BUDDY_IS_HERE_HELP', 1, 0, 0, 0, 0,
 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_BUDDY_IS_HERE', 'AS2D_IF_LEVELUP', 1, 1),
('PROMOTION_UNA_POSSESSED', 'TXT_KEY_PROMOTION_UNA_POSSESSED',
 'TXT_KEY_PROMOTION_UNA_POSSESSED_HELP', 1, 0, 0, 0, 0,
 58, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_POSSESSED', 'AS2D_IF_LEVELUP', 1, 1),
('PROMOTION_UNA_POSSESSION_READY', 'TXT_KEY_PROMOTION_UNA_POSSESSION_READY',
 'TXT_KEY_PROMOTION_UNA_POSSESSION_READY_HELP', 1, 0, 0, 0, 0,
 58, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_POSSESSION_READY', 'AS2D_IF_LEVELUP', 1, 1),
('PROMOTION_UNA_POSSESSION_COOLDOWN', 'TXT_KEY_PROMOTION_UNA_POSSESSION_COOLDOWN',
 'TXT_KEY_PROMOTION_UNA_POSSESSION_COOLDOWN_HELP', 1, 0, 0, 0, 0,
 58, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_POSSESSION_COOLDOWN', 'AS2D_IF_LEVELUP', 1, 1);

INSERT INTO UnitPromotions
    (Type, Description, Help, CannotBeChosen, LostWithUpgrade, CombatPercent,
     PortraitIndex, IconAtlas, PediaType, PediaEntry, ShowInUnitPanel)
VALUES
('PROMOTION_UNA_ERA_ANCIENT',     'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0,   0, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0),
('PROMOTION_UNA_ERA_CLASSICAL',   'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0,  29, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0),
('PROMOTION_UNA_ERA_MEDIEVAL',    'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0,  71, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0),
('PROMOTION_UNA_ERA_RENAISSANCE', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0, 129, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0),
('PROMOTION_UNA_ERA_INDUSTRIAL',  'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0, 229, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0),
('PROMOTION_UNA_ERA_MODERN',      'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0, 357, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0),
('PROMOTION_UNA_ERA_ATOMIC',      'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0, 514, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0),
('PROMOTION_UNA_ERA_INFORMATION', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0, 614, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0);

-- Buddy-strength variants replace the normal Era promotion while adjacent.
-- Values are relative to Trentrouls' base strength of 7 and reproduce the
-- intended 14/18/24/32/46/64/86/100 strength curve after integer rounding.
INSERT INTO UnitPromotions
    (Type, Description, Help, CannotBeChosen, LostWithUpgrade, CombatPercent,
     PortraitIndex, IconAtlas, PediaType, PediaEntry, ShowInUnitPanel)
VALUES
('PROMOTION_UNA_BUDDY_ERA_ANCIENT',     'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0,  100, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0),
('PROMOTION_UNA_BUDDY_ERA_CLASSICAL',   'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0,  157, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0),
('PROMOTION_UNA_BUDDY_ERA_MEDIEVAL',    'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0,  243, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0),
('PROMOTION_UNA_BUDDY_ERA_RENAISSANCE', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0,  357, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0),
('PROMOTION_UNA_BUDDY_ERA_INDUSTRIAL',  'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0,  557, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0),
('PROMOTION_UNA_BUDDY_ERA_MODERN',      'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0,  814, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0),
('PROMOTION_UNA_BUDDY_ERA_ATOMIC',      'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0, 1129, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0),
('PROMOTION_UNA_BUDDY_ERA_INFORMATION', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH_HELP', 1, 0, 1329, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_UNA_ERA_STRENGTH', 0);

-- Trentrouls: starts at Warrior strength, has no train/purchase/upgrade route.
INSERT INTO Units
    (Type, Description, Civilopedia, Strategy, Help, Combat, Cost, FaithCost,
     RequiresFaithPurchaseEnabled, Moves, BaseSightRange, Class, CombatClass, Domain,
     DefaultUnitAI, MilitarySupport, MilitaryProduction, Pillage, PrereqTech,
     ObsoleteTech, GoodyHutUpgradeUnitClass, HurryCostModifier, ExtraMaintenanceCost,
     UnitArtInfo, UnitArtInfoCulturalVariation, UnitArtInfoEraVariation,
     UnitFlagIconOffset, PortraitIndex, IconAtlas, UnitFlagAtlas, ShowInPedia, NoSupply)
SELECT
    'UNIT_UNA_TRENTROULS', 'TXT_KEY_UNIT_UNA_TRENTROULS',
    'TXT_KEY_UNIT_UNA_TRENTROULS_PEDIA', 'TXT_KEY_UNIT_UNA_TRENTROULS_STRATEGY',
    'TXT_KEY_UNIT_UNA_TRENTROULS_HELP', 7, -1, -1, 0, 2, 2,
    'UNITCLASS_UNA_TRENTROULS', CombatClass, Domain, DefaultUnitAI,
    1, 1, 1, NULL, NULL, NULL, -1, 0,
    UnitArtInfo, UnitArtInfoCulturalVariation, UnitArtInfoEraVariation,
    UnitFlagIconOffset, 0, 'UNA_TRENTROULS_UNIT_ATLAS', UnitFlagAtlas, 1, 1
FROM Units WHERE Type = 'UNIT_WARRIOR';

-- Buddy: Scout art and movement, deliberately only 3 Combat Strength.
INSERT INTO Units
    (Type, Description, Civilopedia, Strategy, Help, Combat, Cost, FaithCost,
     RequiresFaithPurchaseEnabled, Moves, BaseSightRange, Class, CombatClass, Domain,
     DefaultUnitAI, MilitarySupport, MilitaryProduction, Pillage, PrereqTech,
     ObsoleteTech, GoodyHutUpgradeUnitClass, HurryCostModifier, ExtraMaintenanceCost,
     UnitArtInfo, UnitArtInfoCulturalVariation, UnitArtInfoEraVariation,
     UnitFlagIconOffset, PortraitIndex, IconAtlas, UnitFlagAtlas, ShowInPedia, NoSupply)
SELECT
    'UNIT_UNA_BUDDY', 'TXT_KEY_UNIT_UNA_BUDDY',
    'TXT_KEY_UNIT_UNA_BUDDY_PEDIA', 'TXT_KEY_UNIT_UNA_BUDDY_STRATEGY',
    'TXT_KEY_UNIT_UNA_BUDDY_HELP', 3, 125, -1, 0, 2, 2,
    'UNITCLASS_UNA_BUDDY', CombatClass, Domain, DefaultUnitAI,
    1, 1, 1, 'TECH_AGRICULTURE', NULL, NULL, 0, 2,
    UnitArtInfo, UnitArtInfoCulturalVariation, UnitArtInfoEraVariation,
    UnitFlagIconOffset, 0, 'UNA_BUDDY_ATLAS', UnitFlagAtlas, 1, 1
FROM Units WHERE Type = 'UNIT_SCOUT';

INSERT INTO Unit_AITypes (UnitType, UnitAIType) VALUES
('UNIT_UNA_TRENTROULS', 'UNITAI_ATTACK'),
('UNIT_UNA_BUDDY', 'UNITAI_EXPLORE');

INSERT INTO Unit_Flavors (UnitType, FlavorType, Flavor) VALUES
('UNIT_UNA_TRENTROULS', 'FLAVOR_OFFENSE', 16),
('UNIT_UNA_TRENTROULS', 'FLAVOR_DEFENSE', 22),
('UNIT_UNA_BUDDY', 'FLAVOR_RECON', 12),
('UNIT_UNA_BUDDY', 'FLAVOR_DEFENSE', 16);

INSERT INTO Unit_FreePromotions (UnitType, PromotionType) VALUES
('UNIT_UNA_TRENTROULS', 'PROMOTION_UNA_ONE_TRUE_RULER'),
('UNIT_UNA_TRENTROULS', 'PROMOTION_UNA_ERA_ANCIENT'),
('UNIT_UNA_TRENTROULS', 'PROMOTION_UNA_POSSESSION_READY'),
('UNIT_UNA_BUDDY', 'PROMOTION_UNA_BELOVED_COMPANION'),
('UNIT_UNA_BUDDY', 'PROMOTION_IGNORE_TERRAIN_COST');

-- Civ V's setup and Dawn of Man screens display at most two unique components
-- and list unit overrides before building overrides. Trentrouls is already the
-- leader and the default unit of his untrainable starting class, so only Buddy
-- needs to be registered as a civilization unit override. This leaves the
-- second visible component slot for Centrelink without affecting Trentrouls'
-- starting spawn or gameplay systems.
INSERT INTO Civilization_UnitClassOverrides (CivilizationType, UnitClassType, UnitType)
VALUES ('CIVILIZATION_UNA_COURT', 'UNITCLASS_UNA_BUDDY', 'UNIT_UNA_BUDDY');

INSERT INTO Civilization_FreeUnits (CivilizationType, UnitClassType, UnitAIType, Count) VALUES
('CIVILIZATION_UNA_COURT', 'UNITCLASS_SETTLER', 'UNITAI_SETTLE', 1),
('CIVILIZATION_UNA_COURT', 'UNITCLASS_UNA_TRENTROULS', 'UNITAI_ATTACK', 1);

-- Centrelink: a Bank replacement with +1 local Happiness.
INSERT INTO Buildings
    (Type, Description, Civilopedia, Strategy, Help, GoldMaintenance, Cost, FaithCost,
     HurryCostModifier, MinAreaSize, ConquestProb, Happiness, UnmoddedHappiness,
     TradeRouteRecipientBonus, TradeRouteTargetBonus,
     BuildingClass, ArtDefineTag, PrereqTech, SpecialistType, SpecialistCount,
     GreatWorkSlotType, GreatWorkCount, FreeStartEra, PortraitIndex, IconAtlas,
     ArtInfoCulturalVariation, ArtInfoEraVariation, ArtInfoRandomVariation, ShowInPedia)
SELECT
    'BUILDING_UNA_CENTRELINK', 'TXT_KEY_BUILDING_UNA_CENTRELINK',
    'TXT_KEY_BUILDING_UNA_CENTRELINK_PEDIA', 'TXT_KEY_BUILDING_UNA_CENTRELINK_STRATEGY',
    'TXT_KEY_BUILDING_UNA_CENTRELINK_HELP', GoldMaintenance, Cost, FaithCost,
    HurryCostModifier, MinAreaSize, ConquestProb, 1, 0,
    TradeRouteRecipientBonus, TradeRouteTargetBonus,
    BuildingClass, ArtDefineTag, PrereqTech, SpecialistType, SpecialistCount,
    GreatWorkSlotType, GreatWorkCount, FreeStartEra, 0, 'UNA_CENTRELINK_ATLAS',
    ArtInfoCulturalVariation, ArtInfoEraVariation, ArtInfoRandomVariation, 1
FROM Buildings WHERE Type = 'BUILDING_BANK';

INSERT INTO Building_YieldModifiers (BuildingType, YieldType, Yield)
SELECT 'BUILDING_UNA_CENTRELINK', YieldType, Yield
FROM Building_YieldModifiers WHERE BuildingType = 'BUILDING_BANK';

INSERT INTO Building_YieldChanges (BuildingType, YieldType, Yield)
SELECT 'BUILDING_UNA_CENTRELINK', YieldType, Yield
FROM Building_YieldChanges WHERE BuildingType = 'BUILDING_BANK';

INSERT INTO Building_ClassesNeededInCity (BuildingType, BuildingClassType)
SELECT 'BUILDING_UNA_CENTRELINK', BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_BANK';

INSERT INTO Building_Flavors (BuildingType, FlavorType, Flavor)
SELECT 'BUILDING_UNA_CENTRELINK', FlavorType, Flavor
FROM Building_Flavors WHERE BuildingType = 'BUILDING_BANK';

INSERT INTO Civilization_BuildingClassOverrides (CivilizationType, BuildingClassType, BuildingType)
VALUES ('CIVILIZATION_UNA_COURT', 'BUILDINGCLASS_BANK', 'BUILDING_UNA_CENTRELINK');
