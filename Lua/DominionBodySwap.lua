-- ===========================================================================
-- The Dominion of Una Court - Body Swap
-- ===========================================================================

print("DominionBodySwap.lua loaded")

local SAVE = Modding.OpenSaveData()
local CIV_DOMINION = GameInfoTypes.CIVILIZATION_DOMINION_UNA_COURT
local UNIT_TRENT = GameInfoTypes.UNIT_DOMINION_TRENTROULS
local UNIT_FREEHOLD_TRENT = GameInfoTypes.UNIT_UNA_TRENTROULS
local UNIT_BUDDY = GameInfoTypes.UNIT_UNA_BUDDY
local PROMO_BORROWED = GameInfoTypes.PROMOTION_DOMINION_BORROWED_BODY
local PROMO_ENEMY_TRENT = GameInfoTypes.PROMOTION_DOMINION_ENEMY_IN_TRENT
local PROMO_READY = GameInfoTypes.PROMOTION_DOMINION_SWAP_READY
local PROMO_COOLDOWN = GameInfoTypes.PROMOTION_DOMINION_SWAP_COOLDOWN
local PROMO_IMMUNE = GameInfoTypes.PROMOTION_DOMINION_SWAP_IMMUNE
local DOMAIN_AIR = GameInfoTypes.DOMAIN_AIR
local activeTransfer = false
local pendingReturns = {}

local function Key(playerID, suffix)
    return "DOMINION_SWAP_" .. tostring(playerID) .. "_" .. suffix
end
local function GetNumber(playerID, suffix)
    return tonumber(SAVE.GetValue(Key(playerID, suffix))) or 0
end
local function SetNumber(playerID, suffix, value)
    SAVE.SetValue(Key(playerID, suffix), tonumber(value) or 0)
end
local function IsDominion(player)
    return player ~= nil and player:IsAlive() and CIV_DOMINION ~= nil
        and player:GetCivilizationType() == CIV_DOMINION
end

function Dominion_IsBodySwapTransfer()
    return activeTransfer
end

local function GameSpeedValues()
    local info = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    local speedType = info ~= nil and info.Type or "GAMESPEED_STANDARD"
    if speedType == "GAMESPEED_QUICK" then return 8, 1 end
    if speedType == "GAMESPEED_EPIC" then return 18, 3 end
    if speedType == "GAMESPEED_MARATHON" then return 36, 6 end
    return 12, 2
end

local function GoldenAgeReward(player)
    local base = math.max(5, math.min(12, player:GetCurrentEra() + 5))
    local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    local percent = speed ~= nil and tonumber(speed.GoldenAgePercent) or 100
    return math.max(1, math.floor((base * percent / 100) + 0.5))
end

local function UnitInfo(unit)
    return unit ~= nil and GameInfo.Units[unit:GetUnitType()] or nil
end

function Dominion_IsEligibleBodySwapTarget(playerID, trent, target)
    if trent == nil or target == nil or target:IsDead() or target:GetOwner() == playerID then return false end
    local unitType = target:GetUnitType()
    if unitType == UNIT_TRENT or unitType == UNIT_FREEHOLD_TRENT or unitType == UNIT_BUDDY then return false end
    if target:GetDomainType() == DOMAIN_AIR then return false end
    if PROMO_BORROWED ~= nil and target:IsHasPromotion(PROMO_BORROWED) then return false end
    if PROMO_ENEMY_TRENT ~= nil and target:IsHasPromotion(PROMO_ENEMY_TRENT) then return false end
    if PROMO_IMMUNE ~= nil and target:IsHasPromotion(PROMO_IMMUNE) then return false end

    local info = UnitInfo(target)
    if info == nil or tonumber(info.Trade or 0) ~= 0 or tonumber(info.NukeDamageLevel or 0) > 0
        or tonumber(info.Suicide or 0) ~= 0 or info.Special == "SPECIALUNIT_MISSILE" then return false end
    local targetPlot, trentPlot = target:GetPlot(), trent:GetPlot()
    if targetPlot == nil or trentPlot == nil or targetPlot:IsCity() then return false end
    if Map.PlotDistance(trentPlot:GetX(), trentPlot:GetY(), targetPlot:GetX(), targetPlot:GetY()) > 2 then return false end
    local player, owner = Players[playerID], Players[target:GetOwner()]
    return player ~= nil and owner ~= nil and owner:IsAlive() and not owner:IsBarbarian()
        and Teams[player:GetTeam()]:IsAtWar(owner:GetTeam())
