# Changelog

This file records the main player-facing and technical changes included in each repository push. New entries are added at the top.

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
