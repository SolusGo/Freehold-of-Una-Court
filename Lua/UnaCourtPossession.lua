-- ===========================================================================
-- The Freehold of Una Court - Body Possession
-- One active target per Una Court player. State is persisted with Modding data.
-- ===========================================================================

print("UnaCourtPossession.lua loaded")

local SAVE = Modding.OpenSaveData()
local CIV_UNA = GameInfoTypes.CIVILIZATION_UNA_COURT
local UNIT_TRENT = GameInfoTypes.UNIT_UNA_TRENTROULS
local UNIT_BUDDY = GameInfoTypes.UNIT_UNA_BUDDY
local PROMO_POSSESSED = GameInfoTypes.PROMOTION_UNA_POSSESSED
local PROMO_READY = GameInfoTypes.PROMOTION_UNA_POSSESSION_READY
local PROMO_COOLDOWN = GameInfoTypes.PROMOTION_UNA_POSSESSION_COOLDOWN
local DOMAIN_AIR = GameInfoTypes.DOMAIN_AIR
local activeTransfer = false

local function Key(playerID, suffix)
    return "UNA_POSSESSION_" .. tostring(playerID) .. "_" .. suffix
end

local function GetNumber(playerID, suffix)
    return tonumber(SAVE.GetValue(Key(playerID, suffix))) or 0
end

local function SetNumber(playerID, suffix, value)
    SAVE.SetValue(Key(playerID, suffix), tonumber(value) or 0)
end
local function ClearSuspended(playerID)
    SetNumber(playerID, "SAVE_SUSPENDED", 0)
    SetNumber(playerID, "SAVE_TARGET_OWNER", -1)
    SetNumber(playerID, "SAVE_TARGET_ID", -1)
    SetNumber(playerID, "SAVE_TURNS", 0)
    SetNumber(playerID, "SAVE_COOLDOWN", 0)
end

local function IsUnaPlayer(player)
    return player ~= nil and player:IsAlive() and CIV_UNA ~= nil and player:GetCivilizationType() == CIV_UNA
end

local function FindTrent(player)
    if UnaCourt_FindTrentrouls ~= nil then return UnaCourt_FindTrentrouls(player) end
    for unit in player:Units() do
        if unit:GetUnitType() == UNIT_TRENT then return unit end
    end
    return nil
end

local function GameSpeedValues()
    local info = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    local speedType = info ~= nil and info.Type or "GAMESPEED_STANDARD"
    if speedType == "GAMESPEED_QUICK" then return 20, 2 end
    if speedType == "GAMESPEED_EPIC" then return 45, 5 end
    if speedType == "GAMESPEED_MARATHON" then return 90, 9 end
    return 30, 3
end

local function UnitIsTrade(unit)
    local info = GameInfo.Units[unit:GetUnitType()]
    return info ~= nil and tonumber(info.Trade or 0) ~= 0
end

function UnaCourt_IsEligiblePossessionTarget(playerID, trent, target)
    if trent == nil or target == nil or target:IsDead() then return false end
    if target:GetOwner() == playerID then return false end
    if target:GetUnitType() == UNIT_TRENT or target:GetUnitType() == UNIT_BUDDY then return false end
    if target:GetDomainType() == DOMAIN_AIR or UnitIsTrade(target) then return false end
    if PROMO_POSSESSED ~= nil and target:IsHasPromotion(PROMO_POSSESSED) then return false end

    local targetPlot = target:GetPlot()
    local trentPlot = trent:GetPlot()
    if targetPlot == nil or trentPlot == nil or targetPlot:IsCity() then return false end
    if Map.PlotDistance(trentPlot:GetX(), trentPlot:GetY(), targetPlot:GetX(), targetPlot:GetY()) > 2 then return false end

    local owner = Players[target:GetOwner()]
    if owner == nil or not owner:IsAlive() or owner:IsBarbarian() then return false end
    return Teams[Players[playerID]:GetTeam()]:IsAtWar(owner:GetTeam())
end

