-- Soft Kitty gameplay. Persistent state and all rewards live in this context.
local SAVE = Modding.OpenSaveData()
local CIV = GameInfoTypes.CIVILIZATION_TRENT_SOFT_KITTY
local ROMANTIC = GameInfoTypes.UNIT_TRENT_HOPELESS_ROMANTIC
local COMFORT = GameInfoTypes.BUILDING_TRENT_COMFORT_ROOM
local COMBAT = GameInfoTypes.PROMOTION_TRENT_REPERCUSSION_COMBAT
local MOVEMENT = GameInfoTypes.PROMOTION_TRENT_REPERCUSSION_MOVEMENT
local GP = GameInfoTypes.BUILDING_TRENT_REPERCUSSION_DUMMY
local RECOVERY = GameInfoTypes.BUILDING_TRENT_COMFORT_RECOVERY_DUMMY
local MUSIC = GameInfoTypes.BUILDING_TRENT_MUSIC_DUMMY
local MUSIC_SLOT = GameInfoTypes.GREAT_WORK_SLOT_MUSIC
local PROD = {}
for n = 1, 15 do PROD[n] = GameInfoTypes["BUILDING_TRENT_REPERCUSSION_PROD_" .. n] end
local A = MajorCivApproachTypes
local busy, refreshing, dirty = false, false, false
local function Read(id, key, default)
    local value = tonumber(SAVE.GetValue("TRENT_SOFTKITTY_" .. id .. "_" .. key))
    if value == nil then return default or 0 end
    return value
end
local function Write(id, key, value) SAVE.SetValue("TRENT_SOFTKITTY_" .. id .. "_" .. key, value) end
local function Turn() return Game.GetGameTurn() end
local function IsTrent(p) return p ~= nil and p:IsAlive() and p:GetCivilizationType() == CIV end
local function Scale(value, column)
    local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    return math.max(1, math.floor(value * (speed and speed[column] or 100) / 100 + 0.5))
end
local function Remaining(id) return math.max(0, Read(id, "REPERCUSSION_END") - Turn()) end
local function Cooldown(id) return math.max(0, Read(id, "COOLDOWN_END") - Turn()) end
local function Notify(id, title, body)
    local p = Players[id]
    if p and p:IsHuman() then
        p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, body, title)
    end
end
local function Changed() LuaEvents.TrentSoftKittyChanged() end
local function ValidTarget(id, targetID)
    local p, target = Players[id], Players[targetID]
    return IsTrent(p) and targetID ~= id and target ~= nil and target:IsAlive()
        and not target:IsMinorCiv() and not target:IsBarbarian()
        and Teams[p:GetTeam()]:IsHasMet(target:GetTeam())
        and not Teams[p:GetTeam()]:IsAtWar(target:GetTeam())
end
local function Relationship(id, targetID)
    local p, target = Players[id], Players[targetID]
    local friend = p:IsDoF(targetID) or target:IsDoF(id)
    local approach = A.MAJOR_CIV_APPROACH_NEUTRAL
    -- This is the TARGET's approach toward Trent, not the reverse direction.
    if not target:IsHuman() then
        if target.GetMajorCivApproach then approach = target:GetMajorCivApproach(id)
        elseif p.GetApproachTowardsUsGuess then approach = p:GetApproachTowardsUsGuess(targetID) end
    end
    if friend or approach == A.MAJOR_CIV_APPROACH_FRIENDLY then return "Friendly", 200, 0, friend and 100 or 75 end
    if approach == A.MAJOR_CIV_APPROACH_HOSTILE or approach == A.MAJOR_CIV_APPROACH_WAR then return "Hostile", 50, 50, -50 end
    if approach == A.MAJOR_CIV_APPROACH_GUARDED then return "Guarded", 75, 25, 10 end
    if approach == A.MAJOR_CIV_APPROACH_DECEPTIVE then return "Guarded", 75, 25, 0 end
    return "Neutral", 100, 10, approach == A.MAJOR_CIV_APPROACH_AFRAID and 35 or 40
