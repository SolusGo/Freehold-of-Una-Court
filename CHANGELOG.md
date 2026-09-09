# Changelog

This file records the main player-facing and technical changes included in each repository push. New entries are added at the top.

## 2026-09-09 - Library Exile emblem filename collision fix

- Gave every Library Exile civilization-emblem texture a globally unique filename, preventing Civ V's texture cache from substituting Soft Kitty's crowned-cat emblem in the civilization-selection list.
- Added validation covering the collision-safe filenames at all six supported icon sizes; gameplay and fixed version 3 remain unchanged.

## 2026-09-09 - Standalone Library Exile leader portrait

- Replaced the shared-sheet Library Exile leader lookup with dedicated 1×1 DDS textures at portrait index 0 for every supported size.
- This prevents Civ V's setup UI from substituting the Soft Kitty leader portrait while retaining the intended school-blazer, tablet-holding Trent artwork.
- Audited the remaining Trent icon mappings and also isolated the visible iPad Reader and School Library onto standalone 1×1 atlases, preventing the same shared-sheet substitution from affecting the unique badges.
- Refreshed the separate Library Exile alpha-emblem atlas used by the third setup-screen badge; this was the final stale binding still displaying Soft Kitty's crowned cat.

## 2026-09-09 - Library Exile leader icon correction

- Assigned the intended school-blazer, tablet-holding Library Exile portrait to a fresh leader-only atlas identity, preventing the setup screen from reusing another Trent civilization's cached portrait.
- Left the leader art, gameplay and fixed version 3 unchanged.

## 2026-09-09 - Library Exile civilization icon correction

- Moved the Library Exile's tablet-and-open-book emblem onto a fresh, dedicated civilization atlas identity so the civilization-selection screen cannot reuse the Ultimate Possessor emblem from a stale atlas binding.
- Kept the existing icon art, gameplay and fixed mod version unchanged.

## 2026-09-09 - Ultimate Possessor balance nerf

- Kept Ultimate Possession's Era capacity, targeting, range, temporary ownership, unit preservation, UI, Golden Retriever, Centrelink, 3 Una Court, and all other mechanics unchanged.
- Reduced Standard-speed possession duration to 2 turns for groups of 1–4 units and 1 turn for groups of 5–8 units.
- Increased Standard-speed cooldown to 8 turns for one unit plus 5 turns per additional possessed unit: 8/13/18/23/28/33/38/43 turns.
- Preserved the existing Quick, Epic, and Marathon game-speed timing scaling and updated the command-panel previews and Civilopedia text to match.

## 2026-09-07 - Library Exile civilization

- Added the fifth Trent civilization, a defensive Science/Culture faction whose School Library cities gain up to three +3% Exile Stacks from civilizations denouncing or at war with Trent.
- Added a permanent, save-safe Visitor identity: the first friend provides +15% Great Writer generation, +2 Happiness, and extra School Library Culture whenever that friendship is active.
- Added the School Library and iPad Reader by cloning the installed Community Patch Library and Great Writer definitions, preserving population Science, Great Works, Political Treatises, names, AI data, and future baseline fields.
- Added non-stacking stationed Reader yields and 25 Science per Era when an iPad Reader is expended through a Great Person action.
- Added library-themed civilization, leader, unit and building icons; a custom map; silent Dawn of Man and static diplomacy art; dialogue; twenty cities; and structured Civilopedia articles.
- Added ten Lua 5.1 gameplay scenarios plus baseline, full activation-order, localization, project and art validation.
- Preserved every existing UI context, fixed the package at version 3, and enabled the new civilization's defensive AI profile. In-game playtesting remains necessary.

## 2026-09-07 - Soft Kitty Serenader civilization

