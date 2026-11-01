<div align="center">

<img src="Art/Source/TrentDawnOfManPainted.png" alt="Trent presiding over Una Court beside a roaring hearth" width="640">

# 👑 Una Court Civilizations

**Eight Trents. Eight ways to rule Una Court.**

Loyal companions, stolen armies, questionable serenades, library exile, missing phones and remarkably generous Centrelink payments.

**Civilization V: Brave New World** · **Community Patch v151** · **Version 3** · **Single player / Windows**

[Choose your Trent](#civilization-roster) · [Install](#installation) · [Civilization guides](#civilization-guides) · [Compatibility](#compatibility) · [Development](#development)

</div>

---

## Civilization roster

All eight civilizations are selectable by a human player in the same mod. **AI opponent** indicates whether the civilization is enabled for AI selection in the current database.

| Civilization | Playstyle | Signature ability | Unique content | AI opponent |
| :--- | :--- | :--- | :--- | :---: |
| 🐕 **[Freehold of Una Court](#freehold)** | Companions & empire growth | Era-scaled city bonuses; adjacent Buddy doubles the bonuses and Trentrouls' strength. Possess nearby enemies. | **Trentrouls** hero · **Buddy** companion · **Centrelink** (Bank) | — |
| 🔴 **[Dominion of Una Court](#dominion)** | Aggression & risky exchanges | Body Swap lends an enemy Trentrouls' original body. Active swaps double city bonuses and grant Golden Age Points. | **Trentrouls** hero · **Centrelink** (Bank) | — |
| 🌀 **[Ultimate Possession](#ultimate-possession)** | Army control & tactical warfare | Possess **1–8 enemy or Barbarian units** near friendly cities and military units, with capacity increasing by era. | **Golden Retriever** (Scout) · **Centrelink** (Bank) · **3 Una Court** National Wonder | — |
| 🎵 **[Soft Kitty Serenader](#soft-kitty)** | Culture, Tourism & diplomacy | Sing to peaceful rivals for Culture, targeted Tourism and allied city-state influence; unfriendly audiences can cause backlash. | **Hopeless Romantic** (Great Musician) · **Comfort Room** (Opera House) | ✓ |
| 📚 **[Library Exile](#library-exile)** | Tall Science & Culture | Hostile majors strengthen School Libraries. Your first friend becomes the permanent Visitor, rewarding renewed friendship. | **iPad Reader** (Great Writer) · **School Library** (Library) | ✓ |
| 📱 **[Phone Stealer](#phone-stealer)** | Espionage & Capital growth | Spies steal one Phone per rival; the Stash supplies Science, Gold, Culture and Happiness at a diplomatic cost. | **Una Court Butler** (Worker) · **Centrelink** (Bank) | ✓ |
| 👑 **[Princedom of Una Court](#princedom)** | Hero progression & tactical mastery | Develop Possession and Body Swap independently through **12 mastery stacks each**. One original body, one life. | **Trent Steinhauer** hero · **Fanfic Monument** (Monument) | ✓ |
| 💰 **[Wealthy of Una Court](#wealthy)** | Gold, infrastructure & city-state alliances | Audit wealthy rivals for real Gold transfers, enjoy doubled Centrelink benefits and collect an era-scaled luxury allowance. | **Enhanced Centrelink** (Bank) · **3 Una Court** (Palace) | — |

### Your opening army

| Civilizations | Opening units | Special defeat condition |
| :--- | :--- | :--- |
| Freehold & Dominion | Settler + their own **Trentrouls** in place of a Warrior | The original Trentrouls body's death collapses the empire, including during enemy control. |
| Princedom | Settler + **Trent Steinhauer** in place of a Warrior | Trent's original body's death collapses the empire. Normal upgrades preserve his identity. |
| Ultimate Possession, Soft Kitty, Library Exile, Phone Stealer & Wealthy | Normal Settler + Warrior | No irreplaceable hero or special collapse mechanic. |

> **Choose carefully:** borrowed bodies are expendable. The original bodies of Freehold, Dominion and Princedom heroes are not.

## Installation

Requires **Civilization V: Brave New World on Windows** and the **Community Patch DLL**. The manifest requires Community Patch v151 or later; the documented implementation baseline is **v151**. Full Vox Populi is not required; see [compatibility](#compatibility) before using the complete overhaul.

1. Install and enable the Community Patch.
2. From this repository's root, run the following with **Python 3.9+**:

   ```powershell
   python Tools/package_mod.py --package
   ```

3. Copy the generated **`Build/Una Court Civilizations (v 3)`** folder into your Civilization V user folder's **`MODS`** directory, usually:

   ```text
   Documents\My Games\Sid Meier's Civilization 5\MODS\
   ```

4. In the game's Mods menu, enable **The Freehold of Una Court (v 3)**. This retained mod name contains **all eight** civilizations.
5. Start a **new game** and select your Trent. Avoid enabling a second installed copy of the collection.

**ModBuddy alternative:** open `UnaCourt.civ5proj` and choose **Build → Build Solution**. ModBuddy is optional; plain-file packaging uses only Python's standard library. Pillow and Lupa are development dependencies, not requirements for packaging or playing.

The version stays fixed at **3**, so new builds replace the existing mod folder. Existing saves without a civilization's database entries are unsupported.

## Civilization guides

Expand a civilization for its abilities, unique content and important tradeoffs. Unless specified otherwise, turn counts and ability rewards below use **Standard speed**.

<a id="freehold"></a>
<details>
<summary><strong>🐕 Freehold of Una Court</strong> — keep Buddy close and Trentrouls alive</summary>

### The Court Lives Through Him

- Every city gains **+1% Food, Production, Gold, Science, Culture, Faith and Great Person generation per era**, from +1% in Ancient to +8% in Information.
- Adjacent **Buddy doubles** both the empire bonus and Trentrouls' current Combat Strength.
- Trentrouls grows from **7 to 50 Combat Strength** across the eras. He is irreplaceable: his death collapses the Freehold.
- **Body Possession** temporarily takes an eligible non-Barbarian enemy unit within **two tiles**. Ordinary Workers and Settlers are eligible; Great People, religious units, cargo and loaded transports are excluded because their hidden state cannot be recreated safely.

### Unique content

| Content | Benefits |
| :--- | :--- |
| **Buddy** | Retrainable companion, limited to one at a time. Costs **125 Production**, has **3 Combat Strength**, ignores terrain movement costs and empowers adjacent Trentrouls. |
| **Centrelink** | Replaces the Bank, keeping its normal benefits and adding **+1 local Happiness**. |

**Court advice:** protect Buddy as carefully as Trentrouls. Positioning the pair safely keeps both the army and the empire stronger.

</details>

<a id="dominion"></a>
<details>
<summary><strong>🔴 Dominion of Una Court</strong> — their army, your body, enormous stakes</summary>

### The One Who Possesses Una Court

- Cities gain the Freehold's **+1% to +8% era-scaled yields and Great Person generation**, doubled during Body Swap.
- Starting a swap grants **5–12 Golden Age Points by era**, scaled with game speed.
- Trentrouls' era strengths are **8 / 10 / 16 / 22 / 30 / 42 / 56 / 72**. His original body's death destroys the Dominion, even while an enemy controls it.

### Body Swap

Exchange bodies with an eligible enemy within **two tiles** while at war. The borrowed body receives **+5% Combat Strength** and can fight, build or found cities normally; those actions remain permanent. The enemy receives the original Trentrouls and may move him one tile **or** make one melee attack per turn, never both.

Losing or expending the borrowed body returns Trentrouls. Losing the original body ends the civilization.

| Speed | Active duration | Full cooldown |
| :--- | ---: | ---: |
| Quick | 1 turn | 8 turns |
| Standard | 2 turns | 12 turns |
| Epic | 3 turns | 18 turns |
| Marathon | 6 turns | 36 turns |

Barbarians, other Una Court heroes, immune units, air units, missiles, nuclear/suicide units, trade units, Great People, religious units, cargo and loaded transports are ineligible.

**Centrelink** replaces the Bank and adds **+1 local Happiness** to its normal benefits.

**Court advice:** check what can reach the original body before accepting a powerful borrowed one.

</details>

<a id="ultimate-possession"></a>
<details>
<summary><strong>🌀 Ultimate Possession</strong> — why stop at borrowing one unit?</summary>

### Two Possessions for the Price of One

Project possession from every friendly city and military unit, with **no separate Trentrouls hero to protect**. Eligible enemy and Barbarian units within **two tiles** can be selected in the Una Court panel.

- Capacity increases from **1 target in Ancient** to **8 in Information**.
- Groups of **1–4** last **2 turns**; groups of **5–8** last **1 turn**.
- Cooldown is **8 turns for one target, plus 5 per additional target**.

| Targets | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Cooldown, turns | 8 | 13 | 18 | 23 | 28 | 33 | 38 | 43 |

Quick, Epic and Marathon scale duration and cooldown by **67%, 150% and 300%** respectively.

Possessed units retain type, promotions, damage, experience, level, name, movement, facing, fortification, embarked state and attached ScriptData. They cannot be deleted, gifted or upgraded; strategic-resource requirements are checked before activation. Great People, religious units, cargo and loaded transports are excluded; ordinary Workers and Settlers remain eligible.

Survivors return when the duration expires or peace is signed. Units killed or expended remain gone; surviving units belonging to an eliminated major are safely disbanded. Automatic target selection exists in the script, but **AI civilization selection is currently disabled**.

### Unique content

| Content | Benefits |
| :--- | :--- |
| **Golden Retriever** · Scout | **45 Production**, **3 Movement**, +1 Gold maintenance over a Scout. Retains Scout abilities; non-stacking **Good Boy** aura gives adjacent friendly units **+10% Combat Strength and +5 HP healing per turn**. |
| **3 Una Court** · National Wonder | Available at **Civil Service**, costs **250 Production**. Provides **+1 Happiness**, **+5% Gold in every city** and **+1 Culture from unemployed Citizens** empire-wide. |
| **Centrelink** · Bank | Normal Bank benefits plus **+1 local Happiness**. |

**Court advice:** borrow the units that decide the battle. Filling every slot also commits you to a longer cooldown.

</details>

<a id="soft-kitty"></a>
<details>
<summary><strong>🎵 Soft Kitty Serenader</strong> — Culture, courtship and consequences</summary>

### Soft Kitty, Warm Kitty

Use **Sing Soft Kitty** to choose a met, peaceful major civilization. A successful song gives **30 Culture and 20 targeted Tourism per era number**, plus **5 influence** with each city-state allied to the audience. Base cooldown is **15 turns**.

| Audience | Rewards | Backlash risk |
| :--- | :--- | :--- |
| Friendly or Declaration of Friendship | 200% | Normally none |
| Neutral or afraid | 100% | 10% |
| Guarded or deceptive | 75% | 25% |
| Hostile | 50% | 50% |

The confirmation shows current rewards and risk. The first audience to cause backlash becomes the permanent **Ex**: future songs to that civilization gain **+25% rewards** but carry at least **15% backlash risk**.

**Repercussions:** a failed song gives no rewards and causes **5 turns** of **−15% Production, −10% military Combat Strength and −20% Great Person generation**. Land/naval military units trained during recovery lose one Movement until recovery ends; purchases are exempt. Further backlash refreshes the duration without stacking penalties.

### Unique content

- **Hopeless Romantic** replaces the Great Musician and retains Great Work creation. Its custom **Serenade**, replacing the native concert action, consumes the unit beside a peaceful foreign major city for **125% of normal concert Tourism, 100 Culture** and the allied city-state influence bonus. The Ex receives a further **20% Tourism**. Hostile audiences have **25% backlash risk**, but the concert still pays its rewards.
- **Comfort Room** inherits the active Opera House and adds **+1 Culture, +1 local Happiness, +1 Culture per local Great Work of Music and +10% local Great Musician generation**. Each room reduces the empire's recovery Production penalty by one percentage point, capped at zero, and produces **+3 local Culture** during recovery.

Song yields, concert Tourism, cooldown and recovery scale with game speed. The concert's **100 Culture** is fixed. Cooldown, Ex identity and recovery persist through saves. AI can choose audiences and use adjacent concerts.

**Court advice:** cultivate friendly audiences before singing. Comfort Rooms soften the economic cost when romance goes badly.

</details>

<a id="library-exile"></a>
<details>
<summary><strong>📚 Library Exile</strong> — turn diplomatic isolation into scholarship</summary>

### Banished to the Library

Each living major civilization denouncing or at war with Trent supplies **one Exile Stack**, even if both conditions apply. Each stack gives School Library cities **+3% Science and +3% Culture**, capped at **three stacks / +9%**.

The first civilization to share a Declaration of Friendship becomes the permanent **Visitor**. While friendship with that same civilization is active, all cities gain **+15% Great Writer generation**, the empire gains **+2 Happiness**, and School Libraries gain **+1 Culture**. Another friend cannot replace the Visitor.

### Unique content

| Content | Benefits |
| :--- | :--- |
| **School Library** · Library | Inherits the installed Community Patch Library; adds **+1 Culture, +1 Great Writer Point** and **one Great Work of Writing slot**. |
| **iPad Reader** · Great Writer | Retains Great Works and Political Treatises. A Reader in a School Library city at turn start gives **+2 Science and +2 Culture** there; multiple Readers do not stack. Expending one through a Great Person action awards **25 Science per era number**, from 25 to 200. |

Exile and Visitor state persist through saves. The civilization uses defensive AI priorities and adds no core UI replacement.

**Court advice:** build tall around School Libraries, and remember who your first friend was when diplomacy improves.

</details>

<a id="phone-stealer"></a>
<details>
<summary><strong>📱 Phone Stealer</strong> — a thriving Capital, a growing Stash, some angry rivals</summary>

### The Red-Headed Phone Snatcher

An established Spy in a foreign Capital can begin **Snatch Phone**, taking **8 turns** to steal that rival's unique Phone. Moving the Spy away cancels the attempt.

- Each Phone gives the Capital **+2 Science, +2 Gold and +1 Culture**; every three Phones provide **+1 Happiness**.
- The victim receives **He Stole My Phone!**, a strong opinion penalty lasting exactly while Trent holds its Phone.
- Phones from eliminated civilizations stay in the Stash.
- Returning a Phone removes its yields and grievance, and protects it from another theft for **30 turns**.

The **Phone Stash** window shows rivals, mission progress, yields, held Phones and return protection. Mission and protection timing scale with game speed. AI begins missions against established non-friendly targets and avoids close friends unless relations deteriorate.

### Unique content

| Content | Benefits |
| :--- | :--- |
| **Una Court Butler** · Worker | Costs **20% more Production**, works **25% faster**. Capture attempts return it to Trent's Capital or the nearest valid tile instead of permanently transferring it. |
| **Centrelink** · Bank | Uses the shared Bank replacement and art, with normal Bank benefits plus **+1 local Happiness**. |

**Court advice:** balance the Capital's growing income against the diplomatic value of returning a rival's Phone.

</details>

<a id="princedom"></a>
<details>
<summary><strong>👑 Princedom of Una Court</strong> — Pupil of Two Masters</summary>

### One Trent. Two masters. One life.

**Trent Steinhauer** studies possession under Baby and body exchange under Captain Ginyu. He replaces the opening Warrior at **150% of its base strength**: **12 Combat Strength and 2 Movement** on the inspected Community Patch baseline. He upgrades normally between techniques but cannot be replaced, purchased, gifted or disbanded. Ordinary Warriors remain trainable.

Use the **Two Masters** panel against visible, adjacent enemy **land military units**, including Barbarians, outside cities. Each successful activation grants one permanent stack to that technique alone, capped at **12**. The activation uses the mastery held **before** earning its new stack.

| Mastery stacks | Duration | Possession damage | Swap damage | Original-body swap resistance | Target base strength limit |
| :--- | ---: | ---: | ---: | ---: | :--- |
| 0–2 | 1 turn | −35% | −20% | 80% | 100% of Trent |
| 3–5 | 1 turn | −20% | 0% | 82% | 125% |
| 6–8 | 2 turns | −10% | +15% | 85% | 150% |
| 9–11 | 2 turns | 0% | +25% | 88% | 200% |
| 12 | 3 turns | +10% | +40% | 90% | Unlimited |

Both techniques share a fixed cooldown: **5 / 8 / 12 / 24 turns** on Quick / Standard / Epic / Marathon. Mastery never reduces it.

- **Possession** leaves the original body immobile and vulnerable.
- **Body Swap** gives the enemy the original body with damage resistance. It may move at most one tile but cannot attack, pillage, embark or capture cities.
- The original body's death collapses the empire, even after upgrading or during enemy control. Losing a borrowed body does not.
- **Fanfic Monuments** inherit Monuments and double their intrinsic benefits while either technique is active. On the inspected baseline, intrinsic Culture rises from **+2 to +4**; maintenance and policy/religious modifiers are not doubled.

AI uses the same abilities, practices on Barbarians and avoids obvious danger, while native tactical AI still controls ordinary movement.

**Court advice:** escort Trent, practice both techniques and upgrade between activations. Even maximum resistance is not immortality.

See the **[full Princedom guide](Princedom/README.md)** for targeting, rounding, return behavior and progression; [engine notes](Princedom/CP151_NOTES.md) and [validation checklist](Princedom/TESTING.md) document the remaining limits. In-game verification is pending.

</details>

<a id="wealthy"></a>
<details>
<summary><strong>💰 Wealthy of Una Court</strong> — the man who has everything, yet still receives Centrelink</summary>

### Cheating the Centrelink System

A **human-only** economic civilization favoring infrastructure purchases and city-state alliances for Diplomatic Victory, with Science as a secondary route. It has a normal opening and no special combat bonus.

Every **25 turns**, rank surviving, met foreign majors by treasury. From the richest third, rounded up, audit up to **two** civilizations with at least **500 Gold and +10 GPT**. Contact is required; war does not prevent an audit.

1. Transfer **5% of each donor's current treasury** immediately.
2. On Trent's next **five turns**, transfer **20% of each donor's current positive GPT**.
3. Round payments down and cap them at available treasury. Trent receives exactly what the donor loses; a non-positive GPT pays nothing that turn, but the turn still counts.

Audit intervals are **17 / 25 / 38 / 75 turns** on Quick / Standard / Epic / Marathon. Installments always last **five turns**.

### Unique content

| Content | Benefits |
| :--- | :--- |
| **Enhanced Centrelink** · Bank | A Wealthy-only version doubles the shared Centrelink's positive yields, yield modifiers, local Happiness (**+2 instead of +1**), Merchant capacity and recipient trade Gold. Costs, maintenance, prerequisites, penalties and foreign traders' target bonus are retained. |
| **3 Una Court** · Palace | Retains normal Palace effects and follows the Capital. Adds total **+1 empire Happiness and +2 GPT per current era level**: Ancient +1/+2, Medieval +3/+6, Information +8/+16. Tiers replace each other rather than accumulating. |

This **3 Una Court is a Palace replacement**; Ultimate Possession's building of the same name is a **National Wonder**. Other civilizations keep their ordinary Centrelink.

**Court advice:** explore early to meet donors, research Banking and invest the proceeds in infrastructure and city-state alliances.

See [Wealthy testing and implementation notes](WEALTHY_TESTING.md) for the complete algorithm, persistence, schema contract and pending in-game checklist. Full Vox Populi Happiness is unsupported.

</details>

## Compatibility

| Area | Current support |
| :--- | :--- |
| **Ruleset** | Brave New World + Community Patch; v151 is the documented baseline. Soft Kitty also has database validation against Community Patch 5.4.2. |
| **Full Vox Populi** | Not fully verified. Wealthy's Happiness implementation specifically targets CP-only behavior. |
| **Game modes** | Windows single player. Multiplayer, hotseat and Mac are disabled in the manifest. |
| **Saves** | Start a new game when adding these civilizations. Scripted cooldowns and civilization state persist through saves; engine playtesting remains pending where noted. |
| **Other mods** | Specialized units may store private state outside a unit or key it by UnitID; generic ownership transfer cannot preserve all such external state. |
| **Release status** | Alpha. Automated checks cover database, assets and mocked Lua behavior; in-game layout, pathfinding and interactions with other mods still need playtesting. |

### Interface and ownership transfers

The shared right-side panel switches between Freehold Possession, Dominion Body Swap and Ultimate Mass Possession. Ultimate adds multi-selection, capacity/cooldown previews, active-unit tracking and unit/capital finders. Soft Kitty, Phone Stealer and Princedom have their own civilization-specific panels. Panels hide in city view and do not replace core TopPanel, UnitPanel, CityView, Community Patch or EUI contexts.

The original three possession systems temporarily normalize unit ownership while saving, then restore active effects after saving or gameplay initialization on load. Dominion restores remaining duration, cooldown and unit state, including movement, damage, experience, level, name, promotions and attached ScriptData. Princedom has its own persistent ownership system, described in its [guide](Princedom/README.md).

The collection uses base-game unit models with custom emblems and leader art. The first four civilizations share Una Court's location map; later variants use dedicated or framed court maps.

## Development

### Repository map

| Path | Contents |
| :--- | :--- |
| [`Art/`](Art/) | Icon atlases, leader scenes, previews and retained source artwork/prompts |
| [`SQL/`](SQL/) | Seven civilizations' definitions, inheritance, scaling and English text |
| [`Lua/`](Lua/) | Possession, companion auras, songs, exile, Phone missions, audits, AI and save state |
| [`UI/`](UI/) | Shared possession panel and isolated song / Phone Stash panels |
| [`Princedom/`](Princedom/) | Princedom's isolated SQL, Lua, UI, art, documentation and engine checklist |
| [`Tools/`](Tools/) | Packaging, reproducible art/inheritance builders and validators |
| [`CHANGELOG.md`](CHANGELOG.md) · [`PATCHNOTES.md`](PATCHNOTES.md) | Detailed change history and release notes |

<details>
<summary><strong>🛠 Validation commands and playtesting</strong></summary>

Run commands from the repository root. Packaging needs only Python 3.9+; art tools use **Pillow**, and gameplay tests use **Lupa / Lua 5.1**, with local dependencies in `.modbuddy/test-deps`. Phone Stealer's documented test setup uses Python 3.12. Database validators need the appropriate installed Community Patch baseline or debug database; inspect each tool's arguments before running on another installation.

| Area | Database / asset validation | Gameplay tests |
| :--- | :--- | :--- |
| Shared possession safety | `python Tools/validate_mod.py` | `python Tools/test_possession_safety.py` |
| Soft Kitty | `python Tools/validate_soft_kitty.py` | `python Tools/test_soft_kitty.py` |
| Library Exile | `python Tools/validate_library_exile.py` | `python Tools/test_library_exile.py` |
| Phone Stealer | `python Tools/validate_phone_stealer.py` | `python Tools/test_phone_stealer.py` |
| Princedom | `python Tools/validate_princedom.py` | `python Tools/test_princedom.py` |
| Wealthy | `python Tools/validate_wealthy.py` | `python Tools/test_wealthy.py` |

**Reproducible assets:** `Tools/build_soft_kitty_art.py`, `Tools/build_library_exile_art.py`, `Tools/build_phone_stealer_art.py`, `Tools/build_princedom_art.py` and `Tools/build_wealthy_art.py` rebuild their respective artwork. Source images and prompts are retained in `Art/Source/`; Princedom's guide documents its reused artwork and generated glyphs. Corresponding inheritance builders are also in `Tools/`.

**Wealthy inheritance:** `python Tools/build_wealthy_inheritance.py --check` checks exact regeneration against the CP v151 contract in `Tools/wealthy_schema.json`. `python Tools/test_wealthy_inheritance.py` checks schema failures and reproducibility. The builder and `validate_wealthy.py` accept `--baseline-db`, `--cp-root` and `--game-assets` for explicit read-only inputs.

**Wealthy persistence:** `Modding.OpenSaveData` stores the last processed turn, next audit, two donor IDs and remaining installments under `TRENT_WEALTHY_V1_` keys. Only Trent's `PlayerDoTurn` advances transfers. Initialization/load cleans stale buildings; era/capture callbacks reconcile Palace tiers without levying Gold. Routine reconciliation is limited to Wealthy cities, with capture/gift/liberation cleaning the affected city. Unfinished installments survive a callback gap beyond the next audit date. See [WEALTHY_TESTING.md](WEALTHY_TESTING.md) for source evidence and CP-only Happiness caveats.

### In-game smoke tests

For every civilization, begin a **new game**, check selection/Civilopedia icons and opening units, exercise its ability, save/reload through active effects and cooldowns, and inspect **Lua.log** and **Database.log**.

- **Soft Kitty:** meet a major, preview and confirm a song, test backlash/recovery, use an adjacent Hopeless Romantic, create a Great Work and verify Comfort Room bonuses. Open/close city view to check panel isolation.
- **Library Exile:** build a School Library and station a Reader inside. Confirm a rival both denouncing and at war counts once; test three hostile majors and reconciliation. Let the first friendship expire, befriend someone else, then renew the original Visitor. Test Great Work and Political Treatise actions.
- **Phone Stealer:** establish a Spy in a foreign Capital, complete a scaled mission, verify Capital yields and the victim's opinion, then save/reload with a held Phone and an active mission. Return a Phone, check protection, and test Butler capture by both rivals and Barbarians.
- **Princedom:** follow the [engine checklist](Princedom/TESTING.md) and [CP v151 limitations](Princedom/CP151_NOTES.md), including identity across upgrades, both masteries and original-body death.
- **Wealthy:** follow the [audit, Palace and save/load checklist](WEALTHY_TESTING.md). Automated scenarios do not replace the pending engine checks.

Refresh the registered manifest after changing game files with `python Tools/package_mod.py`; use `--package` to also produce an installable folder.

</details>

---

<p align="center"><em>Long live Una Court. Keep an eye on your phone.</em></p>
