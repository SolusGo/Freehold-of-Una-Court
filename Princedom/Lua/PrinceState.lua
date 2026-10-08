-- Native conversion preserves DLL-managed unit metadata. Explicit snapshots
-- restore fields Convert recalculates using the receiving owner's traits.
Prince = Prince or {}
local P = Prince
P.save = Modding.OpenSaveData()
P.states, P.refs, P.pending, P.depth = {}, {}, {}, 0
P.CIV = GameInfoTypes.CIVILIZATION_PRINCE_UNA
P.UNIT = GameInfoTypes.UNIT_PRINCE_TRENT
P.IDENTITY = GameInfoTypes.PROMOTION_PRINCE_IDENTITY
P.BORROWED = GameInfoTypes.PROMOTION_PRINCE_BORROWED
P.SHELL = GameInfoTypes.PROMOTION_PRINCE_SHELL
local fields = {"started","fallen","bodyOwner","bodyID","possession","swap","readyTurn",
    "kind","expires","activated","targetOwner","borrowedOwner","borrowedID","resistance",
    "damage","suspended","targetType","targetX","targetY","bodyType","bodyX","bodyY","shellMovedTurn"}
function P.IsPlayer(id)
    local p = Players[id]
    return p and p:GetCivilizationType() == P.CIV
end
function P.State(id)
    if not P.states[id] then
        local s = { possession=0, swap=0, readyTurn=0, bodyOwner=id, bodyID=-1 }
        for _, k in ipairs(fields) do
            local v = P.save.GetValue("PRINCE_V1_" .. id .. "_" .. k)
            if v ~= nil then s[k] = v end
        end
        s.possession = math.min(12, math.max(0, tonumber(s.possession) or 0))
        s.swap = math.min(12, math.max(0, tonumber(s.swap) or 0))
        P.states[id] = s
    end
    return P.states[id]
end
function P.Persist(id)
    local s = P.State(id)
    for _, k in ipairs(fields) do P.save.SetValue("PRINCE_V1_" .. id .. "_" .. k, s[k]) end
end
function P.Unit(owner, id)
    local p = Players[owner]
    local u = p and id and p:GetUnitByID(id)
    if u and not u:IsDead() and not u:IsDelayedDeath() then return u end
end
function P.Body(id) local s=P.State(id); return P.Unit(s.bodyOwner,s.bodyID) end
function P.Borrowed(id) local s=P.State(id); return P.Unit(s.borrowedOwner,s.borrowedID) end
function P.RefKey(owner,id) return tostring(owner)..":"..tostring(id) end
function P.Reindex()
    P.refs = {}
    for id,s in pairs(P.states) do
        if s.started == 1 and s.fallen ~= 1 then
            P.refs[P.RefKey(s.bodyOwner,s.bodyID)] = { player=id, role="body" }
            if s.kind then P.refs[P.RefKey(s.borrowedOwner,s.borrowedID)] = { player=id, role="borrowed" } end
        end
    end
end
function P.Ref(owner,id) return P.refs[P.RefKey(owner,id)] end
function P.Snapshot(u)
    local s = { type=u:GetUnitType(), ai=u:GetUnitAIType(), x=u:GetX(), y=u:GetY(),
        damage=u:GetDamage(), xp=u:GetExperienceTimes100(), level=u:GetLevel(),
        moves=u:GetMoves(), attack=u:IsOutOfAttacks(), name=u:GetNameNoDesc(),
        script=u:GetScriptData(), facing=u:GetFacingDirection(), promotions={} }
    for row in GameInfo.UnitPromotions() do s.promotions[row.ID] = u:IsHasPromotion(row.ID) end
    return s
end
function P.Apply(u,s)
    for promotion,enabled in pairs(s.promotions) do u:SetHasPromotion(promotion,enabled) end
    u:SetExperienceTimes100(s.xp)
    u:SetLevel(s.level)
    u:SetDamage(s.damage)
    u:SetName(s.name)
    u:SetScriptData(s.script)
    u:SetMoves(s.moves)
    if s.attack then
        for _=1,32 do
            if u:IsOutOfAttacks() then break end
            u:SetMadeAttack(true)
        end
    end
end
function P.Transaction(callback)
    P.depth = P.depth + 1
    local ok,a,b = pcall(callback)
    P.depth = P.depth - 1
    if not ok then print("Princedom transfer error: " .. tostring(a)) end
    return ok,a,b
end
function P.Allocate(u,owner)
    local snapshot=P.Snapshot(u)
    local created
    P.Transaction(function()
        created=Players[owner]:InitUnit(snapshot.type,snapshot.x,snapshot.y,snapshot.ai,snapshot.facing)
    end)
    return created
end
function P.Transfer(u, owner, reserved)
    if not u or not Players[owner] then return nil end
    if u:GetOwner() == owner then return u end
    local snapshot = P.Snapshot(u)
    local sourceOwner,sourceID=u:GetOwner(),u:GetID()
    local created=reserved or P.Allocate(u,owner)
    if not created then return nil end -- Source still exists: safe allocation failure.
    local ok = P.Transaction(function()
        created:Convert(u,false)
        P.Apply(created,snapshot)
        -- Convert uses delayed deletion. Finish it before native save
        -- serialization, so an old-controller copy cannot enter the save.
        if u:IsDelayedDeath() then u:Kill(false,-1) end
    end)
    if not ok then
        -- Never delete a source that survived an unsuccessful conversion.
        if P.Unit(sourceOwner,sourceID) then
            P.Transaction(function() created:Kill(false,-1) end)
            return nil
        end
        -- Conversion succeeded, but a setter failed: retain the sole live body.
        print("Princedom retained converted body after a metadata setter failed")
    end
    return created
end
function P.SetBody(id,u)
    local s=P.State(id)
    s.bodyOwner,s.bodyID=u:GetOwner(),u:GetID()
    u:SetHasPromotion(P.IDENTITY,true)
    u:SetName(Locale.ConvertTextKey("TXT_KEY_PRINCE_TRENT"))
    P.Reindex(); P.Persist(id)
end
function P.ClearTemporary(u)
    if not u then return end
    u:SetHasPromotion(P.BORROWED,false)
    u:SetHasPromotion(P.SHELL,false)
    for _, resistance in ipairs({80,82,85,88,90}) do
        u:SetHasPromotion(GameInfoTypes["PROMOTION_PRINCE_RESIST_"..resistance],false)
    end
end
function P.Place(u)
    -- Native search is deterministic, respects terrain and 1UPT, and keeps the
    -- current tile if legal. No fallback spawning or duplicate bodies.
    if u and not u:JumpToNearestValidPlot() then
        print("Princedom: no legal return tile; removing stranded body")
        u:Kill(false,-1)
        return false
    end
    return u ~= nil
end