- Added a fourth, culture-focused Trent civilization with era-scaled songs, audience-based rewards and backlash risks, persistent Ex tracking, and AI support.
- Added Hopeless Romantic concerts and Comfort Rooms, inheriting the installed Community Patch Great Musician and Opera House definitions rather than replacing their baseline mechanics.
- Implemented temporary Repercussions, trained-unit movement penalties, recovery notices, capped Comfort Room mitigation, and save/load-safe cooldowns.
- Added an isolated audience/confirmation UI that hides in city view without replacing existing panels.
- Added navy/gold circular icon atlases, leader and Dawn artwork, static diplomacy art, dialogue, and structured Civilopedia entries. Retained artwork sources and prompts.
- Added database/atlas/UI validation and twelve mocked Lua 5.1 gameplay scenarios covering rewards, recovery, save/load, consumption, ownership changes, speed scaling and AI.
- Kept package version 3 and the previous three civilizations' player-only selection settings. New civ AI is enabled per its design brief. In-game playtesting remains necessary.

## 2026-08-31 - Ultimate Possession Civilopedia and wonder-art polish

### Changed

- Filled the previously blank Ultimate Possession Civilopedia overview with native sections for its rules, possession scaling, Golden Retriever, shared Centrelink, 3 Una Court, strategy, and faction lore.
- Added a structured Trentrouls leader biography with title, era, four readable history sections, and gameplay factoids.
- Expanded the Golden Retriever and 3 Una Court individual Civilopedia articles with practical usage guidance.
- Rebuilt all six 3 Una Court icon sizes as a focused circular mansion portrait with transparent corners and layered Civ V-style gold framing.
- Kept the mod fixed at version 3 and added validation for the structured Civilopedia keys and wonder-icon transparency.

## 2026-08-31 - Ultimate Possession duplicate starting Warrior fix

### Fixed

- Ultimate Possession now retains exactly one ordinary Warrior when Vox Populi, a handicap, or another setup rule grants an overlapping opening-unit package.
- Restricted the cleanup to turn zero and to duplicate base Warriors, so trained, captured, upgraded, possessed, and later-game units remain untouched.
- Kept the intended normal Settler-and-Warrior opening and the mod's fixed version 3 deployment.

## 2026-08-30 - Ultimate Possession civilization-icon cleanup

### Changed

- Removed the Ultimate Possession emblem's square black background and rebuilt all six civilization-icon atlases with proper transparency.
- Reduced and centered the purple-gold medallion to match the visual footprint of the Freehold and Dominion civilization icons in selection lists and other UI.
- Kept the mod fixed at version 3 and used DXT5 compression for clean transparent corners.

## 2026-08-30 - Ultimate Possessor leader-list polish

### Changed

- Rebuilt the Ultimate Possessor leader portrait at all six Civ V atlas sizes as a circular icon with transparent corners and layered gold framing.
- Matched the established Dominion portrait footprint so the artwork no longer fills the square, intrudes into adjacent civilization rows, or breaks the leader-list rhythm.
- Kept the mod fixed at version 3 and regenerated the portrait atlases with DXT5 transparency.

## 2026-08-30 - Ultimate Possession civilization

### Added

- Added a third playable civilization, **Trentrouls - Ultimate Possession**, with a normal Settler and Warrior start.
- Added **Two Possessions for the Price of One**, a multi-unit possession ability with Era-scaled capacity from 1 to 8 targets and a Standard-speed cooldown of 5 turns plus 3 per additional target.
- Added a dedicated multi-select mode to the existing Una Court command panel, including selected-count, capacity, duration, prospective cooldown, active-unit, and network-range feedback.
- Added Barbarian possession, strategic-resource validation, safe peace and eliminated-owner handling, AI target selection, and delete/gift/upgrade protection.
- Added save/load-safe mass possession: temporary ownership is normalized before serialization and reconstructed after saving or loading with transactional rollback.
- Added the **Golden Retriever** Scout replacement with 3 Movement and the non-stacking **Good Boy** aura: adjacent friendly units gain +10% Combat Strength and +5 HP healing per turn.
- Added the unique National Wonder **3 Una Court**, providing +1 Happiness and +5% Gold in every city while unemployed Citizens produce +1 Culture.
- Shared the existing **Centrelink** Bank replacement with the new civilization instead of duplicating its building definition.
- Added dedicated generated artwork for the Ultimate Possessor Dawn of Man scene, purple-gold civilization emblem and alpha mask, Trentrouls leader atlas, and 3 Una Court wonder atlas at every required Civ V size.
- Added reproducible art-build and project/database/art validation tools.

