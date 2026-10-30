-- Wealthy Trent: real treasury transfers and idempotent Palace reconciliation.
-- Only PlayerDoTurn advances collection. Activation T gives immediate Gold;
-- installments occur on Trent's T+1..T+5. UI/load/era/capture never levy Gold.
MapModData.TrentWealthy = MapModData.TrentWealthy or {}
local API = MapModData.TrentWealthy
if API.RuntimeLoaded then return end
API.RuntimeLoaded = true
local CIV = GameInfoTypes.CIVILIZATION_TRENT_WEALTHY
if not CIV then return end
local wealthyIDs = {}
for id=0,GameDefines.MAX_MAJOR_CIVS-1 do
    if Players[id] and Players[id]:GetCivilizationType()==CIV then
        wealthyIDs[#wealthyIDs+1] = id
    end
end
if #wealthyIDs==0 then return end
local SAVE = Modding.OpenSaveData()
local PREFIX = 'TRENT_WEALTHY_V1_'
local function Read(id, name, fallback)
    local n = tonumber(SAVE.GetValue(PREFIX .. id .. '_' .. name))
    if n == nil then return fallback end
    return n
end
local function Write(id, name, n) SAVE.SetValue(PREFIX .. id .. '_' .. name, n) end
local function IsTrent(p) return p and p:GetCivilizationType() == CIV end
local function Major(p) return p and not p:IsMinorCiv() and not p:IsBarbarian() end
local function Interval()
    local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    return math.max(1, math.floor(25 * (speed and speed.TrainPercent or 100) / 100 + 0.5))
end
local function Notify(p, title, body)
    if p and p:IsHuman() then
        p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, body,
            Locale.ConvertTextKey(title), -1, -1)
    end
end
local function Transfer(victim, trent, requested)
    local amount = math.max(0, math.min(math.floor(requested), math.floor(victim:GetGold())))
    if amount > 0 then
        victim:ChangeGold(-amount)
        trent:ChangeGold(amount)
    end
    return amount