end
local function Preview(id, targetID)
    if not ValidTarget(id, targetID) then return nil end
    local relation, multiplier, risk, score = Relationship(id, targetID)
    local ex = Read(id, "EX_PLAYER", -1) == targetID
    local factor = math.max(1, Players[id]:GetCurrentEra() + 1)
    local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    local scale = (speed and speed.CulturePercent or 100) / 100
    local reward = multiplier / 100 * (ex and 1.25 or 1)
    return {id=targetID, name=Players[targetID]:GetCivilizationShortDescription(),
        leader=Locale.ConvertTextKey(GameInfo.Leaders[Players[targetID]:GetLeaderType()].Description),
        relationship=relation, risk=ex and math.max(15, risk) or risk, ex=ex, score=score,
        culture=math.floor(30 * factor * reward * scale + 0.5),
        tourism=math.floor(20 * factor * reward * scale + 0.5)}
end
local function ComfortCount(p)
    local count = 0
    for city in p:Cities() do if city:GetNumRealBuilding(COMFORT) > 0 then count = count + 1 end end
    return count
end
local function SetBuilding(city, building, count)
    if building and city:GetNumRealBuilding(building) ~= count then city:SetNumRealBuilding(building, count) end
end
local function Military(unit)
    return unit:IsCombatUnit() and unit:GetDomainType() ~= GameInfoTypes.DOMAIN_AIR
end
local function RefreshPlayer(id)
    local p = Players[id]
    if not p then return end
    local isTrent = IsTrent(p)
    local active = isTrent and Remaining(id) > 0
    local penalty = active and math.max(0, 15 - ComfortCount(p)) or 0
    for city in p:Cities() do
        for n = 1, 15 do SetBuilding(city, PROD[n], penalty == n and 1 or 0) end
        SetBuilding(city, GP, active and 1 or 0)
        local hasComfort = isTrent and city:GetNumRealBuilding(COMFORT) > 0
        SetBuilding(city, RECOVERY, active and hasComfort and 1 or 0)
        local works = hasComfort and city:GetNumGreatWorksFilled(MUSIC_SLOT) or 0
        SetBuilding(city, MUSIC, works)
    end
    for unit in p:Units() do
        local combat = active and unit:IsCombatUnit()
        if unit:IsHasPromotion(COMBAT) ~= combat then unit:SetHasPromotion(COMBAT, combat) end
        if (not active or not Military(unit)) and unit:IsHasPromotion(MOVEMENT) then unit:SetHasPromotion(MOVEMENT, false) end
    end
end
local function RefreshAll()
    if refreshing then return end
    refreshing = true
    for id = 0, (GameDefines.MAX_CIV_PLAYERS or 63) - 1 do RefreshPlayer(id) end
    refreshing = false
end
local function Backlash(id, targetID)
    if Read(id, "EX_PLAYER", -1) < 0 then Write(id, "EX_PLAYER", targetID) end
    Write(id, "REPERCUSSION_END", math.max(Read(id, "REPERCUSSION_END"), Turn() + Scale(5, "TrainPercent")))
    Write(id, "RECOVERY_PENDING", 1)
    RefreshPlayer(id)
    Notify(id, "KICKED IN THE BALLS", "The Serenade was not received as Trent intended. He will require some time to recover.")
end
local function Influence(id, targetID)
    for minorID = GameDefines.MAX_MAJOR_CIVS or 22, (GameDefines.MAX_CIV_PLAYERS or 63) - 1 do
        local minor = Players[minorID]
        if minor and minor:IsAlive() and minor:IsMinorCiv() and minor:GetAlly() == targetID then
            minor:ChangeMinorCivFriendshipWithMajor(id, 5)
        end
    end
end
local function Award(id, row)
    local p = Players[id]
    p:ChangeJONSCulture(row.culture)
    -- Exact previewed instant yields: diplomatic and game-speed factors have
    -- already been applied, so CP must not apply them for a second time.
    p:ChangeInfluenceOnPlayer(row.id, row.tourism, false, false)
    Influence(id, row.id)
end
local function Sing(id, targetID)
    if busy or not IsTrent(Players[id]) or Cooldown(id) > 0 or Remaining(id) > 0 then return false end
    local row = Preview(id, targetID)
    if not row or not Players[id].ChangeInfluenceOnPlayer then return false end
    busy = true
    -- Persist before yields so a repeated request or UI reload cannot pay twice.
    Write(id, "LAST_USE", Turn())
    Write(id, "COOLDOWN_END", Turn() + Scale(15, "TrainPercent"))
    if Game.Rand(100, "Soft Kitty audience") < row.risk then
        Backlash(id, targetID)
    else
        Award(id, row)
        Notify(id, "A receptive audience", row.name .. " enjoyed the Serenade: +" .. row.culture .. " Culture and +" .. row.tourism .. " Tourism.")
    end
    busy = false
    Changed()
    return true