### Compatibility

- Kept the mod fixed at version 3 and deployed over only `The Freehold of Una Court (v 3)`.
- Reused the existing isolated InGameUIAddin rather than replacing TopPanel, UnitPanel, CityView, Community Patch, or EUI files.
- Retained the Freehold and Dominion rules, assets, UI modes, and save/load systems unchanged except for registering the shared third mode.

## 2026-08-07 - Persistent save-safe Body Swap

### Changed

- Replaced the one-way save cleanup with a transactional save/load system for both Dominion Body Swap and Freehold Body Possession.
- Active transfers now temporarily restore ordinary ownership immediately before serialization, then automatically reconstruct the transfer after the save completes.
- Saves record the normalized unit IDs, original owner, remaining duration, and cooldown in Civ V's embedded save database; loading reconstructs the active transfer after gameplay Lua initializes.
- Preserved unit movement, damage, experience, custom names, and promotions through the save transaction.
- Made save-only ownership transfers unattributed so they cannot award ordinary combat-kill credit during suspension or reconstruction.
- Added a shared deferred gameplay-update dispatcher inside Una Court's existing loader so post-save restoration and combat-return safety coexist without replacing external TopPanel, UnitPanel, CityView, Community Patch, or EUI contexts.
- Added validation and rollback paths that retain ordinary ownership if either temporary body cannot be reconstructed.
- Updated the README and Civilopedia strategy text, and kept the mod at version 3.

### Compatibility

- Previously corrupted saves still cannot be repaired because they fail before gameplay Lua loads; this system protects newly written saves whose pre-save hook executes.

## 2026-08-07 - Save-safe possession ownership

### Fixed

- Enabled the Community Patch pre-save gameplay event for Una Court.
- Active Dominion Body Swap now ends immediately before manual saves, quicksaves, and autosaves are serialized, returning both bodies to their ordinary owners while retaining the cooldown.
- Applied the same pre-save ownership normalization to Freehold Body Possession.
- Removed temporary cross-civilization unit ownership from newly written save files to avoid native load failures before gameplay Lua initializes.
- Documented the intentional save behavior in the Civilopedia strategy and README.
- Kept the mod at version 3 so deployment replaces the existing version 3 folder.

### Compatibility

- Existing saves that already crash during native deserialization cannot be repaired by Lua because the crash occurs before Lua loads; this change protects newly created saves.

## 2026-08-07 - Next-turn empire collapse

### Changed

- Replaced the temporary opponent-victory workaround with normal Una Court player elimination.
- Trentrouls' death now queues the Freehold or Dominion collapse until the next civilization turn begins instead of removing cities and units during combat/UI processing.
- Added a Community Patch end-turn-blocker safety check; cleanup defers to another turn if any blocker is still active.
- Removed empire destruction from the per-frame update path while retaining safe processing for borrowed-body returns.
- Kept the mod at version 3 so deployment replaces the existing version 3 folder.

## 2026-08-07 - End-turn-safe human defeat

### Fixed

- Identified the latest Community Patch assertion as an unresolved end-turn blocker (`3`, production) being present when Trentrouls' collapse eliminated the active human player.
- Changed both Freehold and Dominion human defeat handling to award a real Domination victory to a living opponent instead of deleting the active human's last city during the blocker update.
- Retained full physical empire collapse for AI-controlled Una Court civilizations.
- Added a compatible defeat-screen fallback for DLL builds that do not expose the winner-setting API.
- Prevented Trentrouls setup and trait refresh from restarting if the player selects one-more-turn after the scripted defeat.
- Kept the mod at version 3 so deployment replaces the existing version 3 folder.

## 2026-08-06 - Combat-safe Trentrouls collapse

### Fixed

