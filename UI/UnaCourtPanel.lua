-- Shared command panel for both Una Court civilizations.

print("UnaCourtPanel.lua loaded")
include("InstanceManager")

local CIV_FREEHOLD = GameInfoTypes.CIVILIZATION_UNA_COURT
local CIV_DOMINION = GameInfoTypes.CIVILIZATION_DOMINION_UNA_COURT
local UNIT_FREEHOLD_TRENT = GameInfoTypes.UNIT_UNA_TRENTROULS
local UNIT_DOMINION_TRENT = GameInfoTypes.UNIT_DOMINION_TRENTROULS
local UNIT_BUDDY = GameInfoTypes.UNIT_UNA_BUDDY
local PROMO_POSSESSED = GameInfoTypes.PROMOTION_UNA_POSSESSED
local PROMO_BORROWED = GameInfoTypes.PROMOTION_DOMINION_BORROWED_BODY
local PROMO_ENEMY_TRENT = GameInfoTypes.PROMOTION_DOMINION_ENEMY_IN_TRENT
local PROMO_IMMUNE = GameInfoTypes.PROMOTION_DOMINION_SWAP_IMMUNE
local DOMAIN_AIR = GameInfoTypes.DOMAIN_AIR
local SAVE = Modding.OpenSaveData()
local targets = InstanceManager:new("UnaCourtTargetInstance", "TargetButton", Controls.TargetStack)
local cityScreenOpen = false
local selectedOwner, selectedUnit = nil, nil

local FREEHOLD_ERA = {
    "PROMOTION_UNA_ERA_ANCIENT", "PROMOTION_UNA_ERA_CLASSICAL",
    "PROMOTION_UNA_ERA_MEDIEVAL", "PROMOTION_UNA_ERA_RENAISSANCE",
    "PROMOTION_UNA_ERA_INDUSTRIAL", "PROMOTION_UNA_ERA_MODERN",
    "PROMOTION_UNA_ERA_ATOMIC", "PROMOTION_UNA_ERA_INFORMATION"
}
local FREEHOLD_BUDDY_ERA = {
    "PROMOTION_UNA_BUDDY_ERA_ANCIENT", "PROMOTION_UNA_BUDDY_ERA_CLASSICAL",
    "PROMOTION_UNA_BUDDY_ERA_MEDIEVAL", "PROMOTION_UNA_BUDDY_ERA_RENAISSANCE",
    "PROMOTION_UNA_BUDDY_ERA_INDUSTRIAL", "PROMOTION_UNA_BUDDY_ERA_MODERN",
    "PROMOTION_UNA_BUDDY_ERA_ATOMIC", "PROMOTION_UNA_BUDDY_ERA_INFORMATION"
}
local DOMINION_ERA = {
    "PROMOTION_DOMINION_ERA_ANCIENT", "PROMOTION_DOMINION_ERA_CLASSICAL",
    "PROMOTION_DOMINION_ERA_MEDIEVAL", "PROMOTION_DOMINION_ERA_RENAISSANCE",
    "PROMOTION_DOMINION_ERA_INDUSTRIAL", "PROMOTION_DOMINION_ERA_MODERN",
    "PROMOTION_DOMINION_ERA_ATOMIC", "PROMOTION_DOMINION_ERA_INFORMATION"
}

local function Mode(player)
    if player == nil or not player:IsAlive() then return nil end
    if player:GetCivilizationType() == CIV_FREEHOLD then return "freehold" end
    if player:GetCivilizationType() == CIV_DOMINION then return "dominion" end
    return nil
end

local function SaveNumber(prefix, playerID, suffix)
    return tonumber(SAVE.GetValue(prefix .. tostring(playerID) .. "_" .. suffix)) or 0
end

local function FindUnit(player, unitType)
    if player == nil or unitType == nil then return nil end
    for unit in player:Units() do
        if unit:GetUnitType() == unitType then return unit end
    end
    return nil
end

local function State(mode, playerID, suffix)
    local prefix = mode == "dominion" and "DOMINION_SWAP_" or "UNA_POSSESSION_"
    return SaveNumber(prefix, playerID, suffix)
end

