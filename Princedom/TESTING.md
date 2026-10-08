# Validation record and engine checklist

Automated checks run on **9 October 2026**. Gameplay tests execute the actual new backend in **Lua 5.1** through Lupa. They use an explicit Civ V API mock; the mock does not emulate the full DLL, rendering, serialization or native defeated flag.

## Executed automated checks

| Check | Result |
| --- | --- |
| Opening Warrior replacement, exactly one canonical hero, no repeated spawn | Passed |
| Retraining, gifting, disbanding and active upgrade vetoes | Passed |
| Enemy and Barbarian eligibility, both techniques, invalid categories | Passed |
| Separate mastery, failed-activation behavior, cap and thresholds | Passed |
| 130 combinations of 13 mastery counts × 2 techniques × 5 speeds | Passed |
| Shared fixed cooldown, activation/expiration turn boundaries | Passed |
| Pure source-role damage hook and repeat-query behavior | Passed |
| Native resistance promotion selection, city bombard delta 50 → 5 at 90% | Passed in mock; actual DLL application pending |
| Shell ownership/action/movement restrictions and borrowed embark veto | Passed |
| Evolving health, fractional XP, promotions, position and ScriptData on return | Passed |
| Borrowed-body death preserves Trent | Passed |
| Original-body death normally, during both techniques, before a city and after repeated upgrades | Passed empire cleanup in mock; native defeated flag pending |
| Multiple normal upgrades retain identity, cooldown and both masteries | Passed |
| Fanfic Monument bonuses apply once, only to Monument cities, and clear | Passed |
| Save normalization/resumption, load-state reconstruction and fresh IDs | Passed in mock; real save serialization pending |
| Eliminated target owner, peace and unexpected borrowed conversion | Passed |
| Failed possession and failed two-body allocation preserve original sources | Passed |
| Local AI activation and wounded retreat | Passed |
| Real SQL on in-memory BNW + installed CP v151 schema | Passed |
| Scalar and related-table Warrior/Monument inheritance, retrainable militia | Passed |
| Existing baseline unit/building/civilization rows remain unchanged | Passed |
| English localization references and city/diplomacy rows | Passed |
| DDS dimensions, mipmaps, transparency, atlas texture references and XML | Passed |
| Manifest file hashes, ordered registrations and 5 UI entry points | Passed |
| Lua 5.1 syntax for all new gameplay/UI files | Passed |
| Actual panel code against UI mock: target activation and city/diplomacy/popup/bulk visibility | Passed; native rendering pending |
| Complete seven-civilization SQL activation order | Passed |
| Existing Freehold/Dominion/Ultimate possession safety regression suite | Passed |
| Existing Soft Kitty (12), Library Exile (10) and Phone Stealer (24) Lua gameplay scenarios | Passed |

Commands from the repository root:

```powershell
python Tools/package_mod.py
python Tools/test_princedom.py
python Tools/validate_princedom.py
python Tools/package_mod.py --package
```

Install matching Python dependencies if needed: Pillow for asset checks and Lupa for Lua 5.1. `test_princedom.py` looks in `.modbuddy/test-deps311`, `.modbuddy/test-deps`, then normal Python packages. SQL checks read the local BNW debug database and installed CP schema without changing either.

## Pending real in-game checks

All boxes below are **not run**. Use BNW with Community Patch v151, enable logging in the game's configuration, and install the generated mod folder. Start a fresh game. FireTuner/IGE may be used to set up targets and technologies; their use is optional and should be recorded. Record save names, speed, mods and Lua/Database log errors for each failure. Inspect actual applied HP changes and unit counts, rather than only combat previews.

