# The Freehold of Una Court

A custom civilization for Sid Meier's Civilization V: Brave New World, designed for the Community Patch / Vox Populi ruleset.

Lead the Freehold as **Trentrouls**, an irreplaceable ruler who begins the game on the map. His presence steadily empowers the entire empire, and his companion Buddy can double both his personal strength and the Freehold's growing bonuses. Protect him carefully: if Trentrouls dies, the Freehold collapses.

## Civilization overview

### Leader: Trentrouls

Trentrouls replaces the starting Warrior and functions as the heart of the civilization. His combat strength grows with each era:

| Era | Strength |
| --- | ---: |
| Ancient | 7 |
| Classical | 9 |
| Medieval | 12 |
| Renaissance | 16 |
| Industrial | 23 |
| Modern | 32 |
| Atomic | 43 |
| Information | 50 |

When Buddy is adjacent, Trentrouls' current strength is doubled.

Trentrouls can also use **Body Possession** on an eligible enemy unit within two tiles. Possession temporarily transfers Trentrouls into the target body, after which he returns. The cooldown and duration scale with game speed.

### Unique ability: The Court Lives Through Him

While Trentrouls lives, every city receives an empire-wide bonus that increases by era:

- +1% in the Ancient Era, rising by 1% each era to +8% in the Information Era.
- Applies to Food, Production, Gold, Science, Culture, Faith, and Great Person generation.
- The bonus is doubled while Buddy is adjacent to Trentrouls.

If Trentrouls is killed, the Freehold immediately collapses: the killer captures the capital, the remaining cities and units are removed, and the Freehold is eliminated.

### Unique unit: Buddy

Buddy is a cheap, limited companion unit:

- Cost: 125 Production
- Combat strength: 3
- Ignores terrain movement costs
- Limited to one at a time
- Doubles Trentrouls' strength and empire bonus while adjacent
- Can be trained again if lost

### Unique building: Centrelink

Centrelink replaces the Bank and provides **+1 local Happiness** in addition to the Bank's normal benefits.

## How it plays

The Freehold is a high-risk, high-reward civilization. Keeping Trentrouls alive rewards you with an increasingly powerful empire, while moving Buddy alongside him creates short windows of exceptional strength. Body Possession offers tactical disruption and mobility, but committing Trentrouls to the front line always risks losing the entire civilization.

## Current alpha status

The core civilization, era scaling, Trentrouls, Buddy, Centrelink, Body Possession UI and AI behavior, save persistence, and defeat collapse are implemented.

Current limitations:

- Buddy has a custom portrait; remaining art currently uses base-game placeholders.
- Possessing highly specialized units may not preserve every unusual unit-specific state.
- Multiplayer is intentionally disabled while the custom gameplay systems are stabilized.

## Requirements

- Sid Meier's Civilization V: Brave New World
- Community Patch / Vox Populi DLL
- ModBuddy from the Civilization V SDK to build from source

## Build and install

1. Open `UnaCourt.civ5proj` in ModBuddy.
2. Choose **Build > Build Solution**.
3. In Civilization V, open **Mods**, enable **The Freehold of Una Court**, and start a new game.

The built mod is deployed by ModBuddy to your Civilization V `MODS` folder. Generated packages and local build artifacts are intentionally excluded from this repository.

## Source layout

- `Art/` — custom icon atlases and retained source artwork
- `SQL/` — civilization, units, building, scaling data, and text
- `Lua/` — gameplay systems, possession logic, AI, and save persistence
- `UI/` — in-game Una Court command panel
- `UnaCourt.civ5proj` — ModBuddy project
- `CHANGELOG.md` — dated summary of changes included in each push

## Development status

This is an early playable implementation. Balance values and edge-case behavior may change as testing continues. See [CHANGELOG.md](CHANGELOG.md) for the history of shipped changes.
