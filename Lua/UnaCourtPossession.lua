-- ===========================================================================
-- The Freehold of Una Court - Body Possession
-- One active target per Una Court player. State is persisted with Modding data.
-- ===========================================================================

print("UnaCourtPossession.lua loaded")

local SAVE = Modding.OpenSaveData()
local CIV_UNA = GameInfoTypes.CIVILIZATION_UNA_COURT
local UNIT_TRENT = GameInfoTypes.UNIT_UNA_TRENTROULS
local UNIT_DOMINION_TRENT = GameInfoTypes.UNIT_DOMINION_TRENTROULS
local UNIT_BUDDY = GameInfoTypes.UNIT_UNA_BUDDY
local PROMO_POSSESSED = GameInfoTypes.PROMOTION_UNA_POSSESSED
local PROMO_READY = GameInfoTypes.PROMOTION_UNA_POSSESSION_READY
local PROMO_COOLDOWN = GameInfoTypes.PROMOTION_UNA_POSSESSION_COOLDOWN
local DOMAIN_AIR = GameInfoTypes.DOMAIN_AIR
local activeTransfer = false

local function RunTransfer(label, callback)
    activeTransfer = true
    local ok, first, second = pcall(callback)
    activeTransfer = false
    if not ok then
        print("Una Court " .. tostring(label) .. " transfer failed: " .. tostring(first))
        return false, nil, nil
    end
    return true, first, second
end

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

local function UnitHasUnsafeTransferState(unit)
    local info = GameInfo.Units[unit:GetUnitType()]
    if info == nil then return true end
    if tonumber(info.Trade or 0) ~= 0 or tonumber(info.NukeDamageLevel or 0) > 0
        or tonumber(info.Suicide or 0) ~= 0 or info.Special == "SPECIALUNIT_MISSILE"
        or info.Special == "SPECIALUNIT_PEOPLE" or tonumber(info.ReligionSpreads or 0) > 0
        or tonumber(info.ReligiousStrength or 0) > 0 or tonumber(info.FoundReligion or 0) ~= 0
        or tonumber(info.RemoveHeresy or 0) ~= 0 then return true end

    if unit.IsCargo ~= nil then
        local ok, isCargo = pcall(function() return unit:IsCargo() end)
        if ok and isCargo then return true end
    end
    if unit.GetCargo ~= nil then
        local ok, cargo = pcall(function() return unit:GetCargo() end)
        if ok and (cargo == true or tonumber(cargo or 0) > 0) then return true end
    elseif unit.HasCargo ~= nil then
        local ok, hasCargo = pcall(function() return unit:HasCargo() end)
        if ok and hasCargo then return true end
    end
    return false
end

local function UnitWasRemoved(owner, unitID)
    if owner == nil or unitID == nil then return true end
    local unit = owner:GetUnitByID(unitID)
    if unit == nil then return true end
    if unit.IsDead ~= nil then
        local ok, dead = pcall(function() return unit:IsDead() end)
        if ok and dead then return true end
    end
    if unit.IsDelayedDeath ~= nil then
        local ok, delayed = pcall(function() return unit:IsDelayedDeath() end)
        if ok and delayed then return true end
    end
    return false
end

local function KillAndVerify(unit, killerPlayerID, label)
    local owner = Players[unit:GetOwner()]
    local unitID = unit:GetID()
    unit:Kill(false, killerPlayerID)
    if not UnitWasRemoved(owner, unitID) then
        error(tostring(label) .. ": original unit still exists after Kill")
    end
end

