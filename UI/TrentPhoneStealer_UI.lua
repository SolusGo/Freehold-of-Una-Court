include("InstanceManager")
include("IconSupport")

local manager = InstanceManager:new("PhoneStashEntry", "PhoneButton", Controls.PhoneStack)
local snapshot, selected, cityOpen, refreshPending = {}, nil, false, true

local function CityScreen()
    return cityOpen or (UI.IsCityScreenUp and UI.IsCityScreenUp())
end

local function Close()
    selected = nil
    Controls.Panel:SetHide(true)
end

local function Select(row)
    selected = row.action and row or nil
    if row.action == "snatch" then
        Controls.Confirmation:SetText("Begin Snatch Phone against " .. row.name
            .. "?[NEWLINE]The Spy must remain established in the Capital until the mission completes.")
        Controls.Confirm:SetText("Begin Snatch Phone")
        Controls.Confirm:SetDisabled(false)
    elseif row.action == "return" then
        Controls.Confirmation:SetText("Return " .. row.name .. "'s Phone?[NEWLINE]"
            .. "Its yields and diplomatic grievance end immediately; it gains temporary protection.")
        Controls.Confirm:SetText("Return Phone")
        Controls.Confirm:SetDisabled(false)
    else
        Controls.Confirmation:SetText(row.name .. "[NEWLINE]" .. row.status)
        Controls.Confirm:SetText("No action available")
        Controls.Confirm:SetDisabled(true)
    end
end

local function Refresh()
    snapshot = {}
    LuaEvents.TrentPhoneStealerQuery(Game.GetActivePlayer(), snapshot)
    local show = snapshot.enabled and not CityScreen()
    Controls.StashButton:SetHide(not show)
    if not show then Close() return end
    Controls.StashButton:SetText("[ICON_SPY] Phone Stash: " .. snapshot.count .. "/" .. snapshot.total)
    Controls.StashButton:SetToolTipString("Open the Phone Stash. Each Phone provides +2 Science, +2 Gold and +1 Culture in the Capital; every three provide +1 Happiness.")
    if Controls.Panel:IsHidden() then return end

    IconHookup(0, 64, "PHONE_STEALER_ABILITY_ATLAS", Controls.AbilityIcon)
    Controls.Summary:SetText("Phone Stash — " .. snapshot.count .. " / " .. snapshot.total .. " Phones"
        .. "[NEWLINE]+" .. snapshot.science .. " [ICON_RESEARCH]  +" .. snapshot.gold .. " [ICON_GOLD]  +"
        .. snapshot.culture .. " [ICON_CULTURE]  +" .. snapshot.happiness .. " [ICON_HAPPINESS_1]")

    local oldID = selected and selected.id
    selected = nil
    Controls.Confirm:SetDisabled(true)
    Controls.Confirm:SetText("Confirm")
    Controls.Confirmation:SetText("Select a civilization. Established Spies can begin Snatch Phone; stolen Phones may be returned.")
    manager:ResetInstances()
    for _, row in ipairs(snapshot.targets or {}) do
        local item = manager:GetInstance()
        item.CivilizationName:SetText(row.name .. (row.stolen and "  [COLOR_POSITIVE_TEXT][ICON_SPY] STOLEN[ENDCOLOR]" or ""))
        item.PhoneStatus:SetText(row.leader .. " | " .. row.status)
        item.PhoneButton:SetToolTipString(row.status)
        local target = row
        item.PhoneButton:RegisterCallback(Mouse.eLClick, function() Select(target) end)
        if row.id == oldID then Select(row) end
    end
    Controls.Empty:SetHide(#(snapshot.targets or {}) > 0)
    Controls.PhoneStack:CalculateSize()
    Controls.PhoneStack:ReprocessAnchoring()
    Controls.PhoneScroll:CalculateInternalSize()
end

Controls.StashButton:RegisterCallback(Mouse.eLClick, function()
    selected = nil
    Controls.Panel:SetHide(false)
    Refresh()
end)
Controls.Cancel:RegisterCallback(Mouse.eLClick, Close)
Controls.Confirm:RegisterCallback(Mouse.eLClick, function()
    if selected == nil or selected.action == nil then return end
    local row = selected
    Close()
    LuaEvents.TrentPhoneStealerRequest(Game.GetActivePlayer(), row.id, row.action)
    Refresh()
end)

ContextPtr:SetInputHandler(function(message, key)
    if message == KeyEvents.KeyDown and key == Keys.VK_ESCAPE and not Controls.Panel:IsHidden() then
        Close()
        return true
    end
    return false
end)

local function QueueRefresh() refreshPending = true end
LuaEvents.TrentPhoneStealerChanged.Add(QueueRefresh)
Events.ActivePlayerTurnStart.Add(QueueRefresh)
Events.SerialEventUnitInfoDirty.Add(QueueRefresh)
Events.SerialEventEnterCityScreen.Add(function() cityOpen = true Close() Refresh() end)
Events.SerialEventExitCityScreen.Add(function() cityOpen = false QueueRefresh() end)
if Events.GameplaySetActivePlayer then Events.GameplaySetActivePlayer.Add(function() Close() QueueRefresh() end) end

local elapsed = 0
ContextPtr:SetUpdate(function(delta)
    elapsed = elapsed + delta
    if refreshPending and elapsed >= 0.25 then
        refreshPending, elapsed = false, 0
        Refresh()
    end
end)

Refresh()
