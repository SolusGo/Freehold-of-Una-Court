-- Shared, self-contained command panel for all three Una Court civilizations.

print("UnaCourtPanel.lua loaded")
include("InstanceManager")

local CIV_FREEHOLD = GameInfoTypes.CIVILIZATION_UNA_COURT
local CIV_DOMINION = GameInfoTypes.CIVILIZATION_DOMINION_UNA_COURT
local CIV_ULTIMATE = GameInfoTypes.CIVILIZATION_ULTIMATE_POSSESSION
local UNIT_FREEHOLD_TRENT = GameInfoTypes.UNIT_UNA_TRENTROULS
local UNIT_DOMINION_TRENT = GameInfoTypes.UNIT_DOMINION_TRENTROULS
local UNIT_BUDDY = GameInfoTypes.UNIT_UNA_BUDDY
local UNIT_GOLDEN_RETRIEVER = GameInfoTypes.UNIT_ULTIMATE_GOLDEN_RETRIEVER
local PROMO_POSSESSED = GameInfoTypes.PROMOTION_UNA_POSSESSED
local PROMO_BORROWED = GameInfoTypes.PROMOTION_DOMINION_BORROWED_BODY
local PROMO_ENEMY_TRENT = GameInfoTypes.PROMOTION_DOMINION_ENEMY_IN_TRENT
local PROMO_IMMUNE = GameInfoTypes.PROMOTION_DOMINION_SWAP_IMMUNE
local PROMO_ULTIMATE_POSSESSED = GameInfoTypes.PROMOTION_ULTIMATE_POSSESSED
local DOMAIN_AIR = GameInfoTypes.DOMAIN_AIR
local SAVE = Modding.OpenSaveData()
local targets = InstanceManager:new("UnaCourtTargetInstance", "TargetButton", Controls.TargetStack)
local cityScreenOpen = false
local selectedOwner, selectedUnit = nil, nil
local selectedTargets = {}

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
local EXCLUDED_TYPES = {
    [UNIT_FREEHOLD_TRENT or -1001] = true,
    [UNIT_DOMINION_TRENT or -1002] = true,
    [UNIT_BUDDY or -1003] = true
}

local function Mode(player)
    if player == nil or not player:IsAlive() then return nil end
    if player:GetCivilizationType() == CIV_FREEHOLD then return "freehold" end
    if player:GetCivilizationType() == CIV_DOMINION then return "dominion" end
    if player:GetCivilizationType() == CIV_ULTIMATE then return "ultimate" end
    return nil
end

local function Prefix(mode)
    if mode == "dominion" then return "DOMINION_SWAP_" end
    if mode == "ultimate" then return "ULTIMATE_POSSESSION_" end
    return "UNA_POSSESSION_"
end
local function State(mode, playerID, suffix)
    return tonumber(SAVE.GetValue(Prefix(mode) .. tostring(playerID) .. "_" .. suffix)) or 0
end
local function FindUnit(player, unitType)
    if player == nil or unitType == nil then return nil end
    for unit in player:Units() do if unit:GetUnitType() == unitType then return unit end end
    return nil
end
local function FindTrent(player, mode, playerID)
    if mode == "ultimate" then return nil end
    local unitType = mode == "dominion" and UNIT_DOMINION_TRENT or UNIT_FREEHOLD_TRENT
    local owned = FindUnit(player, unitType)
    if owned ~= nil or mode ~= "dominion" or State(mode, playerID, "ACTIVE") ~= 1 then return owned end
    local owner = Players[State(mode, playerID, "TRENT_OWNER")]
    return owner ~= nil and owner:GetUnitByID(State(mode, playerID, "TRENT_UNIT_ID")) or nil
end
local function FindOwnedTrent(player, mode)
    if mode == "ultimate" then return nil end
    return FindUnit(player, mode == "dominion" and UNIT_DOMINION_TRENT or UNIT_FREEHOLD_TRENT)
end

local function UnitExcluded(unit, mode)
    if unit == nil or unit:IsDead() or EXCLUDED_TYPES[unit:GetUnitType()] then return true end
    local info = GameInfo.Units[unit:GetUnitType()]
    if info == nil or tonumber(info.Trade or 0) ~= 0 or unit:GetDomainType() == DOMAIN_AIR then return true end
    if mode ~= "freehold" and (tonumber(info.NukeDamageLevel or 0) > 0
        or tonumber(info.Suicide or 0) ~= 0 or info.Special == "SPECIALUNIT_MISSILE") then return true end
    if unit.IsCargo ~= nil and unit:IsCargo() then return true end
    return false
