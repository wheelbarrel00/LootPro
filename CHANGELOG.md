# Changelog

All notable changes to **Loot Pro** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.5] - 2026-04-13

### Changed
- Migrated minimap button to **LibDBIcon-1.0** for better stability and compatibility with other addons.

### Added
- **LibDataBroker-1.1** launcher object — Loot Pro now appears automatically in DataBroker display addons (Titan Panel, ChocolateBar, ElvUI minimap bar, etc.).

### Embedded Libraries
- LibStub
- CallbackHandler-1.0
- LibDataBroker-1.1
- LibDBIcon-1.0

### Notes
- Existing minimap icon position and visibility settings carry over automatically — no reconfiguration needed.

## [1.1.4] - 2026-04-10

### Fixed
- **Reputation loss messages** now display correctly with proper formatting (e.g., `- 62 Rep: Gadgetzan`). The previous patterns matched legacy "You gain/lost X reputation" wording and never fired on modern WoW's "Reputation with X increased/decreased by Y." messages.
- **Loot count display** is now accurate. The `(N)` total in parentheses previously showed the pre-loot count due to a timing race with bag updates; it now uses a one-frame deferred lookup and reflects the true post-loot total.
- **TOC Interface version** updated to `120001` for WoW 12.0.1 (Midnight). Removed stale `110005` (War Within) and `120000` (Midnight pre-patch) entries.

### Changed
- **Slider labels in Layout tab** cleaned up. Removed the redundant yellow header above each slider; the value-bearing label is now yellow, normal-sized, and remains centered above the bar.
