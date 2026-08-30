-- ===========================================================================
-- Trentrouls, the Ultimate Possessor
-- Era-scaled, simultaneous possession with safe save/load normalization.
-- ===========================================================================

print("UltimatePossession.lua loaded")

local SAVE = Modding.OpenSaveData()
local CIV_ULTIMATE = GameInfoTypes.CIVILIZATION_ULTIMATE_POSSESSION
local UNIT_WARRIOR = GameInfoTypes.UNIT_WARRIOR
local UNIT_GOLDEN_RETRIEVER = GameInfoTypes.UNIT_ULTIMATE_GOLDEN_RETRIEVER
local PROMO_GOOD_BOY = GameInfoTypes.PROMOTION_ULTIMATE_GOOD_BOY
local PROMO_GOOD_BOY_AURA = GameInfoTypes.PROMOTION_ULTIMATE_GOOD_BOY_AURA
local PROMO_POSSESSED = GameInfoTypes.PROMOTION_ULTIMATE_POSSESSED
local DOMAIN_AIR = GameInfoTypes.DOMAIN_AIR
local MAX_SLOTS = 8
local activeTransfer = false

local EXCLUDED_TYPES = {
    [GameInfoTypes.UNIT_UNA_TRENTROULS or -1001] = true,
    [GameInfoTypes.UNIT_UNA_BUDDY or -1002] = true,
    [GameInfoTypes.UNIT_DOMINION_TRENTROULS or -1003] = true
}

local function Key(playerID, suffix)
    return "ULTIMATE_POSSESSION_" .. tostring(playerID) .. "_" .. suffix
end

local function GetNumber(playerID, suffix)
    return tonumber(SAVE.GetValue(Key(playerID, suffix))) or 0
end

local function SetNumber(playerID, suffix, value)
    SAVE.SetValue(Key(playerID, suffix), tonumber(value) or 0)
end

local function SlotKey(slot, suffix)
    return "SLOT_" .. tostring(slot) .. "_" .. suffix
end

local function SaveSlotKey(slot, suffix)
    return "SAVE_SLOT_" .. tostring(slot) .. "_" .. suffix
end

local function IsUltimatePlayer(player)
    return player ~= nil and player:IsAlive() and CIV_ULTIMATE ~= nil
        and player:GetCivilizationType() == CIV_ULTIMATE
end

local function IsOpeningTurn()
    if Game == nil or Game.GetElapsedGameTurns == nil then return false end
    local ok, turns = pcall(function() return Game.GetElapsedGameTurns() end)
    return ok and tonumber(turns) == 0
end