local function CaptureUnitState(unit)
    local state = {
        unitType = unit:GetUnitType(),
        unitAI = unit:GetUnitAIType(),
        x = unit:GetX(), y = unit:GetY(),
        damage = unit:GetDamage(),
        experience = unit:GetExperience(),
        level = unit:GetLevel(),
        moves = unit:GetMoves(),
        promotions = {}
    }

    if unit.HasName ~= nil and unit:HasName() then state.name = unit:GetNameNoDesc() end
    for promotion in GameInfo.UnitPromotions() do
        if unit:IsHasPromotion(promotion.ID) then state.promotions[#state.promotions + 1] = promotion.ID end
    end
    return state
end

local function RestoreUnitState(unit, state, isPossessed)
    if unit == nil then return end
    if state.damage ~= nil then unit:SetDamage(state.damage) end
    if state.experience ~= nil and state.experience > 0 then unit:ChangeExperience(state.experience) end
    if state.name ~= nil and state.name ~= "" then unit:SetName(state.name) end

    for _, promotionID in ipairs(state.promotions or {}) do
        if promotionID ~= PROMO_POSSESSED then unit:SetHasPromotion(promotionID, true) end
    end
    if PROMO_POSSESSED ~= nil then unit:SetHasPromotion(PROMO_POSSESSED, isPossessed == true) end
    if state.moves ~= nil and unit.SetMoves ~= nil then unit:SetMoves(state.moves) end
end

local function CreateTransferredUnit(newOwner, state, possessed)
    local newUnit = newOwner:InitUnit(state.unitType, state.x, state.y, state.unitAI)
    if newUnit == nil then return nil end
    RestoreUnitState(newUnit, state, possessed)
    if newUnit.JumpToNearestValidPlot ~= nil then pcall(function() newUnit:JumpToNearestValidPlot() end) end
    return newUnit
end

local function ClearActive(playerID)
    SetNumber(playerID, "ACTIVE", 0)
    SetNumber(playerID, "UNIT_ID", -1)
    SetNumber(playerID, "ORIGINAL_OWNER", -1)
    SetNumber(playerID, "TURNS", 0)
end

local function UpdateTrentPromotion(playerID)
    local player = Players[playerID]
    if not IsUnaPlayer(player) then return end
    local trent = FindTrent(player)
    if trent == nil then return end

    local ready = GetNumber(playerID, "ACTIVE") == 0 and GetNumber(playerID, "COOLDOWN") <= 0
    if PROMO_READY ~= nil then trent:SetHasPromotion(PROMO_READY, ready) end
    if PROMO_COOLDOWN ~= nil then trent:SetHasPromotion(PROMO_COOLDOWN, not ready) end
end

local function NotifyPossessionReady(player)
    if player == nil or not player:IsHuman() then return end

    local trent = FindTrent(player)
    local x = trent ~= nil and trent:GetX() or -1
    local y = trent ~= nil and trent:GetY() or -1
    local title = "Body Possession Ready"
    local message = "Trentrouls may possess another eligible enemy unit within two tiles."

    if player.AddNotification ~= nil
        and NotificationTypes ~= nil
        and NotificationTypes.NOTIFICATION_GENERIC ~= nil then
        local ok, err = pcall(function()
            player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, message, title, x, y)
        end)
        if ok then return end
        print("Una Court ready notification failed: " .. tostring(err))
    end

    if Events.GameplayAlertMessage ~= nil then
        Events.GameplayAlertMessage(title .. ": " .. message)
    end
end

function UnaCourt_GetPossessionStatus(playerID)
    return {
        active = GetNumber(playerID, "ACTIVE") == 1,
        unitID = GetNumber(playerID, "UNIT_ID"),
        originalOwner = GetNumber(playerID, "ORIGINAL_OWNER"),
        turns = GetNumber(playerID, "TURNS"),
        cooldown = GetNumber(playerID, "COOLDOWN")
    }
end

function UnaCourt_StartPossession(playerID, trentID, targetOwnerID, targetUnitID)
    local player = Players[playerID]
    local targetOwner = Players[targetOwnerID]
    if not IsUnaPlayer(player) or targetOwner == nil then return false end
    if GetNumber(playerID, "ACTIVE") == 1 or GetNumber(playerID, "COOLDOWN") > 0 then return false end

    local trent = player:GetUnitByID(trentID)
    local target = targetOwner:GetUnitByID(targetUnitID)
    if trent == nil or trent:GetUnitType() ~= UNIT_TRENT then return false end
    if not UnaCourt_IsEligiblePossessionTarget(playerID, trent, target) then return false end

    local state = CaptureUnitState(target)
    local cooldown, duration = GameSpeedValues()

    activeTransfer = true
    target:Kill(false, playerID)
    local possessed = CreateTransferredUnit(player, state, true)
    activeTransfer = false
    if possessed == nil then return false end

    ClearSuspended(playerID)
    SetNumber(playerID, "ACTIVE", 1)
    SetNumber(playerID, "UNIT_ID", possessed:GetID())
    SetNumber(playerID, "ORIGINAL_OWNER", targetOwnerID)
    SetNumber(playerID, "TURNS", duration)
    SetNumber(playerID, "COOLDOWN", cooldown)
    UpdateTrentPromotion(playerID)

    if Events.GameplayAlertMessage ~= nil then
        Events.GameplayAlertMessage("Trentrouls has possessed " .. possessed:GetName() .. " for " .. tostring(duration) .. " turns.")
    end
    if LuaEvents.UnaCourtPossessionChanged ~= nil then LuaEvents.UnaCourtPossessionChanged(playerID) end
    return true
end