local function FindTrent(player, mode, playerID)
    local unitType = mode == "dominion" and UNIT_DOMINION_TRENT or UNIT_FREEHOLD_TRENT
    local owned = FindUnit(player, unitType)
    if owned ~= nil or mode ~= "dominion" or State(mode, playerID, "ACTIVE") ~= 1 then return owned end
    local owner = Players[State(mode, playerID, "TRENT_OWNER")]
    return owner ~= nil and owner:GetUnitByID(State(mode, playerID, "TRENT_UNIT_ID")) or nil
end

local function FindOwnedTrent(player, mode)
    return FindUnit(player, mode == "dominion" and UNIT_DOMINION_TRENT or UNIT_FREEHOLD_TRENT)
end

local function TradeOrExcluded(unit, mode)
    local info = GameInfo.Units[unit:GetUnitType()]
    if info == nil or tonumber(info.Trade or 0) ~= 0 then return true end
    if mode == "dominion" and (tonumber(info.NukeDamageLevel or 0) > 0
        or tonumber(info.Suicide or 0) ~= 0 or info.Special == "SPECIALUNIT_MISSILE") then return true end
    return false
end

local function Eligible(playerID, mode, trent, target)
    if trent == nil or target == nil or target:IsDead() or target:GetOwner() == playerID then return false end
    local unitType = target:GetUnitType()
    if unitType == UNIT_FREEHOLD_TRENT or unitType == UNIT_DOMINION_TRENT or unitType == UNIT_BUDDY then return false end
    if target:GetDomainType() == DOMAIN_AIR or TradeOrExcluded(target, mode) then return false end
    if mode == "freehold" and PROMO_POSSESSED ~= nil and target:IsHasPromotion(PROMO_POSSESSED) then return false end
    if mode == "dominion" then
        if PROMO_BORROWED ~= nil and target:IsHasPromotion(PROMO_BORROWED) then return false end
        if PROMO_ENEMY_TRENT ~= nil and target:IsHasPromotion(PROMO_ENEMY_TRENT) then return false end
        if PROMO_IMMUNE ~= nil and target:IsHasPromotion(PROMO_IMMUNE) then return false end
    end
    local plot, trentPlot = target:GetPlot(), trent:GetPlot()
    if plot == nil or trentPlot == nil or plot:IsCity()
        or Map.PlotDistance(trentPlot:GetX(), trentPlot:GetY(), plot:GetX(), plot:GetY()) > 2 then return false end
    local player, owner = Players[playerID], Players[target:GetOwner()]
    return owner ~= nil and owner:IsAlive() and not owner:IsBarbarian()
        and Teams[player:GetTeam()]:IsAtWar(owner:GetTeam())
end

local function IsCityScreenOpen()
    return (UI.IsCityScreenUp ~= nil and UI.IsCityScreenUp()) or cityScreenOpen
end

local function Timing(mode)
    local info = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    local speed = info ~= nil and info.Type or "GAMESPEED_STANDARD"
    if mode == "dominion" then
        if speed == "GAMESPEED_QUICK" then return 8, 1 end
        if speed == "GAMESPEED_EPIC" then return 18, 3 end
        if speed == "GAMESPEED_MARATHON" then return 36, 6 end
        return 12, 2
    end
    if speed == "GAMESPEED_QUICK" then return 20, 2 end
    if speed == "GAMESPEED_EPIC" then return 45, 5 end
    if speed == "GAMESPEED_MARATHON" then return 90, 9 end
    return 30, 3
end

local function Strength(unitType, promotionTypes, era)
    local info = GameInfo.Units[unitType]
    local base = info ~= nil and tonumber(info.Combat) or 0
    local promoID = GameInfoTypes[promotionTypes[math.max(0, math.min(7, era)) + 1]]
    local promo = promoID ~= nil and GameInfo.UnitPromotions[promoID] or nil
    local percent = promo ~= nil and tonumber(promo.CombatPercent) or 0
    return math.floor((base * (100 + percent) / 100) + 0.5)
end

local function ClearSelection()
    selectedOwner, selectedUnit = nil, nil
end

local function Layout()
    Controls.TargetStack:CalculateSize()
    Controls.TargetStack:ReprocessAnchoring()
    Controls.TargetScroll:CalculateInternalSize()
end