function UnaCourt_IsEligiblePossessionTarget(playerID, trent, target)
    if trent == nil or target == nil or target:IsDead() then return false end
    if target:GetOwner() == playerID then return false end
    if target:GetUnitType() == UNIT_TRENT or target:GetUnitType() == UNIT_DOMINION_TRENT
        or target:GetUnitType() == UNIT_BUDDY then return false end
    if target:GetDomainType() == DOMAIN_AIR or UnitHasUnsafeTransferState(target) then return false end
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
        direction = unit.GetFacingDirection ~= nil and unit:GetFacingDirection() or nil,
        embarked = unit.IsEmbarked ~= nil and unit:IsEmbarked() or false,
        fortifyTurns = unit.GetFortifyTurns ~= nil and unit:GetFortifyTurns() or nil,
        promotions = {}
    }

    if unit.HasName ~= nil and unit:HasName() then state.name = unit:GetNameNoDesc() end
    if unit.GetScriptData ~= nil then
        local ok, scriptData = pcall(function() return unit:GetScriptData() end)
        if ok then state.scriptData = scriptData end
    end
    for promotion in GameInfo.UnitPromotions() do
        if unit:IsHasPromotion(promotion.ID) then state.promotions[#state.promotions + 1] = promotion.ID end
    end
    return state
end

local function RestoreUnitState(unit, state, isPossessed)
    if unit == nil then return end
    if state.damage ~= nil then unit:SetDamage(state.damage) end
    if state.experience ~= nil and unit.SetExperience ~= nil then unit:SetExperience(state.experience)
    elseif state.experience ~= nil and state.experience > 0 then unit:ChangeExperience(state.experience) end
    if state.level ~= nil and unit.SetLevel ~= nil then unit:SetLevel(math.max(1, state.level)) end
    if state.name ~= nil and state.name ~= "" then unit:SetName(state.name) end
    if state.scriptData ~= nil and unit.SetScriptData ~= nil then
        pcall(function() unit:SetScriptData(state.scriptData) end)
    end

    for _, promotionID in ipairs(state.promotions or {}) do
        if promotionID ~= PROMO_POSSESSED then unit:SetHasPromotion(promotionID, true) end
    end
    if PROMO_POSSESSED ~= nil then unit:SetHasPromotion(PROMO_POSSESSED, isPossessed == true) end
    if state.moves ~= nil and unit.SetMoves ~= nil then unit:SetMoves(state.moves) end
    if state.fortifyTurns ~= nil and unit.SetFortifyTurns ~= nil then unit:SetFortifyTurns(state.fortifyTurns) end
    if state.embarked and unit.SetEmbarked ~= nil then pcall(function() unit:SetEmbarked(true) end) end
end

local function CreateTransferredUnit(newOwner, state, possessed)
    local newUnit = newOwner:InitUnit(state.unitType, state.x, state.y, state.unitAI, state.direction)
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

    local targetRemoved = false
    local transferOK, possessed = RunTransfer("activation", function()
        KillAndVerify(target, playerID, "activation")
        targetRemoved = true
        return CreateTransferredUnit(player, state, true)
    end)
    if not transferOK or possessed == nil then
        if targetRemoved and targetOwner:IsAlive() then
            RunTransfer("activation rollback", function()
                return CreateTransferredUnit(targetOwner, state, false)
            end)
        end
        return false
    end

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
            local removed = false
            local transferOK
            transferOK, returned = RunTransfer("return", function()
                KillAndVerify(possessed, preserveMoves and -1 or originalOwnerID, "return")
                removed = true
                return CreateTransferredUnit(originalOwner, state, false)
            end)
            if not transferOK or returned == nil then
                if not removed and not possessed:IsDead() then
                    -- The transfer failed before the tracked body was removed.
                    -- Keep the possession active so it can be retried safely.
                    UpdateTrentPromotion(playerID)
                    return false
                end
                local rollback = nil
                if removed then
                    _, rollback = RunTransfer("return rollback", function()
                        return CreateTransferredUnit(player, state, true)
                    end)
                end
                if rollback ~= nil then
                    SetNumber(playerID, "UNIT_ID", rollback:GetID())
                    UpdateTrentPromotion(playerID)
                    return false
                end
                ClearActive(playerID)
                UpdateTrentPromotion(playerID)
                return false
            end
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
    local targetRemoved = false
    local transferOK, possessed = RunTransfer("save restore", function()
        KillAndVerify(target, -1, "save restore")
        targetRemoved = true
        return CreateTransferredUnit(player, state, true)
    end)
    if not transferOK or possessed == nil then
        if targetRemoved then
            RunTransfer("save restore rollback", function()
                return CreateTransferredUnit(targetOwner, state, false)
            end)
        end
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

local function IsProtectedPossessedUnit(playerID, unitID)
    local player = Players[playerID]
    local unit = player ~= nil and player:GetUnitByID(unitID) or nil
    return unit ~= nil and PROMO_POSSESSED ~= nil and unit:IsHasPromotion(PROMO_POSSESSED)
end

if GameEvents.PlayerCanGiftUnit ~= nil then
    GameEvents.PlayerCanGiftUnit.Add(function(playerID, _, unitID)
        return not IsProtectedPossessedUnit(playerID, unitID)
    end)
end

if GameEvents.PlayerCanDoCommand ~= nil then
    GameEvents.PlayerCanDoCommand.Add(function(playerID, unitID, commandID)
        if not IsProtectedPossessedUnit(playerID, unitID) then return true end
        if CommandTypes ~= nil and (commandID == CommandTypes.COMMAND_DELETE
            or commandID == CommandTypes.COMMAND_UPGRADE
            or commandID == CommandTypes.COMMAND_GIFT) then return false end
        return true
    end)
end

if GameEvents.CanHaveAnyUpgrade ~= nil then
    GameEvents.CanHaveAnyUpgrade.Add(function(playerID, unitID)
        return not IsProtectedPossessedUnit(playerID, unitID)
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
