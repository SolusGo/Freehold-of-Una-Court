-- Trent, the Phone Stealer: foreign-capital missions, Phone Stash and loyal Butlers.
MapModData.TrentPhoneStealer = MapModData.TrentPhoneStealer or {}
local API = MapModData.TrentPhoneStealer
if API.RuntimeLoaded then return end
API.RuntimeLoaded = true

local function ID(name) return GameInfoTypes[name] end
local CIV = ID("CIVILIZATION_TRENT_PHONE_STEALER")
local BUTLER = ID("UNIT_TRENT_UNA_COURT_BUTLER")
local DIPLO = ID("DIPLOMODIFIER_TRENT_STOLE_PHONE")
local SAVE = Modding.OpenSaveData()
local MAX_PHONES = 21
local MISSION_TURNS = 8
local RETURN_TURNS = 30
local queuedButlers = {}

local function Truth(value) return value == true or value == 1 end
local function Turn() return Game.GetGameTurn() end
local function IsMajorID(value)
    return type(value) == "number" and value >= 0 and value < GameDefines.MAX_MAJOR_CIVS
end
local function IsTrent(player)
    if type(player) == "number" then player = Players[player] end
    return player ~= nil and CIV ~= nil and player:GetCivilizationType() == CIV
end
local function IsEverAlive(player)
    if player == nil then return false end
    if player.IsEverAlive then return player:IsEverAlive() end
    return player:IsAlive()
end
local function Scale(value)
    local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    return math.max(1, math.floor(value * (speed and speed.TrainPercent or 100) / 100 + 0.5))
end
local function Key(name, first, second)
    local value = "TRENT_PHONE_V1_" .. name .. "_" .. tostring(first)
    return second == nil and value or value .. "_" .. tostring(second)
end
local function Read(name, first, second, fallback)
    local value = tonumber(SAVE.GetValue(Key(name, first, second)))
    return value == nil and (fallback or 0) or value
end
local function Write(name, first, second, value)
    SAVE.SetValue(Key(name, first, second), value)
end
local function PhoneOwner(targetID)
    return Read("OWNER", targetID, nil, 0) - 1
end
local function SetPhoneOwner(targetID, ownerID)
    Write("OWNER", targetID, nil, ownerID + 1)
end
local function MissionStart(playerID, targetID)
    return Read("MISSION", playerID, targetID, -1)
end
local function SetMissionStart(playerID, targetID, value)
    Write("MISSION", playerID, targetID, value)
end
local function Cooldown(targetID)
    return math.max(0, Read("RETURN", targetID) - Turn())
end
local function Notify(playerID, titleKey, bodyKey, x, y, ...)
    local player = Players[playerID]
    if player == nil or not player:IsHuman() then return end
    local body = Locale.ConvertTextKey(bodyKey, ...)
    local title = Locale.ConvertTextKey(titleKey)
    if player.AddNotification and NotificationTypes then
        player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, body, title, x or -1, y or -1)
    elseif Events and Events.GameplayAlertMessage then
        Events.GameplayAlertMessage(title .. ": " .. body)
    end
end
local function Changed()
    if LuaEvents and LuaEvents.TrentPhoneStealerChanged then LuaEvents.TrentPhoneStealerChanged() end
end

local function EstablishedSpy(playerID, targetID)
    local player, target = Players[playerID], Players[targetID]
    if player == nil or target == nil or not target:IsAlive() or player.GetEspionageSpies == nil then return false end
    local capital = target:GetCapitalCity()
    if capital == nil then return false end
    for _, spy in ipairs(player:GetEspionageSpies() or {}) do
        if spy.CityX == capital:GetX() and spy.CityY == capital:GetY()
            and not Truth(spy.IsDiplomat) and Truth(spy.EstablishedSurveillance) then
            return true
        end
    end
    return false
end

local function PhoneCount(playerID)
    local count = 0
    for targetID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        if PhoneOwner(targetID) == playerID then count = count + 1 end
    end
    return count
end

