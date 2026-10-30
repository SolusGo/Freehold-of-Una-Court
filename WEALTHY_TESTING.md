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
If callbacks are skipped so long that the next audit becomes due with installments
still outstanding, finish those installments before starting another audit. The
final installment and the next audit's immediate transfer may share a callback;
neither is repeated on reload. This does not change the normal T+1..T+5 schedule.

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

Routine Palace work is bounded to Wealthy owners. On a Wealthy player's turn,
only that player's cities are reconciled; foreign turns check cached Wealthy
players' alive status without city iteration unless a life-state transition
requires cleanup. Era/founding events reconcile only the relevant Wealthy owner.
CityCaptureComplete handles conquest, trades, gifts and liberation by reconciling
affected Wealthy owners and the single transferred foreign city. Previous Capital
coordinates allow cleanup after an unexpected ownership change without retaining
invalid city userdata or assuming city IDs survive transfer. A full cleanup of
every owner's stale Wealthy buildings runs only at initialization/load.

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
are repaired by that Wealthy player's next turn. Alive-state transitions are
observed on any player's turn, including elimination and resurrection.

The source path was re-audited during hardening: `CvCity::processBuilding`
updates UnmoddedHappiness through ChangeUnmoddedHappinessFromBuildings and updates
native base yields through ChangeBaseYieldRateFromBuildings/GetYieldChange.
In CP-only mode, `CvPlayer::DoUpdateTotalHappiness` adds GetHappinessFromCities,
which sums GetLocalHappiness with no population clamp. Thus the configured tier
is an empire Happiness contribution, and its +2N Gold is an actual native flat
building yield, subject to normal city yield modifiers. This is source/database
verification, not an executed DLL gameplay test. Native AddFreeCapitalBuildings
resolves the Palace class through the civilization override; the complete Palace
clone retains Capital=1, all scalar effects and all supported relationship rows.

Native source evidence at the previously audited revision:

- [Lua SetNumRealBuilding binding](https://github.com/LoneGazebo/Community-Patch-DLL/blob/aefacbf1b24a27aa42dc50b4283420a999f7fded/CvGameCoreDLL_Expansion2/Lua/CvLuaCity.cpp#L5583)
- [Native SetNumRealBuilding effect dispatch](https://github.com/LoneGazebo/Community-Patch-DLL/blob/aefacbf1b24a27aa42dc50b4283420a999f7fded/CvGameCoreDLL_Expansion2/CvBuildingClasses.cpp#L6041)
- [Building Happiness processing](https://github.com/LoneGazebo/Community-Patch-DLL/blob/aefacbf1b24a27aa42dc50b4283420a999f7fded/CvGameCoreDLL_Expansion2/CvCity.cpp#L13718)
- [Building yield processing](https://github.com/LoneGazebo/Community-Patch-DLL/blob/aefacbf1b24a27aa42dc50b4283420a999f7fded/CvGameCoreDLL_Expansion2/CvCity.cpp#L14600)
- [CP-only empire Happiness path](https://github.com/LoneGazebo/Community-Patch-DLL/blob/aefacbf1b24a27aa42dc50b4283420a999f7fded/CvGameCoreDLL_Expansion2/CvPlayer.cpp#L20260)
- [City Happiness sum](https://github.com/LoneGazebo/Community-Patch-DLL/blob/aefacbf1b24a27aa42dc50b4283420a999f7fded/CvGameCoreDLL_Expansion2/CvPlayer.cpp#L21669)
- [Native Palace relocation](https://github.com/LoneGazebo/Community-Patch-DLL/blob/aefacbf1b24a27aa42dc50b4283420a999f7fded/CvGameCoreDLL_Expansion2/CvCity.cpp#L35974)

The Lua binding dispatches to native SetNumRealBuilding, whose effect processing
calls CvCity::processBuilding even for dummy buildings. That function also
recalculates the owner's net Happiness. The Lua reconciliation therefore uses
the native yield/Happiness system rather than only setting informational state.

## Automated checks

Run from the repository root:

```
python Tools/build_wealthy_inheritance.py
python Tools/build_wealthy_inheritance.py --check
python Tools/test_wealthy_inheritance.py
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

For reproducible inputs on any machine, all three inheritance/validation tools
accept `--baseline-db "<pre-collection Civ5DebugDatabase.db>"`,
`--cp-root "<Community Patch v151 folder>"`, and `--game-assets "<Civ V Assets>"`.
The default game path retains this checkout's existing G: installation convention;
override it for other machines. Inputs are read-only; schema additions run only
on an in-memory copy. `--loaded-db` validates an already activated game cache
directly rather than replaying SQL over existing civilization entries. The
separate baseline input may still be supplied for the regeneration check.

The builder follows CP's activation manifest for schema discovery, ignores
inactive files and excludes localization files from the schema fingerprint.
CP's installed Policy schema contains an XML comment rejected by strict XML
parsers; comments are stripped before parsing so table discovery is not silently
skipped. Malformed non-comment schema now fails explicitly. A missing optional
localization XML named in the installed CP manifest is outside this schema audit;
the on-disk counterpart is SQL and no installed CP files are changed here.

`Tools/wealthy_schema.json` records CP version 151, a line-ending-independent
fingerprint of activated schema inputs and the 149 referenced tables' explicit
key/ID/modified-column types. The generated SQL still reads full active rows with
SELECT *, so unreferenced scalar additions are inherited normally. The read-only
`--check` compares generated SQL and contract exactly, tolerating checkout line
endings. Missing declared building tables, missing required columns or incompatible
types fail explicitly. Regeneration still produces 296 clones with unchanged
gameplay SQL; only a schema-contract comment was added to 110_Wealthy_Inherit.sql.

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

- `test_wealthy.py`: **34/34** scenarios passed using actual Lua 5.1 after hardening.
- `test_wealthy_inheritance.py`: exact regeneration, explicit input paths,
  optional/inactive table exclusion, missing tables/columns/type failures,
  comment handling, line-ending stability and unchanged source DB bytes passed.
- The `--loaded-db` CLI branch passed a smoke test against a synthetic, fully
  activated SQL fixture. This checks the procedure, not an actual engine-loaded
  cache; that in-game validation is still pending.
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
Hardening also adds `Tools/wealthy_schema.json` and
`Tools/test_wealthy_inheritance.py`, and extends the existing read-only
`Tools/princedom_db.py` helper with optional explicit input paths.

Added art in `Art/WealthyTrent/`: `WealthyCiv{256,128,80,64,45,32}.dds`,
`WealthyLeader{256,128,80,64,45,32}.dds`,
`WealthyPalace{256,128,80,64,45,32}.dds`,
`WealthyAlpha{128,80,64,48,45,32,24,16}.dds`, `WealthyDawn.dds`,
`WealthyLeaderScene.dds`, `WealthyMap.dds`, `WealthyLeaderScene.xml`,
`WealthyAtlases.xml`, `WealthyPreview.png`. Retained sources:
`Art/Source/WealthyTrent/WealthyScene.png` and `PROMPT.md`.
