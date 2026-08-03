-- The Freehold of Una Court - human command panel

print("UnaCourtPanel.lua loaded")
include("InstanceManager")

local CIV_UNA = GameInfoTypes.CIVILIZATION_UNA_COURT
local UNIT_TRENT = GameInfoTypes.UNIT_UNA_TRENTROULS
local UNIT_BUDDY = GameInfoTypes.UNIT_UNA_BUDDY
local PROMO_POSSESSED = GameInfoTypes.PROMOTION_UNA_POSSESSED
local DOMAIN_AIR = GameInfoTypes.DOMAIN_AIR
local SAVE = Modding.OpenSaveData()
local targetManager = InstanceManager:new("UnaCourtTargetInstance", "TargetButton", Controls.TargetStack)
local cityScreenOpen = false
local selectedTargetOwnerID = nil
local selectedTargetUnitID = nil

local ERA_PROMOTION_TYPES = {
    "PROMOTION_UNA_ERA_ANCIENT",
    "PROMOTION_UNA_ERA_CLASSICAL",
    "PROMOTION_UNA_ERA_MEDIEVAL",
    "PROMOTION_UNA_ERA_RENAISSANCE",
    "PROMOTION_UNA_ERA_INDUSTRIAL",
    "PROMOTION_UNA_ERA_MODERN",
    "PROMOTION_UNA_ERA_ATOMIC",
    "PROMOTION_UNA_ERA_INFORMATION"
}

local BUDDY_ERA_PROMOTION_TYPES = {
    "PROMOTION_UNA_BUDDY_ERA_ANCIENT",
    "PROMOTION_UNA_BUDDY_ERA_CLASSICAL",
    "PROMOTION_UNA_BUDDY_ERA_MEDIEVAL",
    "PROMOTION_UNA_BUDDY_ERA_RENAISSANCE",
    "PROMOTION_UNA_BUDDY_ERA_INDUSTRIAL",
    "PROMOTION_UNA_BUDDY_ERA_MODERN",
    "PROMOTION_UNA_BUDDY_ERA_ATOMIC",
    "PROMOTION_UNA_BUDDY_ERA_INFORMATION"
}

local function SaveNumber(playerID, suffix)
    return tonumber(SAVE.GetValue("UNA_POSSESSION_" .. tostring(playerID) .. "_" .. suffix)) or 0
end

local function IsUnaPlayer(player)
    return player ~= nil and player:IsAlive() and CIV_UNA ~= nil and player:GetCivilizationType() == CIV_UNA
end

local function FindUnit(player, unitType)
    if player == nil then return nil end
    for unit in player:Units() do
        if unit:GetUnitType() == unitType then return unit end
    end
    return nil
end

local function IsTradeUnit(unit)
    local info = GameInfo.Units[unit:GetUnitType()]
    return info ~= nil and tonumber(info.Trade or 0) ~= 0
end

local function IsEligible(playerID, trent, target)
    if target == nil or trent == nil or target:IsDead() or target:GetOwner() == playerID then return false end
    if target:GetUnitType() == UNIT_TRENT or target:GetUnitType() == UNIT_BUDDY then return false end
    if target:GetDomainType() == DOMAIN_AIR or IsTradeUnit(target) then return false end
    if PROMO_POSSESSED ~= nil and target:IsHasPromotion(PROMO_POSSESSED) then return false end
    local plot = target:GetPlot()
    local trentPlot = trent:GetPlot()
    if plot == nil or trentPlot == nil or plot:IsCity() then return false end
    if Map.PlotDistance(trentPlot:GetX(), trentPlot:GetY(), plot:GetX(), plot:GetY()) > 2 then return false end
    local owner = Players[target:GetOwner()]
    return owner ~= nil and owner:IsAlive() and not owner:IsBarbarian()
        and Teams[Players[playerID]:GetTeam()]:IsAtWar(owner:GetTeam())
end

local function BuddyDistance(trent, buddy)
    if trent == nil or buddy == nil then return nil end
    return Map.PlotDistance(trent:GetX(), trent:GetY(), buddy:GetX(), buddy:GetY())
end

local function IsCityScreenOpen()
    if UI.IsCityScreenUp ~= nil and UI.IsCityScreenUp() then return true end
    return cityScreenOpen
