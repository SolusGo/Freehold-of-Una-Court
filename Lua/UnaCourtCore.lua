-- ===========================================================================
-- The Freehold of Una Court - core gameplay
-- ===========================================================================

print("UnaCourtCore.lua loaded")

local CIV_UNA = GameInfoTypes.CIVILIZATION_UNA_COURT
local UNIT_TRENT = GameInfoTypes.UNIT_UNA_TRENTROULS
local UNIT_BUDDY = GameInfoTypes.UNIT_UNA_BUDDY
local UNIT_WARRIOR = GameInfoTypes.UNIT_WARRIOR
local UNIT_SETTLER = GameInfoTypes.UNIT_SETTLER
local UNITAI_ATTACK = GameInfoTypes.UNITAI_ATTACK
local PROMO_BUDDY = GameInfoTypes.PROMOTION_UNA_BUDDY_IS_HERE
local CORE_SAVE = Modding.OpenSaveData()

local ERA_PROMOTIONS = {
    GameInfoTypes.PROMOTION_UNA_ERA_ANCIENT,
    GameInfoTypes.PROMOTION_UNA_ERA_CLASSICAL,
    GameInfoTypes.PROMOTION_UNA_ERA_MEDIEVAL,
    GameInfoTypes.PROMOTION_UNA_ERA_RENAISSANCE,
    GameInfoTypes.PROMOTION_UNA_ERA_INDUSTRIAL,
    GameInfoTypes.PROMOTION_UNA_ERA_MODERN,
    GameInfoTypes.PROMOTION_UNA_ERA_ATOMIC,
    GameInfoTypes.PROMOTION_UNA_ERA_INFORMATION
}

local BUDDY_ERA_PROMOTIONS = {
    GameInfoTypes.PROMOTION_UNA_BUDDY_ERA_ANCIENT,
    GameInfoTypes.PROMOTION_UNA_BUDDY_ERA_CLASSICAL,
    GameInfoTypes.PROMOTION_UNA_BUDDY_ERA_MEDIEVAL,
    GameInfoTypes.PROMOTION_UNA_BUDDY_ERA_RENAISSANCE,
    GameInfoTypes.PROMOTION_UNA_BUDDY_ERA_INDUSTRIAL,
    GameInfoTypes.PROMOTION_UNA_BUDDY_ERA_MODERN,
    GameInfoTypes.PROMOTION_UNA_BUDDY_ERA_ATOMIC,
    GameInfoTypes.PROMOTION_UNA_BUDDY_ERA_INFORMATION
}

local BONUS_BUILDINGS = {}
for level = 1, 16 do
    BONUS_BUILDINGS[level] = GameInfoTypes["BUILDING_UNA_COURT_BONUS_" .. tostring(level)]
end

local collapsing = {}
local pendingCollapses = {}

function UnaCourt_IsPlayer(player)
    return player ~= nil
        and player:IsAlive()
        and CIV_UNA ~= nil
        and player:GetCivilizationType() == CIV_UNA
end

function UnaCourt_FindUnit(player, unitType)
    if player == nil or unitType == nil then return nil end
    for unit in player:Units() do
        if unit:GetUnitType() == unitType then return unit end
    end
    return nil
end

function UnaCourt_FindTrentrouls(player)
    return UnaCourt_FindUnit(player, UNIT_TRENT)
end

function UnaCourt_FindBuddy(player)
    return UnaCourt_FindUnit(player, UNIT_BUDDY)
end

local function UnaCourt_TrentGrantedKey(playerID)
    return "UNA_CORE_" .. tostring(playerID) .. "_TRENT_GRANTED"
end

local function UnaCourt_FindStartingUnit(player, unitType)
    if player == nil or unitType == nil then return nil end
    for unit in player:Units() do
        if unit:GetUnitType() == unitType then return unit end
    end
    return nil
end

local function UnaCourt_IsOpeningTurn()
    if Game == nil or Game.GetElapsedGameTurns == nil then return false end
    local ok, elapsedTurns = pcall(function() return Game.GetElapsedGameTurns() end)
    return ok and tonumber(elapsedTurns) == 0
end

