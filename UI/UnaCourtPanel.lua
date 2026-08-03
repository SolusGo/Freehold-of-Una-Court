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
    if target == nil or trent == nil or target:GetOwner() == playerID then return false end
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

local function UnitLabel(target)
    local owner = Players[target:GetOwner()]
    local strength = math.max(target:GetBaseCombatStrength(), target:GetBaseRangedCombatStrength())
    local ownerName = owner ~= nil and owner:GetName() or "Unknown"
    return string.format("[ICON_STRENGTH] %s  |  %s  |  %d  |  (%d,%d)",
        target:GetName(), ownerName, strength, target:GetX(), target:GetY())
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

    Controls.StatusLabel:SetString(
        "Trentrouls: " .. trentState .. "[NEWLINE]" ..
        "Buddy: " .. buddyState .. "[NEWLINE]" ..
        "Empire bonus: " .. (eraBonus > 0 and ("+" .. tostring(eraBonus) .. "% to all core yields and Great People") or "Inactive") .. "[NEWLINE]" ..
        "Body Possession: " .. possessionState
    )

    targetManager:ResetInstances()
    local targetCount = 0
    if trent ~= nil and not active and cooldown <= 0 then
        for otherPlayerID = 0, (GameDefines.MAX_CIV_PLAYERS or 63) - 1 do
            local otherPlayer = Players[otherPlayerID]
            if otherPlayer ~= nil and otherPlayer:IsAlive() and otherPlayerID ~= playerID then
                for target in otherPlayer:Units() do
                    if IsEligible(playerID, trent, target) then
                        targetCount = targetCount + 1
                        local instance = targetManager:GetInstance()
                        instance.TargetButton:SetText(UnitLabel(target))
                        instance.TargetButton:SetToolTipString("Temporarily transfer this unit to Una Court. Actions taken while possessed are permanent.")
                        local targetOwnerID = target:GetOwner()
                        local targetUnitID = target:GetID()
                        instance.TargetButton:RegisterCallback(Mouse.eLClick, function()
                            LuaEvents.UnaCourtPossessRequest(playerID, trent:GetID(), targetOwnerID, targetUnitID)
                            RefreshPanel()
                        end)
                    end
                end
            end
        end
    end

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

local function FocusUnit(unitType)
    local player = Players[Game.GetActivePlayer()]
    if not IsUnaPlayer(player) or IsCityScreenOpen() then return end

    local unit = FindUnit(player, unitType)
    if unit == nil then
        RefreshPanel()
        return
    end

    local plot = unit:GetPlot()
    Controls.CommandPanel:SetHide(true)
    if plot ~= nil then UI.LookAt(plot, 0) end
    UI.SelectUnit(unit)
end

local function TogglePanel()
    if IsCityScreenOpen() then
        Controls.CommandPanel:SetHide(true)
        return
    end
    if Controls.CommandPanel:IsHidden() then
        RefreshPanel()
        Controls.CommandPanel:SetHide(false)
    else
        Controls.CommandPanel:SetHide(true)
    end
end

Controls.CommandButton:RegisterCallback(Mouse.eLClick, TogglePanel)
Controls.FindTrentButton:RegisterCallback(Mouse.eLClick, function() FocusUnit(UNIT_TRENT) end)
Controls.FindBuddyButton:RegisterCallback(Mouse.eLClick, function() FocusUnit(UNIT_BUDDY) end)
Controls.RefreshButton:RegisterCallback(Mouse.eLClick, RefreshPanel)
Controls.CloseButton:RegisterCallback(Mouse.eLClick, function() Controls.CommandPanel:SetHide(true) end)

ContextPtr:SetInputHandler(function(uiMsg, wParam)
    if uiMsg == KeyEvents.KeyDown and wParam == Keys.VK_ESCAPE and not Controls.CommandPanel:IsHidden() then
        Controls.CommandPanel:SetHide(true)
        return true
    end
    return false
end)

if Events.ActivePlayerTurnStart ~= nil then Events.ActivePlayerTurnStart.Add(RefreshPanel) end
if Events.SerialEventUnitInfoDirty ~= nil then Events.SerialEventUnitInfoDirty.Add(RefreshPanel) end
if Events.SerialEventUnitCreated ~= nil then Events.SerialEventUnitCreated.Add(RefreshPanel) end
if Events.SerialEventEnterCityScreen ~= nil then
    Events.SerialEventEnterCityScreen.Add(function()
        cityScreenOpen = true
        Controls.CommandButton:SetHide(true)
        Controls.CommandPanel:SetHide(true)
    end)
end
if Events.SerialEventExitCityScreen ~= nil then
    Events.SerialEventExitCityScreen.Add(function()
        cityScreenOpen = false
        RefreshPanel()
    end)
end
if LuaEvents.UnaCourtPossessionChanged ~= nil then LuaEvents.UnaCourtPossessionChanged.Add(RefreshPanel) end

RefreshPanel()
print("Una Court command panel initialized")