end

local function GameSpeedValues()
    local info = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    local speedType = info ~= nil and info.Type or "GAMESPEED_STANDARD"
    if speedType == "GAMESPEED_QUICK" then return 20, 2 end
    if speedType == "GAMESPEED_EPIC" then return 45, 5 end
    if speedType == "GAMESPEED_MARATHON" then return 90, 9 end
    return 30, 3
end

local function TrentStrengthForEra(eraIndex, buddyAdjacent)
    local unitInfo = UNIT_TRENT ~= nil and GameInfo.Units[UNIT_TRENT] or nil
    local baseStrength = unitInfo ~= nil and tonumber(unitInfo.Combat) or 0
    local promotionTypes = buddyAdjacent and BUDDY_ERA_PROMOTION_TYPES or ERA_PROMOTION_TYPES
    local promotionType = promotionTypes[math.max(0, math.min(7, eraIndex)) + 1]
    local promotionID = promotionType ~= nil and GameInfoTypes[promotionType] or nil
    local promotionInfo = promotionID ~= nil and GameInfo.UnitPromotions[promotionID] or nil
    local combatPercent = promotionInfo ~= nil and tonumber(promotionInfo.CombatPercent) or 0
    return math.floor((baseStrength * (100 + combatPercent) / 100) + 0.5)
end

local function ClearTargetSelection()
    selectedTargetOwnerID = nil
    selectedTargetUnitID = nil
end

local function UnitLabel(record, selected)
    local text = string.format("%d tile%s  |  [ICON_STRENGTH] %d  |  %s  |  %s",
        record.distance, record.distance == 1 and "" or "s", record.strength, record.name, record.ownerName)
    if selected then return "[COLOR_POSITIVE_TEXT]" .. text .. "[ENDCOLOR]" end
    return text
end

local function UpdateLayout()
    Controls.TargetStack:CalculateSize()
    Controls.TargetStack:ReprocessAnchoring()
    Controls.TargetScroll:CalculateInternalSize()
end