end
local function RomanticUnit(id, unitID)
    local p = Players[id]
    if not IsTrent(p) then return nil end
    local unit = p:GetUnitByID(unitID)
    if not unit or unit:GetUnitType() ~= ROMANTIC or unit:IsDelayedDeath() or unit:IsDead()
        or unit:IsInCombat() or unit:MovesLeft() <= 0 or unit:IsEmbarked() then return nil end
    if Read(id, "SPENT_" .. unitID .. "_" .. unit:GetGameTurnCreated()) == 1 then return nil end
    return unit
end
local function AdjacentCity(unit, targetID)
    local target = Players[targetID]
    if not target then return false end
    for city in target:Cities() do
        if Map.PlotDistance(unit:GetX(), unit:GetY(), city:GetX(), city:GetY()) == 1 then return true end
    end
    return false
end
local function RomanticPreview(id, unitID, targetID)
    local unit = RomanticUnit(id, unitID)
    if not unit or not ValidTarget(id, targetID) or not AdjacentCity(unit, targetID) then return nil end
    local row = Preview(id, targetID)
    -- GetTourismBlastStrength is the musician's stored native concert strength.
    -- Concert tours use CulturePercent and target tourism modifiers in CP.
    local base = unit:GetTourismBlastStrength()
    local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    local scale = (speed and speed.CulturePercent or 100) / 100
    local modifier = math.max(0, 100 + Players[id]:GetTourismModifierWith(targetID)) / 100
    row.tourism = math.floor(base * scale * modifier * 1.25 * (row.ex and 1.20 or 1) + 0.5)
    row.culture = 100
    row.risk = row.relationship == "Hostile" and 25 or 0
    row.unit = unitID
    return row
end
local function Serenade(id, unitID, targetID)
    if busy then return false end
    local row = RomanticPreview(id, unitID, targetID)
    if not row or not Players[id].ChangeInfluenceOnPlayer then return false end
    local unit = Players[id]:GetUnitByID(unitID)
    busy = true
    Write(id, "SPENT_" .. unitID .. "_" .. unit:GetGameTurnCreated(), 1)
    -- Delayed removal is safe for unit-selection callbacks. The persistent spent
    -- marker blocks a second request before the engine finishes deleting it.
    unit:Kill(true, -1)
    Award(id, row)
    if Game.Rand(100, "Hopeless Romantic audience") < row.risk then Backlash(id, targetID) end
    Notify(id, "Serenade", "The Hopeless Romantic's performance awarded " .. row.culture .. " Culture and " .. row.tourism .. " Tourism. The musician has been expended.")
    busy = false
    Changed()
    return true
