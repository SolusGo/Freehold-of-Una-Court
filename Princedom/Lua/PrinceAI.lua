local P=Prince
function P.Nearby(body,radius,callback)
    for dx=-radius,radius do
        for dy=-radius,radius do
            local plot=Map.PlotXYWithRangeCheck(body:GetX(),body:GetY(),dx,dy,radius)
            if plot then for i=0,plot:GetNumUnits()-1 do callback(plot:GetUnit(i),plot) end end
        end
    end
end
function P.AI(id)
    local p,s,body=Players[id],P.State(id),P.Body(id)
    if not p or p:IsHuman() or not body or s.fallen==1 or s.kind then return end
    local danger=0
    P.Nearby(body,2,function(u)
        if u:GetOwner()~=id and Teams[p:GetTeam()]:IsAtWar(Players[u:GetOwner()]:GetTeam())
            and u:GetPlot():IsVisible(p:GetTeam(),false) and not u:IsInvisible(p:GetTeam(),false) then
            danger=danger+math.max(u:GetBaseCombatStrength(),u:GetBaseRangedCombatStrength())
        end
    end)
    local hp=body:GetMaxHitPoints()-body:GetDamage()
    if hp<45 or danger>body:GetBaseCombatStrength()*3 then
        local best,bestDanger=nil,math.huge
        for direction=0,5 do
            local plot=Map.PlotDirection(body:GetX(),body:GetY(),direction)
            if plot and not plot:IsWater() and not plot:IsImpassable() and plot:GetNumUnits()==0
                and (plot:GetOwner()==id or plot:GetOwner()==-1) then
                local risk=0
                for d=0,5 do
                    local near=Map.PlotDirection(plot:GetX(),plot:GetY(),d)
                    if near then for i=0,near:GetNumUnits()-1 do
                        local enemy=near:GetUnit(i)
                        if Teams[p:GetTeam()]:IsAtWar(Players[enemy:GetOwner()]:GetTeam()) then risk=risk+enemy:GetBaseCombatStrength() end
                    end end
                end
                if risk<bestDanger then best,bestDanger=plot,risk end
            end
        end
        if best then body:PushMission(MissionTypes.MISSION_MOVE_TO,best:GetX(),best:GetY(),0,0,1) end
        return
    end
    if not P.Ready(id) then return end
    local best,score,kind=nil,-math.huge,nil
    P.Nearby(body,1,function(u)
        for _,technique in ipairs({"possess","swap"}) do
            if P.Validate(id,technique,u) and (technique~="swap" or hp>=65 and danger<=body:GetBaseCombatStrength()*2) then
                local values=P.Values(id,technique)
                local value=math.max(u:GetBaseCombatStrength(),u:GetBaseRangedCombatStrength())
                    *(100-u:GetDamage())/100*(100+values.damage)/100
                    + (u:GetOwner()==GameDefines.BARBARIAN_PLAYER and 4 or 0)
                if technique=="swap" then value=value-3 end
                if value>score then best,score,kind=u,value,technique end
            end
        end
    end)
    if best then P.Activate(id,kind,best:GetOwner(),best:GetID()) end
end
