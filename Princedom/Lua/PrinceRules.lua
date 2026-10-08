-- Pure rules shared by gameplay, UI snapshots and the Lua 5.1 tests.
Prince = Prince or {}
Prince.Rules = {}
local R = Prince.Rules
function R.Level(stacks) return math.min(5, math.floor(math.max(0, stacks) / 3) + 1) end
function R.Gain(stacks) return math.min(12, math.max(0, stacks) + 1) end
function R.Speed(info)
    local speeds = { GAMESPEED_QUICK={5,0.67}, GAMESPEED_STANDARD={8,1},
        GAMESPEED_EPIC={12,1.5}, GAMESPEED_MARATHON={24,3} }
    local s = speeds[info.Type]
    local factor = math.max(0.01, (tonumber(info.TrainPercent) or 100) / 100)
    return s and s[1] or math.max(1, math.floor(8 * factor + 0.5)), s and s[2] or factor
end
function R.Values(kind, stacks, speed)
    local level = R.Level(stacks)
    local cooldown, factor = R.Speed(speed)
    local duration = ({1,1,2,2,3})[level]
    return { level=level, duration=math.max(1, math.floor(duration * factor + 0.5)),
        cooldown=cooldown, strength=({1,1.25,1.5,2,math.huge})[level],
        damage=(kind == "swap" and {-20,0,15,25,40} or {-35,-20,-10,0,10})[level],
        resistance=kind == "swap" and ({80,82,85,88,90})[level] or 0 }
end
function R.DamageDelta(damage, modifier)
    if damage <= 0 then return 0 end
    return math.max(1, math.floor(damage * (100 + modifier) / 100 + 0.5)) - damage
end
