include("PrinceRules.lua")
include("PrinceState.lua")
if not Prince.CIV or not Prince.UNIT then return end
include("PrinceAbilities.lua")
include("PrinceIdentity.lua")
include("PrinceCombat.lua")
include("PrinceAI.lua")
local P=Prince
GameEvents.PlayerDoTurn.Add(function(owner)
    for id,s in pairs(P.states) do
        if s.fallen~=1 then
            if s.suspended==1 then P.Resume(id) end
            if s.started==1 and not P.Body(id) then P.QueueFall(id,-1)
            elseif s.kind then
                if owner==id and Game.GetGameTurn()>=s.expires or not P.Borrowed(id)
                    or not Players[s.targetOwner]:IsAlive()
                    or not Teams[Players[id]:GetTeam()]:IsAtWar(Players[s.targetOwner]:GetTeam()) then
                    P.End(id,"Expired or ownership/diplomacy changed",owner==id)
                else
                    local body=P.Body(id)
                    if body and body:GetOwner()==owner then
                        body:SetMoves(s.kind=="swap" and math.min(body:GetMoves(),GameDefines.MOVE_DENOMINATOR or 60) or 0)
                    end
                end
            end
        end
    end
    if P.IsPlayer(owner) then P.Initialize(owner); P.Bonuses(owner); P.AI(owner); LuaEvents.PrinceChanged(owner) end
end)
local function RefreshCities() for id in pairs(P.states) do P.Bonuses(id) end end
GameEvents.CityConstructed.Add(RefreshCities)
GameEvents.CitySoldBuilding.Add(RefreshCities)
GameEvents.CityCaptureComplete.Add(RefreshCities)
GameEvents.PlayerCityFounded.Add(RefreshCities)
GameEvents.MakePeace.Add(function()
    for id,s in pairs(P.states) do
        if s.kind and not Teams[Players[id]:GetTeam()]:IsAtWar(Players[s.targetOwner]:GetTeam()) then P.End(id,"Peace signed") end
    end
end)
LuaEvents.PrinceRequest.Add(function(id,kind,owner,unitID)
    if id==Game.GetActivePlayer() and Players[id]:IsHuman() then P.Activate(id,kind,owner,unitID) end
end)
LuaEvents.PrinceQuery.Add(function(id,result)
    if not P.IsPlayer(id) then return end
    local s,body=P.State(id),P.Body(id)
    result.enabled=Players[id]:IsAlive() and s.fallen~=1
    result.bodyOwner,result.bodyID=s.bodyOwner,s.bodyID
    result.possession,result.swap=s.possession,s.swap
    result.cooldown=math.max(0,s.readyTurn-Game.GetGameTurn())
    result.kind=s.kind
    result.remaining=s.kind and math.max(0,s.expires-Game.GetGameTurn()) or 0
    result.damage,result.resistance=s.damage,s.resistance
    result.possessValues,result.swapValues=P.Values(id,"possess"),P.Values(id,"swap")
    result.targets={}
    if body then P.Nearby(body,1,function(u)
        if u:GetOwner()~=id and u:GetPlot():IsVisible(Players[id]:GetTeam(),false)
            and not u:IsInvisible(Players[id]:GetTeam(),false) then
            local possess,whyPossess=P.Validate(id,"possess",u)
            local swap,whySwap=P.Validate(id,"swap",u)
            result.targets[#result.targets+1]={owner=u:GetOwner(),id=u:GetID(),x=u:GetX(),y=u:GetY(),
                name=u:GetName(),strength=math.max(u:GetBaseCombatStrength(),u:GetBaseRangedCombatStrength()),
                possess=possess,swap=swap,whyPossess=whyPossess,whySwap=whySwap}
        end
    end) end
end)
for id=0,(GameDefines.MAX_MAJOR_CIVS or 22)-1 do
    if P.IsPlayer(id) then
        P.State(id)
        if P.State(id).suspended==1 then
            local playerID=id
            UnaCourt_QueueDeferredRestore(function() P.Resume(playerID); P.Initialize(playerID) end)
        else P.Initialize(id) end
        P.Bonuses(id)
    end
end
P.Reindex()
print("Princedom of Una Court initialized")