local function RefreshStash(playerID)
    local player = Players[playerID]
    if not IsTrent(player) then return end
    local count = math.min(MAX_PHONES, PhoneCount(playerID))
    local capital = player:GetCapitalCity()
    for city in player:Cities() do
        for index = 1, MAX_PHONES do
            local building = ID("BUILDING_TRENT_PHONE_STASH_" .. tostring(index))
            if building ~= nil then city:SetNumRealBuilding(building, city == capital and index == count and 1 or 0) end
        end
    end
end

local function ValidTarget(playerID, targetID)
    if not IsMajorID(playerID) or not IsMajorID(targetID) or playerID == targetID
        or not IsTrent(Players[playerID]) then return false end
    local target = Players[targetID]
    return target ~= nil and target:IsAlive()
end

local function StartMission(playerID, targetID)
    if not ValidTarget(playerID, targetID) or PhoneOwner(targetID) >= 0 or Cooldown(targetID) > 0
        or MissionStart(playerID, targetID) >= 0 or not EstablishedSpy(playerID, targetID) then return false end
    SetMissionStart(playerID, targetID, Turn())
    local target = Players[targetID]
    if Players[playerID]:IsHuman() and Events and Events.GameplayAlertMessage then
        Events.GameplayAlertMessage("Snatch Phone begun in " .. target:GetCivilizationShortDescription()
            .. ". Keep the Spy established in the Capital for " .. Scale(MISSION_TURNS) .. " turns.")
    end
    Changed()
    return true
end

local function CompleteMission(playerID, targetID)
    if not ValidTarget(playerID, targetID) or PhoneOwner(targetID) >= 0
        or not EstablishedSpy(playerID, targetID) then return false end
    SetPhoneOwner(targetID, playerID)
    SetMissionStart(playerID, targetID, -1)
    RefreshStash(playerID)
    local player, target = Players[playerID], Players[targetID]
    local capital = target:GetCapitalCity()
    local x, y = capital and capital:GetX() or -1, capital and capital:GetY() or -1
    Notify(playerID, "TXT_KEY_PHONE_STEALER_NOTIFICATION_TITLE", "TXT_KEY_PHONE_STEALER_NOTIFICATION_BODY",
        x, y, player:GetName(), capital and capital:GetName() or target:GetCivilizationShortDescription(),
        target:GetCivilizationShortDescription())
    Notify(targetID, "TXT_KEY_PHONE_STEALER_VICTIM_TITLE", "TXT_KEY_PHONE_STEALER_VICTIM_BODY", x, y)
    Changed()
    return true
end

local function ReturnPhone(playerID, targetID)
    if not IsTrent(Players[playerID]) or PhoneOwner(targetID) ~= playerID then return false end
    SetPhoneOwner(targetID, -1)
    Write("RETURN", targetID, nil, Turn() + Scale(RETURN_TURNS))
    for otherID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do SetMissionStart(otherID, targetID, -1) end
    RefreshStash(playerID)
    local target = Players[targetID]
    local name = target and target:GetCivilizationShortDescription() or "the civilization"
    local capital = Players[playerID]:GetCapitalCity()
    Notify(playerID, "TXT_KEY_PHONE_STEALER_RETURN_TITLE", "TXT_KEY_PHONE_STEALER_RETURN_BODY",
        capital and capital:GetX() or -1, capital and capital:GetY() or -1, name, Scale(RETURN_TURNS))
    Changed()
    return true
end

local function ShouldAIStart(playerID, targetID)
    local player, target = Players[playerID], Players[targetID]
    if player == nil or target == nil then return false end
    local playerTeam, targetTeam = Teams[player:GetTeam()], Teams[target:GetTeam()]
    if playerTeam and targetTeam and playerTeam:IsAtWar(target:GetTeam()) then return true end
    if target.IsDenouncingPlayer and target:IsDenouncingPlayer(playerID) then return true end
    return not (target.IsDoF and target:IsDoF(playerID))
end

