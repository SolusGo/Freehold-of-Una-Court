-- ===========================================================================
-- The Dominion of Una Court - core gameplay
-- ===========================================================================

print("DominionCore.lua loaded")

local SAVE = Modding.OpenSaveData()
local CIV_DOMINION = GameInfoTypes.CIVILIZATION_DOMINION_UNA_COURT
local UNIT_TRENT = GameInfoTypes.UNIT_DOMINION_TRENTROULS
local UNIT_WARRIOR = GameInfoTypes.UNIT_WARRIOR
local UNIT_SETTLER = GameInfoTypes.UNIT_SETTLER
local UNITAI_ATTACK = GameInfoTypes.UNITAI_ATTACK
local ERA_PROMOTIONS = {
    GameInfoTypes.PROMOTION_DOMINION_ERA_ANCIENT,
    GameInfoTypes.PROMOTION_DOMINION_ERA_CLASSICAL,
    GameInfoTypes.PROMOTION_DOMINION_ERA_MEDIEVAL,
    GameInfoTypes.PROMOTION_DOMINION_ERA_RENAISSANCE,
    GameInfoTypes.PROMOTION_DOMINION_ERA_INDUSTRIAL,
    GameInfoTypes.PROMOTION_DOMINION_ERA_MODERN,
    GameInfoTypes.PROMOTION_DOMINION_ERA_ATOMIC,
    GameInfoTypes.PROMOTION_DOMINION_ERA_INFORMATION
}
local BONUS_BUILDINGS = {}
for level = 1, 16 do
    BONUS_BUILDINGS[level] = GameInfoTypes["BUILDING_UNA_COURT_BONUS_" .. tostring(level)]
end

local collapsing = {}
local pendingCollapses = {}

local function Key(playerID, suffix)
    return "DOMINION_SWAP_" .. tostring(playerID) .. "_" .. suffix
end

local function GetNumber(playerID, suffix)
    return tonumber(SAVE.GetValue(Key(playerID, suffix))) or 0
end

function Dominion_IsPlayer(player)
    return player ~= nil and player:IsAlive() and CIV_DOMINION ~= nil
        and player:GetCivilizationType() == CIV_DOMINION
end

local function FindOwnedUnit(player, unitType)
    if player == nil or unitType == nil then return nil end
    for unit in player:Units() do
        if unit:GetUnitType() == unitType then return unit end
    end
    return nil
end

function Dominion_FindOwnedTrent(player)
    return FindOwnedUnit(player, UNIT_TRENT)
end

-- During Body Swap the original body belongs to the target's owner.
function Dominion_FindTrentBody(player)
    if player == nil then return nil end
    local owned = Dominion_FindOwnedTrent(player)
    if owned ~= nil then return owned end
    if GetNumber(player:GetID(), "ACTIVE") ~= 1 then return nil end
    local owner = Players[GetNumber(player:GetID(), "TRENT_OWNER")]
    return owner ~= nil and owner:GetUnitByID(GetNumber(player:GetID(), "TRENT_UNIT_ID")) or nil
end

local function IsOpeningTurn()
    if Game == nil or Game.GetElapsedGameTurns == nil then return false end
    local ok, turns = pcall(function() return Game.GetElapsedGameTurns() end)
    return ok and tonumber(turns) == 0
end

local function StartingKey(playerID)
    return "DOMINION_CORE_" .. tostring(playerID) .. "_TRENT_GRANTED"
end