end

local function Capture(unit)
    local state = {
        unitType = unit:GetUnitType(), unitAI = unit:GetUnitAIType(),
        x = unit:GetX(), y = unit:GetY(), damage = unit:GetDamage(),
        experience = unit:GetExperience(), moves = unit:GetMoves(), promotions = {}
    }
    if unit.HasName ~= nil and unit:HasName() then state.name = unit:GetNameNoDesc() end
    for promotion in GameInfo.UnitPromotions() do
        if unit:IsHasPromotion(promotion.ID) then state.promotions[#state.promotions + 1] = promotion.ID end
    end
    return state
end

local function Create(owner, state, role)
    local unit = owner:InitUnit(state.unitType, state.x, state.y, state.unitAI)
    if unit == nil then return nil end
    if state.damage ~= nil then unit:SetDamage(state.damage) end
    if state.experience ~= nil and state.experience > 0 then unit:ChangeExperience(state.experience) end
    if state.name ~= nil and state.name ~= "" then unit:SetName(state.name) end
    for _, promotionID in ipairs(state.promotions or {}) do
        if promotionID ~= PROMO_BORROWED and promotionID ~= PROMO_ENEMY_TRENT
            and promotionID ~= PROMO_READY and promotionID ~= PROMO_COOLDOWN then
            unit:SetHasPromotion(promotionID, true)
        end
    end
    if PROMO_BORROWED ~= nil then unit:SetHasPromotion(PROMO_BORROWED, role == "borrowed") end
    if PROMO_ENEMY_TRENT ~= nil then unit:SetHasPromotion(PROMO_ENEMY_TRENT, role == "enemy_trent") end
    if state.moves ~= nil and unit.SetMoves ~= nil then unit:SetMoves(state.moves) end
    if unit.JumpToNearestValidPlot ~= nil then pcall(function() unit:JumpToNearestValidPlot() end) end
    return unit
end

local function ClearActive(playerID)
    SetNumber(playerID, "ACTIVE", 0)
    SetNumber(playerID, "BORROWED_ID", -1)
    SetNumber(playerID, "ORIGINAL_OWNER", -1)
    SetNumber(playerID, "TRENT_OWNER", -1)
    SetNumber(playerID, "TRENT_UNIT_ID", -1)
    SetNumber(playerID, "TURNS", 0)
end

local function UpdateReadyPromotion(playerID)
    local player = Players[playerID]
    if not IsDominion(player) then return end
    local trent = Dominion_FindOwnedTrent ~= nil and Dominion_FindOwnedTrent(player) or nil
    if trent == nil then return end
    local ready = GetNumber(playerID, "ACTIVE") == 0 and GetNumber(playerID, "COOLDOWN") <= 0
    if PROMO_READY ~= nil then trent:SetHasPromotion(PROMO_READY, ready) end
    if PROMO_COOLDOWN ~= nil then trent:SetHasPromotion(PROMO_COOLDOWN, not ready) end
end

local function NotifyReady(player)
    if player == nil or not player:IsHuman() then return end
    local trent = Dominion_FindOwnedTrent ~= nil and Dominion_FindOwnedTrent(player) or nil
    local x, y = trent ~= nil and trent:GetX() or -1, trent ~= nil and trent:GetY() or -1
    local title, message = "Body Swap Ready", "Trentrouls may exchange bodies with an eligible enemy within two tiles."
    if player.AddNotification ~= nil and NotificationTypes ~= nil and NotificationTypes.NOTIFICATION_GENERIC ~= nil then
        local ok = pcall(function() player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, message, title, x, y) end)
        if ok then return end
    end
    if Events.GameplayAlertMessage ~= nil then Events.GameplayAlertMessage(title .. ": " .. message) end
