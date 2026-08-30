# Una Court Civilizations

A version 3 Civilization V: Brave New World mod for the Community Patch / Vox Populi ruleset. It adds three selectable civilizations led by Trentrouls: the companion-focused **Freehold of Una Court**, the aggressive **Dominion of Una Court**, and the army-stealing **Ultimate Possession**.

The Freehold and Dominion begin with a Settler and their own Trentrouls instead of an ordinary Warrior. In either realm, Trentrouls is irreplaceable: if his body dies, the civilization collapses. Ultimate Possession uses the normal Settler and Warrior start because Trentrouls acts through its civilization ability rather than appearing as a separate map unit.

## The Freehold of Una Court

The Freehold rewards protecting Trentrouls and keeping Buddy close.

### The Court Lives Through Him

- Every city gains +1% Food, Production, Gold, Science, Culture, Faith, and Great Person generation per era, from +1% to +8%.
- Buddy doubles the empire bonus while adjacent to Trentrouls.
- Trentrouls grows from 7 Combat Strength in the Ancient Era to 50 in the Information Era; Buddy doubles his current strength while adjacent.
- Trentrouls may temporarily possess an eligible non-Barbarian enemy unit within two tiles.
- If Trentrouls dies, the Freehold collapses.

### Buddy

Buddy is a retrainable, one-at-a-time companion unit. He costs 125 Production, has 3 Combat Strength, ignores terrain movement costs, and empowers Trentrouls while adjacent.

## The Dominion of Una Court

The Dominion is the aggressive alternate Trentrouls civilization. It turns nearby enemy units into weapons, but each exchange gives the enemy control of Trentrouls' original—and fatal—body.

### The One Who Possesses Una Court

- Every city gains the same +1% to +8% era-scaled yields and Great Person generation as the Freehold.
- The empire bonus doubles while a Body Swap is active.
- Starting a Body Swap grants 5 to 12 Golden Age Points by era on Standard speed, scaled for the selected game speed.
- Trentrouls grows through 8/10/16/22/30/42/56/72 Combat Strength by era.
- If Trentrouls' original body dies, including while controlled by an enemy, the Dominion collapses.

### Body Swap

Trentrouls can exchange bodies with an eligible enemy unit within two tiles while at war:

- The Dominion receives the borrowed body with +5% Combat Strength.
- The enemy receives Trentrouls' original body for the swap's duration.
- The borrowed body can move, fight, found cities, build, spread religion, and perform Great Person actions normally. Those actions are permanent.
- The enemy-controlled Trentrouls can move one tile or make one melee attack per turn, but cannot move and then attack.
- Losing or expending the borrowed body returns Trentrouls. Killing his original body destroys the Dominion.
- Air units, missiles, nuclear and suicide units, trade units, immune units, other Una Court heroes, and Barbarians are excluded for stability.
- Saving or autosaving temporarily returns both bodies to their normal owners for safe serialization, then automatically restores the active Body Swap with the same remaining duration, cooldown, movement, damage, experience, name, and promotions. Loading that save restores the swap after gameplay initialization.

| Game speed | Active duration | Full cooldown |
| --- | ---: | ---: |
| Quick | 1 turn | 8 turns |
| Standard | 2 turns | 12 turns |
| Epic | 3 turns | 18 turns |
| Marathon | 6 turns | 36 turns |

## Trentrouls - Ultimate Possession

Ultimate Possession is the large-scale version of Trentrouls' power. Instead of risking a unique Trentrouls unit, it projects a possession network from every friendly city and military unit.

### Two Possessions for the Price of One

- Enemy and Barbarian units within two tiles of any friendly city or military unit can be selected in the Una Court panel.
- Maximum simultaneous targets equal the current Era number: 1 in the Ancient Era, increasing to 8 in the Information Era.
- All selected units are possessed together for 3 turns on Standard speed.
- Cooldown depends on the size of the group: 5 turns for one unit, then +3 turns for every additional unit.
- Possessed units retain their type, promotions, damage, experience, name, movement, and embarked state.
- Possessed units cannot be deleted, gifted, or upgraded. Strategic-resource requirements are checked before activation.
- Surviving units return to their original owner when the duration expires or peace is signed. Units killed or expended while possessed stay gone. If an original major civilization has been eliminated, its surviving borrowed unit is disbanded safely.
- Saving and loading uses the same ownership-normalization transaction as the other Una Court possession systems: ordinary ownership is serialized, then the active group is rebuilt after the save or load finishes.
- AI-controlled Ultimate Possession automatically selects the most valuable eligible targets.

| Units selected | Standard cooldown |
| ---: | ---: |
| 1 | 5 turns |
| 2 | 8 turns |
| 3 | 11 turns |
| 4 | 14 turns |
| 5 | 17 turns |
| 6 | 20 turns |
| 7 | 23 turns |
| 8 | 26 turns |

Quick, Epic, and Marathon games scale these cooldowns to 67%, 150%, and 300%. Active duration is 2/3/5/9 turns on Quick/Standard/Epic/Marathon.

### Golden Retriever

The Golden Retriever replaces the Scout. It costs 45 Production, has 3 Movement, and costs one additional Gold per turn while retaining the Scout's ordinary abilities. Its non-stacking **Good Boy** promotion grants adjacent friendly units +10% Combat Strength and +5 HP healing per turn.

### 3 Una Court

This unique National Wonder becomes available at Civil Service and costs 250 Production. It provides +1 Happiness and +5% Gold in every city, while unemployed Citizens in every city produce +1 Culture.

## Shared unique building: Centrelink

All three civilizations replace the Bank with the same single **Centrelink** building definition. Centrelink retains the Bank's normal benefits and adds +1 local Happiness.

## Interface and compatibility

The existing right-side command panel automatically switches between Freehold Body Possession, Dominion Body Swap, and Ultimate Mass Possession. Ultimate mode provides toggleable multi-selection, capacity and cooldown previews, active-unit tracking, and capital/retriever/possessed-unit finders. The panel hides in city view and does not replace the TopPanel, UnitPanel, CityView, Community Patch, or EUI contexts.

## Current alpha limitations

- The three civilizations share Una Court's location map and base-game unit models. Each has dedicated emblem and leader art; Ultimate Possession also has custom Dawn of Man and 3 Una Court artwork.
- Highly specialized modded units may contain internal state that Civ V Lua cannot perfectly preserve through an ownership transfer.
- Multiplayer and hotseat are intentionally disabled while the scripted transfer systems are stabilized.

## Requirements and installation

- Sid Meier's Civilization V: Brave New World
- Community Patch / Vox Populi DLL
- ModBuddy from the Civilization V SDK to build from source

Open `UnaCourt.civ5proj`, choose **Build > Build Solution**, then enable **The Freehold of Una Court (v 3)** in Civilization V's Mods menu and start a new game. The version remains fixed at 3 so new builds replace the existing mod folder.

## Source layout

- `Art/` — custom icon atlases and retained source artwork
- `SQL/` — all three civilizations, units, shared and unique buildings, scaling data, and text
- `Lua/` — Freehold possession, Dominion Body Swap, Ultimate Mass Possession, AI, aura support, collapse safety, and save/load ownership transactions
- `UI/` — shared Una Court command panel
- `Tools/` — reproducible art building and validation scripts
- `CHANGELOG.md` — player-facing and technical changes for each push
