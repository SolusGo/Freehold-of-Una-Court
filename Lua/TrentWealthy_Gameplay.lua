-- Wealthy Trent: real treasury transfers and idempotent Palace reconciliation.
-- Only PlayerDoTurn advances collection. Activation T gives immediate Gold;
-- installments occur on Trent's T+1..T+5. UI/load/era/capture never levy Gold.
MapModData.TrentWealthy = MapModData.TrentWealthy or {}
local API = MapModData.TrentWealthy
if API.RuntimeLoaded then return end
API.RuntimeLoaded = true
local CIV = GameInfoTypes.CIVILIZATION_TRENT_WEALTHY
if not CIV then return end
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
local function RefreshPalaces()
    local palace = GameInfoTypes.BUILDING_TRENT_WEALTHY_PALACE
    local ordinary = GameInfoTypes.BUILDING_PALACE
    for id = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        local p = Players[id]
        if p then
            local wealthy = IsTrent(p) and p:IsAlive()
            if IsTrent(p) and not p:IsAlive() then Clear(id) end
            local capital = wealthy and p:GetCapitalCity() or nil
            local level = math.min(8, math.max(1, p:GetCurrentEra()+1))
            for city in p:Cities() do
                local isCapital = capital and city:GetID() == capital:GetID()
                -- Never replace or remove another civilization's normal Palace.
                SetBuilding(city,palace,isCapital and 1 or 0)
                if wealthy and city:GetNumRealBuilding(ordinary)>0 then SetBuilding(city,ordinary,0) end
                for tier=1,8 do
                    SetBuilding(city,GameInfoTypes['BUILDING_TRENT_WEALTHY_LUXURY_'..tier],
                        isCapital and tier==level and 1 or 0)
                end
            end
        end
    end
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
    if turn >= nextTurn then
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
local exists = false
for id=0,GameDefines.MAX_MAJOR_CIVS-1 do if IsTrent(Players[id]) then exists=true end end
if not exists then return end
for id=0,GameDefines.MAX_MAJOR_CIVS-1 do
    if IsTrent(Players[id]) and Read(id,'NEXT',nil)==nil then
        Write(id,'NEXT',Game.GetGameTurn()+Interval())
    end
end
GameEvents.PlayerDoTurn.Add(function(id) RefreshPalaces(); Process(id) end)
-- Events reconcile state only; they never advance installment counters.
GameEvents.TeamSetEra.Add(RefreshPalaces)
GameEvents.CityCaptureComplete.Add(RefreshPalaces)
GameEvents.PlayerCityFounded.Add(RefreshPalaces)
Events.LoadScreenClose.Add(RefreshPalaces)
RefreshPalaces()
API.Interval, API.Targets, API.RefreshPalaces = Interval, Targets, RefreshPalaces