end

function Dominion_StartBodySwap(playerID, trentID, targetOwnerID, targetUnitID)
    local player, targetOwner = Players[playerID], Players[targetOwnerID]
    if not IsDominion(player) or targetOwner == nil or GetNumber(playerID, "ACTIVE") == 1
        or GetNumber(playerID, "COOLDOWN") > 0 then return false end
    local trent, target = player:GetUnitByID(trentID), targetOwner:GetUnitByID(targetUnitID)
    if trent == nil or trent:GetUnitType() ~= UNIT_TRENT
        or not Dominion_IsEligibleBodySwapTarget(playerID, trent, target) then return false end

    local trentState, targetState = Capture(trent), Capture(target)
    local cooldown, duration = GameSpeedValues()
    activeTransfer = true
    target:Kill(false, playerID)
    trent:Kill(false, targetOwnerID)
    local borrowed = Create(player, targetState, "borrowed")
    local enemyTrent = Create(targetOwner, trentState, "enemy_trent")
    activeTransfer = false

    if borrowed == nil or enemyTrent == nil then
        activeTransfer = true
        if borrowed ~= nil then borrowed:Kill(false, -1) end
        if enemyTrent ~= nil then enemyTrent:Kill(false, -1) end
        if Dominion_FindOwnedTrent ~= nil and Dominion_FindOwnedTrent(player) == nil then Create(player, trentState, "trent") end
        if targetOwner:IsAlive() then Create(targetOwner, targetState, "target") end
        activeTransfer = false
        return false
    end

    if enemyTrent.SetMoves ~= nil then enemyTrent:SetMoves(0) end
    SetNumber(playerID, "ACTIVE", 1)
    SetNumber(playerID, "BORROWED_ID", borrowed:GetID())
    SetNumber(playerID, "ORIGINAL_OWNER", targetOwnerID)
    SetNumber(playerID, "TRENT_OWNER", targetOwnerID)
    SetNumber(playerID, "TRENT_UNIT_ID", enemyTrent:GetID())
    SetNumber(playerID, "TURNS", duration)
    SetNumber(playerID, "COOLDOWN", cooldown)
    local reward = GoldenAgeReward(player)
    player:ChangeGoldenAgeProgressMeter(reward)
    if Dominion_RefreshPlayer ~= nil then Dominion_RefreshPlayer(playerID) end
    if Events.GameplayAlertMessage ~= nil then
        Events.GameplayAlertMessage("Body Swap active for " .. tostring(duration) .. " turns. +" .. tostring(reward) .. " Golden Age Points.")
    end
    if LuaEvents.DominionBodySwapChanged ~= nil then LuaEvents.DominionBodySwapChanged(playerID) end
    return true
end