- Prevented the Dominion collapse from immediately killing the same Trentrouls object already undergoing the Community Patch DLL's delayed combat death.
- Excluded the dying original body from the Dominion's remaining-unit purge and allowed the combat system to finish deleting it normally.
- Made both Freehold and Dominion death queues idempotent so duplicate `UnitPrekill` callbacks cannot reset or repeat a collapse.
- Added two settled post-combat update frames before empire cleanup, with the next-player-turn path retained as a safe fallback.
- Kept the mod at version 3 so deployment replaces the existing version 3 folder.

## 2026-08-06 - Dominion emblem clarity and Buddy restriction

### Fixed

- Restricted Buddy's custom unit class to the Freehold civilization override, preventing the Dominion and all unrelated civilizations from training him.
- Simplified the Dominion civilization medallion for small UI sizes by removing the compressed grey backdrop and redundant inner keylines, using a clean black field and brighter crimson emblem instead.
- Regenerated and validated the complete DXT5 civilization colour atlas while retaining its established 88% Civ V-safe footprint.
- Kept the mod at version 3 so deployment replaces the existing version 3 folder.

## 2026-08-06 - Dominion leader portrait correction

### Fixed

- Rewired the Dominion leader record to use its dedicated red-violet "ready to possess" Trentrouls portrait instead of the Freehold Trentrouls leader portrait.
- Reused the already validated Dominion Trentrouls atlas at every required Civ V icon size and kept the mod at version 3.

## 2026-08-06 - Dominion heraldic banners

### Changed

- Replaced the generic mask motifs on the Dominion Dawn of Man banners with the civilization's actual circular house-and-split-mask emblem.
- Integrated the emblem into the aged crimson fabric, folds, perspective, and torch lighting while preserving Trentrouls, his throne pose, psychic effects, architecture, and composition.
- Rebuilt the exact 1024x768 DXT1 game texture; the shared Una Court map and fixed mod version 3 remain unchanged.

## 2026-08-06 - Dominion Dawn of Man throne scene

### Added

- Added a dedicated Dominion Dawn of Man painting inspired by the supplied Trent reference and the relaxed, commanding throne posture associated with Whiterun's jarls.
- Depicted Supreme Possessor Trentrouls seated deep on an original dark-wood-and-iron throne in a crimson-black court, with restrained Body Swap energy around his resting hand.
- Created the exact 1024x768 DXT1 texture required by Civ V while retaining the full-resolution generated painting in `Art/Source`.

### Changed

- The Dominion now uses `Art/DominionDawnOfMan/DominionDawnOfMan.dds`; the Freehold retains its existing fireplace Dawn of Man artwork.
- Both Una Court civilizations deliberately continue to use the same styled Una Court location map.
- Kept the Dawn of Man presentation silent and the mod at version 3 so deployment replaces the existing version 3 folder.

## 2026-08-06 - Dominion Trentrouls possession portrait

### Added

- Added a dedicated Dominion Trentrouls unique-unit portrait based on the supplied reference photograph.
- Reimagined Trentrouls in a Civ V-style painted crimson-and-black court outfit, reaching forward with glowing eyes and red-violet psychic energy to communicate that Body Swap is ready.
- Created native DXT5 atlas assets at Civ V's required 256, 128, 80, 64, 45, and 32 pixel sizes.
- Retained the full-resolution generated portrait in `Art/Source` for future revisions.

### Changed

- The Dominion Trentrouls unit now references `DOMINION_TRENTROULS_UNIT_ATLAS`; the Freehold retains its existing teal-energy Trentrouls portrait.
- Applied the same 88% visual footprint and layered gold medallion frame used by the other right-side civilization component icons.
- Kept the mod at version 3 so deployment replaces the existing version 3 folder.

## 2026-08-06 - Dominion civilization emblem

### Added

- Added the supplied red-and-black house-and-mask design as the Dominion of Una Court's dedicated civilization emblem.
- Added a Dominion-specific monochrome alpha emblem for map flags and compact interface elements.
- Created native DXT5 assets at Civ V's required 256, 128, 80, 64, 45, and 32 pixel colour-atlas sizes and 128, 80, 64, 45, and 32 pixel alpha-atlas sizes.
- Retained the supplied full-resolution image in `Art/Source` for future revisions.

