# CP v151 API audit and known engine limits

Inspected the installed **Community Patch v151 (5.4.6)** modinfo, database schema files and native API source at revision [`aefacbf1b24a27aa42dc50b4283420a999f7fded`](https://github.com/LoneGazebo/Community-Patch-DLL/tree/aefacbf1b24a27aa42dc50b4283420a999f7fded). Its `CustomMods.h` identifies itself as CP v151. This source audit establishes available interfaces; it does not prove that every binary distributed under version 151 is identical to this revision.

## Verified interfaces

Source paths below refer to `CvGameCoreDLL_Expansion2/` at that revision:

| Interface | Source | Implementation use |
| --- | --- | --- |
| `UnitPrekill(player,unit,type,x,y,delay,killer)` | `CustomMods.h`, `CvUnit.cpp::kill` | Original-body death and borrowed-body loss. Internal conversions suppress only this mod's death handling. |
| `UnitUpgraded(player,old,new,goody)` | `CvUnit.cpp::DoUpgradeTo` | Fires before native conversion removes the old object; transfers canonical identity first. |
| `UnitConverted(oldPlayer,newPlayer,oldID,newID,isUpgrade)` | `CvUnit.cpp::convert` | Tracks ownership/type changes before `old->kill(true)`. Unexpected conversions follow the physical body and cancel control safely. |
| `newUnit:Convert(oldUnit,isUpgrade)` | `Lua/CvLuaUnit.cpp::lConvert` | Native conversion plus exact explicit HP, XP-times-100, level, promotions, movement, name and ScriptData restoration. Source delayed deletion is completed before serialization. |
| `CanDoCommand`, `CanHaveAnyUpgrade`, `UnitCanHaveAnyUpgrade`, `PlayerCanGiftUnit`, `PlayerCanDisbandUnit` | `CustomMods.h`, `CvUnit.cpp` | Command, upgrade, gifting and scrapping vetoes. `PlayerCanDoCommand` is not assumed to exist. |
| `CanMoveInto`, `UnitCanPillage`, `UnitCanRangeAttackAt`, `UnitSetXY` | `CustomMods.h`, `CvUnit.cpp` | Immobilization, shell attack/city/embark restrictions, borrowed embark restriction and shell movement budget. |
| `BattleStarted`, `BattleJoined`, `BattleDamageDelta`, `BattleFinished` | `CustomMods.h`, `CvGameCoreStructs.cpp`, `CvUnitCombat.cpp` | Source-role lookup and pure outgoing damage adjustment, plus city bombardment resistance. |
| `UnitPromotions.DamageTakenMod` | Installed `PromotionTableChanges.sql`, `CvUnit.cpp::getMeleeCombatDamage`, `GetRangeCombatDamage` | Native percentage reduction of actual unit-combat damage. Resistance is never represented as Combat Strength. |
| `GameSave` | `CustomMods.h` | Normalizes controllers before native serialization, then queues resumption through the collection's one-frame deferred queue. Loading reconstructs control from scalar save data and native unit state. |
| `CustomMissionPossible`, `CustomMissionStart`, associated custom mission events | `CustomMods.h`, `CvUnitMission.cpp` | Investigated. A dedicated UI and AI call the same validated backend; no fake native mission or replacement UnitPanel is needed for single player. |
| `KillCities`, native `verifyAlive()` | `Lua/CvLuaPlayer.cpp`, `CvPlayer.cpp` | Removes cities/units and lets the genuine native elimination check set the defeated state. There is no exposed Lua `SetAlive` in the audited API. |

`EVENTS_CAN_MOVE_INTO` is explicitly labeled expensive upstream. Its handler immediately returns after one dictionary lookup for unrelated units, with no global unit or map scan, database access or save reads. Target searches are local, city reconciliation occurs only on relevant events/turns, and the technique panel has no update loop. Native turn and combat generation remain authoritative.

## Combat differences imposed by the DLL

* `BattleDamageDelta(role,baseDamage)` uses the **source** role, not the recipient. `CvCombatInfo::getDamageInflicted()` can call it repeatedly; the handler returns a pure delta and never mutates health. This avoids recursion and duplicate processing.
* Native `DamageTakenMod=-90` scales normal melee/ranged incoming damage to roughly 10% before health changes. `CvCity::rangeCombatDamage` omits that field, so city bombardment receives one negative delta from the combat hook instead. No post-combat healing is used. A sufficiently damaging hit can still kill the shell.
* **Positive delta cap:** `CvCombatInfo::getDamageInflicted()` caps increases using the source body's remaining hit points. For example, base damage 50 with a +40% intended modifier becomes 70 for a healthy source, but an injured source may be capped below that value. The mod uses the supported hook and preserves that native clamp. This can weaken a positive bonus on a badly wounded borrowed body. Altering HP to evade the clamp would introduce lethal-combat and save-state errors; a corrected DLL would be required for exact universal increases.
* The hook sees damage after some native caps and simultaneous-death adjustments. Combat previews and animations can use cached final damage computed before the hook and differ from final applied HP changes. Check actual HP rather than relying solely on the preview.
* Native armor does not intercept arbitrary `SetDamage`, nuclear destruction, or every terrain, attrition or third-party scripted damage source. These can still kill the original body and correctly trigger collapse. Other promotions' `DamageTakenMod` values combine according to native additive rules. Consequently the table is exact for normal baseline combat and approximately describes combat with other special damage effects; it is not invulnerability.

## Defeat timing and ownership caveats

The original-body death callback immediately persists `fallen=1`, disables techniques and removes Monument bonuses. City/unit destruction runs through the shared deferred queue outside `CvUnit::kill` to avoid a re-entrant combat deletion. After all cities and living units are gone, CP's next native `verifyAlive()` sets the genuine defeated flag. This is **not a synchronous Lua SetAlive(false)** and may wait for a native turn boundary. It handles Complete Kills and pre-city starts because both cities and units are removed. An unusual removal with no death/conversion event is detected at the next player-turn reconciliation. If strict same-callback native defeat is required, the DLL must expose a safe elimination operation.

Both destination bodies are allocated before either source is converted. Failed allocations leave the originals intact and grant no mastery/cooldown. Returns keep tracked state when allocation fails and retry at a later safe turn. No replacement is spawned for a body that actually died. A unit cannot be returned to an eliminated original owner. Native relocation is deterministic and may move a returned body away from its current location; no legal plot means its removal, including defeat if it is Trent.

Save suspension keeps the logical technique active, its locked modifiers, deadlines and Monument bonus, while writing ordinary ownership. It does not award mastery or restart cooldown. Native unit serialization holds the current promotions, experience and health; scalar save keys hold both canonical IDs/controllers and original type/activation-position metadata. The original unit's ScriptData is preserved verbatim rather than appropriated as a mod identity tag. Conversion can still trigger other mods' events, and arbitrary third-party state stored solely against old unit IDs is outside native conversion's guarantees. Fortification/mission queues and partly used multiattack counters cannot be reproduced exactly through the audited public Lua setters; transfers may reset those transient tactical states. Zero movement and exhausted attacks are preserved, and ordinary returned units are exhausted until their normal refresh.

The AI's local safety checks reduce obvious risks but cannot give the DLL tactical planner a complete understanding of global death stakes. Multiplayer and hotseat are disabled: direct UI LuaEvents are not a network-synchronized mission protocol. No in-game binary, save-file round trip, huge-map performance run or renderer behavior has been claimed tested.
