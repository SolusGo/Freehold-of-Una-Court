# Una Court Civilizations

A version 3 Civilization V: Brave New World mod for the Community Patch ruleset. It adds five selectable civilizations led by Trent: the companion-focused **Freehold of Una Court**, the aggressive **Dominion of Una Court**, the army-stealing **Ultimate Possession**, the musical **Soft Kitty Serenader**, and the science-and-culture focused **Library Exile**.

The Freehold and Dominion begin with a Settler and their own Trentrouls instead of an ordinary Warrior. In either realm, Trentrouls is irreplaceable: if his body dies, the civilization collapses. Ultimate Possession, Soft Kitty, and Library Exile use normal starting units because Trent acts through their civilization mechanics rather than appearing as a separate map unit.

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
- On Standard speed, groups of 1–4 units are possessed for 2 turns; groups of 5–8 units are possessed for 1 turn.
- Cooldown depends on the size of the group: 8 turns for one unit, then +5 turns for every additional unit.
- Possessed units retain their type, promotions, damage, experience, name, movement, and embarked state.
- Possessed units cannot be deleted, gifted, or upgraded. Strategic-resource requirements are checked before activation.
- Surviving units return to their original owner when the duration expires or peace is signed. Units killed or expended while possessed stay gone. If an original major civilization has been eliminated, its surviving borrowed unit is disbanded safely.
- Saving and loading uses the same ownership-normalization transaction as the other Una Court possession systems: ordinary ownership is serialized, then the active group is rebuilt after the save or load finishes.
- AI-controlled Ultimate Possession automatically selects the most valuable eligible targets.

| Units selected | Standard cooldown |
| ---: | ---: |
| 1 | 8 turns |
| 2 | 13 turns |
| 3 | 18 turns |
| 4 | 23 turns |
| 5 | 28 turns |
| 6 | 33 turns |
| 7 | 38 turns |
| 8 | 43 turns |

Quick, Epic, and Marathon games retain the existing 67%, 150%, and 300% timing scaling for both duration and cooldown.

### Golden Retriever

The Golden Retriever replaces the Scout. It costs 45 Production, has 3 Movement, and costs one additional Gold per turn while retaining the Scout's ordinary abilities. Its non-stacking **Good Boy** promotion grants adjacent friendly units +10% Combat Strength and +5 HP healing per turn.

### 3 Una Court

This unique National Wonder becomes available at Civil Service and costs 250 Production. It provides +1 Happiness and +5% Gold in every city, while unemployed Citizens in every city produce +1 Culture.

## Trent - The Soft Kitty Serenader

A navy-and-gold Una Court focused on Culture, Tourism and diplomacy. It uses a normal starting army, with no irreplaceable Trent unit or collapse mechanic.

- **Soft Kitty, Warm Kitty:** use the independent **Sing Soft Kitty** button to select a met, peaceful major civilization. Standard-speed cooldown is 15 turns. Successful songs award 30 Culture and 20 targeted Tourism per era number, plus 5 influence with each city-state allied to the audience.
- Friendly audiences or Declarations of Friendship double rewards and normally cannot fail. Neutral/afraid audiences have 10% backlash risk; guarded/deceptive audiences receive 75% rewards with 25% risk; hostile audiences receive 50% rewards with 50% risk. The confirmation displays the current rewards and risk.
- **Repercussions:** a failed song gives no rewards and causes five Standard-speed turns of -15% Production, -10% military Combat Strength and -20% Great Person generation. Military land/naval units trained during recovery also lose one Movement until recovery ends; purchases are exempt. Further backlash refreshes the duration without stacking the penalties.
- The first civilization to cause backlash becomes the permanent **Ex**: subsequent songs give +25% rewards but have at least 15% backlash risk. Cooldown, Ex and recovery survive saving and loading.
- **Hopeless Romantic:** replaces the active ruleset's Great Musician, retaining Great Work creation. Its custom **Serenade** action requires adjacency to a peaceful foreign major city and consumes the unit for 125% of its normal concert Tourism, 100 Culture and the allied city-state influence bonus. The Ex receives a further 20% Tourism. Hostile audiences have a 25% backlash risk, but the concert still awards its rewards. The native concert mission is replaced by this action.
- **Comfort Room:** replaces and inherits the active Opera House, adding 1 Culture, 1 local Happiness, 1 Culture per local Great Work of Music and 10% local Great Musician generation. Each Comfort Room reduces the empire's recovery Production penalty by one percentage point, capped at zero, and produces 3 extra Culture locally during recovery.

Cooldown and recovery durations scale with game speed; ordinary song yields and concert Tourism also scale. The fixed concert Culture award is 100. This civ has custom circular portraits, a static diplomacy scene, silent Dawn of Man art, and native Civilopedia articles. Its AI can select audiences and use adjacent concerts; the existing three civs remain player-only, as configured previously.

## Trent - The Library Exile

The Library Exile is a defensive, tall-leaning civilization that turns diplomatic isolation into Science and Culture.