### Changed

- Applied the same 88% visual footprint and layered Civ V-style gold medallion frame used by Una Court's other selection-screen component icons.
- The Dominion now references its own colour and alpha atlases; the Freehold retains its existing dog-and-target emblem.
- Kept the mod at version 3 so deployment replaces the existing version 3 folder.

## 2026-08-06 - Dominion of Una Court

### Added

- Added the Dominion of Una Court as a second selectable civilization led by Supreme Possessor Trentrouls.
- Added Dominion Trentrouls with 8/10/16/22/30/42/56/72 era-scaled Combat Strength and a Settler-plus-Trentrouls opening with no ordinary Warrior.
- Added Body Swap: exchange Trentrouls with an eligible enemy within two tiles, control the borrowed body with +5% Combat Strength, and leave the original body under enemy control.
- Added game-speed-scaled Body Swap duration and cooldown, era-scaled Golden Age Point rewards, AI target selection, save persistence, and permanent borrowed-unit actions.
- Added a Dominion mode to the existing command panel with preview-and-confirm targeting, body status, timing, strength, and Find Borrowed controls.
- Added separate red-and-gold Dominion player colours and complete Civilopedia, strategy, Dawn of Man, city, unit, promotion, and leader text.

### Changed

- Centrelink is shared through one building definition and two civilization overrides; both Una Courts receive the same Bank replacement with +1 local Happiness.
- The existing right-side UI context now serves both civilizations without replacing TopPanel, UnitPanel, CityView, Community Patch, or EUI files.
- Updated the README to describe both playable Una Court variants and their distinct mechanics.
- Kept the mod at version 3 so deployment replaces the existing version 3 folder.

### Safety

- Deferred Dominion collapse and borrowed-body return processing until combat has ended, preventing recursive unit deletion inside the Community Patch DLL combat callback.
- Isolated all Dominion saved-data keys and promotions from the Freehold's existing Body Possession system.
- Excluded air, missile, nuclear, suicide, trade, immune, Una Court hero, and Barbarian targets from Body Swap.

## 2026-08-03 - Ginger-red civilization colour

### Changed

- Replaced Una Court's dark-green primary player colour with a warm auburn/ginger red inspired by Trent's hair (`#9E331F`).
- Retained the existing gold secondary colour for strong contrast across map borders, city banners, unit flags, and strategic-view markers.
- Kept the mod at version 3 so deployment continues to replace the existing version 3 folder.

## 2026-08-03 - Multiple opening Warriors cleanup

### Fixed

- Corrected the starting-unit fallback for handicap and mod combinations that grant more than one ordinary Warrior.
- Una Court now removes the complete turn-zero Warrior starting package before creating or retaining Trentrouls, rather than removing only the first Warrior found.
- The cleanup remains restricted to turn zero; Warriors trained, upgraded, captured, spawned, or loaded on later turns are untouched.
- Kept the mod at version 3 so deployment continues to replace the existing version 3 folder.

## 2026-08-03 - Possession safety and tactical information

### Added

- Added a one-time standard Civ V notification when Body Possession's cooldown reaches zero.
- Added a preview-and-confirm possession workflow: selecting a target highlights it and centers the camera, while a separate confirmation button performs the possession.
- Added Trentrouls' current and next-Era Combat Strength plus the full game-speed-adjusted possession duration and cooldown to the command panel.

### Changed

- Eligible possession targets are now sorted by distance first, then by highest Combat Strength, with stable name and unit-ID tie breakers.
- Target entries now display their distance and Combat Strength directly.
- Kept every new control inside the unchanged right-side 424x520 command panel; no TopPanel, UnitPanel, CityView, Community Patch, or EUI context is overridden.
- Kept the mod at version 3 so deployment continues to replace the existing version 3 folder.

## 2026-08-03 - Unit-finding and Buddy distance controls

### Added

