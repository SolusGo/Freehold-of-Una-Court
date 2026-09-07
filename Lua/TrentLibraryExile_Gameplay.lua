-- Library Exile gameplay: diplomacy polling, Visitor persistence and Reader bonuses.
local SAVE = Modding.OpenSaveData()
local CIV = GameInfoTypes.CIVILIZATION_TRENT_LIBRARY_EXILE
local SCHOOL = GameInfoTypes.BUILDING_TRENT_SCHOOL_LIBRARY
local READER = GameInfoTypes.UNIT_TRENT_IPAD_READER
local EXILE = {
    GameInfoTypes.BUILDING_TRENT_EXILE_1,
    GameInfoTypes.BUILDING_TRENT_EXILE_2,
    GameInfoTypes.BUILDING_TRENT_EXILE_3,
}
local VISITOR_WRITER = GameInfoTypes.BUILDING_TRENT_VISITOR_WRITER
local VISITOR_HAPPINESS = GameInfoTypes.BUILDING_TRENT_VISITOR_HAPPINESS
local VISITOR_CULTURE = GameInfoTypes.BUILDING_TRENT_VISITOR_CULTURE
local READER_CITY = GameInfoTypes.BUILDING_TRENT_READER_CITY
local DUMMIES = {EXILE[1],EXILE[2],EXILE[3],VISITOR_WRITER,VISITOR_HAPPINESS,VISITOR_CULTURE,READER_CITY}

local function Key(id, suffix) return "TRENT_LIBRARY_EXILE_" .. id .. "_" .. suffix end
local function Read(id, suffix, default)
    local value = tonumber(SAVE.GetValue(Key(id, suffix)))
    if value == nil then return default end
    return value
end
local function Write(id, suffix, value) SAVE.SetValue(Key(id, suffix), value) end
local function IsExile(player)
    return player and player:IsAlive() and player:GetCivilizationType() == CIV
end
local function Notify(id, title, body, ...)
    local player = Players[id]
    if player and player:IsHuman() then
        player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,
            Locale.ConvertTextKey(body, ...), Locale.ConvertTextKey(title))
    end
end
local function SetBuilding(city, building, amount)
    if building and city:GetNumRealBuilding(building) ~= amount then
        city:SetNumRealBuilding(building, amount)
    end
end
local function DoF(player, otherID)
    local other = Players[otherID]
    return other and other:IsAlive() and (player:IsDoF(otherID) or other:IsDoF(player:GetID()))
end
local function FindVisitor(id, player)
    local visitor = Read(id, "VISITOR", -1)
    if visitor >= 0 then return visitor end
    for otherID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        if otherID ~= id and DoF(player, otherID) then
            Write(id, "VISITOR", otherID)
            Notify(id, "TXT_KEY_LIBRARY_EXILE_VISITOR_TITLE", "TXT_KEY_LIBRARY_EXILE_VISITOR_BODY",
                Players[otherID]:GetCivilizationShortDescription())
            return otherID
        end
    end
    return -1
end
local function CountExileStacks(id, player)
    local stacks = 0
    for otherID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local other = Players[otherID]
        if otherID ~= id and other and other:IsAlive() and not other:IsMinorCiv() then
            local war = Teams[player:GetTeam()]:IsAtWar(other:GetTeam())
            local denounced = other.IsDenouncingPlayer and other:IsDenouncingPlayer(id)
            if war or denounced then stacks = stacks + 1 end
        end
    end
    return math.min(3, stacks)
end
local function ReaderPresent(player, city)
    for unit in player:Units() do
        if unit:GetUnitType() == READER and not unit:IsDead() and not unit:IsDelayedDeath()
            and unit:GetX() == city:GetX() and unit:GetY() == city:GetY() then
            return true
        end
    end
    return false
end
local function RefreshPlayer(id)
    local player = Players[id]
    if not IsExile(player) then return end
    local stacks = CountExileStacks(id, player)
    local previous = Read(id, "STACKS", -1)
    Write(id, "STACKS", stacks)
    if previous >= 0 and previous ~= stacks then
        Notify(id, "TXT_KEY_LIBRARY_EXILE_STACK_TITLE", "TXT_KEY_LIBRARY_EXILE_STACK_BODY", stacks, stacks * 3)
    end
    local visitor = FindVisitor(id, player)
    local activeVisitor = visitor >= 0 and DoF(player, visitor)
    local capital = player:GetCapitalCity()
    for city in player:Cities() do
        local hasSchool = city:GetNumRealBuilding(SCHOOL) > 0
        for index = 1, 3 do SetBuilding(city, EXILE[index], hasSchool and stacks == index and 1 or 0) end
        SetBuilding(city, VISITOR_WRITER, activeVisitor and 1 or 0)
        SetBuilding(city, VISITOR_HAPPINESS, activeVisitor and capital == city and 1 or 0)
        SetBuilding(city, VISITOR_CULTURE, activeVisitor and hasSchool and 1 or 0)
        SetBuilding(city, READER_CITY, hasSchool and ReaderPresent(player, city) and 1 or 0)
    end
end
local function CleanupPlayer(player)
    if not player then return end
    for city in player:Cities() do
        for _, building in ipairs(DUMMIES) do SetBuilding(city, building, 0) end
    end
end
local function RefreshAll()
    for id = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local player = Players[id]
        if IsExile(player) then RefreshPlayer(id) else CleanupPlayer(player) end
    end
end
local function GreatPersonExpended(id, unitID, unitType)
    -- Older DLL event signatures pass the unit type as argument two.
    local kind = unitType or unitID
    local player = Players[id]
    if IsExile(player) and kind == READER then
        local amount = 25 * math.max(1, player:GetCurrentEra() + 1)
        player:ChangeOverflowResearch(amount)
        Notify(id, "TXT_KEY_LIBRARY_EXILE_READER_TITLE", "TXT_KEY_LIBRARY_EXILE_READER_BODY", amount)
    end
end
local function CanConstruct(id, buildingType)
    for _, dummy in ipairs(DUMMIES) do if buildingType == dummy then return false end end
    return true
end

GameEvents.PlayerDoTurn.Add(function(id)
    if id < GameDefines.MAX_MAJOR_CIVS then RefreshAll() end
end)
GameEvents.GreatPersonExpended.Add(GreatPersonExpended)
GameEvents.PlayerCanConstruct.Add(CanConstruct)
GameEvents.CityCaptureComplete.Add(function() RefreshAll() end)
Events.SequenceGameInitComplete.Add(RefreshAll)
print("Trent Library Exile gameplay initialized")
