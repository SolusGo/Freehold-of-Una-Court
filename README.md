# Una Court Civilizations

A version 3 Civilization V: Brave New World mod for the Community Patch / Vox Populi ruleset. It adds two selectable civilizations led by Trentrouls: the companion-focused **Freehold of Una Court** and the aggressive **Dominion of Una Court**.

Both civilizations begin with a Settler and their own Trentrouls instead of an ordinary Warrior. In either realm, Trentrouls is irreplaceable: if his body dies, the civilization collapses.

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

| Game speed | Active duration | Full cooldown |
| --- | ---: | ---: |
| Quick | 1 turn | 8 turns |
| Standard | 2 turns | 12 turns |
| Epic | 3 turns | 18 turns |
| Marathon | 6 turns | 36 turns |

## Shared unique building: Centrelink

Both civilizations replace the Bank with the same single **Centrelink** building definition. Centrelink retains the Bank's normal benefits and adds +1 local Happiness.

## Interface and compatibility

The existing right-side command panel automatically switches between Freehold Body Possession and Dominion Body Swap. It includes preview-and-confirm targeting, current and next-era strength, ability timing, and unit-finding controls. The panel hides in city view and does not replace the TopPanel, UnitPanel, CityView, Community Patch, or EUI contexts.

## Current alpha limitations

- The two civilizations share Una Court's location map, leader portrait, and base-game unit models; each now has its own emblem, flag alpha, Trentrouls unit portrait, and Dawn of Man artwork.
- Highly specialized modded units may contain internal state that Civ V Lua cannot perfectly preserve through an ownership transfer.
- Multiplayer and hotseat are intentionally disabled while the scripted transfer systems are stabilized.

## Requirements and installation

- Sid Meier's Civilization V: Brave New World
- Community Patch / Vox Populi DLL
- ModBuddy from the Civilization V SDK to build from source

Open `UnaCourt.civ5proj`, choose **Build > Build Solution**, then enable **The Freehold of Una Court (v 3)** in Civilization V's Mods menu and start a new game. The version remains fixed at 3 so new builds replace the existing mod folder.

## Source layout

- `Art/` — custom icon atlases and retained source artwork
- `SQL/` — both civilizations, units, the shared building, scaling data, and text
- `Lua/` — Freehold possession, Dominion Body Swap, AI, collapse safety, and save persistence
- `UI/` — shared Una Court command panel
- `CHANGELOG.md` — player-facing and technical changes for each push
