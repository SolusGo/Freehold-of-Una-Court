# Wealthy Trent: implementation and engine checks

This is the eighth civilization in the existing version 3 mod, with the same GUID
and CP v151 dependency. Start a new game: saves without these database entries are
unsupported. The new civilization is human-only (`Playable=1`, `AIPlayable=0`).
The native Palace free-building class and ordinary Settler/handicap Warrior setup
are retained. There are no unique units, possession, Buddy or collapse mechanics.

## Economy and turn order

Only Trent's `GameEvents.PlayerDoTurn` advances the economy. First reconcile
Palaces, then process any existing installments, then activate a due audit.
Activation on turn T transfers 5% immediately. Installments run on T+1 through
T+5, exactly once each. A zero-payment turn still consumes an installment.
UI refresh, load, capital capture and era callbacks never transfer Gold.

At initialization, the first audit is scheduled for the current turn plus
`floor(25 * GameSpeeds.TrainPercent / 100 + 0.5)`. This follows the collection's
speed convention: Standard 25, Quick 17, Epic 38, Marathon 75. Subsequent audits
are scheduled from the activation turn, including when nobody qualifies. A missed
callback never produces a backlog of old audits. Five installment turns always
remain five, independent of speed. An interrupted/dead target slot is dropped.

Rank **all living, met foreign major civilizations** by treasury descending, then
player ID ascending. Take the richest `ceil(count / 3)` and, within that group,
select at most two with treasury >=500 and calculated GPT >=10. Qualifiers outside
the richest third do not replace ineligible members of that third. War and team
membership do not exempt an otherwise foreign civilization. City-States and
Barbarians are excluded. Other Wealthy players, if inserted with custom setup,
can be foreign donors; every recipient maintains independent state.

Immediate payment: `min(availableGold, floor(treasury * 5 / 100))`.
Installment: `min(availableGold, floor(max(0, CalculateGoldRate()) * 20 / 100))`.
Both `ChangeGold(-amount)` on the donor and `ChangeGold(amount)` on Trent execute
in the same synchronous Lua callback. No Gold is created by collection. There
are no native GPT modifiers, diplomacy deals or UI-only accounting changes.
CalculateGoldRate supplies CP's integer GPT; fractional GPT is not taxed.

State is stored through `Modding.OpenSaveData()` like the existing civilizations:
scalar keys `TRENT_WEALTHY_V1_<playerID>_LAST`, `NEXT`, `REMAINING`, `TARGET1`,
and `TARGET2`. LAST is persisted before any mutations to prevent duplicate or
re-entrant processing. NEXT, remaining turns and selected player IDs survive
reload. Reload never performs economy processing. Normal game saves capture the
native treasuries and mod save state together. This is not crash-atomic database
accounting; crashing halfway through a callback is outside supported save/load.

Eliminated Trent receives no payments. Observed elimination clears active slots;
resurrection retains his cooldown and may start a new due audit, without arrears.
A victim eliminated at payment time is removed from that audit even if later
resurrected. A skipped turn does not generate multiple catch-up installments.

One aggregated audit/payment report goes to Trent, with one report per affected
human donor per turn. Each shows actual Gold removed/received and remaining turns.

## Centrelink and Palace inheritance

`110_Wealthy_Inherit.sql` executes after the shared Centrelink and all seven prior
civilizations. It clones the shared Centrelink and the active Palace, including
all supported BNW/CP `Building_*` relationship tables. SELECT * clones scalar
columns at activation time, so the active ruleset's actual values are retained.
The generator discovers tables only from installed BNW/CP schemas, avoiding
optional third-party or temporary debug tables. The shared Centrelink itself is
never changed. Rebuild inheritance when targeting a materially different schema.