local function UnaCourt_RemoveStartingWarriors(player, playerID)
    if not UnaCourt_IsOpeningTurn() then return false end

    local warriorIDs = {}
    for unit in player:Units() do
        if unit:GetUnitType() == UNIT_WARRIOR then
            warriorIDs[#warriorIDs + 1] = unit:GetID()
        end
    end

    for _, unitID in ipairs(warriorIDs) do
        local warrior = player:GetUnitByID(unitID)
        if warrior ~= nil then warrior:Kill(false, -1) end
    end

    if #warriorIDs > 0 then
        print("Una Court removed " .. tostring(#warriorIDs)
            .. " opening Warrior(s) for player " .. tostring(playerID))
    end
    return #warriorIDs > 0
end

local function UnaCourt_EnsureStartingTrentrouls(playerID)
    local player = Players[playerID]
    if not UnaCourt_IsPlayer(player) then return nil end

    local existingTrent = UnaCourt_FindTrentrouls(player)
    if existingTrent ~= nil then
        -- SQL normally grants Trentrouls before this Lua loads. Civ V/VP may
        -- independently grant one or more ordinary opening Warriors as well,
        -- so remove the complete Warrior package before returning the hero.
        UnaCourt_RemoveStartingWarriors(player, playerID)
        CORE_SAVE.SetValue(UnaCourt_TrentGrantedKey(playerID), 1)
        return existingTrent
    end

    if tonumber(CORE_SAVE.GetValue(UnaCourt_TrentGrantedKey(playerID))) == 1 then
        return nil
    end

    -- Never replace a Warrior when loading or continuing a later turn. If
    -- Trentrouls is absent after setup, the empire-collapse path owns that state.
    if not UnaCourt_IsOpeningTurn() then return nil end

    local x, y = nil, nil
    local warrior = UnaCourt_FindStartingUnit(player, UNIT_WARRIOR)
    if warrior ~= nil then
        x, y = warrior:GetX(), warrior:GetY()
    end

    -- Some handicap/mod combinations grant multiple opening Warriors. Replace
    -- their entire starting package with Trentrouls, not merely its first unit.
    UnaCourt_RemoveStartingWarriors(player, playerID)

    if x == nil or y == nil then
        local settler = UnaCourt_FindStartingUnit(player, UNIT_SETTLER)
        if settler ~= nil then x, y = settler:GetX(), settler:GetY() end
    end

    if x == nil or y == nil then
        local capital = player:GetCapitalCity()
        if capital ~= nil then x, y = capital:GetX(), capital:GetY() end
    end

    if x == nil or y == nil then
        local startingPlot = player:GetStartingPlot()
        if startingPlot ~= nil then x, y = startingPlot:GetX(), startingPlot:GetY() end
    end

    if x == nil or y == nil then
        print("Una Court could not find a valid starting plot for Trentrouls (player " .. tostring(playerID) .. ")")
        return nil
    end

    local trent = player:InitUnit(UNIT_TRENT, x, y, UNITAI_ATTACK)
    if trent ~= nil then
        if trent.JumpToNearestValidPlot ~= nil then
            pcall(function() trent:JumpToNearestValidPlot() end)
        end
        CORE_SAVE.SetValue(UnaCourt_TrentGrantedKey(playerID), 1)
        print("Una Court granted starting Trentrouls to player " .. tostring(playerID)
            .. " at (" .. tostring(trent:GetX()) .. "," .. tostring(trent:GetY()) .. ")")
    end
    return trent
end

function UnaCourt_IsBuddyAdjacent(trent, buddy)
    if trent == nil or buddy == nil then return false end
    local trentPlot = trent:GetPlot()
    local buddyPlot = buddy:GetPlot()
    if trentPlot == nil or buddyPlot == nil then return false end
    return Map.PlotDistance(trentPlot:GetX(), trentPlot:GetY(), buddyPlot:GetX(), buddyPlot:GetY()) <= 1
end

local function UnaCourt_ClearEraPromotions(trent)
    for _, promotionID in ipairs(ERA_PROMOTIONS) do
        if promotionID ~= nil then trent:SetHasPromotion(promotionID, false) end
    end
    for _, promotionID in ipairs(BUDDY_ERA_PROMOTIONS) do
        if promotionID ~= nil then trent:SetHasPromotion(promotionID, false) end
    end
end

local function UnaCourt_ApplyTrentState(player)
    local trent = UnaCourt_FindTrentrouls(player)
    if trent == nil then return end

    local eraIndex = math.max(0, math.min(7, player:GetCurrentEra()))
    local buddyNearby = UnaCourt_IsBuddyAdjacent(trent, UnaCourt_FindBuddy(player))
    UnaCourt_ClearEraPromotions(trent)
    local eraPromotion = buddyNearby and BUDDY_ERA_PROMOTIONS[eraIndex + 1] or ERA_PROMOTIONS[eraIndex + 1]
    if eraPromotion ~= nil then trent:SetHasPromotion(eraPromotion, true) end

    if PROMO_BUDDY ~= nil then trent:SetHasPromotion(PROMO_BUDDY, buddyNearby) end
end

local function UnaCourt_ApplyCityBonus(player)
    local trent = UnaCourt_FindTrentrouls(player)
    local activeLevel = 0

    if trent ~= nil then
        activeLevel = math.max(1, math.min(8, player:GetCurrentEra() + 1))
        if UnaCourt_IsBuddyAdjacent(trent, UnaCourt_FindBuddy(player)) then
            activeLevel = activeLevel * 2
        end
    end

    for city in player:Cities() do
        for level = 1, 16 do
            local buildingID = BONUS_BUILDINGS[level]
            if buildingID ~= nil then
                city:SetNumRealBuilding(buildingID, level == activeLevel and 1 or 0)
            end
        end
    end
end

function UnaCourt_RefreshPlayer(playerID)
    local player = Players[playerID]
    if not UnaCourt_IsPlayer(player) then return end
    UnaCourt_ApplyTrentState(player)
    UnaCourt_ApplyCityBonus(player)
end

local function UnaCourt_CountUnits(player, unitType)
    local count = 0
    for unit in player:Units() do
        if unit:GetUnitType() == unitType then count = count + 1 end
    end
    return count
end

local function UnaCourt_EnforceCaps(player)
    local seenTrent = false
    local seenBuddy = false
    local remove = {}

    for unit in player:Units() do
        if unit:GetUnitType() == UNIT_TRENT then
            if seenTrent then remove[#remove + 1] = unit:GetID() else seenTrent = true end
        elseif unit:GetUnitType() == UNIT_BUDDY then
            if seenBuddy then remove[#remove + 1] = unit:GetID() else seenBuddy = true end
        end
    end

    for _, unitID in ipairs(remove) do
        local unit = player:GetUnitByID(unitID)
        if unit ~= nil then unit:Kill(false, -1) end
    end
end

local function UnaCourt_DestroyRemainingEmpire(playerID, killerPlayerID)
    if collapsing[playerID] then return end
    collapsing[playerID] = true

    local player = Players[playerID]
    if player == nil then return end

    -- End possession before cities and units are removed.
    if UnaCourt_EndPossession ~= nil then
        pcall(function() UnaCourt_EndPossession(playerID, "Trentrouls has fallen") end)
    end

    local capital = player:GetCapitalCity()
    local capitalID = capital ~= nil and capital:GetID() or -1
    local cityIDs = {}
    for city in player:Cities() do cityIDs[#cityIDs + 1] = city:GetID() end

    for _, cityID in ipairs(cityIDs) do
        if cityID ~= capitalID then
            local city = player:GetCityByID(cityID)
            if city ~= nil then city:Kill() end
        end
    end

    if capital ~= nil then
        local killer = killerPlayerID ~= nil and killerPlayerID >= 0 and Players[killerPlayerID] or nil
        local validKiller = killer ~= nil and killer:IsAlive() and not killer:IsBarbarian()
        local transferred = false

        if validKiller and killer.AcquireCity ~= nil then
            transferred = pcall(function() killer:AcquireCity(capital, true, false) end)
        end

        if not transferred then
            local stillCapital = player:GetCityByID(capitalID)
            if stillCapital ~= nil then stillCapital:Kill() end
        end
    end

    local unitIDs = {}
    for unit in player:Units() do
        if unit:GetUnitType() ~= UNIT_TRENT then unitIDs[#unitIDs + 1] = unit:GetID() end
    end
    for _, unitID in ipairs(unitIDs) do
        local unit = player:GetUnitByID(unitID)
        if unit ~= nil then unit:Kill(false, killerPlayerID or -1) end
    end

    if Events.GameplayAlertMessage ~= nil then
        Events.GameplayAlertMessage("Trentrouls has fallen. The Freehold of Una Court has collapsed.")
    end
end

local function UnaCourt_ProcessPendingCollapses(force)
    local ready = {}
    for playerID, pending in pairs(pendingCollapses) do
        if force or pending.ready then
            ready[#ready + 1] = {
                playerID = playerID,
                killerPlayerID = pending.killerPlayerID
            }
        end
    end

    for _, pending in ipairs(ready) do
        pendingCollapses[pending.playerID] = nil
        UnaCourt_DestroyRemainingEmpire(pending.playerID, pending.killerPlayerID)
    end
end

local function UnaCourt_DoTurn(playerID)
    -- Guaranteed safe fallback for scripted deaths or combat modes that do not
    -- emit EndCombatSim. By the next player turn, no unit remains in combat.
    UnaCourt_ProcessPendingCollapses(true)

    local player = Players[playerID]
    if not UnaCourt_IsPlayer(player) then return end
    UnaCourt_EnsureStartingTrentrouls(playerID)
    UnaCourt_EnforceCaps(player)
    UnaCourt_RefreshPlayer(playerID)
end

GameEvents.PlayerDoTurn.Add(UnaCourt_DoTurn)

if GameEvents.PlayerCanTrain ~= nil then
    GameEvents.PlayerCanTrain.Add(function(playerID, unitType)
        local player = Players[playerID]
        if not UnaCourt_IsPlayer(player) then return true end
        if unitType == UNIT_TRENT then return false end
        if unitType == UNIT_BUDDY and UnaCourt_CountUnits(player, UNIT_BUDDY) >= 1 then return false end
        return true
    end)
end

if GameEvents.TeamSetEra ~= nil then
    GameEvents.TeamSetEra.Add(function(teamID)
        for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
            local player = Players[playerID]
            if UnaCourt_IsPlayer(player) and player:GetTeam() == teamID then
                UnaCourt_RefreshPlayer(playerID)
            end
        end
    end)
end

if GameEvents.UnitSetXY ~= nil then
    GameEvents.UnitSetXY.Add(function(playerID, unitID)
        local player = Players[playerID]
        if not UnaCourt_IsPlayer(player) then return end
        local unit = player:GetUnitByID(unitID)
        if unit ~= nil and (unit:GetUnitType() == UNIT_TRENT or unit:GetUnitType() == UNIT_BUDDY) then
            UnaCourt_RefreshPlayer(playerID)
        end
    end)
end

if Events.SerialEventCityCreated ~= nil then
    Events.SerialEventCityCreated.Add(function(_, playerID)
        if playerID ~= nil then UnaCourt_RefreshPlayer(playerID) end
    end)
end

if GameEvents.CityCaptureComplete ~= nil then
    GameEvents.CityCaptureComplete.Add(function(_, _, _, _, newPlayerID)
        if newPlayerID ~= nil then UnaCourt_RefreshPlayer(newPlayerID) end
    end)
end

if GameEvents.UnitPrekill ~= nil then
    GameEvents.UnitPrekill.Add(function(killedPlayerID, _, killedUnitType, _, _, _, killerPlayerID)
        if killedUnitType == UNIT_TRENT then
            local player = Players[killedPlayerID]
            if UnaCourt_IsPlayer(player) and not collapsing[killedPlayerID] then
                -- Never destroy the empire from UnitPrekill itself. During a
                -- combat kill, the DLL still marks Trentrouls and his opponent
                -- as in combat; recursively killing units here triggers a
                -- CvUnit assertion. EndCombatSim releases the queue safely.
                pendingCollapses[killedPlayerID] = {
                    killerPlayerID = killerPlayerID,
                    ready = false
                }
                print("Una Court queued post-combat collapse for player " .. tostring(killedPlayerID))
            end
        end
    end)
end

if Events.EndCombatSim ~= nil then
    Events.EndCombatSim.Add(function()
        for _, pending in pairs(pendingCollapses) do
            pending.ready = true
        end
    end)
end

-- EndCombatSim is raised while the UI finishes the combat presentation. Wait
-- one update tick before mutating city and unit ownership.
if ContextPtr ~= nil and ContextPtr.SetUpdate ~= nil then
    ContextPtr:SetUpdate(function()
        UnaCourt_ProcessPendingCollapses(false)
    end)
end

for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
    UnaCourt_EnsureStartingTrentrouls(playerID)
    UnaCourt_RefreshPlayer(playerID)
end

print("Una Court core initialized")