- Added `Find Trent` and `Find Buddy` buttons to the existing Una Court command panel; each selects its unit and centers the map on it.
- Added Buddy's exact map distance to the status display when Buddy is not adjacent to Trentrouls.

### Changed

- Reflowed the command panel's existing bottom row to fit the two new controls without enlarging or moving the panel.
- The Una Court launcher and command panel now hide while the city screen is open, preventing overlap with city-view controls while leaving the top-left unit panel untouched.
- Kept the mod at version 3 so deployment continues to replace the existing version 3 folder.

## 2026-08-03 - Silent Dawn of Man presentation

### Changed

- Removed Una Court's inherited American Dawn of Man audio event so the loading presentation is silent.
- Preserved the inherited soundtrack tag so ordinary in-game music continues after loading.
- Kept the mod at version 3 so deployment continues to replace the existing version 3 folder.

## 2026-08-03 - Selection-screen spacing and readability

### Changed

- Reduced the complete Buddy, Centrelink, and Una Court civilization medallions to 88% of their atlas slots so they match neighbouring civilizations' component icons.
- Left Trent's corrected leader size, Trentrouls' unit portrait, and the civilization flag alpha atlas unchanged.
- Shortened the unique ability summary to three concise sentences so it no longer crosses the civilization-row divider.
- Kept the mod at version 3 so deployment continues to replace the existing version 3 folder.

## 2026-08-03 - Duplicate starting Warrior fix

### Fixed

- Una Court now begins with its Settler and Trentrouls without also retaining Civ V's ordinary opening Warrior.
- Corrected the starting-unit fallback's existing-Trentrouls path, which previously returned before removing the separately granted Warrior.
- Limited the cleanup to one Warrior on turn zero so trained, upgraded, captured, or later-game Warriors are never affected.
- Kept the mod at version 3 so deployment continues to replace the existing version 3 folder.

## 2026-08-03 - Leader medallion sizing correction

### Changed

- Reduced Trent's leader medallion to 82% of its atlas slot so it matches the dimensions of stock and neighbouring modded leader portraits.
- Added transparent padding around all six leader atlas sizes to prevent the portrait from crossing civilization-row dividers.
- Left the component, unit, building, civilization, and flag icons unchanged.
- Kept the mod at version 3 so deployment continues to replace the existing version 3 folder.

## 2026-08-03 - Gold medallion icon pass

### Changed

- Reduced the visual scale of Una Court's custom portraits so their artwork no longer crowds the civilization-selection icon slots.
- Added layered dark-and-gold Civ V-style medallion rims to Trent's leader portrait, Trentrouls, Buddy, Centrelink, and the Una Court civilization emblem.
- Rebuilt all five colour atlases at the required 256, 128, 80, 64, 45, and 32 pixel sizes with clean transparent corners and DXT5 compression.
- Left the civilization alpha atlas unchanged so flag recolouring continues to work normally.
- Kept the mod at version 3 so deployment continues to replace the existing version 3 folder.

## 2026-08-03 - Dawn of Man aesthetic pass

### Changed

- Reworked Trent's Dawn of Man image into a painterly Civ V-style court portrait while preserving his identity, seated pose, glasses, and smartphone.
- Added dark-green-and-gold Freehold clothing, warm fireplace lighting, and a more imposing carved-stone setting.
- Restyled the real Una Court location map with parchment colour grading, subtle paper texture, edge shading, and a green-gold frame while preserving its roads, marker, labels, river, and attribution.
- Kept the original photograph and map alongside the new full-resolution styled source assets for future revisions.
- Kept the mod at version 3 so deployment continues to replace the existing version 3 folder.

## 2026-08-03 - Dawn of Man and location artwork

### Added

- Added the supplied photograph of Trent as Una Court's 1024x768 Dawn of Man image.
- Added the supplied Una Court location map in Civ V's 360x412 civilization-map format.
- Retained both original source images for future crop or presentation revisions.

### Changed

- Replaced the temporary American Dawn of Man and map images with dedicated Una Court assets.
- Kept the mod at version 3 so deployment continues to replace the existing version 3 folder.