end
local function Query(id, unitID, result)
    local p = Players[id]
    result.enabled = IsTrent(p)
    if not result.enabled then return end
    result.cooldown, result.recovery = Cooldown(id), Remaining(id)
    result.comfort = ComfortCount(p)
    result.penalty = result.recovery > 0 and math.max(0, 15 - result.comfort) or 0
    result.ex = Read(id, "EX_PLAYER", -1)
    result.targets, result.romantics = {}, {}
    result.unitValid = RomanticUnit(id, unitID or -1) ~= nil
    for targetID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
        local row = Preview(id, targetID)
        if row then result.targets[#result.targets + 1] = row end
        if result.unitValid then
            local concert = RomanticPreview(id, unitID, targetID)
            if concert then result.romantics[#result.romantics + 1] = concert end
        end
    end
end
local function AIScore(id, row)
    local p, target = Players[id], Players[row.id]
    local score = row.score + (row.ex and 15 or 0) + 20 -- cultural leader personality
    if target:GetJONSCultureEverGenerated() > p:GetJONSCultureEverGenerated() then score = score + 30 end
    return score - row.risk / 2
end
local function DoTurn(id)
    local p = Players[id]
    RefreshPlayer(id)
    if not IsTrent(p) or Read(id, "LAST_TURN", -1) == Turn() then return end
    Write(id, "LAST_TURN", Turn())
    if Remaining(id) == 0 and Read(id, "RECOVERY_PENDING") == 1 then
        Write(id, "RECOVERY_PENDING", 0)
        Notify(id, "Trent has recovered", "Trent has recovered and is prepared to serenade the world once again. The normal Soft Kitty cooldown still applies.")
    end
    if not p:IsHuman() then
        local snapshot = {}
        Query(id, -1, snapshot)
        local best, bestScore
        for _, row in ipairs(snapshot.targets) do
            local score = AIScore(id, row)
            if bestScore == nil or score > bestScore then best, bestScore = row, score end
        end
        if best then Sing(id, best.id) end
        local ids = {}
        for unit in p:Units() do if unit:GetUnitType() == ROMANTIC then ids[#ids + 1] = unit:GetID() end end
        table.sort(ids)
        for _, unitID in ipairs(ids) do
            local unitBest, unitScore
            for targetID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
                local row = RomanticPreview(id, unitID, targetID)
                if row and row.relationship ~= "Hostile" and row.relationship ~= "Guarded" then
                    local score = AIScore(id, row)
                    if unitScore == nil or score > unitScore then unitBest, unitScore = row, score end
                end
            end
            if unitBest then Serenade(id, unitID, unitBest.id) end
        end
    end
    Changed()
end

LuaEvents.TrentSoftKittyQuery.Add(Query)
LuaEvents.TrentSoftKittyRequest.Add(function(id, targetID, unitID, culture, tourism, risk)
    local p = Players[id]
    if id ~= Game.GetActivePlayer() or not IsTrent(p) or not p:IsHuman() or not p:IsTurnActive() then return end
    local row = unitID and unitID >= 0 and RomanticPreview(id, unitID, targetID) or Preview(id, targetID)
    if not row or row.culture ~= culture or row.tourism ~= tourism or row.risk ~= risk then
        Notify(id, "Audience changed", "The target or reward changed. Please select the audience again.")
        Changed()
        return
    end
    if unitID and unitID >= 0 then Serenade(id, unitID, targetID) else Sing(id, targetID) end
end)
GameEvents.PlayerDoTurn.Add(DoTurn)
GameEvents.CityTrained.Add(function(id, cityID, unitID, gold, faith)
    local p = Players[id]
    if IsTrent(p) and Remaining(id) > 0 then
        local unit = p:GetUnitByID(unitID)
        if unit and Military(unit) and not gold and not faith then unit:SetHasPromotion(MOVEMENT, true) end
        RefreshPlayer(id)
    end
end)
GameEvents.CanStartMission.Add(function(id, unitID, mission)
    local p = Players[id]
    local unit = p and p:GetUnitByID(unitID)
    if IsTrent(p) and unit and unit:GetUnitType() == ROMANTIC and mission == GameInfoTypes.MISSION_ONE_SHOT_TOURISM then
        -- All custom concerts go through Serenade; normal Great Works remain
        -- available to the native AI and human unit panel.
        return false
    end
    return true
end)
GameEvents.PlayerCanConstruct.Add(function(id, building)
    if building == COMFORT then return IsTrent(Players[id]) end
    if building == GP or building == RECOVERY or building == MUSIC then return false end
    for _, value in ipairs(PROD) do if value == building then return false end end
    return true
end)
GameEvents.CityCaptureComplete.Add(function(oldOwner, capital, x, y, newOwner)
    RefreshPlayer(oldOwner) RefreshPlayer(newOwner) dirty = true
end)
GameEvents.PlayerCityFounded.Add(function(id) RefreshPlayer(id) end)
GameEvents.CityConstructed.Add(function(id) RefreshPlayer(id) Changed() end)
local function MarkDirty() if not refreshing then dirty = true end end
if GameEvents.UnitCreated then GameEvents.UnitCreated.Add(MarkDirty) end
if GameEvents.UnitUpgraded then GameEvents.UnitUpgraded.Add(MarkDirty) end
if GameEvents.UnitCaptured then GameEvents.UnitCaptured.Add(MarkDirty) end
if GameEvents.UnitSetXY then GameEvents.UnitSetXY.Add(MarkDirty) end
if Events.SerialEventCityInfoDirty then Events.SerialEventCityInfoDirty.Add(MarkDirty) end
if Events.SerialEventGreatWorksScreenDirty then Events.SerialEventGreatWorksScreenDirty.Add(MarkDirty) end
local elapsed = 0
if UnaCourt_RegisterUpdate then UnaCourt_RegisterUpdate(function(delta)
    elapsed = elapsed + delta
    if dirty and elapsed >= 0.5 then
        dirty, elapsed = false, 0
        RefreshAll() Changed()
    end
end) end
RefreshAll()
print("Soft Kitty Serenader gameplay initialized")
