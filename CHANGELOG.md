# Changelog

This file records the main player-facing and technical changes included in each repository push. New entries are added at the top.

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