## 2026-08-03 - Una Court nation emblem

### Added

- Added the supplied gold target-and-dog design as Una Court's civilization portrait.
- Added a transparent alpha version of the emblem for civilization flags and compact interface elements.
- Created native DDS assets at Civ V's required portrait and civilization-alpha atlas sizes.
- Retained the supplied full-resolution source image for future art revisions.

### Changed

- Replaced Una Court's temporary American civilization icon and alpha emblem with dedicated custom atlases.
- Kept the mod at version 3 so deployment continues to replace the existing version 3 folder.

## 2026-08-03 - Trentrouls portrait art

### Added

- Added a custom green-and-gold leader portrait inspired by Trent's supplied reference photo.
- Added a distinct armoured Trentrouls unit portrait featuring teal Body Possession energy.
- Created native DDS icon assets for both portraits at Civ V's 256, 128, 80, 64, 45, and 32 pixel atlas sizes.
- Retained the two full-resolution painted outputs for future art revisions without adding the private reference photograph to the repository.

### Changed

- Replaced Trentrouls' temporary Washington leader portrait and Warrior unit portrait with dedicated custom atlases.
- Kept the mod at version 3 so deployment continues to replace the existing version 3 folder.

## 2026-08-03 - Centrelink icon art

### Added

- Added custom Centrelink artwork for the building portrait and civilization unique-component display.
- Created native DDS icon assets at Civ V's 256, 128, 80, 64, 45, and 32 pixel atlas sizes.
- Retained the supplied full-resolution Centrelink wordmark while using its coloured emblem for legibility in small UI icons.

### Changed

- Replaced Centrelink's temporary Bank portrait with the custom `UNA_CENTRELINK_ATLAS` artwork.
- Kept the mod at version 3 so future deployments replace the existing version 3 folder.

## 2026-08-03 - Buddy portrait art

### Added

- Added custom Buddy artwork for unit portraits and civilization unique-component displays.
- Created native DDS icon assets at Civ V's 256, 128, 80, 64, 45, and 32 pixel atlas sizes.
- Retained the supplied full-resolution source image for future art revisions.

### Changed

- Replaced Buddy's temporary Scout portrait with the custom `UNA_BUDDY_ATLAS` artwork.
- Bumped the mod to version 3 so Civilization V installs the new graphics as a fresh build.

## 2026-08-03 - Centrelink visibility fix

### Fixed

- Centrelink now appears as one of Una Court's two unique components on the civilization selection and Dawn of Man screens.
- Trentrouls remains the leader and unique starting hero, but no longer consumes one of Civ V's two displayed component slots.
- Expanded Una Court's Dawn of Man, Civilopedia, and strategy text to identify Centrelink and its local Happiness bonus.
- Bumped the mod to version 2 so Civilization V installs the corrected database presentation as a new build.

## 2026-08-03 - Initial playable alpha

### Added

- Complete ModBuddy project for the Freehold of Una Court.
- Trentrouls as the civilization's unique starting hero, with era-scaled combat strength.
- The Court Lives Through Him, granting era-scaled empire yields and Great Person generation while Trentrouls lives.
- Buddy, a retrainable limited companion who doubles Trentrouls' strength and empire bonus while adjacent.
- Centrelink, a Bank replacement with +1 local Happiness.
- Body Possession targeting panel, game-speed-scaled duration and cooldown, AI usage, and save persistence.
- Freehold collapse behavior when Trentrouls dies.
- In-game Civilopedia and localization text.

### Fixed

- Added a one-time starting-unit fallback so Trentrouls appears even when another mod changes the normal starting-unit sequence.
- Deferred the Freehold's collapse until combat has fully ended, preventing a Community Patch DLL assertion when Trentrouls dies in combat.
- Updated the command panel to clearly show when Trentrouls is fallen and the empire bonus is inactive.

### Known limitations

- Art currently uses base-game placeholders.
- Specialized unit state may not be fully preserved during Body Possession.
- Multiplayer is disabled during alpha development.
