# The Princedom of Una Court

The seventh selectable civilization in the Una Court collection, led by **Trent Steinhauer — Pupil of Two Masters**. Requires Civilization V: Brave New World on Windows and **Community Patch v151**. Start a new game; single player is the supported mode.

Trent studies possession under Baby (Dragon Ball GT) and body exchange under Captain Ginyu (Dragon Ball Z). He replaces the opening Warrior and begins at 150% of the installed Warrior's base strength: **12 strength and 2 Movement** with the inspected 8-strength Warrior. The active Warrior's upgrade tables are inherited, rather than hardcoding an upgrade chain. Normal upgrades preserve his identity and abilities. Ordinary Warriors remain trainable through a private, baseline-identical militia class; their displayed name and rules remain Warrior.

**There is one original Trent body. Its death collapses the entire empire**, including before founding a city, after upgrading, or while the enemy controls it. Borrowed bodies are expendable. Trent cannot be retrained, purchased, gifted or disbanded, and cannot upgrade during a technique.

## Techniques

Select Trent on the world map and open **Two Masters**. Choose **Possess** or **Body Swap**. Eligible adjacent units are highlighted in violet; click a target in the panel to activate. Rows explain invalid targets. The panel shows each mastery, next progression level, duration, damage modifier, resistance, cooldown and active effect. Active values are fixed before the successful activation grants its stack, so crossing a threshold improves the *next* use.

Possession transfers an enemy military unit to Una Court and leaves Trent's original body immobile and vulnerable. Body Swap gives the enemy control of Trent's original body and gives Una Court the enemy's body. The original body can move at most one adjacent land tile per turn and cannot attack, pillage, embark, upgrade, disband, be gifted or capture cities. Its resistance reduces incoming damage rather than increasing strength.

Targets must be **visible, adjacent enemy land military units**, including Barbarians, outside cities and off transports. Neither unit may be embarked or already involved in a technique. Civilian, naval, aircraft, suicidal, nuclear, religious and Great Person bodies are excluded. Other irreplaceable Una Court heroes and other systems' borrowed bodies are protected. A borrowed unit cannot activate another technique, upgrade, embark, be gifted or be disbanded. Native movement and combat still apply; a target with zero movement does not gain free movement.

At expiration, both surviving bodies return to their previous owners, retaining their **current** damage, fractional experience, level, promotions, position, name and ScriptData. Promotions and damage earned during control remain on that physical body. Native conversion also preserves the metadata the DLL handles. Returned targets receive zero movement until their normal refresh, preventing an extra turn. Trent receives his fresh movement budget when returning at the start of his own turn; an early cancellation exhausts him until normal refresh. Native deterministic relocation handles illegal terrain/stacking. If no legal location exists, the stranded unit is removed; losing Trent this way still causes collapse. Peace cancels a technique. Eliminated original target owners are never resurrected.

## Mastery and balance

Possession and Body Swap start at 0 independently, gain exactly one stack on a successful activation, and permanently cap at 12. Failed actions grant no stack or cooldown. Upgrades and saves preserve both counters. Mastery never reduces cooldown.

| Stacks | Level | Standard duration | Possession damage | Swap damage | Original body swap resistance | Target base strength limit |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 0–2 | 1 | 1 | −35% | −20% | 80% | 100% of Trent |
| 3–5 | 2 | 1 | −20% | 0% | 82% | 125% |
| 6–8 | 3 | 2 | −10% | +15% | 85% | 150% |
| 9–11 | 4 | 2 | 0% | +25% | 88% | 200% |
| 12 | 5 | 3 | +10% | +40% | 90% | Unlimited |

Strength eligibility uses the higher of each body's native **base melee and base ranged strength**; terrain, temporary strength and ordinary combat promotions do not count. This prevents powerful ranged units qualifying through a low melee value. Each technique uses its own mastery for eligibility.

| Speed | Shared cooldown | Duration multiplier | 1 standard turn | 2 standard turns | 3 standard turns |
| --- | ---: | ---: | ---: | ---: | ---: |
| Quick | 5 | 0.67 | 1 | 1 | 2 |
| Standard | 8 | 1.00 | 1 | 2 | 3 |
| Epic | 12 | 1.50 | 2 | 3 | 5 |
| Marathon | 24 | 3.00 | 3 | 6 | 9 |

Duration is `max(1, floor(standardDuration * multiplier + 0.5))`. For a custom speed, the multiplier is `TrainPercent / 100`, and cooldown is `max(1, floor(8 * multiplier + 0.5))`.