For Wealthy Centrelink, positive intrinsic Yield/YieldChange/YieldModifier,
Happiness, NumSpecialists and free-specialist Count table effects double.
Positive scalar Happiness, UnmoddedHappiness, SpecialistCount and
TradeRouteRecipientBonus double. TradeRouteTargetBonus benefits foreign traders
and remains unchanged. Costs, maintenance, prerequisites, production/purchase
rules, negative effects and flavor weights remain unchanged. Current inspected
baseline: cost 200, Banking, +1 local Happiness, one Merchant, recipient/target
bonuses 1/1. Wealthy: cost 200, Banking, +2 local Happiness, two Merchants,
recipient/target 2/1. Yield tables are inherited and multiplied, never invented.
The audited [CvTradeClasses.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/aefacbf1b24a27aa42dc50b4283420a999f7fded/CvGameCoreDLL_Expansion2/CvTradeClasses.cpp#L3165)
confirms TargetBonus pays the route origin owner while RecipientBonus pays the
destination owner; only the latter is doubled on Trent's building.

`BUILDING_TRENT_WEALTHY_PALACE` uses BUILDINGCLASS_PALACE, Capital=1 and all
active Palace effects/relationship rows. It is distinct from Ultimate's National
Wonder. One of eight unbuildable, hidden Luxury Allowance tiers is present in the
current Capital. The tiers give total +N UnmoddedHappiness and +2N Gold, with
N=clamp(currentEra+1,1,8). Era progression replaces the old tier; it never adds
another tier. Lua removes stray Wealthy Palaces/tiers outside the current Wealthy
Capital, including transferred cities, and removes a duplicate ordinary Palace
only from Wealthy cities. Other civilizations' normal Palaces are untouched.

CP API audit used the installed CP v151 (5.4.6) schema and source revision
`aefacbf1b24a27aa42dc50b4283420a999f7fded`, already retained in `.modbuddy/cp151`.
`CvCity::GetLocalHappiness` includes UnmoddedHappiness, and in Community Patch-only
mode `CvPlayer::GetHappinessFromCities` sums it uncapped into empire Happiness.
This satisfies the empire-wide bonus without population-capped local Happiness.
Full Vox Populi changes Happiness accounting and is **not** a compatibility claim.
`CvLuaPlayer` exposes GetGold/ChangeGold/CalculateGoldRate; no unsupported DLL calls
are assumed. `TeamSetEra` requires **EVENTS_NEW_ERA**, explicitly enabled here.
Standard PlayerDoTurn, CityCaptureComplete and PlayerCityFounded plus load
reconciliation cover normal transitions; arbitrary third-party capital changes
are repaired by the next player-turn reconciliation.

## Automated checks

Run from the repository root:

```
python Tools/build_wealthy_inheritance.py
python Tools/build_wealthy_art.py
python Tools/package_mod.py --package
python Tools/validate_wealthy.py
python Tools/test_wealthy.py
```

The validator runs all manifest SQL against a read-only copy of the available
debug DB with the installed CP schema. It checks all eight civilizations,
human-only flags, class overrides, starting units, every prior DB row, both
building inheritance sets, positive/negative sentinel effects, localizations,
atlases, DDS mipmaps/transparency, manifest hashes, project parity and GUID/version.
This is a schema/inheritance dry-run, **not** proof that the game loaded it.
After launching the mod, optional read-only actual cache checks can be run with
`python Tools/validate_wealthy.py --loaded-db "<path to Civ5DebugDatabase.db>"`.

The Lua 5.1 harness executes the actual module, covering conservation, five
payments, reloads, duplicate callbacks, changing GPT, liquidity caps, eligibility,
ties, Standard/Quick/Marathon, eliminated players, resurrection, empty audits,
era tiers, capital capture, pre-city starts, notifications, advanced starts and
no-Wealthy no-op. Lupa must be available; this checkout includes ignored local
Python 3.11 and 3.12 test dependencies. Pillow is needed for asset checks.

## Manual in-game verification — pending

1. Package and enable only this collection and CP v151. Start a new Standard
   game as The Wealthy of Una Court. Check all eight setup options, human-only
   random AI exclusion, Warrior/Settler and two building uniques; no Trentrouls.
2. Inspect capital Palace yields, Great Work slot, defense and other baseline
   effects against an ordinary Palace. Confirm +1 empire Happiness and +2 GPT
   with a one-population Capital. Inspect the Happiness breakdown to distinguish
   this from population-capped local Centrelink Happiness.
3. Meet enough major civilizations. Set one eligible donor to 2,000 Gold/+100 GPT
   and keep its economy constant. Observe 100 immediate and exactly five 20-Gold
   deductions. Account separately for normal native per-turn Gold income.
4. Save/reload on audit turn and during each installment; confirm no duplicate
   deductions and unchanged targets/cooldown. Try manual and end-turn autosaves.
5. Test negative GPT, empty treasury, war, ties, two donors, an unmet rich leader,
   City-States/Barbarians, donor elimination and Trent elimination/resurrection.
6. Verify the Capital's tiers at Medieval (+3/+6) and Information (+8/+16), with
   no old tiers. Capture the Capital; check native relocation and exactly one
   allowance. Recapture it and reload. Repeat with no surviving cities.
7. Reach Banking: compare the original and Wealthy Centrelinks in production,
   tooltips and loaded DB. Confirm prerequisites and later building chains,
   unchanged cost/maintenance and foreign trader income, double Merchant capacity
   and positive yields/modifiers. Capture a Centrelink city with another civ and
   verify native building-class conversion removes Wealthy-only benefits.
8. Repeat audit on Marathon (75-turn interval, five installments). Inspect Dawn,
   map, diplomacy scene, icons and Civilopedia. Confirm other seven civilizations'
   unique mechanics behave as before.

No actual in-game scenarios above have been claimed as passed. Single-player is
the target; multiplayer and hotseat remain disabled by the existing collection.

## Recorded validation results

- `test_wealthy.py`: **20/20** scenarios passed using actual Lua 5.1.
- `validate_wealthy.py`: full 31-action activation sequence, all eight identities,
  unchanged previous DB rows, Centrelink/Palace inheritance, positive/negative
  sentinel inputs, era tiers, localization and 305-file manifest/asset checks passed.
- Existing `validate_mod.py`, `validate_soft_kitty.py`,
  `validate_library_exile.py`, `validate_princedom.py` passed.
- `validate_phone_stealer.py` passed with its required pre-Phone-Stealer baseline
  generated in an ignored workspace cache from earlier manifest actions. The
  unmodified validator cannot run against a plain BNW debug cache because it
  expects the shared Centrelink to already exist. No game cache was changed.
- Existing Soft Kitty (12), Library Exile (10), Phone Stealer (24), Princedom (33)
  and possession-safety gameplay suites passed using the local Python 3.11/Lupa
  runtime. Older harnesses' Python 3.12 dependency path was adapted in the runner
  by pre-importing the installed 3.11 Lua runtime; their source files were unchanged.
- Plain-file packaging succeeded with version 3, the original GUID, the existing
  five UI entry points and the new gameplay loaded through UnaCourtLoader.
- Palace/civilization/leader icons were visually inspected. Dawn and leader scene
  derive from the generated source shown during implementation. Native game art,
  tooltip refresh and gameplay checks remain pending above.

## File inventory

Modified: `Lua/UnaCourtLoader.lua`, `UnaCourt.civ5proj`, `UnaCourt.modinfo`,
`Tools/package_mod.py`, `README.md`, `CHANGELOG.md`. Pre-existing project formatting
and its SoftKitty folder entry are retained locally and excluded from this commit.

Added gameplay/database: `Lua/TrentWealthy_Gameplay.lua`,
`SQL/110_Wealthy_Inherit.sql`, `SQL/111_Wealthy_Core.sql`,
`SQL/112_Wealthy_Text.sql`.

Added tools/docs: `Tools/build_wealthy_inheritance.py`,
`Tools/build_wealthy_art.py`, `Tools/register_wealthy.py`,
`Tools/test_wealthy.py`, `Tools/validate_wealthy.py`, `WEALTHY_TESTING.md`.

Added art in `Art/WealthyTrent/`: `WealthyCiv{256,128,80,64,45,32}.dds`,
`WealthyLeader{256,128,80,64,45,32}.dds`,
`WealthyPalace{256,128,80,64,45,32}.dds`,
`WealthyAlpha{128,80,64,48,45,32,24,16}.dds`, `WealthyDawn.dds`,
`WealthyLeaderScene.dds`, `WealthyMap.dds`, `WealthyLeaderScene.xml`,
`WealthyAtlases.xml`, `WealthyPreview.png`. Retained sources:
`Art/Source/WealthyTrent/WealthyScene.png` and `PROMPT.md`.