end
local function HasRequiredResources(player, unit)
    if player == nil or player.GetNumResourceAvailable == nil then return true end
    local info = unit ~= nil and GameInfo.Units[unit:GetUnitType()] or nil
    if info == nil then return false end
    for requirement in GameInfo.Unit_ResourceQuantityRequirements{ UnitType = info.Type } do
        local resourceID = GameInfoTypes[requirement.ResourceType]
        if resourceID ~= nil then
            local ok, available = pcall(function() return player:GetNumResourceAvailable(resourceID, true) end)
            if ok and tonumber(available or 0) < tonumber(requirement.Cost or 0) then return false end
        end
    end
    return true
end
local function NetworkDistance(player, targetPlot)
    local best = 999
    if player == nil or targetPlot == nil then return best end
    for city in player:Cities() do
        local plot = city:Plot()
        if plot ~= nil then best = math.min(best, Map.PlotDistance(plot:GetX(), plot:GetY(), targetPlot:GetX(), targetPlot:GetY())) end
    end
    for unit in player:Units() do
        if not unit:IsDead() and unit:IsCombatUnit() and unit:GetPlot() ~= nil then
            local plot = unit:GetPlot()
            best = math.min(best, Map.PlotDistance(plot:GetX(), plot:GetY(), targetPlot:GetX(), targetPlot:GetY()))
        end
    end
    return best
end

local function Eligible(playerID, mode, trent, target)
    if target == nil or UnitExcluded(target, mode) or target:GetOwner() == playerID then return false end
    if mode == "freehold" and PROMO_POSSESSED ~= nil and target:IsHasPromotion(PROMO_POSSESSED) then return false end
    if mode == "dominion" then
        if PROMO_BORROWED ~= nil and target:IsHasPromotion(PROMO_BORROWED) then return false end
        if PROMO_ENEMY_TRENT ~= nil and target:IsHasPromotion(PROMO_ENEMY_TRENT) then return false end
        if PROMO_IMMUNE ~= nil and target:IsHasPromotion(PROMO_IMMUNE) then return false end
    end
    if mode == "ultimate" and PROMO_ULTIMATE_POSSESSED ~= nil and target:IsHasPromotion(PROMO_ULTIMATE_POSSESSED) then return false end
    local player, owner = Players[playerID], Players[target:GetOwner()]
    local plot = target:GetPlot()
    if player == nil or owner == nil or not owner:IsAlive() or plot == nil or plot:IsCity() then return false end
    if mode == "ultimate" then
        if NetworkDistance(player, plot) > 2 or not HasRequiredResources(player, target) then return false end
        return owner:IsBarbarian() or (owner:GetTeam() ~= player:GetTeam() and Teams[player:GetTeam()]:IsAtWar(owner:GetTeam()))
    end
    if trent == nil or trent:GetPlot() == nil or owner:IsBarbarian() then return false end
    if Map.PlotDistance(trent:GetX(), trent:GetY(), plot:GetX(), plot:GetY()) > 2 then return false end
    return Teams[player:GetTeam()]:IsAtWar(owner:GetTeam())
end

local function IsCityScreenOpen()
    return (UI.IsCityScreenUp ~= nil and UI.IsCityScreenUp()) or cityScreenOpen
end
local function Timing(mode, selectedCount)
    local info = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    local speed = info ~= nil and info.Type or "GAMESPEED_STANDARD"
    if mode == "ultimate" then
        local duration = speed == "GAMESPEED_QUICK" and 2 or speed == "GAMESPEED_EPIC" and 5
            or speed == "GAMESPEED_MARATHON" and 9 or 3
        local percent = speed == "GAMESPEED_QUICK" and 67 or speed == "GAMESPEED_EPIC" and 150
            or speed == "GAMESPEED_MARATHON" and 300 or 100
        local cooldown = math.max(1, math.floor(((5 + 3 * math.max(0, (selectedCount or 1) - 1)) * percent + 50) / 100))
        return cooldown, duration
    end
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
local function SelectionKey(ownerID, unitID) return tostring(ownerID) .. ":" .. tostring(unitID) end
local function SelectedCount()
    local count = 0
    for _, selected in pairs(selectedTargets) do if selected then count = count + 1 end end
    return count
end
local function ClearSelection() selectedOwner, selectedUnit, selectedTargets = nil, nil, {} end
local function Layout()
    Controls.TargetStack:CalculateSize()
    Controls.TargetStack:ReprocessAnchoring()
    Controls.TargetScroll:CalculateInternalSize()