local function RefreshPanel()
    local playerID = Game.GetActivePlayer()
    local player = Players[playerID]
    local mode = Mode(player)
    local visible = mode ~= nil and not IsCityScreenOpen()
    Controls.CommandButton:SetHide(not visible)
    if not visible then
        ClearSelection()
        Controls.CommandPanel:SetHide(true)
        return
    end

    local dominion = mode == "dominion"
    Controls.CommandButton:SetText(dominion and "[ICON_STRENGTH] DOMINION" or "[ICON_STRENGTH] UNA COURT")
    Controls.CommandButton:SetToolTipString(dominion and "Open Dominion Body Swap command" or "Open Una Court Body Possession command")
    Controls.TitleLabel:SetText(dominion and "DOMINION COMMAND" or "UNA COURT COMMAND")
    Controls.SubtitleLabel:SetText(dominion and "THE ONE WHO POSSESSES" or "THE COURT LIVES THROUGH HIM")
    Controls.TargetsTitleLabel:SetText(dominion and "BODY SWAP TARGETS" or "POSSESSION TARGETS")
    Controls.ConfirmPossessionButton:SetText(dominion and "Confirm Body Swap" or "Confirm Possession")
    Controls.FindBuddyButton:SetText(dominion and "Find Borrowed" or "Find Buddy")

    local ownedTrent = FindOwnedTrent(player, mode)
    local trent = FindTrent(player, mode, playerID)
    local active = State(mode, playerID, "ACTIVE") == 1
    local turns, cooldown = State(mode, playerID, "TURNS"), State(mode, playerID, "COOLDOWN")
    local era = math.max(0, math.min(7, player:GetCurrentEra()))
    local level = trent ~= nil and era + 1 or 0
    local strength, nextStrength
    local buddy, adjacent
    if dominion then
        strength = Strength(UNIT_DOMINION_TRENT, DOMINION_ERA, era)
        nextStrength = era < 7 and Strength(UNIT_DOMINION_TRENT, DOMINION_ERA, era + 1) or nil
        if active then level = level * 2 end
    else
        buddy = FindUnit(player, UNIT_BUDDY)
        adjacent = trent ~= nil and buddy ~= nil and Map.PlotDistance(trent:GetX(), trent:GetY(), buddy:GetX(), buddy:GetY()) <= 1
        local set = adjacent and FREEHOLD_BUDDY_ERA or FREEHOLD_ERA
        strength = Strength(UNIT_FREEHOLD_TRENT, set, era)
        nextStrength = era < 7 and Strength(UNIT_FREEHOLD_TRENT, set, era + 1) or nil
        if adjacent then level = level * 2 end
    end

    local stateText = active and ("Active: " .. tostring(turns) .. " turns")
        or (cooldown > 0 and ("Cooldown: " .. tostring(cooldown) .. " turns") or "[COLOR_POSITIVE_TEXT]READY[ENDCOLOR]")
    local strengthText = trent ~= nil and (tostring(strength) .. (nextStrength ~= nil and (" > " .. tostring(nextStrength) .. " next Era") or " (maximum)")) or "Unavailable"
    local fullCooldown, fullDuration = Timing(mode)
    if dominion then
        local bodyText = active and "[COLOR_NEGATIVE_TEXT]ENEMY-CONTROLLED[ENDCOLOR]" or "Under Dominion control"
        Controls.StatusLabel:SetText(
            "Trentrouls: " .. (trent ~= nil and "[COLOR_POSITIVE_TEXT]ALIVE[ENDCOLOR]" or "[COLOR_NEGATIVE_TEXT]FALLEN[ENDCOLOR]") .. " | [ICON_STRENGTH] " .. strengthText .. "[NEWLINE]" ..
            "Original body: " .. bodyText .. "[NEWLINE]" ..
            "Empire: " .. (level > 0 and ("+" .. tostring(level) .. "% all yields and Great People") or "Inactive") .. "[NEWLINE]" ..
            "Body Swap: " .. stateText .. "[NEWLINE]" ..
            "Timing: " .. tostring(fullDuration) .. " active / " .. tostring(fullCooldown) .. " cooldown turns")
    else
        local buddyText = "Not trained"
        if buddy ~= nil and trent == nil then buddyText = "Trentrouls fallen"
        elseif adjacent then buddyText = "[COLOR_POSITIVE_TEXT]ADJACENT[ENDCOLOR]"
        elseif buddy ~= nil then
            buddyText = tostring(Map.PlotDistance(trent:GetX(), trent:GetY(), buddy:GetX(), buddy:GetY())) .. " tiles away"
        end
        Controls.StatusLabel:SetText(
            "Trentrouls: " .. (trent ~= nil and "[COLOR_POSITIVE_TEXT]ALIVE[ENDCOLOR]" or "[COLOR_NEGATIVE_TEXT]FALLEN[ENDCOLOR]") .. " | [ICON_STRENGTH] " .. strengthText .. "[NEWLINE]" ..
            "Buddy: " .. buddyText .. "[NEWLINE]" ..
            "Empire: " .. (level > 0 and ("+" .. tostring(level) .. "% all yields and Great People") or "Inactive") .. "[NEWLINE]" ..
            "Body Possession: " .. stateText .. "[NEWLINE]" ..
            "Timing: " .. tostring(fullDuration) .. " active / " .. tostring(fullCooldown) .. " cooldown turns")
    end

    Controls.FindTrentButton:SetDisabled(trent == nil)
    local secondary = dominion and (active and player:GetUnitByID(State(mode, playerID, "BORROWED_ID")) or nil) or buddy
    Controls.FindBuddyButton:SetDisabled(secondary == nil)
    Controls.FindBuddyButton:SetToolTipString(dominion and "Center the map on the borrowed body" or "Select Buddy and center the map on him")

    targets:ResetInstances()
    local records = {}
    if ownedTrent ~= nil and not active and cooldown <= 0 then
        local trentPlot = ownedTrent:GetPlot()
        for otherID = 0, (GameDefines.MAX_CIV_PLAYERS or 63) - 1 do
            local other = Players[otherID]
            if other ~= nil and other:IsAlive() and otherID ~= playerID then
                for target in other:Units() do
                    if Eligible(playerID, mode, ownedTrent, target) then
                        records[#records + 1] = {
                            owner = otherID, id = target:GetID(), name = target:GetName(), ownerName = other:GetName(),
                            distance = Map.PlotDistance(trentPlot:GetX(), trentPlot:GetY(), target:GetX(), target:GetY()),
                            strength = math.max(target:GetBaseCombatStrength(), target:GetBaseRangedCombatStrength())
                        }
                    end
                end
            end
        end
    end
    table.sort(records, function(a, b)
        if a.distance ~= b.distance then return a.distance < b.distance end
        if a.strength ~= b.strength then return a.strength > b.strength end
        if a.name ~= b.name then return a.name < b.name end
        return a.owner < b.owner
    end)

    local selectedRecord = nil
    for _, record in ipairs(records) do
        local selected = record.owner == selectedOwner and record.id == selectedUnit
        if selected then selectedRecord = record end
        local instance = targets:GetInstance()
        local text = string.format("%d tile%s  |  [ICON_STRENGTH] %d  |  %s  |  %s",
            record.distance, record.distance == 1 and "" or "s", record.strength, record.name, record.ownerName)
        instance.TargetButton:SetText(selected and "[COLOR_POSITIVE_TEXT]" .. text .. "[ENDCOLOR]" or text)
        instance.TargetButton:SetToolTipString("Preview this target. Confirmation is a separate click.")
        local ownerID, unitID = record.owner, record.id
        instance.TargetButton:RegisterCallback(Mouse.eLClick, function()
            selectedOwner, selectedUnit = ownerID, unitID
            local owner = Players[ownerID]
            local target = owner ~= nil and owner:GetUnitByID(unitID) or nil
            if target ~= nil and target:GetPlot() ~= nil then UI.LookAt(target:GetPlot(), 0) end
            RefreshPanel()
        end)
    end
    if selectedRecord == nil then ClearSelection() end
    Controls.ConfirmPossessionButton:SetDisabled(selectedRecord == nil)
    Controls.ConfirmPossessionButton:SetToolTipString(selectedRecord ~= nil
        and ((dominion and "Exchange bodies with " or "Possess ") .. selectedRecord.name .. ". Actions taken are permanent.")
        or "Select a target below before confirming.")
    Controls.NoTargetsLabel:SetHide(#records > 0)
    if active then Controls.NoTargetsLabel:SetText(dominion and "A Body Swap is already active." or "Only one unit may be possessed at a time.")
    elseif cooldown > 0 then Controls.NoTargetsLabel:SetText(dominion and "Body Swap is recharging." or "Body Possession is recharging.")
    else Controls.NoTargetsLabel:SetText("No eligible enemy units are within two tiles of Trentrouls.") end
    Layout()
end

local function ClosePanel()
    ClearSelection()
    Controls.CommandPanel:SetHide(true)
end

local function Focus(unit, selectable)
    if unit == nil or IsCityScreenOpen() then RefreshPanel() return end
    local plot = unit:GetPlot()
    ClosePanel()
    if plot ~= nil then UI.LookAt(plot, 0) end
    if selectable then UI.SelectUnit(unit) end
end

local function Confirm()
    local playerID = Game.GetActivePlayer()
    local player = Players[playerID]
    local mode = Mode(player)
    if mode == nil or IsCityScreenOpen() then ClearSelection() RefreshPanel() return end
    local trent = FindOwnedTrent(player, mode)
    local owner = selectedOwner ~= nil and Players[selectedOwner] or nil
    local target = owner ~= nil and owner:GetUnitByID(selectedUnit) or nil
    if trent == nil or State(mode, playerID, "ACTIVE") == 1 or State(mode, playerID, "COOLDOWN") > 0
        or not Eligible(playerID, mode, trent, target) then ClearSelection() RefreshPanel() return end
    local trentID, ownerID, unitID = trent:GetID(), target:GetOwner(), target:GetID()
    ClearSelection()
    if mode == "dominion" and LuaEvents.DominionBodySwapRequest ~= nil then
        LuaEvents.DominionBodySwapRequest(playerID, trentID, ownerID, unitID)
    elseif LuaEvents.UnaCourtPossessRequest ~= nil then
        LuaEvents.UnaCourtPossessRequest(playerID, trentID, ownerID, unitID)
    end
    RefreshPanel()
end

Controls.CommandButton:RegisterCallback(Mouse.eLClick, function()
    if IsCityScreenOpen() then ClosePanel()
    elseif Controls.CommandPanel:IsHidden() then RefreshPanel() Controls.CommandPanel:SetHide(false)
    else ClosePanel() end
end)
Controls.ConfirmPossessionButton:RegisterCallback(Mouse.eLClick, Confirm)
Controls.FindTrentButton:RegisterCallback(Mouse.eLClick, function()
    local playerID, player = Game.GetActivePlayer(), Players[Game.GetActivePlayer()]
    local mode = Mode(player)
    local trent = mode ~= nil and FindTrent(player, mode, playerID) or nil
    Focus(trent, trent ~= nil and trent:GetOwner() == playerID)
end)
Controls.FindBuddyButton:RegisterCallback(Mouse.eLClick, function()
    local playerID, player = Game.GetActivePlayer(), Players[Game.GetActivePlayer()]
    local mode = Mode(player)
    local unit = mode == "dominion" and player:GetUnitByID(State(mode, playerID, "BORROWED_ID")) or FindUnit(player, UNIT_BUDDY)
    Focus(unit, true)
end)
Controls.RefreshButton:RegisterCallback(Mouse.eLClick, RefreshPanel)
Controls.CloseButton:RegisterCallback(Mouse.eLClick, ClosePanel)

ContextPtr:SetInputHandler(function(uiMsg, key)
    if uiMsg == KeyEvents.KeyDown and key == Keys.VK_ESCAPE and not Controls.CommandPanel:IsHidden() then ClosePanel() return true end
    return false
end)
if Events.ActivePlayerTurnStart ~= nil then Events.ActivePlayerTurnStart.Add(function() ClearSelection() RefreshPanel() end) end
if Events.SerialEventUnitInfoDirty ~= nil then Events.SerialEventUnitInfoDirty.Add(RefreshPanel) end
if Events.SerialEventUnitCreated ~= nil then Events.SerialEventUnitCreated.Add(RefreshPanel) end
if Events.SerialEventEnterCityScreen ~= nil then Events.SerialEventEnterCityScreen.Add(function() cityScreenOpen = true Controls.CommandButton:SetHide(true) ClosePanel() end) end
if Events.SerialEventExitCityScreen ~= nil then Events.SerialEventExitCityScreen.Add(function() cityScreenOpen = false RefreshPanel() end) end
if LuaEvents.UnaCourtPossessionChanged ~= nil then LuaEvents.UnaCourtPossessionChanged.Add(function() ClearSelection() RefreshPanel() end) end
if LuaEvents.DominionBodySwapChanged ~= nil then LuaEvents.DominionBodySwapChanged.Add(function() ClearSelection() RefreshPanel() end) end

RefreshPanel()
print("Shared Una Court command panel initialized")