local function RefreshPanel()
    local playerID = Game.GetActivePlayer()
    local player = Players[playerID]
    local visible = IsUnaPlayer(player) and not IsCityScreenOpen()
    Controls.CommandButton:SetHide(not visible)
    if not visible then
        ClearTargetSelection()
        Controls.CommandPanel:SetHide(true)
        return
    end

    local trent = FindUnit(player, UNIT_TRENT)
    local buddy = FindUnit(player, UNIT_BUDDY)
    local eraBonus = trent ~= nil and math.max(1, math.min(8, player:GetCurrentEra() + 1)) or 0
    local buddyDistance = BuddyDistance(trent, buddy)
    local adjacent = buddyDistance ~= nil and buddyDistance <= 1
    if adjacent then eraBonus = eraBonus * 2 end

    Controls.FindTrentButton:SetDisabled(trent == nil)
    Controls.FindBuddyButton:SetDisabled(buddy == nil)

    local active = SaveNumber(playerID, "ACTIVE") == 1
    local turns = SaveNumber(playerID, "TURNS")
    local cooldown = SaveNumber(playerID, "COOLDOWN")
    local fullCooldown, fullDuration = GameSpeedValues()
    local trentState = trent ~= nil and "[COLOR_POSITIVE_TEXT]ALIVE[ENDCOLOR]" or "[COLOR_NEGATIVE_TEXT]FALLEN[ENDCOLOR]"
    local buddyState = "Not trained"
    if buddy ~= nil and trent == nil then
        buddyState = "Trentrouls fallen"
    elseif adjacent then
        buddyState = "[COLOR_POSITIVE_TEXT]ADJACENT[ENDCOLOR]"
    elseif buddyDistance ~= nil then
        buddyState = tostring(buddyDistance) .. " tiles away"
    end
    local possessionState = active and ("Active: " .. tostring(turns) .. " turns remaining")
        or (cooldown > 0 and ("Cooldown: " .. tostring(cooldown) .. " turns") or "[COLOR_POSITIVE_TEXT]READY[ENDCOLOR]")
    local strengthState = "Unavailable"
    if trent ~= nil then
        local eraIndex = math.max(0, math.min(7, player:GetCurrentEra()))
        local currentStrength = TrentStrengthForEra(eraIndex, adjacent)
        if eraIndex < 7 then
            strengthState = tostring(currentStrength) .. " > "
                .. tostring(TrentStrengthForEra(eraIndex + 1, adjacent)) .. " next Era"
        else
            strengthState = tostring(currentStrength) .. " (Era maximum)"
        end
    end

    Controls.StatusLabel:SetString(
        "Trentrouls: " .. trentState .. " | [ICON_STRENGTH] " .. strengthState .. "[NEWLINE]" ..
        "Buddy: " .. buddyState .. "[NEWLINE]" ..
        "Empire: " .. (eraBonus > 0 and ("+" .. tostring(eraBonus) .. "% all yields and Great People") or "Inactive") .. "[NEWLINE]" ..
        "Body Possession: " .. possessionState .. "[NEWLINE]" ..
        "Full timing: " .. tostring(fullDuration) .. " active / " .. tostring(fullCooldown) .. " cooldown turns"
    )

    targetManager:ResetInstances()
    local targetRecords = {}
    if trent ~= nil and not active and cooldown <= 0 then
        local trentPlot = trent:GetPlot()
        for otherPlayerID = 0, (GameDefines.MAX_CIV_PLAYERS or 63) - 1 do
            local otherPlayer = Players[otherPlayerID]
            if otherPlayer ~= nil and otherPlayer:IsAlive() and otherPlayerID ~= playerID then
                for target in otherPlayer:Units() do
                    if IsEligible(playerID, trent, target) then
                        targetRecords[#targetRecords + 1] = {
                            target = target,
                            ownerID = target:GetOwner(),
                            unitID = target:GetID(),
                            name = target:GetName(),
                            ownerName = otherPlayer:GetName(),
                            distance = Map.PlotDistance(trentPlot:GetX(), trentPlot:GetY(), target:GetX(), target:GetY()),
                            strength = math.max(target:GetBaseCombatStrength(), target:GetBaseRangedCombatStrength())
                        }
                    end
                end
            end
        end
    end

    table.sort(targetRecords, function(a, b)
        if a.distance ~= b.distance then return a.distance < b.distance end
        if a.strength ~= b.strength then return a.strength > b.strength end
        if a.name ~= b.name then return a.name < b.name end
        if a.ownerName ~= b.ownerName then return a.ownerName < b.ownerName end
        if a.ownerID ~= b.ownerID then return a.ownerID < b.ownerID end
        return a.unitID < b.unitID
    end)

    local selectedRecord = nil
    for _, record in ipairs(targetRecords) do
        local selected = record.ownerID == selectedTargetOwnerID and record.unitID == selectedTargetUnitID
        if selected then selectedRecord = record end

        local instance = targetManager:GetInstance()
        instance.TargetButton:SetText(UnitLabel(record, selected))
        instance.TargetButton:SetToolTipString(selected
            and "Selected for preview. Click Confirm Possession to transfer this unit."
            or "Preview this unit and center the map on it. This click does not possess the unit.")
        local targetOwnerID = record.ownerID
        local targetUnitID = record.unitID
        instance.TargetButton:RegisterCallback(Mouse.eLClick, function()
            selectedTargetOwnerID = targetOwnerID
            selectedTargetUnitID = targetUnitID
            local owner = Players[targetOwnerID]
            local target = owner ~= nil and owner:GetUnitByID(targetUnitID) or nil
            local plot = target ~= nil and target:GetPlot() or nil
            if plot ~= nil then UI.LookAt(plot, 0) end
            RefreshPanel()
        end)
    end

    if selectedRecord == nil then ClearTargetSelection() end
    Controls.ConfirmPossessionButton:SetDisabled(selectedRecord == nil)
    Controls.ConfirmPossessionButton:SetToolTipString(selectedRecord ~= nil
        and ("Confirm Body Possession of " .. selectedRecord.name .. ". Actions taken while possessed are permanent.")
        or "Select a target below before confirming.")

    local targetCount = #targetRecords
    Controls.NoTargetsLabel:SetHide(targetCount > 0)
    if active then
        Controls.NoTargetsLabel:SetString("Only one unit may be possessed at a time.")
    elseif cooldown > 0 then
        Controls.NoTargetsLabel:SetString("Body Possession is recharging.")
    else
        Controls.NoTargetsLabel:SetString("No eligible enemy units are within two tiles of Trentrouls.")
    end
    UpdateLayout()
