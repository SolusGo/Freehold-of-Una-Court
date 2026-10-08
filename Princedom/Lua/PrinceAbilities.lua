local P = Prince
local R = P.Rules
function P.Values(id,kind)
    return R.Values(kind,P.State(id)[kind == "swap" and "swap" or "possession"],
        GameInfo.GameSpeeds[Game.GetGameSpeedType()])
end
function P.Ready(id)
    local s=P.State(id)
    return P.IsPlayer(id) and Players[id]:IsAlive() and Players[id]:IsTurnActive() and s.started == 1 and s.fallen ~= 1
        and not s.kind and Game.GetGameTurn() >= s.readyTurn
end
local exclusions = {"PROMOTION_UNA_POSSESSED","PROMOTION_DOMINION_BORROWED_BODY",
    "PROMOTION_DOMINION_ENEMY_IN_TRENT","PROMOTION_DOMINION_SWAP_IMMUNE",
    "PROMOTION_ULTIMATE_POSSESSED","PROMOTION_PRINCE_IDENTITY","PROMOTION_PRINCE_BORROWED"}
function P.Validate(id,kind,target)
    if kind ~= "possess" and kind ~= "swap" then return false,"Unknown technique" end
    if not P.Ready(id) then return false,"Technique active, cooldown, or Trent unavailable" end
    local body=P.Body(id)
    if not body or body:GetOwner() ~= id or body:GetMoves() <= 0 or body:IsEmbarked() then
        return false,"Select Trent with movement remaining on land"
    end
    if not target or target:IsDead() or target:IsDelayedDeath() then return false,"Target no longer exists" end
    if target:GetOwner() == id then return false,"Requires an enemy" end
    local owner=Players[target:GetOwner()]
    if not owner or not owner:IsAlive() or not Teams[Players[id]:GetTeam()]:IsAtWar(owner:GetTeam()) then
        return false,"Requires war (Barbarians are eligible)"
    end
    if target:GetDomainType() ~= GameInfoTypes.DOMAIN_LAND or not target:IsCombatUnit()
        or target:IsEmbarked() or target:IsCargo() or target:GetCargo() > 0 then
        return false,"Requires an unembarked land military unit without cargo"
    end
    if target:GetPlot():IsCity() then return false,"Units inside cities are protected" end
    if Map.PlotDistance(body:GetX(),body:GetY(),target:GetX(),target:GetY()) ~= 1 then return false,"Must be adjacent" end
    if not target:GetPlot():IsVisible(Players[id]:GetTeam(),false) or target:IsInvisible(Players[id]:GetTeam(),false) then
        return false,"Target must be visible"
    end
    local info=GameInfo.Units[target:GetUnitType()]
    if info.Special == "SPECIALUNIT_PEOPLE" or (tonumber(info.ReligionSpreads) or 0)>0
        or (tonumber(info.Suicide) or 0)>0 or (tonumber(info.NukeDamageLevel) or 0)>0 then
        return false,"This unit has unsafe transfer state"
    end
    for _,name in ipairs(exclusions) do
        local promo=GameInfoTypes[name]
        if promo and target:IsHasPromotion(promo) then return false,"Unit is protected or already borrowed" end
    end
    if P.Ref(target:GetOwner(),target:GetID()) then return false,"Already involved in a technique" end
    local strength=math.max(target:GetBaseCombatStrength(),target:GetBaseRangedCombatStrength())
    local base=math.max(body:GetBaseCombatStrength(),body:GetBaseRangedCombatStrength())
    if strength > base * P.Values(id,kind).strength then return false,"Base strength exceeds this technique's mastery limit" end
    return true,"Eligible"
end
function P.Bonuses(id)
    local s=P.State(id)
    local p=Players[id]
    if not p then return end
    for city in p:Cities() do
        local count=city:GetNumRealBuilding(GameInfoTypes.BUILDING_PRINCE_FANFIC)
        city:SetNumRealBuilding(GameInfoTypes.BUILDING_PRINCE_FANFIC_ACTIVE,
            s.kind and s.fallen ~= 1 and count > 0 and 1 or 0)
    end
end
function P.Changed(id)
    P.Persist(id); P.Reindex(); P.Bonuses(id)
    LuaEvents.PrinceChanged(id)