- **Banished to the Library:** every living major civilization denouncing or at war with Trent supplies one Exile Stack, even when both conditions apply. Each stack gives School Library cities +3% Science and +3% Culture, capped at three stacks and +9%.
- **The Visitor:** the first civilization to share a Declaration of Friendship with Trent is recorded permanently. While friendship with that same Visitor is active, all cities gain +15% Great Writer generation, the empire gains +2 Happiness, and School Libraries produce +1 Culture. Another friend cannot replace the Visitor.
- **School Library:** replaces and inherits the installed Community Patch Library. It additionally produces +1 Culture and +1 Great Writer Point and contains one Great Work of Writing slot.
- **iPad Reader:** replaces and inherits the Great Writer, retaining Great Works and Political Treatises. A Reader stationed in a School Library city at the start of a turn gives that city +2 Science and +2 Culture; multiple Readers do not stack. Expending one through a Great Person action grants 25 Science per Era number, from 25 to 200.
- The civilization has a normal Settler-and-Warrior opening, quiet defensive AI priorities, custom library-themed artwork and map, a silent Dawn of Man screen, complete diplomacy lines, and structured Civilopedia entries.

Exile and Visitor state are refreshed through an isolated gameplay script and persistent save data. The implementation adds no top-left, city-view, unit-panel, or other core UI replacement.

## Shared unique building: Centrelink

The original three civilizations replace the Bank with the same single **Centrelink** building definition. Centrelink retains the Bank's normal benefits and adds +1 local Happiness. Soft Kitty uses its own Comfort Room instead.

## Interface and compatibility

The existing right-side command panel automatically switches between Freehold Body Possession, Dominion Body Swap, and Ultimate Mass Possession. Ultimate mode provides toggleable multi-selection, capacity and cooldown previews, active-unit tracking, and capital/retriever/possessed-unit finders. The panel hides in city view and does not replace the TopPanel, UnitPanel, CityView, Community Patch, or EUI contexts.

Soft Kitty has a separate, civ-only audience window with reward/risk previews, recovery status and confirmation. It hides during city view and does not replace any core or existing Una Court UI files.

## Current alpha limitations

- The first four civilizations share Una Court's location map; Library Exile has its own School Library map art. All five use base-game unit models and dedicated emblems and leader art.
- Soft Kitty is validated against Community Patch 5.4.2's loaded database and mocked Lua 5.1 gameplay. Actual in-game layout, AI pathfinding and interactions with additional mods still require playtesting; full Vox Populi compatibility is not yet verified.
- Highly specialized modded units may contain internal state that Civ V Lua cannot perfectly preserve through an ownership transfer.
- Multiplayer and hotseat are intentionally disabled while the scripted transfer systems are stabilized.

## Requirements and installation

- Sid Meier's Civilization V: Brave New World
- Community Patch / Vox Populi DLL
- ModBuddy from the Civilization V SDK to build from source

Open `UnaCourt.civ5proj`, choose **Build > Build Solution**, then enable **The Freehold of Una Court (v 3)** in Civilization V's Mods menu and start a new game. The version remains fixed at 3 so new builds replace the existing mod folder.

## Source layout

- `Art/` — custom icon atlases and retained source artwork
- `SQL/` — all five civilizations, units, shared and unique buildings, scaling data, and text
- `Lua/` — possession systems, Soft Kitty audiences, Library Exile diplomacy polling, AI, aura support, collapse safety, and save/load state
- `UI/` — shared possession command panel and isolated Soft Kitty audience panel
- `Tools/` — reproducible art building and validation scripts
- `CHANGELOG.md` — player-facing and technical changes for each push

### Soft Kitty verification

Run `Tools/validate_soft_kitty.py` with Python/Pillow against a pre-Soft-Kitty Community Patch debug database. Run `Tools/test_soft_kitty.py` with Lupa installed in `.modbuddy/test-deps` for the twelve Lua 5.1 gameplay scenarios. Art can be rebuilt using `Tools/build_soft_kitty_art.py`; retained source art and generation prompts are in `Art/Source/SoftKitty/`.

For a new-game smoke test: check civilization selection and Civilopedia icons, meet another major civ, inspect and confirm a song, save/reload through cooldown and recovery, and test an adjacent Hopeless Romantic. Open and close the city screen to check panel isolation. Confirm Great Work creation and Comfort Room bonuses; check Lua.log and Database.log for errors. Do not add the new civilization to an existing campaign.

### Library Exile verification

Run `Tools/validate_library_exile.py` against the active Community Patch debug database and `Tools/test_library_exile.py` with the local Lua 5.1 test runtime. Art is reproducible through `Tools/build_library_exile_art.py`; the generated PNG sources and exact built-in generation prompts are retained in `Art/Source/`.

For an in-game smoke test: begin a new Library Exile game, confirm exactly one ordinary Warrior, inspect all Civilopedia and selection icons, build a School Library, and station an iPad Reader inside. Verify one enemy at war and denouncing Trent produces only one stack; test three simultaneous hostile civilizations and reconciliation. Establish the first friendship, let it expire, befriend someone else, then renew the original friendship to confirm permanent Visitor identity. Create both a Great Work and Political Treatise with Readers and check Lua.log and Database.log.
