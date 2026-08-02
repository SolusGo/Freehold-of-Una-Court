# Changelog

This file records the main player-facing and technical changes included in each repository push. New entries are added at the top.

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