function UnaCourt_EndPossession(playerID, reason, preserveMoves)
    local player = Players[playerID]
    if player == nil or GetNumber(playerID, "ACTIVE") ~= 1 then return false end

    local unitID = GetNumber(playerID, "UNIT_ID")
    local originalOwnerID = GetNumber(playerID, "ORIGINAL_OWNER")
    local possessed = player:GetUnitByID(unitID)
    local originalOwner = Players[originalOwnerID]
    local returned = nil

    if possessed ~= nil then
        if originalOwner ~= nil and originalOwner:IsAlive() then
            local state = CaptureUnitState(possessed)
            activeTransfer = true
            possessed:Kill(false, preserveMoves and -1 or originalOwnerID)
            returned = CreateTransferredUnit(originalOwner, state, false)
            activeTransfer = false
            if not preserveMoves and returned ~= nil and returned.SetMoves ~= nil then returned:SetMoves(0) end
        else
            if PROMO_POSSESSED ~= nil then possessed:SetHasPromotion(PROMO_POSSESSED, false) end
        end
    end

    ClearActive(playerID)
    UpdateTrentPromotion(playerID)
    if reason ~= nil and Events.GameplayAlertMessage ~= nil then
        Events.GameplayAlertMessage("Body Possession ended: " .. tostring(reason) .. ".")
    end
    if LuaEvents.UnaCourtPossessionChanged ~= nil then LuaEvents.UnaCourtPossessionChanged(playerID) end
    return true, returned ~= nil and returned:GetID() or -1
end

local function ResumeSuspendedPossession(playerID)
    if GetNumber(playerID, "SAVE_SUSPENDED") ~= 1 then return false end
    local player = Players[playerID]
    local targetOwnerID = GetNumber(playerID, "SAVE_TARGET_OWNER")
    local targetOwner = Players[targetOwnerID]
    local target = targetOwner ~= nil and targetOwner:GetUnitByID(GetNumber(playerID, "SAVE_TARGET_ID")) or nil
    if not IsUnaPlayer(player) or targetOwner == nil or not targetOwner:IsAlive() or target == nil then
        print("Una Court could not restore the save-suspended possession; leaving ownership normalized")
        ClearSuspended(playerID)
        return false
    end

    local state = CaptureUnitState(target)
    activeTransfer = true
    target:Kill(false, -1)
    local possessed = CreateTransferredUnit(player, state, true)
    activeTransfer = false
    if possessed == nil then
        activeTransfer = true
        CreateTransferredUnit(targetOwner, state, false)
        activeTransfer = false
        ClearSuspended(playerID)
        print("Una Court possession restore failed safely; ordinary ownership was retained")
        return false
    end

    SetNumber(playerID, "ACTIVE", 1)
    SetNumber(playerID, "UNIT_ID", possessed:GetID())
    SetNumber(playerID, "ORIGINAL_OWNER", targetOwnerID)
    SetNumber(playerID, "TURNS", GetNumber(playerID, "SAVE_TURNS"))
    SetNumber(playerID, "COOLDOWN", GetNumber(playerID, "SAVE_COOLDOWN"))
    ClearSuspended(playerID)
    UpdateTrentPromotion(playerID)
    if LuaEvents.UnaCourtPossessionChanged ~= nil then LuaEvents.UnaCourtPossessionChanged(playerID) end
    print("Una Court save-suspended possession restored for player " .. tostring(playerID))
    return true
end

local function SuspendPossessionForSave(playerID)
    if GetNumber(playerID, "ACTIVE") ~= 1 then return false end
    local targetOwnerID = GetNumber(playerID, "ORIGINAL_OWNER")
    local turns = GetNumber(playerID, "TURNS")
    local cooldown = GetNumber(playerID, "COOLDOWN")
    local ended, targetID = UnaCourt_EndPossession(playerID, nil, true)
    if not ended or targetID == nil or targetID < 0 then
        ClearSuspended(playerID)
        print("Una Court possession could not be suspended completely; ownership remains normalized")
        return false
    end

    SetNumber(playerID, "SAVE_TARGET_OWNER", targetOwnerID)
    SetNumber(playerID, "SAVE_TARGET_ID", targetID)
    SetNumber(playerID, "SAVE_TURNS", turns)
    SetNumber(playerID, "SAVE_COOLDOWN", cooldown)
    SetNumber(playerID, "SAVE_SUSPENDED", 1)
    return true
end