end
function P.Activate(id,kind,owner,unitID)
    local target=P.Unit(owner,unitID)
    local valid,reason=P.Validate(id,kind,target)
    if not valid then return false,reason end
    local s,body,values=P.State(id),P.Body(id),P.Values(id,kind)
    local targetType,targetX,targetY=target:GetUnitType(),target:GetX(),target:GetY()
    local bodyType,bodyX,bodyY=body:GetUnitType(),body:GetX(),body:GetY()
    -- Reserve both destination objects before deleting either source. A failed
    -- allocation cannot leave an untracked captured target or missing hero.
    local reservedTarget=P.Allocate(target,id)
    local reservedShell=kind=="swap" and P.Allocate(body,owner) or nil
    if not reservedTarget or kind=="swap" and not reservedShell then
        P.Transaction(function()
            if reservedTarget then reservedTarget:Kill(false,-1) end
            if reservedShell then reservedShell:Kill(false,-1) end
        end)
        return false,"Could not reserve both bodies; nothing was transferred"
    end
    local borrowed=P.Transfer(target,id,reservedTarget)
    if not borrowed then return false,"Could not allocate the borrowed body" end
    local shell=body
    if kind == "swap" then
        shell=P.Transfer(body,owner,reservedShell)
        if not shell then
            local rollback=P.Transfer(borrowed,owner)
            if rollback then P.Place(rollback) end
            return false,"Could not transfer Trent; target returned"
        end
    end
    s.kind,s.activated,s.expires=kind,Game.GetGameTurn(),Game.GetGameTurn()+values.duration
    s.shellMovedTurn=nil
    s.targetOwner,s.borrowedOwner,s.borrowedID=owner,id,borrowed:GetID()
    s.targetType,s.targetX,s.targetY=targetType,targetX,targetY
    s.bodyType,s.bodyX,s.bodyY=bodyType,bodyX,bodyY
    s.damage,s.resistance=values.damage,values.resistance
    s.readyTurn=Game.GetGameTurn()+values.cooldown
    local counter=kind == "swap" and "swap" or "possession"
    s[counter]=R.Gain(s[counter]) -- Values above use pre-activation mastery.
    borrowed:SetHasPromotion(P.BORROWED,true)
    P.SetBody(id,shell)
    shell:SetHasPromotion(P.SHELL,true)
    if kind == "swap" then shell:SetHasPromotion(GameInfoTypes["PROMOTION_PRINCE_RESIST_"..values.resistance],true) end
    shell:SetMoves(0)
    P.Changed(id)
    Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_PRINCE_ACTIVATED",values.duration))
    return true
end
function P.End(id,reason,refreshBody)
    local s=P.State(id)
    if not s.kind then return true end
    local borrowed,body=P.Borrowed(id),P.Body(id)
    -- Return body first, so a temporary enemy controller's elimination cannot
    -- destroy the only original shell while returning the borrowed unit.
    if body and body:GetOwner() ~= id and s.fallen ~= 1 then
        local returned=P.Transfer(body,id)
        if not returned then return false end -- Retry next safe event; keep state.
        P.SetBody(id,returned); body=returned
    end
    if borrowed then
        if Players[s.targetOwner] and Players[s.targetOwner]:IsAlive() then
            local returned=P.Transfer(borrowed,s.targetOwner)
            if not returned then return false end
            P.ClearTemporary(returned)
            returned:SetMoves(0)
            P.Place(returned)
        else
            P.Transaction(function() borrowed:Kill(false,-1) end)
        end
    end
    P.ClearTemporary(body)
    s.kind,s.borrowedID,s.borrowedOwner,s.suspended=nil,nil,nil,nil
    if body then
        body:SetMoves(0)
        P.Place(body)
        -- CP refreshes ordinary movement at the previous turn's end. A
        -- scheduled return at our new turn must receive that fresh budget.
        if refreshBody and P.Body(id) then body:SetMoves(body:MaxMoves()); body:SetMadeAttack(false) end
    end
    P.Changed(id)
    return true
end
-- Serialize conventional ownership, matching the collection's CP save protocol.
-- Native serialization still writes all HP/XP/promotions/ScriptData; the save
-- database records which bodies to transfer back on the next frame or load.
function P.Suspend(id)
    local s=P.State(id)
    if not s.kind or s.suspended == 1 then return end
    if not Players[s.targetOwner] or not Players[s.targetOwner]:IsAlive() then P.End(id,"Original owner eliminated"); return end
    local body,borrowed=P.Body(id),P.Borrowed(id)
    if not body or not borrowed then return end
    if s.kind == "swap" then
        body=P.Transfer(body,id)
        if not body then return end
        P.SetBody(id,body)
    end
    borrowed=P.Transfer(borrowed,s.targetOwner)
    if not borrowed then
        if s.kind == "swap" then
            local rollback=P.Transfer(body,s.targetOwner)
            if rollback then P.SetBody(id,rollback) end
        end
        return
    end
    s.borrowedOwner,s.borrowedID,s.suspended=borrowed:GetOwner(),borrowed:GetID(),1
    P.Persist(id); P.Reindex()
end
function P.Resume(id)
    local s=P.State(id)
    if s.suspended ~= 1 or not s.kind then return end
    if not Players[s.targetOwner] or not Players[s.targetOwner]:IsAlive() then P.End(id,"Original owner eliminated"); return end
    local borrowed,body=P.Borrowed(id),P.Body(id)
    if not body then P.QueueFall(id,-1); return end
    if not borrowed then s.borrowedID=nil; P.End(id,"Borrowed body missing on load"); return end
    borrowed=P.Transfer(borrowed,id)
    if not borrowed then return end
    s.borrowedOwner,s.borrowedID=id,borrowed:GetID()
    if s.kind == "swap" then
        local shell=P.Transfer(body,s.targetOwner)
        if not shell then
            local rollback=P.Transfer(borrowed,s.targetOwner)
            if rollback then s.borrowedOwner,s.borrowedID=s.targetOwner,rollback:GetID() end
            P.Persist(id); P.Reindex(); return
        end
        P.SetBody(id,shell)
    end
    s.suspended=nil
    P.Changed(id)
end