If activation occurs on turn **T**, duration **D** expires at the start of Una Court's player turn **T + D**. The activation turn counts as the first active turn, including intervening enemy turns. Cooldown starts immediately and becomes ready on turn **T + C**, where C is the fixed speed cooldown. Absolute turn deadlines prevent duplicate ticks during reloads, other players' turns or repeated events. The display uses those same deadlines. Possession's original body cannot move or initiate attacks while active.

## Fanfic Monument

The Fanfic Monument inherits the installed Monument's scalar fields and related tables at mod activation. The inspected BNW + CP v151 baseline is **40 Production, 1 maintenance, +2 Culture**; CP's Monument change corrects its class description and does not change those effects. While either technique is active, each Fanfic Monument city receives one hidden building copying the Monument's intrinsic benefits. It therefore produces **+4 intrinsic Culture** on this baseline.

The dummy has no maintenance, construction cost, ordinary Monument class or construction prerequisites. Policy/religious bonuses tied to the normal Monument class are applied once. Construction, sales, captures, activation, expiration and loading reconcile a single dummy count rather than adding bonuses repeatedly. Cities without a Fanfic Monument receive none.

## Strategy and AI

Train an escort and practice on Barbarians while the techniques are weak. Possession is safer when the original body has a defended position. Body Swap becomes more powerful as its offense and resistance improve, but exposing the original body remains dangerous. Build Fanfic Monuments throughout the empire and upgrade Trent between activations.

AI decisions use the same backend as the human panel, search only within two tiles, prefer valuable targets, practice on Barbarians, retreat when wounded/outnumbered and avoid risky swaps. A movement veto also rejects obvious high-risk AI attacks with the original body. Native tactical AI continues to control ordinary movement, so perfect strategic understanding cannot be promised.

## Install without ModBuddy

1. Install BNW and Community Patch **v151**, and enable the Community Patch in the Mods menu. Full Vox Populi is not required.
2. From the repository root, run `python Tools/package_mod.py --package` using Python 3.9 or newer. This command only uses the standard library; Pillow and Lupa are needed for art rebuilding and validation, not packaging or playing.
3. Copy the generated **Build/Una Court Civilizations (v 3)** folder into your Civilization V user folder's `MODS` directory. Alternatively, place the repository's registered game files and `UnaCourt.modinfo` together in a mod folder. Avoid activating a second installed copy of the collection.
4. Enable **The Freehold of Una Court** (the collection's retained mod name), then choose **Trent Steinhauer — Pupil of Two Masters / The Princedom of Una Court** in a **new** game.

The manifest registers the six existing civilizations and the new Princedom, with a CP v151 dependency, ordered database actions, gameplay loader, DDS textures and dedicated UI context. Multiplayer, hotseat and Mac are unsupported. This is an independently organized civilization within the collection, not a second standalone mod that duplicates shared definitions.

## Files, validation and limitations

`SQL/` contains activation-time inheritance, definitions and English localization. `Lua/` separates pure rules, ownership/save state, abilities, identity/death, combat, AI and event registration. `UI/` contains the world-map panel. `Art/` contains uniquely named DDS atlases, alpha/flag icons, leader scene, Dawn and map, all with mipmaps. The portrait, unit and scenery reuse the collection's retained Una Court artwork; emblems and technique/building glyphs are reproducible original geometric art from `Tools/build_princedom_art.py`. Atlas slots: civilization 0, leader 1, Trent 2, Monument 3, ability 4, swap 5, possession 6.

Run `python Tools/test_princedom.py` and `python Tools/validate_princedom.py`. The first executes the actual Lua 5.1 backend against an API mock. The second validates SQL against an in-memory BNW database plus the installed CP schema, baseline inheritance, localization, DDS mipmaps/transparency, XML and manifest hashes. Art can be regenerated with `python Tools/build_princedom_art.py`; inheritance with `python Tools/build_princedom_inheritance.py`. Refresh the manifest after changing registered files.

**In-game verification has not been performed.** See [TESTING.md](TESTING.md) for results and reproducible engine checks, and [CP151_NOTES.md](CP151_NOTES.md) for source evidence and engine limitations. In particular: positive offensive bonuses inherit CP v151's wounded-source HP cap; arbitrary scripted/environmental damage and nuclear effects bypass some combat armor; physical empire removal is deferred outside the death callback and the native defeated flag updates at CP's next alive-verification boundary. These are documented differences from fully immediate, universal-damage behavior. No resurrection is implemented.