local function RemoveExtraStartingWarriors(playerID)
    local player = Players[playerID]
    if not IsUltimatePlayer(player) or not IsOpeningTurn() or UNIT_WARRIOR == nil then return end

    local warriorIDs = {}
    for unit in player:Units() do
        if unit:GetUnitType() == UNIT_WARRIOR then
            warriorIDs[#warriorIDs + 1] = unit:GetID()
        end
    end
    table.sort(warriorIDs)

    -- The civilization definition supplies the intended Warrior. Some VP
    -- handicap and setup combinations add another opening package, so retain
    -- one deterministic unit and remove only turn-zero duplicates.
    for index = 2, #warriorIDs do
        local duplicate = player:GetUnitByID(warriorIDs[index])
        if duplicate ~= nil then duplicate:Kill(false, -1) end
    end
    if #warriorIDs > 1 then
        print("Ultimate Possession removed " .. tostring(#warriorIDs - 1)
            .. " duplicate opening Warrior(s) for player " .. tostring(playerID))
    end
end

local function CurrentCapacity(player)
    if player == nil then return 1 end
    return math.max(1, math.min(MAX_SLOTS, (tonumber(player:GetCurrentEra()) or 0) + 1))
end

local function SpeedPercent()
    local info = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    local speed = info ~= nil and info.Type or "GAMESPEED_STANDARD"
    if speed == "GAMESPEED_QUICK" then return 67 end
    if speed == "GAMESPEED_EPIC" then return 150 end
    if speed == "GAMESPEED_MARATHON" then return 300 end
    return 100
end

local function ScaleTurns(standardTurns)
    return math.max(1, math.floor((standardTurns * SpeedPercent() + 50) / 100))
end

local function PossessionDuration()
    local speed = SpeedPercent()
    if speed == 67 then return 2 end
    if speed == 150 then return 5 end
    if speed == 300 then return 9 end
    return 3
end

local function CooldownForCount(count)
    return ScaleTurns(5 + 3 * math.max(0, (tonumber(count) or 1) - 1))
end

local function ClearSlot(playerID, slot)
    SetNumber(playerID, SlotKey(slot, "UNIT_ID"), -1)
    SetNumber(playerID, SlotKey(slot, "ORIGINAL_OWNER"), -1)
end

local function ClearSaveSlot(playerID, slot)
    SetNumber(playerID, SaveSlotKey(slot, "UNIT_ID"), -1)
    SetNumber(playerID, SaveSlotKey(slot, "ORIGINAL_OWNER"), -1)
end

local function ClearActive(playerID)
    SetNumber(playerID, "ACTIVE", 0)
    SetNumber(playerID, "COUNT", 0)
    SetNumber(playerID, "TURNS", 0)
    for slot = 1, MAX_SLOTS do ClearSlot(playerID, slot) end
end

local function ClearSuspended(playerID)
    SetNumber(playerID, "SAVE_SUSPENDED", 0)
    SetNumber(playerID, "SAVE_COUNT", 0)
    SetNumber(playerID, "SAVE_TURNS", 0)
    SetNumber(playerID, "SAVE_COOLDOWN", 0)
    for slot = 1, MAX_SLOTS do ClearSaveSlot(playerID, slot) end
end

local function ActiveRecords(playerID)
    local records = {}
    local player = Players[playerID]
    if player == nil then return records end
    for slot = 1, MAX_SLOTS do
        local unitID = GetNumber(playerID, SlotKey(slot, "UNIT_ID"))
        local ownerID = GetNumber(playerID, SlotKey(slot, "ORIGINAL_OWNER"))
        local unit = unitID >= 0 and player:GetUnitByID(unitID) or nil
        if unit ~= nil then
            records[#records + 1] = { slot = slot, unit = unit, originalOwner = ownerID }
        end
    end
    return records
end

local function Recount(playerID)
    local count = #ActiveRecords(playerID)
    SetNumber(playerID, "COUNT", count)
    if count <= 0 then
        SetNumber(playerID, "ACTIVE", 0)
        SetNumber(playerID, "TURNS", 0)
    else
        SetNumber(playerID, "ACTIVE", 1)
    end
    return count
end

local function UnitInfoExcluded(unit)
    if unit == nil or unit:IsDead() then return true end
    if EXCLUDED_TYPES[unit:GetUnitType()] then return true end
    local info = GameInfo.Units[unit:GetUnitType()]
    if info == nil then return true end
    if tonumber(info.Trade or 0) ~= 0 or tonumber(info.NukeDamageLevel or 0) > 0
        or tonumber(info.Suicide or 0) ~= 0 or info.Special == "SPECIALUNIT_MISSILE" then return true end
    if unit:GetDomainType() == DOMAIN_AIR then return true end
    if unit.IsCargo ~= nil and unit:IsCargo() then return true end
    return false
end

local function HasRequiredResources(player, unit)
    if player == nil or unit == nil or player.GetNumResourceAvailable == nil then return true end
    local info = GameInfo.Units[unit:GetUnitType()]
    if info == nil then return false end
    for requirement in GameInfo.Unit_ResourceQuantityRequirements{ UnitType = info.Type } do
        local resourceID = GameInfoTypes[requirement.ResourceType]
        if resourceID ~= nil then
            local ok, available = pcall(function()
                return player:GetNumResourceAvailable(resourceID, true)
            end)
            if ok and tonumber(available or 0) < tonumber(requirement.Cost or 0) then return false end
        end
    end
    return true
end

local function GroupHasRequiredResources(player, targets)
    if player == nil or player.GetNumResourceAvailable == nil then return true end
    local required = {}
    for _, record in ipairs(targets) do
        local unit = record.originalUnit
        local info = unit ~= nil and GameInfo.Units[unit:GetUnitType()] or nil
        if info ~= nil then
            for requirement in GameInfo.Unit_ResourceQuantityRequirements{ UnitType = info.Type } do
                local resourceID = GameInfoTypes[requirement.ResourceType]
                if resourceID ~= nil then
                    required[resourceID] = (required[resourceID] or 0) + tonumber(requirement.Cost or 0)
                end
            end
        end
    end
    for resourceID, amount in pairs(required) do
        local ok, available = pcall(function()
            return player:GetNumResourceAvailable(resourceID, true)
        end)
        if ok and tonumber(available or 0) < amount then return false end
    end
    return true
end

local function IsNearPossessionNetwork(player, targetPlot)
    if player == nil or targetPlot == nil then return false end
    for city in player:Cities() do
        local plot = city:Plot()
        if plot ~= nil and Map.PlotDistance(plot:GetX(), plot:GetY(), targetPlot:GetX(), targetPlot:GetY()) <= 2 then
            return true
        end
    end
    for unit in player:Units() do
        if not unit:IsDead() and unit:IsCombatUnit() then
            local plot = unit:GetPlot()
            if plot ~= nil and Map.PlotDistance(plot:GetX(), plot:GetY(), targetPlot:GetX(), targetPlot:GetY()) <= 2 then
                return true
            end
        end
    end
    return false
end

function Ultimate_IsEligibleTarget(playerID, target)
    local player = Players[playerID]
    if not IsUltimatePlayer(player) or target == nil or UnitInfoExcluded(target) then return false end
    if target:GetOwner() == playerID then return false end
    if PROMO_POSSESSED ~= nil and target:IsHasPromotion(PROMO_POSSESSED) then return false end
    local plot = target:GetPlot()
    if plot == nil or plot:IsCity() or not IsNearPossessionNetwork(player, plot) then return false end
    if not HasRequiredResources(player, target) then return false end

    local owner = Players[target:GetOwner()]
    if owner == nil or not owner:IsAlive() then return false end
    if owner:IsBarbarian() then return true end
    return owner:GetTeam() ~= player:GetTeam()
        and Teams[player:GetTeam()]:IsAtWar(owner:GetTeam())
end

local function CaptureUnitState(unit)
    local state = {
        unitType = unit:GetUnitType(), unitAI = unit:GetUnitAIType(),
        x = unit:GetX(), y = unit:GetY(), damage = unit:GetDamage(),
        experience = unit:GetExperience(), moves = unit:GetMoves(),
        embarked = unit.IsEmbarked ~= nil and unit:IsEmbarked() or false,
        promotions = {}
    }
    if unit.HasName ~= nil and unit:HasName() then state.name = unit:GetNameNoDesc() end
    for promotion in GameInfo.UnitPromotions() do
        if unit:IsHasPromotion(promotion.ID) then
            state.promotions[#state.promotions + 1] = promotion.ID
        end
    end
    return state
end

local function RestoreUnitState(unit, state, possessed)
    if unit == nil or state == nil then return end
    if state.damage ~= nil then unit:SetDamage(state.damage) end
    if state.experience ~= nil and state.experience > 0 then unit:ChangeExperience(state.experience) end
    if state.name ~= nil and state.name ~= "" then unit:SetName(state.name) end
    for _, promotionID in ipairs(state.promotions or {}) do
        if promotionID ~= PROMO_POSSESSED then unit:SetHasPromotion(promotionID, true) end
    end
    if PROMO_POSSESSED ~= nil then unit:SetHasPromotion(PROMO_POSSESSED, possessed == true) end
    if state.embarked and unit.SetEmbarked ~= nil then pcall(function() unit:SetEmbarked(true) end) end
    if state.moves ~= nil and unit.SetMoves ~= nil then unit:SetMoves(state.moves) end
end

local function CreateTransferredUnit(owner, state, possessed)
    if owner == nil or state == nil then return nil end
    local unit = owner:InitUnit(state.unitType, state.x, state.y, state.unitAI)
    if unit == nil then return nil end
    RestoreUnitState(unit, state, possessed)
    if unit.JumpToNearestValidPlot ~= nil then pcall(function() unit:JumpToNearestValidPlot() end) end
    return unit
end

local function NotifyChanged(playerID)
    if LuaEvents.UltimatePossessionChanged ~= nil then LuaEvents.UltimatePossessionChanged(playerID) end
end

local function Alert(player, title, message)
    if player == nil or not player:IsHuman() then return end
    if player.AddNotification ~= nil and NotificationTypes ~= nil
        and NotificationTypes.NOTIFICATION_GENERIC ~= nil then
        local ok = pcall(function()
            player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, message, title, -1, -1)
        end)
        if ok then return end
    end
    if Events.GameplayAlertMessage ~= nil then Events.GameplayAlertMessage(title .. ": " .. message) end
end

local function ParseTargets(encoded)
    local records, seen = {}, {}
    for ownerText, unitText in string.gmatch(tostring(encoded or ""), "(%d+):(%d+)") do
        local ownerID, unitID = tonumber(ownerText), tonumber(unitText)
        local key = tostring(ownerID) .. ":" .. tostring(unitID)
        if not seen[key] then
            seen[key] = true
            records[#records + 1] = { ownerID = ownerID, unitID = unitID }
        end
    end
    return records
end

function Ultimate_StartPossession(playerID, requestedTargets)
    local player = Players[playerID]
    if not IsUltimatePlayer(player) or GetNumber(playerID, "ACTIVE") == 1
        or GetNumber(playerID, "COOLDOWN") > 0 then return false end

    local request = type(requestedTargets) == "table" and requestedTargets or ParseTargets(requestedTargets)
    local capacity = CurrentCapacity(player)
    if #request < 1 or #request > capacity then return false end

    local targets = {}
    for _, record in ipairs(request) do
        local owner = Players[record.ownerID]
        local unit = owner ~= nil and owner:GetUnitByID(record.unitID) or nil
        if not Ultimate_IsEligibleTarget(playerID, unit) then return false end
        targets[#targets + 1] = {
            originalOwner = record.ownerID,
            originalUnit = unit,
            state = CaptureUnitState(unit)
        }
    end
    if not GroupHasRequiredResources(player, targets) then
        Alert(player, "Mass Possession", "The selected group requires more strategic resources than are available.")
        return false
    end

    local created = {}
    activeTransfer = true
    for index, record in ipairs(targets) do
        record.originalUnit:Kill(false, -1)
        local possessed = CreateTransferredUnit(player, record.state, true)
        if possessed == nil then
            -- Roll the entire activation back to conventional ownership.
            CreateTransferredUnit(Players[record.originalOwner], record.state, false)
            for _, earlier in ipairs(created) do
                local restoredState = CaptureUnitState(earlier.unit)
                earlier.unit:Kill(false, -1)
                CreateTransferredUnit(Players[earlier.originalOwner], restoredState, false)
            end
            activeTransfer = false
            print("Ultimate possession activation rolled back safely at slot " .. tostring(index))
            return false
        end
        created[#created + 1] = { unit = possessed, originalOwner = record.originalOwner }
    end
    activeTransfer = false

    ClearSuspended(playerID)
    ClearActive(playerID)
    for slot, record in ipairs(created) do
        SetNumber(playerID, SlotKey(slot, "UNIT_ID"), record.unit:GetID())
        SetNumber(playerID, SlotKey(slot, "ORIGINAL_OWNER"), record.originalOwner)
    end
    SetNumber(playerID, "ACTIVE", 1)
    SetNumber(playerID, "COUNT", #created)
    SetNumber(playerID, "TURNS", PossessionDuration())
    SetNumber(playerID, "COOLDOWN", CooldownForCount(#created))

    Alert(player, "Mass Possession", "Trentrouls has possessed " .. tostring(#created)
        .. " unit" .. (#created == 1 and "" or "s") .. " for " .. tostring(PossessionDuration()) .. " turns.")
    NotifyChanged(playerID)
    return true
end

local function ReturnSlot(playerID, slot, preserveMoves)
    local player = Players[playerID]
    local unitID = GetNumber(playerID, SlotKey(slot, "UNIT_ID"))
    local ownerID = GetNumber(playerID, SlotKey(slot, "ORIGINAL_OWNER"))
    local unit = player ~= nil and unitID >= 0 and player:GetUnitByID(unitID) or nil
    local owner = Players[ownerID]
    local returned = nil

    if unit ~= nil then
        local state = CaptureUnitState(unit)
        activeTransfer = true
        unit:Kill(false, -1)
        if owner ~= nil and (owner:IsAlive() or owner:IsBarbarian()) then
            returned = CreateTransferredUnit(owner, state, false)
            if returned ~= nil and not preserveMoves and returned.SetMoves ~= nil then returned:SetMoves(0) end
        end
        activeTransfer = false
    end
    ClearSlot(playerID, slot)
    return returned
end

function Ultimate_EndPossession(playerID, reason, preserveMoves)
    if GetNumber(playerID, "ACTIVE") ~= 1 then return false end
    for slot = 1, MAX_SLOTS do ReturnSlot(playerID, slot, preserveMoves == true) end
    ClearActive(playerID)
    local player = Players[playerID]
    if reason ~= nil then Alert(player, "Mass Possession Ended", tostring(reason) .. ".") end
    NotifyChanged(playerID)
    return true
end

local function SuspendForSave(playerID)
    if GetNumber(playerID, "ACTIVE") ~= 1 then return false end
    local turns, cooldown = GetNumber(playerID, "TURNS"), GetNumber(playerID, "COOLDOWN")
    local saved = {}
    for slot = 1, MAX_SLOTS do
        local ownerID = GetNumber(playerID, SlotKey(slot, "ORIGINAL_OWNER"))
        local returned = ReturnSlot(playerID, slot, true)
        if returned ~= nil then
            saved[#saved + 1] = { ownerID = ownerID, unitID = returned:GetID() }
        end
    end
    ClearActive(playerID)
    ClearSuspended(playerID)
    if #saved == 0 then return false end
    for slot, record in ipairs(saved) do
        SetNumber(playerID, SaveSlotKey(slot, "ORIGINAL_OWNER"), record.ownerID)
        SetNumber(playerID, SaveSlotKey(slot, "UNIT_ID"), record.unitID)
    end
    SetNumber(playerID, "SAVE_COUNT", #saved)
    SetNumber(playerID, "SAVE_TURNS", turns)
    SetNumber(playerID, "SAVE_COOLDOWN", cooldown)
    SetNumber(playerID, "SAVE_SUSPENDED", 1)
    return true
end

local function ResumeSuspended(playerID)
    if GetNumber(playerID, "SAVE_SUSPENDED") ~= 1 then return false end
    local player = Players[playerID]
    if not IsUltimatePlayer(player) then ClearSuspended(playerID) return false end
    local normalized = {}
    for slot = 1, MAX_SLOTS do
        local ownerID = GetNumber(playerID, SaveSlotKey(slot, "ORIGINAL_OWNER"))
        local unitID = GetNumber(playerID, SaveSlotKey(slot, "UNIT_ID"))
        local owner = Players[ownerID]
        local unit = owner ~= nil and unitID >= 0 and owner:GetUnitByID(unitID) or nil
        if unit ~= nil then
            normalized[#normalized + 1] = {
                ownerID = ownerID, unit = unit, state = CaptureUnitState(unit)
            }
        end
    end
    if #normalized == 0 then
        print("Ultimate possession save restore found no conventional units; leaving ownership normalized")
        ClearSuspended(playerID)
        return false
    end

    local created = {}
    activeTransfer = true
    for _, record in ipairs(normalized) do
        record.unit:Kill(false, -1)
        local possessed = CreateTransferredUnit(player, record.state, true)
        if possessed == nil then
            CreateTransferredUnit(Players[record.ownerID], record.state, false)
            for _, earlier in ipairs(created) do
                local state = CaptureUnitState(earlier.unit)
                earlier.unit:Kill(false, -1)
                CreateTransferredUnit(Players[earlier.ownerID], state, false)
            end
            activeTransfer = false
            ClearSuspended(playerID)
            print("Ultimate possession save restore rolled back safely")
            return false
        end
        created[#created + 1] = { unit = possessed, ownerID = record.ownerID }
    end
    activeTransfer = false

    local turns = GetNumber(playerID, "SAVE_TURNS")
    local cooldown = GetNumber(playerID, "SAVE_COOLDOWN")
    ClearActive(playerID)
    for slot, record in ipairs(created) do
        SetNumber(playerID, SlotKey(slot, "UNIT_ID"), record.unit:GetID())
        SetNumber(playerID, SlotKey(slot, "ORIGINAL_OWNER"), record.ownerID)
    end
    SetNumber(playerID, "ACTIVE", 1)
    SetNumber(playerID, "COUNT", #created)
    SetNumber(playerID, "TURNS", turns)
    SetNumber(playerID, "COOLDOWN", cooldown)
    ClearSuspended(playerID)
    NotifyChanged(playerID)
    print("Ultimate possession restored " .. tostring(#created) .. " save-suspended units")
    return true
end

local function TargetScore(unit)
    local info = GameInfo.Units[unit:GetUnitType()]
    local score = math.max(unit:GetBaseCombatStrength(), unit:GetBaseRangedCombatStrength())
    if info ~= nil then
        if info.Special == "SPECIALUNIT_PEOPLE" then score = score + 50 end
        if tonumber(info.WorkRate or 0) > 0 then score = score + 10 end
        score = score + math.floor((tonumber(info.Cost or 0) or 0) / 10)
    end
    return score
end

local function BestAITargets(playerID)
    local player = Players[playerID]
    local records = {}
    for ownerID = 0, (GameDefines.MAX_PLAYERS or 64) - 1 do
        local owner = Players[ownerID]
        if owner ~= nil and owner:IsAlive() and ownerID ~= playerID then
            for unit in owner:Units() do
                if Ultimate_IsEligibleTarget(playerID, unit) then
                    records[#records + 1] = {
                        ownerID = ownerID, unitID = unit:GetID(), score = TargetScore(unit)
                    }
                end
            end
        end
    end
    table.sort(records, function(a, b) return a.score > b.score end)
    local result = {}
    for i = 1, math.min(CurrentCapacity(player), #records) do result[#result + 1] = records[i] end
    return result
end

local function RefreshGoodBoyAura(playerID)
    local player = Players[playerID]
    if not IsUltimatePlayer(player) or PROMO_GOOD_BOY_AURA == nil then return end
    local sources = {}
    for unit in player:Units() do
        if PROMO_GOOD_BOY ~= nil and unit:IsHasPromotion(PROMO_GOOD_BOY) and unit:GetPlot() ~= nil then
            sources[#sources + 1] = unit
        end
    end
    for unit in player:Units() do
        local receives = false
        local plot = unit:GetPlot()
        if plot ~= nil then
            for _, source in ipairs(sources) do
                if source:GetID() ~= unit:GetID() then
                    local sourcePlot = source:GetPlot()
                    if sourcePlot ~= nil and Map.PlotDistance(plot:GetX(), plot:GetY(),
                        sourcePlot:GetX(), sourcePlot:GetY()) <= 1 then
                        receives = true
                        break
                    end
                end
            end
        end
        unit:SetHasPromotion(PROMO_GOOD_BOY_AURA, receives)
    end
end

local function NotifyReady(player)
    Alert(player, "Mass Possession Ready", "Trentrouls may possess another group through the Una Court command panel.")
end

local function DoTurn(playerID)
    local player = Players[playerID]
    if not IsUltimatePlayer(player) then return end
    RemoveExtraStartingWarriors(playerID)

    local cooldown = GetNumber(playerID, "COOLDOWN")
    if cooldown > 0 then
        cooldown = cooldown - 1
        SetNumber(playerID, "COOLDOWN", cooldown)
        if cooldown <= 0 then
            NotifyReady(player)
            NotifyChanged(playerID)
        end
    end

    if GetNumber(playerID, "ACTIVE") == 1 then
        for slot = 1, MAX_SLOTS do
            local unitID = GetNumber(playerID, SlotKey(slot, "UNIT_ID"))
            if unitID >= 0 then
                local unit = player:GetUnitByID(unitID)
                local owner = Players[GetNumber(playerID, SlotKey(slot, "ORIGINAL_OWNER"))]
                if unit == nil then
                    ClearSlot(playerID, slot)
                elseif owner ~= nil and not owner:IsBarbarian() and owner:IsAlive()
                    and not Teams[player:GetTeam()]:IsAtWar(owner:GetTeam()) then
                    ReturnSlot(playerID, slot, false)
                elseif owner ~= nil and not owner:IsAlive() and not owner:IsBarbarian() then
                    ReturnSlot(playerID, slot, false)
                end
            end
        end
        if Recount(playerID) > 0 then
            local turns = GetNumber(playerID, "TURNS") - 1
            SetNumber(playerID, "TURNS", turns)
            if turns <= 0 then Ultimate_EndPossession(playerID, "The duration expired", false) end
        else
            NotifyChanged(playerID)
        end
    elseif not player:IsHuman() and GetNumber(playerID, "COOLDOWN") <= 0 then
        local targets = BestAITargets(playerID)
        if #targets > 0 then Ultimate_StartPossession(playerID, targets) end
    end
    RefreshGoodBoyAura(playerID)
end

GameEvents.PlayerDoTurn.Add(DoTurn)

if GameEvents.UnitSetXY ~= nil then
    GameEvents.UnitSetXY.Add(function(playerID)
        local player = Players[playerID]
        if IsUltimatePlayer(player) then RefreshGoodBoyAura(playerID) end
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

if GameEvents.UnitPrekill ~= nil then
    GameEvents.UnitPrekill.Add(function(killedPlayerID, killedUnitID, killedUnitType)
        if activeTransfer then return end
        local killedPlayer = Players[killedPlayerID]
        if IsUltimatePlayer(killedPlayer) then
            local killedUnit = killedPlayer:GetUnitByID(killedUnitID)
            local wasGoodBoy = killedUnit ~= nil and PROMO_GOOD_BOY ~= nil
                and killedUnit:IsHasPromotion(PROMO_GOOD_BOY)
            for slot = 1, MAX_SLOTS do
                if GetNumber(killedPlayerID, SlotKey(slot, "UNIT_ID")) == killedUnitID then
                    ClearSlot(killedPlayerID, slot)
                    Recount(killedPlayerID)
                    NotifyChanged(killedPlayerID)
                    break
                end
            end
            if (wasGoodBoy or killedUnitType == UNIT_GOLDEN_RETRIEVER)
                and UnaCourt_QueueDeferredRestore ~= nil then
                local refreshPlayerID = killedPlayerID
                UnaCourt_QueueDeferredRestore(function() RefreshGoodBoyAura(refreshPlayerID) end)
            end
        end
    end)
end

if LuaEvents.UltimateMassPossessionRequest ~= nil then
    LuaEvents.UltimateMassPossessionRequest.Add(function(playerID, encoded)
        Ultimate_StartPossession(playerID, encoded)
    end)
end

if GameEvents.GameSave ~= nil then
    GameEvents.GameSave.Add(function()
        for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
            if GetNumber(playerID, "ACTIVE") == 1 then
                local suspended = SuspendForSave(playerID)
                print("Ultimate pre-save possession suspension for player " .. tostring(playerID)
                    .. ": " .. tostring(suspended))
                if suspended and UnaCourt_QueueDeferredRestore ~= nil then
                    local restorePlayerID = playerID
                    UnaCourt_QueueDeferredRestore(function() ResumeSuspended(restorePlayerID) end)
                end
            end
        end
    end)
else
    print("Ultimate warning: Community Patch GameSave hook is unavailable")
end

for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
    if GetNumber(playerID, "SAVE_SUSPENDED") == 1 and UnaCourt_QueueDeferredRestore ~= nil then
        local restorePlayerID = playerID
        UnaCourt_QueueDeferredRestore(function() ResumeSuspended(restorePlayerID) end)
    end
    RemoveExtraStartingWarriors(playerID)
    RefreshGoodBoyAura(playerID)
end

print("Ultimate mass possession initialized")