local function ProcessMissions(playerID)
    local player = Players[playerID]
    if not IsTrent(player) or not player:IsAlive() then return end
    local duration = Scale(MISSION_TURNS)
    for targetID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        if targetID ~= playerID then
            local start = MissionStart(playerID, targetID)
            if start >= 0 then
                local cancellation = nil
                if PhoneOwner(targetID) >= 0 then
                    cancellation = "Snatch Phone was cancelled because that Phone is no longer available."
                elseif not ValidTarget(playerID, targetID) then
                    cancellation = "Snatch Phone was cancelled because the target civilization is no longer active."
                elseif not EstablishedSpy(playerID, targetID) then
                    cancellation = "Snatch Phone was cancelled because no Spy remains established in the target Capital."
                end
                if cancellation ~= nil then
                    SetMissionStart(playerID, targetID, -1)
                    if player:IsHuman() and Events and Events.GameplayAlertMessage then
                        Events.GameplayAlertMessage(cancellation)
                    end
                    Changed()
                elseif Turn() - start >= duration then
                    CompleteMission(playerID, targetID)
                end
            elseif not player:IsHuman() and ValidTarget(playerID, targetID) and PhoneOwner(targetID) < 0
                and Cooldown(targetID) == 0 and EstablishedSpy(playerID, targetID)
                and ShouldAIStart(playerID, targetID) then
                StartMission(playerID, targetID)
            end
        end
    end
    RefreshStash(playerID)
end

local function QueueButlerEscape(ownerID, unitID)
    local ownerQueue = queuedButlers[ownerID]
    if ownerQueue == nil then
        ownerQueue = {}
        queuedButlers[ownerID] = ownerQueue
    end
    local marker = tostring(unitID or -1) .. ":" .. tostring(Turn())
    if ownerQueue[marker] then return end
    ownerQueue[marker] = true
    Write("ESCAPES", ownerID, nil, Read("ESCAPES", ownerID) + 1)
end

local function OnUnitPrekill(ownerID, unitID, unitType, _, _, _, killerPlayer)
    if unitType == BUTLER and IsTrent(Players[ownerID]) and killerPlayer ~= nil
        and killerPlayer >= 0 and killerPlayer ~= ownerID then
        QueueButlerEscape(ownerID, unitID)
    end
end

local function OnUnitCaptured(_, _, capturedPlayer, capturedUnit, willBeKilled)
    if not Truth(willBeKilled) then return end
    local player = Players[capturedPlayer]
    local unit = player and player.GetUnitByID and player:GetUnitByID(capturedUnit) or nil
    if unit and unit:GetUnitType() == BUTLER and IsTrent(player) then
        QueueButlerEscape(capturedPlayer, capturedUnit)
    end
end

local function ProcessButlerEscapes(ownerID)
    local pending = Read("ESCAPES", ownerID)
    if pending <= 0 then return end
    local player = Players[ownerID]
    if not IsTrent(player) or not player:IsAlive() then
        Write("ESCAPES", ownerID, nil, 0)
        queuedButlers[ownerID] = nil
        return
    end
    local city = player:GetCapitalCity()
    if city == nil then
        for candidate in player:Cities() do city = candidate break end
    end
    if city == nil then return end
    local created, retry = 0, 0
    for _ = 1, pending do
        local unit = player:InitUnit(BUTLER, city:GetX(), city:GetY())
        if unit then
            if unit.JumpToNearestValidPlot then pcall(function() unit:JumpToNearestValidPlot() end) end
            if unit.SetMoves then unit:SetMoves(0) end
            created = created + 1
        else
            retry = retry + 1
        end
    end
    Write("ESCAPES", ownerID, nil, retry)
    queuedButlers[ownerID] = nil
    if created > 0 then
        Notify(ownerID, "TXT_KEY_PHONE_STEALER_ESCAPE_TITLE", "TXT_KEY_PHONE_STEALER_ESCAPE_BODY",
            city:GetX(), city:GetY())
        Changed()
    end
end

local function CleanupDeadOwners()
    local released = false
    for targetID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local ownerID = PhoneOwner(targetID)
        if ownerID >= 0 and (Players[ownerID] == nil or not Players[ownerID]:IsAlive()) then
            SetPhoneOwner(targetID, -1)
            released = true
        end
    end
    if released then Changed() end
end

local function OnPlayerDoTurn(playerID)
    CleanupDeadOwners()
    ProcessButlerEscapes(playerID)
    ProcessMissions(playerID)
end

