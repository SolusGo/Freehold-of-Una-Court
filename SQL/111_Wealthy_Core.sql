-- The Wealthy of Una Court: human-only economy, ordinary starting units.
UPDATE CustomModOptions SET Value=1 WHERE Name IN ('EVENTS_NEW_ERA','EVENTS_CITY');
INSERT INTO Colors (Type,Red,Green,Blue,Alpha) VALUES
('COLOR_TRENT_WEALTHY_BLUE',0.035,0.12,0.34,1),
('COLOR_TRENT_WEALTHY_GOLD',0.95,0.76,0.30,1);
INSERT INTO PlayerColors (Type,PrimaryColor,SecondaryColor,TextColor) VALUES
('PLAYERCOLOR_TRENT_WEALTHY','COLOR_TRENT_WEALTHY_BLUE','COLOR_TRENT_WEALTHY_GOLD','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits (Type,Description,ShortDescription) VALUES
('TRAIT_TRENT_WEALTHY','TXT_KEY_WEALTHY_TRAIT_HELP','TXT_KEY_WEALTHY_TRAIT');
UPDATE Civilizations SET Description='TXT_KEY_WEALTHY_CIV',ShortDescription='TXT_KEY_WEALTHY_SHORT',
Adjective='TXT_KEY_WEALTHY_ADJECTIVE',Civilopedia='TXT_KEY_WEALTHY_PEDIA',
CivilopediaTag='TXT_KEY_CIV5_WEALTHY',Strategy='TXT_KEY_WEALTHY_STRATEGY',Playable=1,AIPlayable=0,
DefaultPlayerColor='PLAYERCOLOR_TRENT_WEALTHY',PortraitIndex=0,IconAtlas='WEALTHY_CIV_ATLAS',
AlphaIconAtlas='WEALTHY_ALPHA_ATLAS',MapImage='Art/WealthyTrent/WealthyMap.dds',
DawnOfManImage='Art/WealthyTrent/WealthyDawn.dds',DawnOfManQuote='TXT_KEY_WEALTHY_DAWN',DawnOfManAudio=''
WHERE Type='CIVILIZATION_TRENT_WEALTHY';
UPDATE Leaders SET Description='TXT_KEY_WEALTHY_LEADER',Civilopedia='TXT_KEY_WEALTHY_LEADER_PEDIA',
CivilopediaTag='TXT_KEY_CIV5_WEALTHY_LEADER',ArtDefineTag='Art/WealthyTrent/WealthyLeaderScene.xml',
PrimaryVictoryPursuit='VICTORY_PURSUIT_DIPLOMACY',SecondaryVictoryPursuit='VICTORY_PURSUIT_SCIENCE',
VictoryCompetitiveness=8,WonderCompetitiveness=6,MinorCivCompetitiveness=9,Boldness=3,
DiploBalance=8,WarmongerHate=7,DoFWillingness=8,DenounceWillingness=3,WorkWithWillingness=8,
WorkAgainstWillingness=3,Loyalty=7,Forgiveness=7,Neediness=9,Meanness=2,Chattiness=6,
PortraitIndex=0,IconAtlas='WEALTHY_LEADER_ATLAS' WHERE Type='LEADER_TRENT_WEALTHY';
INSERT INTO Leader_Traits VALUES ('LEADER_TRENT_WEALTHY','TRAIT_TRENT_WEALTHY');
INSERT INTO Civilization_Leaders VALUES ('CIVILIZATION_TRENT_WEALTHY','LEADER_TRENT_WEALTHY');
INSERT INTO Leader_Flavors (LeaderType,FlavorType,Flavor)
SELECT 'LEADER_TRENT_WEALTHY',FlavorType,CASE FlavorType
WHEN 'FLAVOR_GOLD' THEN 10 WHEN 'FLAVOR_DIPLOMACY' THEN 10 WHEN 'FLAVOR_SCIENCE' THEN 8
WHEN 'FLAVOR_PRODUCTION' THEN 7 WHEN 'FLAVOR_GROWTH' THEN 8 WHEN 'FLAVOR_OFFENSE' THEN 2
WHEN 'FLAVOR_DEFENSE' THEN 6 WHEN 'FLAVOR_CITY_DEFENSE' THEN 7 ELSE 5 END
FROM Leader_Flavors WHERE LeaderType='LEADER_WASHINGTON';
INSERT INTO Leader_MajorCivApproachBiases (LeaderType,MajorCivApproachType,Bias)
SELECT 'LEADER_TRENT_WEALTHY',MajorCivApproachType,CASE MajorCivApproachType
WHEN 'MAJOR_CIV_APPROACH_WAR' THEN 2 WHEN 'MAJOR_CIV_APPROACH_HOSTILE' THEN 2
WHEN 'MAJOR_CIV_APPROACH_FRIENDLY' THEN 9 WHEN 'MAJOR_CIV_APPROACH_NEUTRAL' THEN 8 ELSE 5 END
FROM Leader_MajorCivApproachBiases WHERE LeaderType='LEADER_WASHINGTON';
INSERT INTO Leader_MinorCivApproachBiases (LeaderType,MinorCivApproachType,Bias)
SELECT 'LEADER_TRENT_WEALTHY',MinorCivApproachType,CASE MinorCivApproachType
WHEN 'MINOR_CIV_APPROACH_FRIENDLY' THEN 9 WHEN 'MINOR_CIV_APPROACH_PROTECTIVE' THEN 8 ELSE 2 END
FROM Leader_MinorCivApproachBiases WHERE LeaderType='LEADER_WASHINGTON';
INSERT INTO Civilization_FreeBuildingClasses VALUES ('CIVILIZATION_TRENT_WEALTHY','BUILDINGCLASS_PALACE');
INSERT INTO Civilization_FreeTechs VALUES ('CIVILIZATION_TRENT_WEALTHY','TECH_AGRICULTURE');
INSERT INTO Civilization_FreeUnits (CivilizationType,UnitClassType,UnitAIType,Count) VALUES
('CIVILIZATION_TRENT_WEALTHY','UNITCLASS_SETTLER','UNITAI_SETTLE',1);
-- Handicap/era setup supplies the normal Warrior. No unit overrides.
INSERT INTO Civilization_BuildingClassOverrides VALUES
('CIVILIZATION_TRENT_WEALTHY','BUILDINGCLASS_BANK','BUILDING_TRENT_WEALTHY_CENTRELINK'),
('CIVILIZATION_TRENT_WEALTHY','BUILDINGCLASS_PALACE','BUILDING_TRENT_WEALTHY_PALACE');
UPDATE Buildings SET Civilopedia='TXT_KEY_WEALTHY_CENTRELINK_PEDIA',
Strategy='TXT_KEY_WEALTHY_CENTRELINK_STRATEGY',Help='TXT_KEY_WEALTHY_CENTRELINK_HELP'
WHERE Type='BUILDING_TRENT_WEALTHY_CENTRELINK';
UPDATE Buildings SET Description='TXT_KEY_WEALTHY_PALACE',Civilopedia='TXT_KEY_WEALTHY_PALACE_PEDIA',
Strategy='TXT_KEY_WEALTHY_PALACE_STRATEGY',Help='TXT_KEY_WEALTHY_PALACE_HELP',
PortraitIndex=0,IconAtlas='WEALTHY_PALACE_ATLAS' WHERE Type='BUILDING_TRENT_WEALTHY_PALACE';
-- Mutually exclusive total tiers, reconciled in Lua. UnmoddedHappiness is
-- uncapped when CPO sums city Happiness; ordinary Happiness is not used here.
CREATE TEMP TABLE WealthyLevels (N INTEGER);
INSERT INTO WealthyLevels VALUES (1),(2),(3),(4),(5),(6),(7),(8);
INSERT INTO BuildingClasses (Type,DefaultBuilding,Description)
SELECT 'BUILDINGCLASS_TRENT_WEALTHY_LUXURY_'||N,'BUILDING_TRENT_WEALTHY_LUXURY_'||N,
'TXT_KEY_WEALTHY_LUXURY' FROM WealthyLevels;
INSERT INTO Buildings
(Type,BuildingClass,Description,Help,Cost,FaithCost,IsDummy,ShowInPedia,NeverCapture,NukeImmune,
 ConquestProb,UnmoddedHappiness,PortraitIndex,IconAtlas)
SELECT 'BUILDING_TRENT_WEALTHY_LUXURY_'||N,'BUILDINGCLASS_TRENT_WEALTHY_LUXURY_'||N,
'TXT_KEY_WEALTHY_LUXURY','TXT_KEY_WEALTHY_PALACE_HELP',-1,-1,1,0,1,1,0,N,0,'WEALTHY_PALACE_ATLAS'
FROM WealthyLevels;
INSERT INTO Building_YieldChanges (BuildingType,YieldType,Yield)
SELECT 'BUILDING_TRENT_WEALTHY_LUXURY_'||N,'YIELD_GOLD',2*N FROM WealthyLevels;
DROP TABLE WealthyLevels;