function Dominion_EndBodySwap(playerID, reason, restoreTrent)
    local player = Players[playerID]
    if player == nil or GetNumber(playerID, "ACTIVE") ~= 1 then return false end
    if restoreTrent == nil then restoreTrent = true end
    local originalOwnerID = GetNumber(playerID, "ORIGINAL_OWNER")
    local originalOwner = Players[originalOwnerID]
    local borrowed = player:GetUnitByID(GetNumber(playerID, "BORROWED_ID"))
    local trentOwner = Players[GetNumber(playerID, "TRENT_OWNER")]
    local enemyTrent = trentOwner ~= nil and trentOwner:GetUnitByID(GetNumber(playerID, "TRENT_UNIT_ID")) or nil

    activeTransfer = true
    if borrowed ~= nil then
        local state = Capture(borrowed)
        borrowed:Kill(false, originalOwnerID)
        if originalOwner ~= nil and originalOwner:IsAlive() then
            local returned = Create(originalOwner, state, "target")
            if returned ~= nil and returned.SetMoves ~= nil then returned:SetMoves(0) end
        end
    end
    if enemyTrent ~= nil then
        local state = Capture(enemyTrent)
        enemyTrent:Kill(false, playerID)
        if restoreTrent and player:IsAlive() then
            local returned = Create(player, state, "trent")
            if returned ~= nil and returned.SetMoves ~= nil then returned:SetMoves(0) end
        end
    end
    activeTransfer = false
    ClearActive(playerID)
    UpdateReadyPromotion(playerID)
    if Dominion_RefreshPlayer ~= nil then Dominion_RefreshPlayer(playerID) end
    if reason ~= nil and Events.GameplayAlertMessage ~= nil then Events.GameplayAlertMessage("Body Swap ended: " .. tostring(reason) .. ".") end
    if LuaEvents.DominionBodySwapChanged ~= nil then LuaEvents.DominionBodySwapChanged(playerID) end
    return true
end