local function EnsureStartingTrent(playerID)
    local player = Players[playerID]
    if not Dominion_IsPlayer(player) or GetNumber(playerID, "ACTIVE") == 1 then return nil end

    local trents, warriors = {}, {}
    for unit in player:Units() do
        if unit:GetUnitType() == UNIT_TRENT then trents[#trents + 1] = unit:GetID()
        elseif unit:GetUnitType() == UNIT_WARRIOR then warriors[#warriors + 1] = unit:GetID() end
    end

    if IsOpeningTurn() then
        for _, unitID in ipairs(warriors) do
            local warrior = player:GetUnitByID(unitID)
            if warrior ~= nil then warrior:Kill(false, -1) end
        end
        for index = 2, #trents do
            local duplicate = player:GetUnitByID(trents[index])
            if duplicate ~= nil then duplicate:Kill(false, -1) end
        end
    end

    local existing = Dominion_FindOwnedTrent(player)
    if existing ~= nil then
        SAVE.SetValue(StartingKey(playerID), 1)
        return existing
    end
    if not IsOpeningTurn() or tonumber(SAVE.GetValue(StartingKey(playerID))) == 1 then return nil end

    local x, y
    local settler = FindOwnedUnit(player, UNIT_SETTLER)
    if settler ~= nil then x, y = settler:GetX(), settler:GetY() end
    if x == nil then
        local plot = player:GetStartingPlot()
        if plot ~= nil then x, y = plot:GetX(), plot:GetY() end
    end
    if x == nil then return nil end

    local trent = player:InitUnit(UNIT_TRENT, x, y, UNITAI_ATTACK)
    if trent ~= nil then
        if trent.JumpToNearestValidPlot ~= nil then pcall(function() trent:JumpToNearestValidPlot() end) end
        SAVE.SetValue(StartingKey(playerID), 1)
    end
    return trent
end

local function ApplyTrentState(player)
    local trent = Dominion_FindTrentBody(player)
    if trent == nil then return end
    for _, promotionID in ipairs(ERA_PROMOTIONS) do
        if promotionID ~= nil then trent:SetHasPromotion(promotionID, false) end
    end
    local era = math.max(0, math.min(7, player:GetCurrentEra()))
    if ERA_PROMOTIONS[era + 1] ~= nil then trent:SetHasPromotion(ERA_PROMOTIONS[era + 1], true) end
end

local function ApplyCityBonus(player)
    local level = 0
    if Dominion_FindTrentBody(player) ~= nil then
        level = math.max(1, math.min(8, player:GetCurrentEra() + 1))
        if GetNumber(player:GetID(), "ACTIVE") == 1 then level = level * 2 end
    end
    for city in player:Cities() do
        for index = 1, 16 do
            local buildingID = BONUS_BUILDINGS[index]
            if buildingID ~= nil then city:SetNumRealBuilding(buildingID, index == level and 1 or 0) end
        end
    end
end

function Dominion_RefreshPlayer(playerID)
    local player = Players[playerID]
    if not Dominion_IsPlayer(player) then return end
    ApplyTrentState(player)
    ApplyCityBonus(player)
end

local function FindHumanDefeatWinner(playerID, killerPlayerID)
    local player = Players[playerID]
    local defeatedTeam = player ~= nil and player:GetTeam() or -1
    local killer = killerPlayerID ~= nil and killerPlayerID >= 0 and Players[killerPlayerID] or nil
    if killer ~= nil and killer:IsAlive() and killer:GetTeam() ~= defeatedTeam and not killer:IsBarbarian()
        and (killer.IsMinorCiv == nil or not killer:IsMinorCiv()) then
        return killer
    end

    for otherPlayerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
        local other = Players[otherPlayerID]
        if otherPlayerID ~= playerID and other ~= nil and other:IsAlive()
            and other:GetTeam() ~= defeatedTeam
            and not other:IsBarbarian()
            and (other.IsMinorCiv == nil or not other:IsMinorCiv()) then
            return other
        end
    end
    return nil
end

-- Eliminating the active human by removing their final city can enter
-- CvPlayer::kill while the UI still owns an end-turn blocker (production,
-- voting, etc.). VP asserts in that state. Declaring a living opponent the
-- winner produces the same real defeat without mutating the active player's
-- cities inside the blocker update.
local function EndHumanGame(playerID, killerPlayerID)
    local player = Players[playerID]
    if player == nil or not player:IsHuman() or Game.GetActivePlayer() ~= playerID then return false end

    local winner = FindHumanDefeatWinner(playerID, killerPlayerID)
    local victoryID = GameInfoTypes.VICTORY_DOMINATION
    if winner ~= nil and victoryID ~= nil and Game.SetWinner ~= nil then
        local ok = pcall(function() Game.SetWinner(winner:GetTeam(), victoryID) end)
        if ok then
            print("Dominion ended the human game after Trentrouls fell; winner player "
                .. tostring(winner:GetID()))
            return true
        end
    end

    -- Compatibility fallback for DLL builds that do not expose Game.SetWinner.
    if winner ~= nil and Events.EndGameShow ~= nil and EndGameTypes ~= nil
        and EndGameTypes.Domination ~= nil then
        local ok = pcall(function()
            Events.EndGameShow(EndGameTypes.Domination, winner:GetID())
        end)
        if ok then
            print("Dominion showed the human defeat screen after Trentrouls fell")
            return true
        end
    end
    return false
end

local function DestroyEmpire(playerID, killerPlayerID)
    if collapsing[playerID] then return end
    collapsing[playerID] = true
    local player = Players[playerID]
    if player == nil then return end

    if Dominion_EndBodySwap ~= nil then
        -- The original body is already in the DLL's death path. End the swap
        -- without issuing a second immediate Kill on that same unit.
        pcall(function() Dominion_EndBodySwap(playerID, "Trentrouls has fallen", false, true) end)
    end

    if Events.GameplayAlertMessage ~= nil then
        Events.GameplayAlertMessage("Trentrouls has fallen. The Dominion of Una Court has collapsed.")
    end

    -- The human game is now over. Keep the map intact behind the defeat screen
    -- instead of triggering VP's end-turn-blocking assertion through last-city
    -- elimination. AI empires still receive the full physical collapse below.
    if EndHumanGame(playerID, killerPlayerID) then return end

    local capital = player:GetCapitalCity()
    local capitalID = capital ~= nil and capital:GetID() or -1
    local cities = {}
    for city in player:Cities() do cities[#cities + 1] = city:GetID() end
    for _, cityID in ipairs(cities) do
        if cityID ~= capitalID then
            local city = player:GetCityByID(cityID)
            if city ~= nil then city:Kill() end
        end
    end
    if capital ~= nil then
        local killer = killerPlayerID ~= nil and killerPlayerID >= 0 and Players[killerPlayerID] or nil
        local acquired = false
        if killer ~= nil and killer:IsAlive() and not killer:IsBarbarian() and killer.AcquireCity ~= nil then
            acquired = pcall(function() killer:AcquireCity(capital, true, false) end)
        end
        if not acquired then
            local remaining = player:GetCityByID(capitalID)
            if remaining ~= nil then remaining:Kill() end
        end
    end

    local units = {}
    for unit in player:Units() do
        -- Trentrouls may remain enumerable while the combat DLL completes his
        -- delayed death. Let the original combat sequence delete him.
        if unit:GetUnitType() ~= UNIT_TRENT then units[#units + 1] = unit:GetID() end
    end
    for _, unitID in ipairs(units) do
        local unit = player:GetUnitByID(unitID)
        if unit ~= nil then unit:Kill(false, killerPlayerID or -1) end
    end
end

function Dominion_ProcessPendingCollapses(force)
    local ready = {}
    for playerID, pending in pairs(pendingCollapses) do
        if force then
            ready[#ready + 1] = { playerID = playerID, killer = pending.killer }
        elseif pending.ready then
            pending.settleTicks = math.max(0, (pending.settleTicks or 0) - 1)
            if pending.settleTicks == 0 then
                ready[#ready + 1] = { playerID = playerID, killer = pending.killer }
            end
        end
    end
    for _, pending in ipairs(ready) do
        pendingCollapses[pending.playerID] = nil
        DestroyEmpire(pending.playerID, pending.killer)
    end
end

local function DoTurn(playerID)
    Dominion_ProcessPendingCollapses(true)
    local player = Players[playerID]
    if not Dominion_IsPlayer(player) or collapsing[playerID] then return end
    EnsureStartingTrent(playerID)
    Dominion_RefreshPlayer(playerID)
end
GameEvents.PlayerDoTurn.Add(DoTurn)

if GameEvents.PlayerCanTrain ~= nil then
    GameEvents.PlayerCanTrain.Add(function(playerID, unitType)
        local player = Players[playerID]
        if Dominion_IsPlayer(player) and unitType == UNIT_TRENT then return false end
        return true
    end)
end

if GameEvents.TeamSetEra ~= nil then
    GameEvents.TeamSetEra.Add(function(teamID)
        for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
            local player = Players[playerID]
            if Dominion_IsPlayer(player) and player:GetTeam() == teamID then Dominion_RefreshPlayer(playerID) end
        end
    end)
end

if GameEvents.UnitSetXY ~= nil then
    GameEvents.UnitSetXY.Add(function(playerID, unitID)
        local player = Players[playerID]
        local unit = player ~= nil and player:GetUnitByID(unitID) or nil
        if Dominion_IsPlayer(player) and unit ~= nil and unit:GetUnitType() == UNIT_TRENT then
            Dominion_RefreshPlayer(playerID)
        end
    end)
end

if Events.SerialEventCityCreated ~= nil then
    Events.SerialEventCityCreated.Add(function(_, playerID)
        if playerID ~= nil then Dominion_RefreshPlayer(playerID) end
    end)
end
if GameEvents.CityCaptureComplete ~= nil then
    GameEvents.CityCaptureComplete.Add(function(_, _, _, _, newPlayerID)
        if newPlayerID ~= nil then Dominion_RefreshPlayer(newPlayerID) end
    end)
end

if GameEvents.UnitPrekill ~= nil then
    GameEvents.UnitPrekill.Add(function(killedPlayerID, killedUnitID, killedUnitType, _, _, _, killerPlayerID)
        if killedUnitType ~= UNIT_TRENT then return end
        if Dominion_IsBodySwapTransfer ~= nil and Dominion_IsBodySwapTransfer() then return end

        local dominionID = nil
        local owner = Players[killedPlayerID]
        if Dominion_IsPlayer(owner) then dominionID = killedPlayerID end
        if dominionID == nil then
            for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
                local player = Players[playerID]
                if Dominion_IsPlayer(player) and GetNumber(playerID, "ACTIVE") == 1
                    and GetNumber(playerID, "TRENT_OWNER") == killedPlayerID
                    and GetNumber(playerID, "TRENT_UNIT_ID") == killedUnitID then
                    dominionID = playerID
                    break
                end
            end
        end
        if dominionID ~= nil and not collapsing[dominionID] and pendingCollapses[dominionID] == nil then
            pendingCollapses[dominionID] = { killer = killerPlayerID, ready = false, settleTicks = 2 }
            print("Dominion queued post-combat collapse for player " .. tostring(dominionID))
        end
    end)
end

if Events.EndCombatSim ~= nil then
    Events.EndCombatSim.Add(function()
        for _, pending in pairs(pendingCollapses) do pending.ready = true end
    end)
end

for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
    EnsureStartingTrent(playerID)
    Dominion_RefreshPlayer(playerID)
end

print("Dominion core initialized")