end

local function ConfirmPossession()
    local playerID = Game.GetActivePlayer()
    local player = Players[playerID]
    if not IsUnaPlayer(player) or IsCityScreenOpen() then
        ClearTargetSelection()
        RefreshPanel()
        return
    end

    local trent = FindUnit(player, UNIT_TRENT)
    local targetOwner = selectedTargetOwnerID ~= nil and Players[selectedTargetOwnerID] or nil
    local target = targetOwner ~= nil and targetOwner:GetUnitByID(selectedTargetUnitID) or nil
    local ready = SaveNumber(playerID, "ACTIVE") == 0 and SaveNumber(playerID, "COOLDOWN") <= 0
    if trent == nil or not ready or not IsEligible(playerID, trent, target) then
        ClearTargetSelection()
        RefreshPanel()
        return
    end

    local trentID = trent:GetID()
    local targetOwnerID = target:GetOwner()
    local targetUnitID = target:GetID()
    ClearTargetSelection()
    if LuaEvents.UnaCourtPossessRequest ~= nil then
        LuaEvents.UnaCourtPossessRequest(playerID, trentID, targetOwnerID, targetUnitID)
    end
    RefreshPanel()
end

local function ClosePanel()
    ClearTargetSelection()
    Controls.CommandPanel:SetHide(true)
end

local function FocusUnit(unitType)
    local player = Players[Game.GetActivePlayer()]
    if not IsUnaPlayer(player) or IsCityScreenOpen() then return end

    local unit = FindUnit(player, unitType)
    if unit == nil then
        RefreshPanel()
        return
    end

    local plot = unit:GetPlot()
    ClosePanel()
    if plot ~= nil then UI.LookAt(plot, 0) end
    UI.SelectUnit(unit)
end

local function TogglePanel()
    if IsCityScreenOpen() then
        ClosePanel()
        return
    end
    if Controls.CommandPanel:IsHidden() then
        RefreshPanel()
        Controls.CommandPanel:SetHide(false)
    else
        ClosePanel()
    end
end

Controls.CommandButton:RegisterCallback(Mouse.eLClick, TogglePanel)
Controls.ConfirmPossessionButton:RegisterCallback(Mouse.eLClick, ConfirmPossession)
Controls.FindTrentButton:RegisterCallback(Mouse.eLClick, function() FocusUnit(UNIT_TRENT) end)
Controls.FindBuddyButton:RegisterCallback(Mouse.eLClick, function() FocusUnit(UNIT_BUDDY) end)
Controls.RefreshButton:RegisterCallback(Mouse.eLClick, RefreshPanel)
Controls.CloseButton:RegisterCallback(Mouse.eLClick, ClosePanel)

ContextPtr:SetInputHandler(function(uiMsg, wParam)
    if uiMsg == KeyEvents.KeyDown and wParam == Keys.VK_ESCAPE and not Controls.CommandPanel:IsHidden() then
        ClosePanel()
        return true
    end
    return false
end)

if Events.ActivePlayerTurnStart ~= nil then
    Events.ActivePlayerTurnStart.Add(function()
        ClearTargetSelection()
        RefreshPanel()
    end)
end
if Events.SerialEventUnitInfoDirty ~= nil then Events.SerialEventUnitInfoDirty.Add(RefreshPanel) end
if Events.SerialEventUnitCreated ~= nil then Events.SerialEventUnitCreated.Add(RefreshPanel) end
if Events.SerialEventEnterCityScreen ~= nil then
    Events.SerialEventEnterCityScreen.Add(function()
        cityScreenOpen = true
        Controls.CommandButton:SetHide(true)
        ClosePanel()
    end)
end
if Events.SerialEventExitCityScreen ~= nil then
    Events.SerialEventExitCityScreen.Add(function()
        cityScreenOpen = false
        RefreshPanel()
    end)
end
if LuaEvents.UnaCourtPossessionChanged ~= nil then
    LuaEvents.UnaCourtPossessionChanged.Add(function()
        ClearTargetSelection()
        RefreshPanel()
    end)
end

RefreshPanel()
print("Una Court command panel initialized")
