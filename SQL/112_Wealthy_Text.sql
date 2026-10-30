INSERT INTO Language_en_US (Tag,Text) VALUES
('TXT_KEY_WEALTHY_CIV','The Wealthy of Una Court'),
('TXT_KEY_WEALTHY_SHORT','Wealthy Una Court'),
('TXT_KEY_WEALTHY_ADJECTIVE','Wealthy'),
('TXT_KEY_WEALTHY_LEADER','Trent'),
('TXT_KEY_WEALTHY_LEADER_PEDIA','The man who has everything, yet still receives Centrelink. Trent presides over a court of velvet chairs, polished ledgers and remarkably persistent benefit claims.'),
('TXT_KEY_WEALTHY_TRAIT','Cheating the Centrelink System'),
('TXT_KEY_WEALTHY_TRAIT_HELP','Centrelinks provide twice their normal positive yields, yield modifiers, local Happiness, Merchant slots and recipient trade-route Gold. Every 25 turns on Standard speed (scaled by game speed), audit up to two of the richest third of living, met foreign major civilizations with at least 500 Gold and +10 GPT. Transfer 5% of each treasury immediately, then 20% of its positive GPT on each of your next five turns. Payments are rounded down and limited to available Gold. Wars do not prevent audits.'),
('TXT_KEY_WEALTHY_PEDIA','Prosperity comes naturally to Una Court, particularly when someone else signs the cheque. Its treasury grows through foreign wealth transfers and lavish domestic institutions. Every contribution removes actual Gold from its donor and deposits the same amount in Trent''s treasury.'),
('TXT_KEY_WEALTHY_STRATEGY','Develop your economy, research Banking and build Centrelinks. Save Gold for infrastructure purchases and City-State alliances. The luxurious Palace grows stronger with your current Era. Diplomatic Victory is preferred; Science offers a second path. Foreign audits require contact, so explore early. There are no special combat bonuses.'),
('TXT_KEY_WEALTHY_CENTRELINK_HELP','Replaces the Bank. Retains the active Centrelink''s requirements, costs and maintenance. Doubles positive intrinsic yields and yield modifiers, local Happiness (+2 instead of +1), Merchant capacity, and trade-route recipient Gold. Foreign traders'' target bonus is unchanged. See the building statistics for active ruleset values.'),
('TXT_KEY_WEALTHY_CENTRELINK_PEDIA','The familiar Centrelink office has discovered an exceptionally deserving applicant: its sovereign. This exclusive version doubles positive benefits from the shared Centrelink while leaving every other civilization''s Centrelink unchanged.'),
('TXT_KEY_WEALTHY_CENTRELINK_STRATEGY','Construct Centrelinks after Banking to multiply domestic wealth and Merchant opportunities. The building retains the ordinary Bank replacement chain and production requirements.'),
('TXT_KEY_WEALTHY_PALACE','3 Una Court'),
('TXT_KEY_WEALTHY_PALACE_HELP','Replaces the Palace and retains all normal Palace effects. In your Capital, adds +1 empire-wide Happiness and +2 Gold per turn per current Era level: Ancient +1/+2, Classical +2/+4, Medieval +3/+6, Renaissance +4/+8, Industrial +5/+10, Modern +6/+12, Atomic +7/+14, Information +8/+16. These are total bonuses, not cumulative additions. Moves with the Capital.'),
('TXT_KEY_WEALTHY_PALACE_PEDIA','A different 3 Una Court from the Ultimate Possessor''s National Wonder: this is Trent''s permanent seat of comfortable government. Normal Palace functions continue beneath the gilt ceilings, while the luxury allowance rises with the Era.'),
('TXT_KEY_WEALTHY_PALACE_STRATEGY','Your Capital receives this Palace automatically. Advance through the Eras to increase its total Happiness and Gold bonuses. Capital relocation transfers the allowance without duplicating it.'),
('TXT_KEY_WEALTHY_LUXURY','3 Una Court Luxury Allowance'),
('TXT_KEY_WEALTHY_DAWN','Trent, fortunate ruler of the Wealthy of Una Court, you have inherited prosperity beyond the dreams of ordinary men. Yet your ambitions extend beyond the wealth already at your disposal. Across the world, prosperous empires accumulate riches, unaware that their success is about to finance your comfortable existence.[NEWLINE][NEWLINE]Will you build an empire of unmatched prosperity, or simply persuade the rest of the world to pay for it?'),
('TXT_KEY_WEALTHY_AUDIT_TITLE','Centrelink Audit Complete!'),
('TXT_KEY_WEALTHY_AUDIT_BODY','Wealthy civilizations have been selected to fund your lifestyle.'),
('TXT_KEY_WEALTHY_CONTRIBUTION_TITLE','Mandatory Centrelink Contribution!'),
('TXT_KEY_WEALTHY_CONTRIBUTION_BODY','A portion of your national wealth has been transferred to Una Court.'),
('TXT_KEY_WEALTHY_REPORT_TITLE','Centrelink Payment Report'),
('TXT_KEY_WEALTHY_INITIAL_LINE','{1_Civ}: {2_Num} Gold deducted; Una Court received {2_Num} Gold. Five payment turns follow.'),
('TXT_KEY_WEALTHY_PAYMENT_LINE','{1_Civ}: {2_Num} Gold deducted; Una Court received {2_Num} Gold. {3_Num} payment turns remaining.'),
('TXT_KEY_CIV5_WEALTHY_HEADING_1','A Comfortable Inheritance'),
('TXT_KEY_CIV5_WEALTHY_TEXT_1','The national budget of Una Court begins with a modest assumption: Trent deserves a comfortable life. The remainder of the budget concerns who will pay for it.'),
('TXT_KEY_CIV5_WEALTHY_HEADING_2','Mandatory Wealth Redistribution'),
('TXT_KEY_CIV5_WEALTHY_TEXT_2','Rank living, met foreign major civilizations by treasury, breaking ties by player ID. Round the size of the richest third upward, then choose at most two members with at least 500 Gold and +10 GPT. Contact is required; peace is not. Audit payments are genuine, conserved treasury transfers.'),
('TXT_KEY_CIV5_WEALTHY_HEADING_3','Five Convenient Instalments'),
('TXT_KEY_CIV5_WEALTHY_TEXT_3','An audit takes 5% of current treasury immediately. On Trent''s following five turns it takes 20% of each donor''s current positive GPT, rounded down and capped by available Gold. A non-positive GPT pays nothing that turn, but that turn still counts. The five-turn duration does not scale with game speed.'),
('TXT_KEY_CIV5_WEALTHY_LEADER_HEADING_1','The Wealthy'),
('TXT_KEY_CIV5_WEALTHY_LEADER_TEXT_1','Trent enjoys the finest things in life: ornate furniture, a peaceful economy and recurring payments from other people.'),
('TXT_KEY_CIVILOPEDIA_LEADERS_WEALTHY_NAME','Trent'),
('TXT_KEY_CIVILOPEDIA_LEADERS_WEALTHY_SUBTITLE','The Wealthy of Una Court'),
('TXT_KEY_CIVILOPEDIA_LEADERS_WEALTHY_LIVED','The present day'),
('TXT_KEY_CIVILOPEDIA_LEADERS_WEALTHY_TITLES_1','The man who has everything'),
('TXT_KEY_WEALTHY_DIPLO_GREETING','Welcome to Una Court. Please leave your financial statements with the butler.'),
('TXT_KEY_WEALTHY_DIPLO_WAR','How inconvenient. Your contribution remains payable.'),
('TXT_KEY_WEALTHY_DIPLO_PEACE','A sensible investment in everybody''s comfort.'),
('TXT_KEY_WEALTHY_DIPLO_DEFEAT','I assume my benefits will continue during this temporary setback.');