end
local function FindFirstUltimatePossessed(playerID, player)
    for slot = 1, 8 do
        local unitID = State("ultimate", playerID, "SLOT_" .. tostring(slot) .. "_UNIT_ID")
        local unit = unitID >= 0 and player:GetUnitByID(unitID) or nil
        if unit ~= nil then return unit end
    end
    return nil
end

local RefreshPanel
RefreshPanel = function()
    local playerID = Game.GetActivePlayer()
    local player = Players[playerID]
    local mode = Mode(player)
    local visible = mode ~= nil and not IsCityScreenOpen()
    Controls.CommandButton:SetHide(not visible)
    if not visible then ClearSelection() Controls.CommandPanel:SetHide(true) return end

    local dominion, ultimate = mode == "dominion", mode == "ultimate"
    Controls.CommandButton:SetText(ultimate and "[ICON_STRENGTH] ULTIMATE" or dominion and "[ICON_STRENGTH] DOMINION" or "[ICON_STRENGTH] UNA COURT")
    Controls.CommandButton:SetToolTipString(ultimate and "Open the Ultimate Possession command panel"
        or dominion and "Open Dominion Body Swap command" or "Open Una Court Body Possession command")
    Controls.TitleLabel:SetText(ultimate and "ULTIMATE POSSESSION" or dominion and "DOMINION COMMAND" or "UNA COURT COMMAND")
    Controls.SubtitleLabel:SetText(ultimate and "WHY HAVE ONE ARMY?" or dominion and "THE ONE WHO POSSESSES" or "THE COURT LIVES THROUGH HIM")
    Controls.TargetsTitleLabel:SetText(ultimate and "MASS POSSESSION TARGETS" or dominion and "BODY SWAP TARGETS" or "POSSESSION TARGETS")
    Controls.ConfirmPossessionButton:SetText(ultimate and "Possess Selected" or dominion and "Confirm Body Swap" or "Confirm Possession")

    local active = State(mode, playerID, "ACTIVE") == 1
    local turns, cooldown = State(mode, playerID, "TURNS"), State(mode, playerID, "COOLDOWN")
    local ownedTrent = FindOwnedTrent(player, mode)
    local trent = FindTrent(player, mode, playerID)
    local era = math.max(0, math.min(7, player:GetCurrentEra()))
    local capacity = ultimate and era + 1 or 1

    if ultimate then
        local selectedCount = SelectedCount()
        local prospectiveCooldown, duration = Timing(mode, math.max(1, selectedCount))
        local activeCount = State(mode, playerID, "COUNT")
        local stateText = active and ("Active: " .. tostring(activeCount) .. " unit" .. (activeCount == 1 and "" or "s") .. ", " .. tostring(turns) .. " turns")
            or (cooldown > 0 and ("Cooldown: " .. tostring(cooldown) .. " turns") or "[COLOR_POSITIVE_TEXT]READY[ENDCOLOR]")
        Controls.StatusLabel:SetText(
            "Maximum possessions: " .. tostring(capacity) .. " | Selected: " .. tostring(selectedCount) .. "[NEWLINE]" ..
            "Mass Possession: " .. stateText .. "[NEWLINE]" ..
            "Selected cooldown: " .. tostring(prospectiveCooldown) .. " turns[NEWLINE]" ..
            "Duration: " .. tostring(duration) .. " turns | Range: 2 tiles[NEWLINE]" ..
            "Network: friendly military units and cities")
        Controls.FindTrentButton:SetText("Find Capital")
        Controls.FindTrentButton:SetDisabled(player:GetCapitalCity() == nil)
        Controls.FindTrentButton:SetToolTipString("Center the map on the capital of Ultimate Possession")
        local possessed = FindFirstUltimatePossessed(playerID, player)
        local retriever = FindUnit(player, UNIT_GOLDEN_RETRIEVER)
        Controls.FindBuddyButton:SetText(possessed ~= nil and "Find Possessed" or "Find Retriever")
        Controls.FindBuddyButton:SetDisabled(possessed == nil and retriever == nil)
        Controls.FindBuddyButton:SetToolTipString(possessed ~= nil and "Select a currently possessed unit" or "Select a Golden Retriever")
    else
        local level = trent ~= nil and era + 1 or 0
        local strength, nextStrength, buddy, adjacent
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
            elseif buddy ~= nil then buddyText = tostring(Map.PlotDistance(trent:GetX(), trent:GetY(), buddy:GetX(), buddy:GetY())) .. " tiles away" end
            Controls.StatusLabel:SetText(
                "Trentrouls: " .. (trent ~= nil and "[COLOR_POSITIVE_TEXT]ALIVE[ENDCOLOR]" or "[COLOR_NEGATIVE_TEXT]FALLEN[ENDCOLOR]") .. " | [ICON_STRENGTH] " .. strengthText .. "[NEWLINE]" ..
                "Buddy: " .. buddyText .. "[NEWLINE]" ..
                "Empire: " .. (level > 0 and ("+" .. tostring(level) .. "% all yields and Great People") or "Inactive") .. "[NEWLINE]" ..
                "Body Possession: " .. stateText .. "[NEWLINE]" ..
                "Timing: " .. tostring(fullDuration) .. " active / " .. tostring(fullCooldown) .. " cooldown turns")
        end
        Controls.FindTrentButton:SetText("Find Trent")
        Controls.FindTrentButton:SetDisabled(trent == nil)
        Controls.FindTrentButton:SetToolTipString("Select Trentrouls and center the map on him")
        local secondary = dominion and (active and player:GetUnitByID(State(mode, playerID, "BORROWED_ID")) or nil) or buddy
        Controls.FindBuddyButton:SetText(dominion and "Find Borrowed" or "Find Buddy")
        Controls.FindBuddyButton:SetDisabled(secondary == nil)
        Controls.FindBuddyButton:SetToolTipString(dominion and "Center the map on the borrowed body" or "Select Buddy and center the map on him")
    end

    targets:ResetInstances()
    local records, validSelections = {}, {}
    if not active and cooldown <= 0 and (ultimate or ownedTrent ~= nil) then
        for otherID = 0, (GameDefines.MAX_PLAYERS or 64) - 1 do
            local other = Players[otherID]
            if other ~= nil and other:IsAlive() and otherID ~= playerID then
                for target in other:Units() do
                    if Eligible(playerID, mode, ownedTrent, target) then
                        local distance = ultimate and NetworkDistance(player, target:GetPlot())
                            or Map.PlotDistance(ownedTrent:GetX(), ownedTrent:GetY(), target:GetX(), target:GetY())
                        records[#records + 1] = { owner = otherID, id = target:GetID(), name = target:GetName(),
                            ownerName = other:IsBarbarian() and "Barbarians" or other:GetName(), distance = distance,
                            strength = math.max(target:GetBaseCombatStrength(), target:GetBaseRangedCombatStrength()) }
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
        local key = SelectionKey(record.owner, record.id)
        local selected = ultimate and selectedTargets[key] or (record.owner == selectedOwner and record.id == selectedUnit)
        if selected then validSelections[key], selectedRecord = true, record end
        local instance = targets:GetInstance()
        local marker = ultimate and (selected and "[x] " or "[ ] ") or ""
        local rowText = string.format("%s%d tile%s | [ICON_STRENGTH] %d | %s | %s", marker, record.distance,
            record.distance == 1 and "" or "s", record.strength, record.name, record.ownerName)
        instance.TargetButton:SetText(selected and "[COLOR_POSITIVE_TEXT]" .. rowText .. "[ENDCOLOR]" or rowText)
        instance.TargetButton:SetToolTipString(ultimate and "Toggle this unit in the mass-possession group."
            or "Preview this target. Confirmation is a separate click.")
        local ownerID, unitID = record.owner, record.id
        instance.TargetButton:RegisterCallback(Mouse.eLClick, function()
            if ultimate then
                local targetKey = SelectionKey(ownerID, unitID)
                if selectedTargets[targetKey] then selectedTargets[targetKey] = nil
                elseif SelectedCount() < capacity then selectedTargets[targetKey] = true
                elseif Events.GameplayAlertMessage ~= nil then Events.GameplayAlertMessage("Maximum possession capacity reached for this Era.") end
            else selectedOwner, selectedUnit = ownerID, unitID end
            local owner = Players[ownerID]
            local target = owner ~= nil and owner:GetUnitByID(unitID) or nil
            if target ~= nil and target:GetPlot() ~= nil then UI.LookAt(target:GetPlot(), 0) end
            RefreshPanel()
        end)
    end
    if ultimate then
        for key in pairs(selectedTargets) do if not validSelections[key] then selectedTargets[key] = nil end end
    elseif selectedRecord == nil then selectedOwner, selectedUnit = nil, nil end

    local selectionCount = ultimate and SelectedCount() or (selectedRecord ~= nil and 1 or 0)
    Controls.ConfirmPossessionButton:SetDisabled(selectionCount <= 0)
    if ultimate then
        local selectedCooldown = Timing(mode, math.max(1, selectionCount))
        Controls.ConfirmPossessionButton:SetToolTipString(selectionCount > 0
            and ("Possess " .. tostring(selectionCount) .. " selected unit" .. (selectionCount == 1 and "" or "s")
                .. ". Cooldown: " .. tostring(selectedCooldown) .. " turns.")
            or "Select at least one target below before confirming.")
    else
        Controls.ConfirmPossessionButton:SetToolTipString(selectedRecord ~= nil
            and ((dominion and "Exchange bodies with " or "Possess ") .. selectedRecord.name .. ". Actions taken are permanent.")
            or "Select a target below before confirming.")
    end
    Controls.NoTargetsLabel:SetHide(#records > 0)
    if active then Controls.NoTargetsLabel:SetText(ultimate and "A mass possession is already active."
        or dominion and "A Body Swap is already active." or "Only one unit may be possessed at a time.")
    elseif cooldown > 0 then Controls.NoTargetsLabel:SetText(ultimate and "Mass Possession is recharging."
        or dominion and "Body Swap is recharging." or "Body Possession is recharging.")
    elseif ultimate then Controls.NoTargetsLabel:SetText("No eligible hostile units are within two tiles of your military network.")
    else Controls.NoTargetsLabel:SetText("No eligible enemy units are within two tiles of Trentrouls.") end
    Layout()
end

local function ClosePanel() ClearSelection() Controls.CommandPanel:SetHide(true) end
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
    if mode == nil or IsCityScreenOpen() or State(mode, playerID, "ACTIVE") == 1
        or State(mode, playerID, "COOLDOWN") > 0 then ClearSelection() RefreshPanel() return end
    if mode == "ultimate" then
        local encoded = {}
        for key, selected in pairs(selectedTargets) do if selected then encoded[#encoded + 1] = key end end
        table.sort(encoded)
        if #encoded > 0 and #encoded <= math.max(1, math.min(8, player:GetCurrentEra() + 1))
            and LuaEvents.UltimateMassPossessionRequest ~= nil then
            ClearSelection()
            LuaEvents.UltimateMassPossessionRequest(playerID, table.concat(encoded, ";"))
        end
        RefreshPanel()
        return
    end
    local trent = FindOwnedTrent(player, mode)
    local owner = selectedOwner ~= nil and Players[selectedOwner] or nil
    local target = owner ~= nil and owner:GetUnitByID(selectedUnit) or nil
    if trent == nil or not Eligible(playerID, mode, trent, target) then ClearSelection() RefreshPanel() return end
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
    if mode == "ultimate" then
        local city = player ~= nil and player:GetCapitalCity() or nil
        if city ~= nil and city:Plot() ~= nil and not IsCityScreenOpen() then ClosePanel() UI.LookAt(city:Plot(), 0) end
    else
        local trent = mode ~= nil and FindTrent(player, mode, playerID) or nil
        Focus(trent, trent ~= nil and trent:GetOwner() == playerID)
    end
end)
Controls.FindBuddyButton:RegisterCallback(Mouse.eLClick, function()
    local playerID, player = Game.GetActivePlayer(), Players[Game.GetActivePlayer()]
    local mode = Mode(player)
    local unit
    if mode == "ultimate" then unit = FindFirstUltimatePossessed(playerID, player) or FindUnit(player, UNIT_GOLDEN_RETRIEVER)
    elseif mode == "dominion" then unit = player:GetUnitByID(State(mode, playerID, "BORROWED_ID"))
    else unit = FindUnit(player, UNIT_BUDDY) end
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
if Events.SerialEventEnterCityScreen ~= nil then Events.SerialEventEnterCityScreen.Add(function()
    cityScreenOpen = true Controls.CommandButton:SetHide(true) ClosePanel()
end) end
if Events.SerialEventExitCityScreen ~= nil then Events.SerialEventExitCityScreen.Add(function()
    cityScreenOpen = false RefreshPanel()
end) end
if LuaEvents.UnaCourtPossessionChanged ~= nil then LuaEvents.UnaCourtPossessionChanged.Add(function() ClearSelection() RefreshPanel() end) end
if LuaEvents.DominionBodySwapChanged ~= nil then LuaEvents.DominionBodySwapChanged.Add(function() ClearSelection() RefreshPanel() end) end
if LuaEvents.UltimatePossessionChanged ~= nil then LuaEvents.UltimatePossessionChanged.Add(function() ClearSelection() RefreshPanel() end) end

RefreshPanel()
print("Shared Una Court command panel initialized")