end
local function Targets(p)
    local all = {}
    for id = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local other = Players[id]
        if id ~= p:GetID() and Major(other) and other:IsAlive()
            and Teams[p:GetTeam()]:IsHasMet(other:GetTeam()) then
            all[#all+1] = {id=id, gold=other:GetGold()}
        end
    end
    table.sort(all, function(a,b) return a.gold > b.gold or (a.gold == b.gold and a.id < b.id) end)
    local chosen = {}
    for i = 1, math.ceil(#all / 3) do
        local item = all[i]
        if item.gold >= 500 and Players[item.id]:CalculateGoldRate() >= 10 and #chosen < 2 then
            chosen[#chosen+1] = item.id
        end
    end
    return chosen
end
local function Clear(id)
    Write(id,'REMAINING',0)
    for slot=1,2 do Write(id,'TARGET'..slot,-1) end
end
local function SetBuilding(city, kind, count)
    if kind and city:GetNumRealBuilding(kind) ~= count then city:SetNumRealBuilding(kind,count) end
end
local PALACE = GameInfoTypes.BUILDING_TRENT_WEALTHY_PALACE
local ORDINARY = GameInfoTypes.BUILDING_PALACE
local tiers = {}
for tier=1,8 do tiers[tier]=GameInfoTypes['BUILDING_TRENT_WEALTHY_LUXURY_'..tier] end
-- Runtime coordinates only: a captured city receives a new owner-local ID and
-- old city userdata can become invalid. Native buildings remain the save state.
local capitals, alive = {}, {}
local function CityAt(x,y)
    local plot = Map.GetPlot(x,y)
    return plot and plot:GetPlotCity() or nil
end
local function ReconcileCity(city, wealthy, capital, level)
    local isCapital = capital and city:GetOwner()==capital:GetOwner() and city:GetID()==capital:GetID()
    -- Remove duplicates first, then install the native Palace and one total tier.
    if wealthy then SetBuilding(city,ORDINARY,0) end
    SetBuilding(city,PALACE,isCapital and 1 or 0)
    for tier=1,8 do SetBuilding(city,tiers[tier],isCapital and tier==level and 1 or 0) end
end
local function RefreshPalaces(id)
    local p = Players[id]
    if not IsTrent(p) then return end
    local living = p:IsAlive()
    if not living and alive[id]~=false then Clear(id) end
    alive[id] = living
    local capital = living and p:GetCapitalCity() or nil
    local level = math.min(8,math.max(1,p:GetCurrentEra()+1))
    local previous = capitals[id]
    if previous then
        local old = CityAt(previous.x,previous.y)
        if old and old:GetOwner()~=id then
            local owner = Players[old:GetOwner()]
            local ownCapital = IsTrent(owner) and owner:IsAlive() and owner:GetCapitalCity() or nil
            ReconcileCity(old,IsTrent(owner),ownCapital,
                ownCapital and math.min(8,math.max(1,owner:GetCurrentEra()+1)) or 0)
        end
    end
    for city in p:Cities() do ReconcileCity(city,true,capital,level) end
    capitals[id] = capital and {x=capital:GetX(),y=capital:GetY()} or nil
end
local function RestorePalaces()
    -- One world cleanup on initialization/load repairs even stale foreign tiers
    -- from an older save. Ordinary turns never iterate foreign city collections.
    for id=0,GameDefines.MAX_CIV_PLAYERS-1 do
        local p = Players[id]
        if IsTrent(p) then RefreshPalaces(id)
        elseif p then
            for city in p:Cities() do ReconcileCity(city,false,nil,0) end
        end
    end
end
local function CheckLifeChanges()
    -- No player-alive event is assumed. This costs one IsAlive per Wealthy
    -- player; only a transition can trigger a city scan on somebody else's turn.
    for _,id in ipairs(wealthyIDs) do
        if Players[id]:IsAlive()~=alive[id] then RefreshPalaces(id) end
    end
end
local function OnCapture(oldOwner, wasCapital, x, y, newOwner)
    if IsTrent(Players[oldOwner]) then RefreshPalaces(oldOwner) end
    if newOwner~=oldOwner and IsTrent(Players[newOwner]) then RefreshPalaces(newOwner) end
    -- Includes gifts, liberation and city trades, not only military conquest.
    local city = CityAt(x,y)
    if city and not IsTrent(Players[city:GetOwner()]) then ReconcileCity(city,false,nil,0) end
end
local function Process(id)
    local p = Players[id]
    if not IsTrent(p) then return end
    if not p:IsAlive() then Clear(id); return end
    local turn = Game.GetGameTurn()
    if Read(id,'LAST',-1) >= turn then return end
    Write(id,'LAST',turn) -- persisted before mutation; callbacks cannot re-enter
    local remaining = Read(id,'REMAINING',0)
    if remaining > 0 then
        local report = {}
        for slot=1,2 do
            local target = Read(id,'TARGET'..slot,-1)
            local victim = target>=0 and Players[target] or nil
            if Major(victim) and victim:IsAlive() then
                local amount = Transfer(victim,p,math.floor(math.max(0,victim:CalculateGoldRate())*20/100))
                local line = Locale.ConvertTextKey('TXT_KEY_WEALTHY_PAYMENT_LINE',
                    victim:GetCivilizationShortDescription(),amount,remaining-1)
                report[#report+1] = line
                Notify(victim,'TXT_KEY_WEALTHY_CONTRIBUTION_TITLE',line)
            else
                Write(id,'TARGET'..slot,-1) -- eliminated targets never resume this cycle
            end
        end
        Write(id,'REMAINING',remaining-1)
        if #report>0 then Notify(p,'TXT_KEY_WEALTHY_REPORT_TITLE',table.concat(report,'[NEWLINE]')) end
    end
    local nextTurn = Read(id,'NEXT',nil)
    if not nextTurn then
        -- Stable global cadence, including advanced-era starts.
        nextTurn = turn + Interval()
        Write(id,'NEXT',nextTurn)
    end
    -- A missed callback must not let the next audit erase unfinished payments.
    if turn >= nextTurn and Read(id,'REMAINING',0)==0 then
        Clear(id)
        Write(id,'NEXT',turn+Interval())
        local chosen, report = Targets(p), {}
        for slot,target in ipairs(chosen) do
            Write(id,'TARGET'..slot,target)
            local victim = Players[target]
            local amount = Transfer(victim,p,math.floor(victim:GetGold()*5/100))
            local line = Locale.ConvertTextKey('TXT_KEY_WEALTHY_INITIAL_LINE',victim:GetCivilizationShortDescription(),amount)
            report[#report+1] = line
            Notify(victim,'TXT_KEY_WEALTHY_CONTRIBUTION_TITLE',
                Locale.ConvertTextKey('TXT_KEY_WEALTHY_CONTRIBUTION_BODY')..'[NEWLINE]'..line)
        end
        if #chosen>0 then
            Write(id,'REMAINING',5)
            Notify(p,'TXT_KEY_WEALTHY_AUDIT_TITLE',Locale.ConvertTextKey('TXT_KEY_WEALTHY_AUDIT_BODY')
                ..'[NEWLINE]'..table.concat(report,'[NEWLINE]'))
        end
    end
end
for _,id in ipairs(wealthyIDs) do
    if Read(id,'NEXT',nil)==nil then
        Write(id,'NEXT',Game.GetGameTurn()+Interval())
    end
end
GameEvents.PlayerDoTurn.Add(function(id)
    CheckLifeChanges()
    if IsTrent(Players[id]) then RefreshPalaces(id); Process(id) end
end)
-- Events reconcile state only; they never advance installment counters.
GameEvents.TeamSetEra.Add(function(team)
    for _,id in ipairs(wealthyIDs) do if Players[id]:GetTeam()==team then RefreshPalaces(id) end end
end)
GameEvents.CityCaptureComplete.Add(OnCapture)
GameEvents.PlayerCityFounded.Add(function(id) RefreshPalaces(id) end)
Events.LoadScreenClose.Add(RestorePalaces)
RestorePalaces()
API.Interval, API.Targets, API.RefreshPalaces = Interval, Targets, RefreshPalaces