-- Preserve the baseline response coverage, overriding the supported greetings.
INSERT INTO Diplomacy_Responses (LeaderType,ResponseType,Response,Bias)
SELECT 'LEADER_TRENT_WEALTHY',ResponseType,Response,Bias
FROM Diplomacy_Responses WHERE LeaderType='LEADER_WASHINGTON';
UPDATE Diplomacy_Responses SET Response=CASE ResponseType
WHEN 'RESPONSE_FIRST_GREETING' THEN 'TXT_KEY_WEALTHY_DIPLO_GREETING'
WHEN 'RESPONSE_DOW_GENERIC' THEN 'TXT_KEY_WEALTHY_DIPLO_WAR'
WHEN 'RESPONSE_PEACE_MADE_BY_HUMAN_GRACIOUS' THEN 'TXT_KEY_WEALTHY_DIPLO_PEACE'
WHEN 'RESPONSE_DEFEATED' THEN 'TXT_KEY_WEALTHY_DIPLO_DEFEAT' ELSE Response END
WHERE LeaderType='LEADER_TRENT_WEALTHY';

INSERT INTO Civilization_SpyNames (CivilizationType,SpyName)
SELECT 'CIVILIZATION_TRENT_WEALTHY',SpyName FROM Civilization_SpyNames WHERE CivilizationType='CIVILIZATION_AMERICA';
INSERT INTO Language_en_US (Tag,Text) VALUES
('TXT_KEY_WEALTHY_CITY_01','Freehold of Una Court'),('TXT_KEY_WEALTHY_CITY_02','Royal Treasury'),
('TXT_KEY_WEALTHY_CITY_03','Velvet Terrace'),('TXT_KEY_WEALTHY_CITY_04','Dividend Bay'),
('TXT_KEY_WEALTHY_CITY_05','Gilt Gardens'),('TXT_KEY_WEALTHY_CITY_06','Benefit Heights'),
('TXT_KEY_WEALTHY_CITY_07','Merchant''s Rest'),('TXT_KEY_WEALTHY_CITY_08','Blue Drawing Room'),
('TXT_KEY_WEALTHY_CITY_09','Audit Harbour'),('TXT_KEY_WEALTHY_CITY_10','Compound Interest'),
('TXT_KEY_WEALTHY_CITY_11','Golden Receipt'),('TXT_KEY_WEALTHY_CITY_12','Comfort Estate'),
('TXT_KEY_WEALTHY_CITY_13','Tax Haven'),('TXT_KEY_WEALTHY_CITY_14','Sovereign Fund'),
('TXT_KEY_WEALTHY_CITY_15','Fine Print'),('TXT_KEY_WEALTHY_CITY_16','Chandelier Court'),
('TXT_KEY_WEALTHY_CITY_17','Plush Landing'),('TXT_KEY_WEALTHY_CITY_18','Cheque Point'),
('TXT_KEY_WEALTHY_CITY_19','Luxury Quay'),('TXT_KEY_WEALTHY_CITY_20','Another Allowance');
INSERT INTO Civilization_CityNames (CivilizationType,CityName)
SELECT 'CIVILIZATION_TRENT_WEALTHY',Tag FROM Language_en_US
WHERE Tag LIKE 'TXT_KEY_WEALTHY_CITY_%' ORDER BY Tag;
