include("InstanceManager")
include("IconSupport")
include("FLuaVector")
local manager=InstanceManager:new("PrinceTarget","TargetButton",Controls.Targets)
local snapshot,mode={},nil
local city,diplo,bulk,popup=false,false,false,false
local highlighted={}
-- Use an existing engine highlight style; arbitrary names have no renderer.
local highlightStyle="SampleStaticTexture"
local world=ContextPtr:LookUpControl("/InGame/WorldView")
if world then Controls.Root:ChangeParent(world) end
local function ClearHighlights()
    for _,row in ipairs(highlighted) do
        Events.SerialEventHexHighlight(ToHexFromGrid(Vector2(row.x,row.y)),false,Vector4(0.7,0.4,1,1),highlightStyle)
    end
    highlighted={}
end
local function Close()
    mode=nil; ClearHighlights(); Controls.Panel:SetHide(true)
end
local function Summary(kind,stacks,v)
    return Locale.ConvertTextKey("TXT_KEY_PRINCE_PROGRESS",kind,stacks,v.level,v.duration,v.damage,
        v.strength==math.huge and Locale.ConvertTextKey("TXT_KEY_PRINCE_UNLIMITED") or tostring(v.strength*100).."%")
end
local function Refresh()
    snapshot={}
    local id=Game.GetActivePlayer()
    LuaEvents.PrinceQuery(id,snapshot)
    local selected=UI.GetHeadSelectedUnit()
    local isSelected=selected and selected:GetOwner()==snapshot.bodyOwner and selected:GetID()==snapshot.bodyID
    local show=snapshot.enabled and (isSelected or snapshot.kind) and not city and not diplo and not bulk and not popup
    Controls.Open:SetHide(not show)
    if not show then Close(); return end
    Controls.Open:SetText(Locale.ConvertTextKey("TXT_KEY_PRINCE_PANEL").." ("..snapshot.cooldown..")")
    if Controls.Panel:IsHidden() then return end
    IconHookup(4,64,"PRINCE_ATLAS",Controls.Ability)
    Controls.Active:SetText(snapshot.kind and Locale.ConvertTextKey("TXT_KEY_PRINCE_ACTIVE",snapshot.kind,snapshot.remaining)
        or Locale.ConvertTextKey("TXT_KEY_PRINCE_COOLDOWN",snapshot.cooldown))
    local text=Summary(Locale.ConvertTextKey("TXT_KEY_PRINCE_POSSESS"),snapshot.possession,snapshot.possessValues)
        .."[NEWLINE][NEWLINE]"..Summary(Locale.ConvertTextKey("TXT_KEY_PRINCE_SWAP"),snapshot.swap,snapshot.swapValues)
        .."[NEWLINE]"..Locale.ConvertTextKey("TXT_KEY_PRINCE_RESISTANCE",snapshot.swapValues.resistance)
    if snapshot.kind then
        text=text.."[NEWLINE]"..Locale.ConvertTextKey("TXT_KEY_PRINCE_LOCKED_VALUES",snapshot.damage,snapshot.resistance)
    end
    Controls.Summary:SetText(text)
    local ready=not snapshot.kind and snapshot.cooldown==0 and isSelected
    Controls.Possess:SetDisabled(not ready); Controls.Swap:SetDisabled(not ready)
    Controls.Hint:SetText(Locale.ConvertTextKey(mode and "TXT_KEY_PRINCE_CHOOSE_TARGET" or "TXT_KEY_PRINCE_CHOOSE_TECHNIQUE"))
    ClearHighlights(); manager:ResetInstances()
    for _,row in ipairs(snapshot.targets or {}) do
        local item=manager:GetInstance()
        local valid=mode and row[mode]
        item.Name:SetText(row.name.."  "..row.strength.."[ICON_STRENGTH]")
        local reason=mode=="swap" and row.whySwap or row.whyPossess
        item.Status:SetText(reason)
        item.TargetButton:SetDisabled(not valid)
        item.TargetButton:SetToolTipString(reason)
        local target=row
        item.TargetButton:RegisterCallback(Mouse.eLClick,function()
            if mode and target[mode] then
                LuaEvents.PrinceRequest(id,mode,target.owner,target.id)
                Close(); Refresh()
            end
        end)
        if valid then
            Events.SerialEventHexHighlight(ToHexFromGrid(Vector2(row.x,row.y)),true,Vector4(0.7,0.4,1,1),highlightStyle)
            highlighted[#highlighted+1]=row
        end
    end
    Controls.Targets:CalculateSize(); Controls.Targets:ReprocessAnchoring(); Controls.Scroll:CalculateInternalSize()
end
Controls.Open:RegisterCallback(Mouse.eLClick,function() Controls.Panel:SetHide(false); Refresh() end)
Controls.Close:RegisterCallback(Mouse.eLClick,Close)
Controls.Possess:RegisterCallback(Mouse.eLClick,function() mode="possess"; Refresh() end)
Controls.Swap:RegisterCallback(Mouse.eLClick,function() mode="swap"; Refresh() end)
ContextPtr:SetInputHandler(function(message,key)
    if message==KeyEvents.KeyDown and key==Keys.VK_ESCAPE and not Controls.Panel:IsHidden() then Close(); return true end
    return false
end)
-- Event-driven: no SetUpdate, timers or polling. Parent WorldView/BulkUI and
-- explicit diplomacy/popup events hide the panel with other native controls.
LuaEvents.PrinceChanged.Add(Refresh)
Events.UnitSelectionChanged.Add(Refresh)
Events.SerialEventUnitInfoDirty.Add(Refresh)
Events.ActivePlayerTurnStart.Add(Refresh)
Events.GameplaySetActivePlayer.Add(function() Close(); Refresh() end)
Events.SerialEventEnterCityScreen.Add(function() city=true; Refresh() end)
Events.SerialEventExitCityScreen.Add(function() city=false; Refresh() end)
Events.AILeaderMessage.Add(function() diplo=true; Refresh() end)
Events.LeavingLeaderViewMode.Add(function() diplo=false; Refresh() end)
Events.SerialEventGameMessagePopupShown.Add(function() popup=true; Close(); Refresh() end)
Events.SerialEventGameMessagePopupProcessed.Add(function() popup=false; Refresh() end)
Events.SystemUpdateUI.Add(function(kind)
    if kind==SystemUpdateUIType.BulkHideUI then bulk=true
    elseif kind==SystemUpdateUIType.BulkShowUI then bulk=false end
    Refresh()
end)
Refresh()