1. **Database and opening:** select the new leader, inspect Dawn/diplomacy/Civilopedia/portraits. Confirm one Settler plus the intended initial hero replacement (difficulty may provide extra ordinary units). Confirm 12 strength against an 8-strength Warrior. Confirm the ordinary Warrior militia is trainable, while Trent is absent from production, Gold and Faith purchases. Start on each difficulty/era you support.
2. **Targets:** create adjacent enemy and Barbarian Warriors and archers. Verify both techniques. Check civilian, naval, aircraft, embarked, city-garrison, invisible, distant, friendly and already-borrowed units are rejected. Confirm range one across wrapped map edges. Other collection heroes and borrowed bodies must be immune.
3. **Progression:** perform enough uses to reach 3, 6, 9 and 12 stacks separately in each technique. Confirm only that counter increases, failed clicks do not grant progress, stack 13 is impossible, thresholds affect the next activation and the other technique's target ceiling stays independent. Use an archer with ranged strength above its melee strength to confirm eligibility uses the higher value.
4. **Timing:** repeat a short ability and maximum mastery at Quick, Standard, Epic and Marathon. At turn T verify cooldown immediately becomes 5/8/12/24 and expiration occurs on your player turn T+D. At T+C confirm readiness. Save near both boundaries; loading and other player turns must not advance either timer twice. Test a custom speed with TrainPercent=200 (cooldown 16, mastered duration 6).
5. **Possession:** verify original-body immobility, normal vulnerability and borrowed movement/combat role. Test melee and ranged actual damage at every threshold against identical targets. Kill the borrowed body and confirm the original survives and the bonus ends. Test a target with zero movement and one that gains a promotion under control.
6. **Body Swap:** verify the enemy and Barbarians receive the original body. Try moving more than one land tile, melee/ranged attacking, pillaging, embarking, gifting, deleting, upgrading and city capture; all prohibited actions must fail. Test AI control of the shell. Compare an ordinary 50-damage hit against 80/82/85/88/90% resistance and include city bombardment. Confirm a sufficiently large hit can still kill the original body. Test the documented positive-offense clamp with a wounded borrowed attacker and distinguish it from a bug in base-strength math.
7. **Fatal identity:** kill Trent normally, during possession, while enemy-controlled in a swap, after several upgrades, before founding a city and under Complete Kills. Confirm all owned cities/units are removed without combat assertions and the native defeat UI/IsAlive state changes at CP's verification boundary. Test unusual deletion/conversion and eliminated shell controller. There must be no respawn on a later turn or reload.
8. **Upgrades:** between techniques, perform the installed Warrior's normal chain and a goody-hut upgrade. Check name/identity, XP/promotions, health, both masteries and cooldown; test abilities after each upgrade. Try upgrading either active body and obtaining extra Trent units through other means. There must be no false defeat or duplicate hero.
9. **Returns:** move both bodies, gain damage/XP/promotions, sign peace, eliminate the target's original owner and force stacking/terrain conflicts. Verify current state returns once, owner elimination never resurrects a civilization, no body permanently stays with the temporary controller and illegal placement resolves deterministically. Test city capture by a borrowed military unit and its eventual return.
10. **Save/load:** manually save and autosave during each technique, both from your turn and a safe interturn state. Load each save into a fresh application session. Check canonical IDs, ownership, state, active duration, cooldown and Monument yields. Repeat after upgrading and after a borrowed death. Check unit counts before/after every transfer and save.
11. **Fanfic Monument:** compare baseline and active yields in multiple cities, including one without a Monument. Repeat techniques, sell/build/capture a Monument, save/load and end a technique. Confirm +2 → +4 → +2 intrinsic Culture on this baseline, no extra maintenance and no duplication of policy/religion class bonuses.
12. **UI:** select Trent, another unit and a borrowed body; reopen the panel during active control and after loading. Check targets/highlights and invalid explanations. Enter and exit diplomacy, cities, technology tree, social policies, Culture Overview and Civilopedia while open. The panel must disappear and recover, and highlights must clear.
13. **AI/performance/regression:** watch AI Una Court use both techniques, gain Barbarian mastery, respect cooldown and retreat from danger. Run a long Huge-map game with 22 major civilizations. Inspect turn times and Lua logs. Start each of the other six civilizations and exercise their native mechanics; their balance and UI must remain unchanged apart from protecting the new canonical hero from other possession systems.

Log checks: no SQL load failures in `Database.log`; no unhandled errors or missing includes/textures in `Lua.log` and UI logs. Save screenshots and a pre-failure save for any unresolved engine issue. Do not mark these checks passed solely because the mock suite passes.
