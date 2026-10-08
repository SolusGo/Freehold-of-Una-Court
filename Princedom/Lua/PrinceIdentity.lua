local P = Prince
local function Defer(f) UnaCourt_QueueDeferredRestore(f) end
local function MakeOrdinary(duplicate)
    P.Transaction(function()
        local kind=GameInfoTypes.UNIT_PRINCE_MILITIA or GameInfoTypes.UNIT_WARRIOR
        local ordinary=Players[duplicate:GetOwner()]:InitUnit(kind,duplicate:GetX(),duplicate:GetY(),GameInfoTypes.UNITAI_ATTACK)
        if ordinary then
            ordinary:Convert(duplicate,false)
            ordinary:SetHasPromotion(P.IDENTITY,false)
            ordinary:SetName("")
            if duplicate:IsDelayedDeath() then duplicate:Kill(false,-1) end
        end
    end)
end
function P.QueueFall(id,killer)
    local s=P.State(id)
    if s.fallen == 1 then return end
    s.fallen=1
    P.Persist(id); P.Bonuses(id)
    -- Mark defeat immediately, then remove the empire outside CvUnit::kill's
    -- stack. Never recursively Kill the body while the combat DLL owns it.
    Defer(function()
        P.End(id,"The Fall of Una Court")
        local p=Players[id]
        if not p then return end
        p:KillCities()
        local units={}
        for u in p:Units() do
            if not u:IsDead() and not u:IsDelayedDeath() then units[#units+1]=u:GetID() end
        end
        P.Transaction(function()
            for _,unitID in ipairs(units) do
                local u=P.Unit(id,unitID)
                if u then u:Kill(false,killer or -1) end
            end
        end)
        -- CP's verifyAlive() sees zero cities and units at its next native
        -- verification boundary, including Complete Kills and pre-city starts.
        Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_PRINCE_FALL"))
        P.Changed(id)
    end)
end
function P.Initialize(id)
    if not P.IsPlayer(id) then return end
    local s,p=P.State(id),Players[id]
    if s.fallen == 1 then return end
    if s.started == 1 then
        if not P.Body(id) then P.QueueFall(id,-1) end
        for u in p:Units() do
            if u:IsHasPromotion(P.IDENTITY) and not P.Ref(id,u:GetID()) then
                -- Foreign cloning mods must not create a second identity.
                u:SetHasPromotion(P.IDENTITY,false)
                P.ClearTemporary(u)
            end
        end
        return
    end
    -- New games only: adding the mod to an existing save cannot resurrect him.
    if Game.GetElapsedGameTurns() ~= 0 then return end
    local candidate,warrior
    for u in p:Units() do
        if u:GetUnitType() == P.UNIT then candidate=candidate or u end
        if u:GetUnitType() == GameInfoTypes.UNIT_WARRIOR then warrior=warrior or u end
    end
    if not candidate then
        local plot=warrior and warrior:GetPlot() or p:GetStartingPlot()
        if not plot then return end
        P.Transaction(function()
            candidate=p:InitUnit(P.UNIT,plot:GetX(),plot:GetY(),GameInfoTypes.UNITAI_ATTACK)
            if candidate and warrior then
                local snap=P.Snapshot(warrior)
                candidate:Convert(warrior,false)
                P.Apply(candidate,snap)
            end
        end)
    end
    if candidate then
        s.started=1
        P.SetBody(id,candidate)
        P.Place(candidate)
        local duplicates={}
        for u in p:Units() do
            if u:GetUnitType()==P.UNIT and u:GetID()~=candidate:GetID() then duplicates[#duplicates+1]=u end
        end
        for _,u in ipairs(duplicates) do MakeOrdinary(u) end
        P.Changed(id)
    end
end
GameEvents.UnitPrekill.Add(function(owner,unitID,_,_,_,_,killer)
    if P.depth>0 then return end
    local ref=P.Ref(owner,unitID)
    if not ref then return end
    if ref.role == "body" then P.QueueFall(ref.player,killer)
    else
        local s=P.State(ref.player)
        s.borrowedID=nil
        P.Persist(ref.player); P.Reindex()
        Defer(function() P.End(ref.player,"Borrowed body destroyed") end)
    end
end)
GameEvents.UnitUpgraded.Add(function(owner,oldID,newID)
    if P.depth>0 then return end
    local ref=P.Ref(owner,oldID)
    if ref and ref.role == "body" then
        local new=P.Unit(owner,newID)
        if new then P.SetBody(ref.player,new) end
    end
end)
GameEvents.UnitConverted.Add(function(oldOwner,newOwner,oldID,newID,isUpgrade)
    if P.depth>0 then return end
    local ref=P.Ref(oldOwner,oldID)
    if not ref then return end
    local s=P.State(ref.player)
    local u=P.Unit(newOwner,newID)
    if not u then return end
    if ref.role == "body" then P.SetBody(ref.player,u)
    else s.borrowedOwner,s.borrowedID=newOwner,newID; P.Persist(ref.player); P.Reindex() end
    if not isUpgrade or s.kind then
        Defer(function()
            if P.State(ref.player).kind then P.End(ref.player,"Unexpected ownership or type conversion")
            elseif ref.role == "body" and u:GetOwner() ~= ref.player then
                local restored=P.Transfer(u,ref.player)
                if restored then P.SetBody(ref.player,restored); P.Place(restored) end
            end
        end)
    end
end)
GameEvents.UnitCreated.Add(function(owner,unitID,unitType)
    if P.depth>0 or unitType~=P.UNIT then return end
    -- Internal initialization and transfer are guarded. All other extra Trent
    -- creation (including another mod) becomes an ordinary Warrior.
    if P.IsPlayer(owner) and P.State(owner).started==1 then
        Defer(function()
            local duplicate=P.Unit(owner,unitID)
            if duplicate and not P.Ref(owner,unitID) then
                MakeOrdinary(duplicate)
            end
        end)
    end
end)
GameEvents.PlayerCanTrain.Add(function(_,unitType) return unitType~=P.UNIT end)
GameEvents.CanDoCommand.Add(function(owner,unitID,command)
    local ref=P.Ref(owner,unitID)
    if not ref then return true end
    if command==CommandTypes.COMMAND_DELETE or command==CommandTypes.COMMAND_GIFT then return false end
    local s=P.State(ref.player)
    if command==CommandTypes.COMMAND_UPGRADE and (s.kind or ref.role=="borrowed") then return false end
    if command==CommandTypes.COMMAND_AUTOMATE and s.kind then return false end
    return true
end)
local function CanUpgrade(owner,unitID)
    local ref=P.Ref(owner,unitID)
    return not ref or (ref.role=="body" and not P.State(ref.player).kind)
end
GameEvents.CanHaveAnyUpgrade.Add(CanUpgrade)
GameEvents.UnitCanHaveAnyUpgrade.Add(CanUpgrade)
GameEvents.PlayerCanGiftUnit.Add(function(owner,_,unitID) return not P.Ref(owner,unitID) end)
GameEvents.PlayerCanDisbandUnit.Add(function(owner,unitID) return not P.Ref(owner,unitID) end)
-- Constant-time lookups on the expensive movement hook: no scans or SaveData
-- reads for unrelated units. Shell movement is at most one tile/turn even
-- after DLL movement refresh, promotions, reloads or AI movement orders.
GameEvents.CanMoveInto.Add(function(owner,unitID,x,y,attack)
    local ref=P.Ref(owner,unitID)
    if not ref then return true end
    local s=P.State(ref.player)
    if s.fallen==1 then return false end
    if not s.kind then
        if ref.role=="body" and attack and not Players[ref.player]:IsHuman() then
            local body=P.Body(ref.player)
            if not body or body:GetDamage()>35 then return false end
            local destination=Map.GetPlot(x,y)
            if destination then for i=0,destination:GetNumUnits()-1 do
                local enemy=destination:GetUnit(i)
                if enemy:GetOwner()~=owner and enemy:GetBaseCombatStrength()>body:GetBaseCombatStrength()*1.25 then return false end
            end end
        end
        return true
    end
    local plot=Map.GetPlot(x,y)
    if not plot or plot:IsWater() then return false end
    if ref.role=="body" then
        if s.kind=="possess" or attack or plot:IsCity() and plot:GetOwner()~=owner then return false end
        if s.shellMovedTurn==Game.GetGameTurn() then return false end
        local u=P.Unit(owner,unitID)
        return u and Map.PlotDistance(u:GetX(),u:GetY(),x,y)<=1
    end
    return true
end)
GameEvents.UnitSetXY.Add(function(owner,unitID)
    if P.depth>0 then return end
    local ref=P.Ref(owner,unitID)
    if ref and ref.role=="body" and P.State(ref.player).kind then
        local s=P.State(ref.player)
        s.shellMovedTurn=Game.GetGameTurn()
        local u=P.Unit(owner,unitID)
        if u then u:SetMoves(0) end
        P.Persist(ref.player)
    end
end)
GameEvents.UnitCanPillage.Add(function(owner,unitID)
    local ref=P.Ref(owner,unitID)
    return not ref or ref.role~="body" or not P.State(ref.player).kind
end)
GameEvents.UnitCanRangeAttackAt.Add(function(owner,unitID)
    local ref=P.Ref(owner,unitID)
    return not ref or ref.role~="body" or not P.State(ref.player).kind
end)
GameEvents.GameSave.Add(function()
    for id in pairs(P.states) do
        if P.State(id).fallen~=1 then
            P.Suspend(id)
            if P.State(id).suspended==1 then Defer(function() P.Resume(id) end) end
        end
    end
end)
