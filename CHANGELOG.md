# Changelog

All notable changes to **Loot Pro** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2026-04-20

### Added
- **Minimum Loot Quality selector** on the Notifications tab — previously
  required hand-editing SavedVariables.
- **`/lp test`** regression harness — synthesizes chat events for all 12
  code paths (money, currency, loot, combat start/end, XP, follower XP,
  delver XP, skill, honor, rep gain, rep loss) and logs pass/fail per
  category. Uses verified real in-game references (Hearthstone itemID 6948,
  Silvermoon Court, Bloodsail Buccaneers).
- **`/lp help`** subcommand listing available commands.
- Locale-agnostic pattern matching via Blizzard globals
  (`FACTION_STANDING_INCREASED`, `LOOT_ITEM_SELF`, `CURRENCY_GAINED`, etc.) —
  faction, loot, and currency filters now work on non-English clients.
- `relativePoint` saved-variable field so readout frames round-trip their
  exact drag position.
- Font-load failure reporting — previously silently swallowed by `pcall`.

### Changed

#### Performance
- `UpdateAllVisuals` is now idempotent — each expensive op (`SetBackdrop`,
  `SetMaxLines`, `SetFont`, `SetPoint`, `SetSize`) is guarded by a cache
  key and only re-applied when its inputs change. Eliminates visible
  message-buffer clearing during slider drags (**H1**).
- SharedMedia font list cached at module scope and invalidated via LSM
  callback, instead of rebuilt and sorted on every widget refresh (**H2**).
- `C_Timer.After` is skipped on retail when the looted item is already in
  the client cache, preventing closure/timer storms during AoE loot (**M5**).
- Follower-XP detection gated behind `CHAT_MSG_COMBAT_XP_GAIN` (previously
  ran `:find("experience")` on every chat/money/faction/currency event)
  (**L2**).

#### Reliability
- `ADDON_LOADED` is unregistered after self-match, so we stop receiving
  every other addon's load event for the session (**H3**).
- `PLAYER_LOGIN` now defensively calls `InitSettings()` if saved variables
  didn't initialize through the normal `ADDON_LOADED` path (**M1**).
- Font-load failures now surface via a rate-limited warning (one print per
  bad path) with automatic fallback to the default font, instead of being
  silently swallowed (**M4**).
- Drag-stop now saves both self-anchor and relative-anchor points so
  positions round-trip exactly across reloads (**M3**).

#### UX Polish
- **Welcome popup persistence hardened** — clicking "Open Settings"
  implicitly sets the "Don't show again" preference, `HookScript` replaces
  `SetScript` for OnShow so templates can't clobber it, and OnHide
  back-writes the checkbox state as a safety net (**M6**).
- Added `minQuality` UI control on the Notifications tab (**H4**).

#### Internationalization
- Faction, loot-prefix, and currency pattern matching now derive from
  Blizzard localized global strings. Addon filters work on non-enUS
  clients (**M2**).

#### Maintainability
- `/lp` slash command registered at file-load time so it's usable during
  loading screens, not only after `PLAYER_LOGIN` (**L7**).
- `InitSettings` now prunes saved-variable keys that no longer exist in
  the defaults schema, preventing bloat across versions (**L3**).
- Removed unused local `cD` from `PostTestMessages` (**L1**).
- Introduced `addon._SafeSetFont` helper shared between Core and Widgets.

### Fixed
- Test-mode and color-preview data now reference real in-game entities:
  Hearthstone (itemID 6948) replaces the non-existent "Earthen Shard";
  rep-gain preview uses Silvermoon Court (Midnight faction) instead of
  the unverified "The Midnight Council".
- Duplicate `[1.2.0]` changelog block removed (was identical to `[2.0.0]`)
  (**L5**).

## [2.1.0] - 2026-04-17

### Added
- Active tab highlighting in config UI — the current tab is now visually distinct

### Changed
- Closing the config UI now automatically deactivates Unlock Windows and 
  Test Mode if either is active

### Fixed
- Reset to Defaults button now visible on all tab panels

### Removed
- Brann Bronzebeard Companion XP line removed from Test Mode preview messages

## [2.0.0] - 2026-04-15

### Added
- **Burning Crusade Classic Anniversary (2.5.5) support** via separate `LootPro_BCC.toc`
- `IS_RETAIL` and `IS_BCC` flags on the addon namespace for client-aware code paths
- BCC-compatible UI frame builder (`CreateVersionedMainFrame`) for clients without modern frame templates

### Fixed
- Loot quality filter no longer silently drops freshly-looted items whose quality isn't cached yet (fail-open behavior)
- BCC: `SetBackdrop` no longer errors on the main settings frame (added `BackdropTemplate` mixin)
- BCC: Welcome text now centers correctly within its bounding box

## [1.1.6] - 2026-04-14

### Fixed
- In-game version string now correctly displays the current version (was stuck at 1.1.3 in the GUI title and minimap tooltip).

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

## [1.1.3] - 2026-04-10

### Changed
- Removed dead `pcall` safety check in event handler (no functional impact — the guard always succeeded).
- Removed Classic Era (`20504`) from supported interface versions until properly tested. Retail and TWW support unchanged.

No user-facing changes.