local function GetDiploModifier(eventID, fromPlayerID, toPlayerID)
    if eventID == DIPLO and fromPlayerID ~= toPlayerID and IsTrent(Players[toPlayerID])
        and PhoneOwner(fromPlayerID) == toPlayerID then return -50 end
    return 0
end

local function IsMet(playerID, targetID)
    local player, target = Players[playerID], Players[targetID]
    if player == nil or target == nil then return false end
    local team = Teams[player:GetTeam()]
    return team ~= nil and team:IsHasMet(target:GetTeam())
end

local function Query(playerID, snapshot)
    snapshot.enabled = IsTrent(Players[playerID]) and Players[playerID]:IsAlive()
    snapshot.targets = {}
    if not snapshot.enabled then return end
    snapshot.count = PhoneCount(playerID)
    snapshot.science = snapshot.count * 2
    snapshot.gold = snapshot.count * 2
    snapshot.culture = snapshot.count
    snapshot.happiness = math.floor(snapshot.count / 3)
    snapshot.total = 0
    local duration = Scale(MISSION_TURNS)
    for targetID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local target = Players[targetID]
        if targetID ~= playerID and IsEverAlive(target) then
            snapshot.total = snapshot.total + 1
            local met = IsMet(playerID, targetID)
            local ownerID = PhoneOwner(targetID)
            local start = MissionStart(playerID, targetID)
            local cooldown = Cooldown(targetID)
            local established = target:IsAlive() and EstablishedSpy(playerID, targetID)
            local known = met or ownerID == playerID
            local row = {
                id=targetID,
                name=known and target:GetCivilizationShortDescription() or "Unmet Civilization",
                leader=known and target:GetName() or "Unknown leader",
                stolen=ownerID == playerID,
                action=nil,
                status="No established Spy in Capital",
            }
            if ownerID == playerID then
                row.status, row.action = "[ICON_SPY] Stolen — diplomatic grievance active", "return"
            elseif ownerID >= 0 then
                row.status = "Phone already held by another Trent"
            elseif cooldown > 0 then
                row.status = "Returned — protected for " .. cooldown .. " turns"
            elseif start >= 0 then
                local elapsed = math.max(0, Turn() - start)
                row.status = "Snatch in progress: " .. math.min(duration, elapsed) .. "/" .. duration .. " turns"
                row.progress = math.min(duration, elapsed)
            elseif not target:IsAlive() then
                row.status = "Eliminated — Phone unavailable"
            elseif established then
                row.status, row.action = "Spy established — Snatch Phone ready", "snatch"
            elseif not met then
                row.status = "Civilization not yet met"
            end
            snapshot.targets[#snapshot.targets + 1] = row
        end
    end
    table.sort(snapshot.targets, function(a, b)
        if a.stolen ~= b.stolen then return a.stolen end
        return a.name < b.name
    end)
end

local function Request(playerID, targetID, action)
    if action == "snatch" then return StartMission(playerID, targetID) end
    if action == "return" then return ReturnPhone(playerID, targetID) end
    return false
end

API.IsTrent = IsTrent
API.PhoneOwner = PhoneOwner
API.SetPhoneOwner = SetPhoneOwner
API.PhoneCount = PhoneCount
API.EstablishedSpy = EstablishedSpy
API.StartMission = StartMission
API.CompleteMission = CompleteMission
API.ReturnPhone = ReturnPhone
API.ProcessMissions = ProcessMissions
API.QueueButlerEscape = QueueButlerEscape
API.ProcessButlerEscapes = ProcessButlerEscapes
API.GetDiploModifier = GetDiploModifier
API.Query = Query
API.Request = Request

GameEvents.PlayerDoTurn.Add(OnPlayerDoTurn)
if GameEvents.UnitPrekill then GameEvents.UnitPrekill.Add(OnUnitPrekill) end
if GameEvents.UnitCaptured then GameEvents.UnitCaptured.Add(OnUnitCaptured) end
if GameEvents.GetDiploModifier then GameEvents.GetDiploModifier.Add(GetDiploModifier) end
LuaEvents.TrentPhoneStealerQuery.Add(Query)
LuaEvents.TrentPhoneStealerRequest.Add(Request)

for playerID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
    if IsTrent(Players[playerID]) then RefreshStash(playerID) end
end