local function FindBestAITarget(playerID, trent)
    local bestTarget, bestScore = nil, -1
    local trentPlot = trent:GetPlot()
    if trentPlot == nil then return nil end

    for dx = -2, 2 do
        for dy = -2, 2 do
            local plot = Map.PlotXYWithRangeCheck(trentPlot:GetX(), trentPlot:GetY(), dx, dy, 2)
            if plot ~= nil then
                for index = 0, plot:GetNumUnits() - 1 do
                    local target = plot:GetUnit(index)
                    if UnaCourt_IsEligiblePossessionTarget(playerID, trent, target) then
                        local info = GameInfo.Units[target:GetUnitType()]
                        local score = math.max(target:GetBaseCombatStrength(), target:GetBaseRangedCombatStrength())
                        if info ~= nil then
                            if tonumber(info.Found or 0) ~= 0 then score = score + 80 end
                            if info.Special == "SPECIALUNIT_PEOPLE" then score = score + 70 end
                            if tonumber(info.WorkRate or 0) > 0 then score = score + 15 end
                        end
                        if score > bestScore then bestTarget, bestScore = target, score end
                    end
                end
            end
        end
    end
    return bestTarget
end

local function PossessionDoTurn(playerID)
    local player = Players[playerID]
    if not IsUnaPlayer(player) then return end

    local cooldown = GetNumber(playerID, "COOLDOWN")
    if cooldown > 0 then
        local remainingCooldown = cooldown - 1
        SetNumber(playerID, "COOLDOWN", remainingCooldown)
        if remainingCooldown <= 0 then
            NotifyPossessionReady(player)
            if LuaEvents.UnaCourtPossessionChanged ~= nil then
                LuaEvents.UnaCourtPossessionChanged(playerID)
            end
        end
    end

    if GetNumber(playerID, "ACTIVE") == 1 then
        local unitID = GetNumber(playerID, "UNIT_ID")
        local originalOwnerID = GetNumber(playerID, "ORIGINAL_OWNER")
        local unit = player:GetUnitByID(unitID)
        local originalOwner = Players[originalOwnerID]

        if unit == nil then
            ClearActive(playerID)
        elseif originalOwner ~= nil and originalOwner:IsAlive()
            and not Teams[player:GetTeam()]:IsAtWar(originalOwner:GetTeam()) then
            UnaCourt_EndPossession(playerID, "peace was signed")
        else
            local turns = GetNumber(playerID, "TURNS") - 1
            SetNumber(playerID, "TURNS", turns)
            if turns <= 0 then UnaCourt_EndPossession(playerID, "the duration expired") end
        end
    end

    if not player:IsHuman() and GetNumber(playerID, "ACTIVE") == 0 and GetNumber(playerID, "COOLDOWN") <= 0 then
        local trent = FindTrent(player)
        local target = FindBestAITarget(playerID, trent)
        if trent ~= nil and target ~= nil then
            UnaCourt_StartPossession(playerID, trent:GetID(), target:GetOwner(), target:GetID())
        end
    end

    UpdateTrentPromotion(playerID)
end

GameEvents.PlayerDoTurn.Add(PossessionDoTurn)

if GameEvents.UnitPrekill ~= nil then
    GameEvents.UnitPrekill.Add(function(killedPlayerID, killedUnitID, _, _, _, _, _)
        if activeTransfer then return end
        local player = Players[killedPlayerID]
        if IsUnaPlayer(player)
            and GetNumber(killedPlayerID, "ACTIVE") == 1
            and GetNumber(killedPlayerID, "UNIT_ID") == killedUnitID then
            ClearActive(killedPlayerID)
            UpdateTrentPromotion(killedPlayerID)
        end
    end)
end

if LuaEvents.UnaCourtPossessRequest ~= nil then
    LuaEvents.UnaCourtPossessRequest.Add(function(playerID, trentID, targetOwnerID, targetUnitID)
        UnaCourt_StartPossession(playerID, trentID, targetOwnerID, targetUnitID)
    end)
end

-- Save only conventional ownership, while recording enough state in Civ V's
-- embedded save database to rebuild possession after saving or loading.
if GameEvents.GameSave ~= nil then
    GameEvents.GameSave.Add(function()
        for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
            if GetNumber(playerID, "ACTIVE") == 1 then
                local suspended = SuspendPossessionForSave(playerID)
                print("Una Court pre-save possession suspension for player " .. tostring(playerID)
                    .. ": " .. tostring(suspended))
                if suspended and UnaCourt_QueueDeferredRestore ~= nil then
                    local restorePlayerID = playerID
                    UnaCourt_QueueDeferredRestore(function() ResumeSuspendedPossession(restorePlayerID) end)
                end
            end
        end
    end)
else
    print("Una Court warning: Community Patch GameSave hook is unavailable")
end

for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
    if GetNumber(playerID, "SAVE_SUSPENDED") == 1 and UnaCourt_QueueDeferredRestore ~= nil then
        local restorePlayerID = playerID
        UnaCourt_QueueDeferredRestore(function() ResumeSuspendedPossession(restorePlayerID) end)
    end
end
for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do UpdateTrentPromotion(playerID) end
print("Una Court Body Possession initialized")