function Dominion_ProcessPendingReturns(force)
    local ready = {}
    for playerID, pending in pairs(pendingReturns) do
        if force or pending.ready then ready[#ready + 1] = playerID end
    end
    for _, playerID in ipairs(ready) do
        pendingReturns[playerID] = nil
        Dominion_EndBodySwap(playerID, "the borrowed body was lost", true)
    end
end

local function FindBestTarget(playerID, trent)
    if trent == nil or trent:GetPlot() == nil then return nil end
    local best, bestScore = nil, -1
    for dx = -2, 2 do
        for dy = -2, 2 do
            local plot = Map.PlotXYWithRangeCheck(trent:GetX(), trent:GetY(), dx, dy, 2)
            if plot ~= nil then
                for index = 0, plot:GetNumUnits() - 1 do
                    local unit = plot:GetUnit(index)
                    if Dominion_IsEligibleBodySwapTarget(playerID, trent, unit) then
                        local info = UnitInfo(unit)
                        local score = math.max(unit:GetBaseCombatStrength(), unit:GetBaseRangedCombatStrength())
                        if info ~= nil and tonumber(info.Found or 0) ~= 0 then score = score + 80 end
                        if info ~= nil and info.Special == "SPECIALUNIT_PEOPLE" then score = score + 70 end
                        if score > bestScore then best, bestScore = unit, score end
                    end
                end
            end
        end
    end
    return best
end

local function DoTurn(playerID)
    Dominion_ProcessPendingReturns(true)
    local player = Players[playerID]
    if player == nil then return end

    -- The enemy may move Trentrouls one tile or make one melee attack, never both.
    for dominionID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
        if GetNumber(dominionID, "ACTIVE") == 1 and GetNumber(dominionID, "TRENT_OWNER") == playerID then
            local trent = player:GetUnitByID(GetNumber(dominionID, "TRENT_UNIT_ID"))
            if trent ~= nil and trent.SetMoves ~= nil then trent:SetMoves(GameDefines.MOVE_DENOMINATOR or 60) end
        end
    end

    if not IsDominion(player) then return end
    local cooldown = GetNumber(playerID, "COOLDOWN")
    if cooldown > 0 then
        cooldown = cooldown - 1
        SetNumber(playerID, "COOLDOWN", cooldown)
        if cooldown <= 0 then NotifyReady(player) end
    end
    if GetNumber(playerID, "ACTIVE") == 1 then
        local owner = Players[GetNumber(playerID, "ORIGINAL_OWNER")]
        local trentOwner = Players[GetNumber(playerID, "TRENT_OWNER")]
        local enemyTrent = trentOwner ~= nil and trentOwner:GetUnitByID(GetNumber(playerID, "TRENT_UNIT_ID")) or nil
        if enemyTrent == nil then
            -- Core's deferred collapse handler owns this case.
        elseif owner ~= nil and owner:IsAlive() and not Teams[player:GetTeam()]:IsAtWar(owner:GetTeam()) then
            Dominion_EndBodySwap(playerID, "peace was signed", true)
        else
            local turns = GetNumber(playerID, "TURNS") - 1
            SetNumber(playerID, "TURNS", turns)
            if turns <= 0 then Dominion_EndBodySwap(playerID, "the duration expired", true) end
        end
    elseif not player:IsHuman() and GetNumber(playerID, "COOLDOWN") <= 0 then
        local trent = Dominion_FindOwnedTrent ~= nil and Dominion_FindOwnedTrent(player) or nil
        local target = FindBestTarget(playerID, trent)
        if trent ~= nil and target ~= nil then Dominion_StartBodySwap(playerID, trent:GetID(), target:GetOwner(), target:GetID()) end
    end
    UpdateReadyPromotion(playerID)
end
GameEvents.PlayerDoTurn.Add(DoTurn)

if GameEvents.UnitSetXY ~= nil then
    GameEvents.UnitSetXY.Add(function(playerID, unitID)
        for dominionID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
            if GetNumber(dominionID, "ACTIVE") == 1 and GetNumber(dominionID, "TRENT_OWNER") == playerID
                and GetNumber(dominionID, "TRENT_UNIT_ID") == unitID then
                local unit = Players[playerID]:GetUnitByID(unitID)
                if unit ~= nil and unit.SetMoves ~= nil then unit:SetMoves(0) end
                break
            end
        end
    end)
end

local function IsProtectedBody(playerID, unitID)
    local unit = Players[playerID] ~= nil and Players[playerID]:GetUnitByID(unitID) or nil
    return unit ~= nil and (unit:GetUnitType() == UNIT_TRENT
        or (PROMO_BORROWED ~= nil and unit:IsHasPromotion(PROMO_BORROWED))
        or (PROMO_ENEMY_TRENT ~= nil and unit:IsHasPromotion(PROMO_ENEMY_TRENT)))
end

if GameEvents.PlayerCanGiftUnit ~= nil then
    GameEvents.PlayerCanGiftUnit.Add(function(playerID, _, unitID)
        if IsProtectedBody(playerID, unitID) then return false end
        return true
    end)
end

-- Community Patch command vetoes prevent either temporary body from being
-- disbanded, sold, gifted, or upgraded through the ordinary unit UI.
if GameEvents.PlayerCanDoCommand ~= nil then
    GameEvents.PlayerCanDoCommand.Add(function(playerID, unitID, commandID)
        if not IsProtectedBody(playerID, unitID) then return true end
        if CommandTypes ~= nil and (commandID == CommandTypes.COMMAND_DELETE
            or commandID == CommandTypes.COMMAND_UPGRADE
            or commandID == CommandTypes.COMMAND_GIFT) then return false end
        return true
    end)
end

if GameEvents.CanHaveAnyUpgrade ~= nil then
    GameEvents.CanHaveAnyUpgrade.Add(function(playerID, unitID)
        return not IsProtectedBody(playerID, unitID)
    end)
end

if GameEvents.UnitPrekill ~= nil then
    GameEvents.UnitPrekill.Add(function(killedPlayerID, killedUnitID)
        if activeTransfer then return end
        for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
            if GetNumber(playerID, "ACTIVE") == 1 and playerID == killedPlayerID
                and GetNumber(playerID, "BORROWED_ID") == killedUnitID then
                pendingReturns[playerID] = { ready = false }
                break
            end
        end
    end)
end
if Events.EndCombatSim ~= nil then
    Events.EndCombatSim.Add(function()
        for _, pending in pairs(pendingReturns) do pending.ready = true end
    end)
end

if LuaEvents.DominionBodySwapRequest ~= nil then
    LuaEvents.DominionBodySwapRequest.Add(function(playerID, trentID, targetOwnerID, targetUnitID)
        Dominion_StartBodySwap(playerID, trentID, targetOwnerID, targetUnitID)
    end)
end

for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do UpdateReadyPromotion(playerID) end
print("Dominion Body Swap initialized")
