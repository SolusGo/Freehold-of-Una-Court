-- CP v151: BattleDamageDelta's role is the SOURCE of damage. The getter may
-- be queried repeatedly, so this handler is pure and never changes HP.
local P=Prince
local participants={}
GameEvents.BattleStarted.Add(function() participants={} end)
GameEvents.BattleJoined.Add(function(owner,unitID,role,isCity)
    participants[role]={city=isCity, ref=not isCity and P.Ref(owner,unitID) or nil}
end)
GameEvents.BattleDamageDelta.Add(function(role,damage)
    local source=participants[role]
    if not source then return 0 end
    local ref=source.ref
    local delta=0
    if ref and ref.role=="borrowed" then
        local s=P.State(ref.player)
        if s.kind and s.suspended~=1 then delta=P.Rules.DamageDelta(damage,s.damage or 0) end
    end
    -- CvCity::rangeCombatDamage omits DamageTakenMod in CP v151. Apply
    -- resistance once here for city bombardment; unit attacks use native armor.
    local receiver=participants[role==0 and 1 or 0]
    local target=receiver and receiver.ref
    if source.city and target and target.role=="body" then
        local s=P.State(target.player)
        if s.kind=="swap" and s.suspended~=1 then
            return P.Rules.DamageDelta(damage,-s.resistance)
        end
    end
    return delta
end)
GameEvents.BattleFinished.Add(function() participants={} end)
-- Shell resistance uses DamageTakenMod promotions in the native melee,
-- ranged and city damage calculation, before lethal damage is applied.
-- There is no post-combat healing, recursion, or death prevention.
