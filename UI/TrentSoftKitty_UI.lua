include("InstanceManager")
include("IconSupport")
local manager = InstanceManager:new("SoftKittyAudience", "AudienceButton", Controls.AudienceStack)
local cityOpen, mode, selected, concertUnit = false, "sing", nil, -1
local snapshot, rows, refreshPending = {}, {}, true
local function Close()
    selected = nil
    Controls.Panel:SetHide(true)
end
local function UnitID()
    local unit = UI.GetHeadSelectedUnit()
    return unit and unit:GetOwner() == Game.GetActivePlayer() and unit:GetID() or -1
end
local function CityScreen()
    return cityOpen or (UI.IsCityScreenUp and UI.IsCityScreenUp())
end
local function Select(row)
    selected = row
    local ex = row.ex and " [COLOR_NEGATIVE_TEXT](The Ex)[ENDCOLOR]" or ""
    Controls.Confirmation:SetText("Serenade " .. row.name .. ex .. "?[NEWLINE]Reward: " .. row.culture
        .. " [ICON_CULTURE] Culture / " .. row.tourism .. " [ICON_TOURISM] Tourism"
        .. "[NEWLINE]Repercussion chance: " .. row.risk .. "%" .. (mode == "romantic" and " | Consumes this musician." or ""))
    Controls.Confirm:SetDisabled(mode == "sing" and (snapshot.cooldown > 0 or snapshot.recovery > 0))
end
local function Refresh()
    local id = Game.GetActivePlayer()
    local unitID = mode == "romantic" and concertUnit or UnitID()
    snapshot = {}
    LuaEvents.TrentSoftKittyQuery(id, unitID, snapshot)
    local show = snapshot.enabled and not CityScreen()
    Controls.SingButton:SetHide(not show)
    Controls.RomanticButton:SetHide(not show or not snapshot.unitValid)
    if not show then Close() return end
    local recovery = snapshot.recovery or 0
    local cooldown = snapshot.cooldown or 0
    Controls.SingButton:SetText(recovery > 0 and "Repercussions: " .. recovery .. " turns"
        or cooldown > 0 and "Soft Kitty: " .. cooldown .. " turns" or "[ICON_GREAT_WORK_MUSIC] Sing Soft Kitty")
    local tooltip = "Sing Soft Kitty: " .. (cooldown > 0 and cooldown .. " turns remaining" or "Ready")
    if recovery > 0 then
        tooltip = tooltip .. "[NEWLINE][NEWLINE]Trent is recovering: " .. recovery .. " turns remaining."
            .. "[NEWLINE]-" .. snapshot.penalty .. "% Production / -10% military Combat Strength"
            .. "[NEWLINE]-20% Great Person generation"
            .. "[NEWLINE]Newly trained land/naval military units: -1 Movement."
            .. "[NEWLINE]Comfort Rooms reduce the Production penalty and gain +3 Culture."
    end
    Controls.SingButton:SetToolTipString(tooltip)
    Controls.RomanticButton:SetToolTipString("Select a met, peaceful major civilization with a city adjacent to this Hopeless Romantic. Serenade consumes the unit.")
    if Controls.Panel:IsHidden() then return end
    Controls.Title:SetText(mode == "romantic" and "HOPELESS ROMANTIC" or "SING SOFT KITTY")
    Controls.Subtitle:SetText(mode == "romantic" and "One final verse. Choose a nearby city." or "Friendship makes a receptive audience.")
    IconHookup(recovery > 0 and 5 or mode == "romantic" and 2 or 4, 64, "SOFT_KITTY_ATLAS", Controls.AbilityIcon)
    Controls.Status:SetText("Soft Kitty: " .. (cooldown > 0 and cooldown .. " turns remaining" or "Ready")
        .. "[NEWLINE]" .. (recovery > 0 and "Repercussions: " .. recovery .. " turns | -" .. snapshot.penalty .. "% Production"
            or "Trent is feeling inspired.") .. "[NEWLINE]Comfort Rooms: " .. snapshot.comfort)
    Controls.Status:SetToolTipString(tooltip)
    rows = mode == "romantic" and snapshot.romantics or snapshot.targets
    manager:ResetInstances()
    local oldID = selected and selected.id
    selected = nil
    Controls.Confirm:SetDisabled(true)
    Controls.Confirmation:SetText(mode == "romantic"
        and "Select an audience. The musician is consumed; rewards are granted even if Hostile backlash occurs."
        or "Select an audience. Rewards are granted on success; a failed song causes Repercussions instead.")
    for _, row in ipairs(rows) do
        local item = manager:GetInstance()
        item.AudienceName:SetText(row.name .. (row.ex and " [COLOR_NEGATIVE_TEXT](The Ex)[ENDCOLOR]" or ""))
        item.AudienceDetails:SetText(row.leader .. " | " .. row.relationship .. " | Risk " .. row.risk .. "%[NEWLINE]"
            .. row.culture .. " [ICON_CULTURE] Culture  +  " .. row.tourism .. " [ICON_TOURISM] Tourism")
        item.AudienceButton:SetToolTipString(row.relationship .. ": " .. row.risk .. "% chance of Repercussions."
            .. (row.ex and " This civilization is permanently The Ex." or ""))
        local target = row
        item.AudienceButton:RegisterCallback(Mouse.eLClick, function() Select(target) end)
        if row.id == oldID then Select(row) end
    end
    Controls.Empty:SetHide(#rows > 0)
    Controls.Empty:SetText(mode == "romantic"
        and "No eligible foreign city is adjacent to this musician. Move beside a city of a met civilization at peace with you."
        or "No eligible audience. Meet another living major civilization at peace with you.")
    Controls.AudienceStack:CalculateSize()
    Controls.AudienceStack:ReprocessAnchoring()
    Controls.AudienceScroll:CalculateInternalSize()
    Controls.Confirm:SetText(mode == "romantic" and "Serenade (consume unit)" or "Sing")
end
Controls.SingButton:RegisterCallback(Mouse.eLClick, function()
    mode, selected, concertUnit = "sing", nil, -1
    Controls.Panel:SetHide(false) Refresh()
end)
Controls.RomanticButton:RegisterCallback(Mouse.eLClick, function()
    mode, selected, concertUnit = "romantic", nil, UnitID()
    Controls.Panel:SetHide(false) Refresh()
end)
Controls.Cancel:RegisterCallback(Mouse.eLClick, Close)
Controls.Confirm:RegisterCallback(Mouse.eLClick, function()
    if not selected then return end
    local row = selected
    local unit = mode == "romantic" and concertUnit or -1
    Close()
    LuaEvents.TrentSoftKittyRequest(Game.GetActivePlayer(), row.id, unit, row.culture, row.tourism, row.risk)
    Refresh()
end)
ContextPtr:SetInputHandler(function(message, key)
    if message == KeyEvents.KeyDown and key == Keys.VK_ESCAPE and not Controls.Panel:IsHidden() then Close() return true end
    return false
end)
local function QueueRefresh() refreshPending = true end
LuaEvents.TrentSoftKittyChanged.Add(QueueRefresh)
Events.ActivePlayerTurnStart.Add(QueueRefresh)
Events.SerialEventUnitInfoDirty.Add(QueueRefresh)
Events.SerialEventUnitCreated.Add(QueueRefresh)
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
