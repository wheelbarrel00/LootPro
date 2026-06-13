<p align="center">
  <img src="https://img.icons8.com/color/96/world-of-warcraft.png" alt="Loot Pro" width="96" />
</p>

<h1 align="center">Loot Pro</h1>

<p align="center">
  <strong>Ultra-lightweight loot and combat text replacement for World of Warcraft</strong>
</p>

<p align="center">
  <a href="https://github.com/wheelbarrel00/LootPro/releases"><img src="https://img.shields.io/github/v/release/wheelbarrel00/LootPro?color=FF2222&label=Version" alt="Version" /></a>
  <img src="https://img.shields.io/badge/WoW-Midnight%2012.0-8B0000?style=flat-square" alt="WoW Midnight" />
  <img src="https://img.shields.io/badge/WoW-BCC%20Anniversary%202.5.5-8B0000?style=flat-square" alt="WoW BCC" />
  <img src="https://img.shields.io/badge/Interface-120005-333333?style=flat-square" alt="Interface" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-333333?style=flat-square" alt="License" /></a>
  <img src="https://img.shields.io/badge/Memory-~350KB-333333?style=flat-square" alt="Memory" />
</p>

---

## Overview

Loot Pro replaces WoW's default scrolling combat and loot text with two clean, repositionable display frames: one for Combat and System messages, one for Loot and Money. Every message type has its own color, toggle, and formatting controls. On top of the live feed it adds optional loot-awareness tools — a session recap, watched-item and rare-drop alerts, tooltip loot counts, category filters, and currency-cap warnings — all off by default. The addon runs at roughly 350 KB of memory, requires no external dependencies, and supports both WoW Retail (Midnight 12.0) and BCC Anniversary (2.5.5).

Open with **`/lp`** or the minimap button.

---

## Features

### Clean Mode

Strips the default "You receive loot:" and "You receive currency:" clutter from every message, leaving just the item name, inline icon, and current bag count. Money messages can optionally display gold, silver, and copper with coin icons instead of raw text.

### Smart Rarity Filtering

Set a minimum quality threshold so only items at or above that rarity appear in the loot frame. Common grey drops can be silenced entirely while greens, blues, and epics still show. When an item has not yet been cached by the client, Loot Pro fails open and displays the message rather than silently dropping it.

### Category Filtering

Beyond the rarity threshold, entire item classes can be hidden from the loot frame — Trade Goods, Consumables, Quest Items, and Recipes — from the Notifications tab. Filtered items are still counted by the session recap; only their feed lines are suppressed.

### Full Color Customization

All 11 message categories have independent color pickers: Money, Currency, Loot, Combat Start, Combat End, Experience, Delver XP, Skill Gains, Honor, Reputation Gain, and Reputation Loss. Colors are previewed live in the settings panel and applied instantly.

### Per-Frame Layout Controls

Each display frame (Combat and Loot) has its own text size, fade duration, frame width, frame height, and max visible lines. A sync button copies one frame's layout to the other. Font selection supports LibSharedMedia-3.0, unlocking dozens of additional fonts when installed. Outline modes include Thin, Thick, and None (with drop shadow).

### Notification Toggles

Every message type can be individually enabled or disabled. Additional toggles control loot count injection, coin icon display, Clean Mode, and combat follower XP visibility.

### Session Recap

A dedicated Recap tab (and the `/lp recap` command) tracks your current play session: total gold, items broken down by rarity, currencies earned, and a short list of notable epic-or-better drops. The tally is held entirely in memory and resets on each login or reload, so it adds nothing to your saved variables. Disabled by default; enable it on the Recap tab.

### Watched-Item Alerts

The Alerts tab lets you build a watchlist by item name, item ID, or shift-clicked item link. When you loot a watched item, Loot Pro shows a center-screen toast and plays an alert sound so you never miss it. Disabled by default.

### Rare Drop Alerts

Optionally color a looted line by its item quality, flash the loot frame, and play a sound when a drop meets a configurable quality threshold (Legendary by default). All three effects are off by default and configured on the Alerts tab.

### Loot Counts in Tooltips

Item tooltips can display how many of that item you have looted during the current session, sourced from the session recap.

### Currency Cap Warnings

When a currency reaches its maximum or weekly cap, its line in the loot frame is tagged so you know further gains are going to waste.

### Auto-Sell Gray Items

A dedicated Vendor tab can automatically sell your poor-quality (gray) junk whenever you open a merchant, with a configurable sell speed and an optional on-screen progress bar. A "Sell Grays Now" button sells on demand, and an optional chat report lists each item sold. Off by default; quest items and items with no sell value are never sold, and each bag slot is re-verified the moment before it sells so a misplaced item is never vendored by mistake.

### Movable Frames and Test Mode

Unlock Windows mode makes both display frames draggable so you can reposition them anywhere on screen. Test Mode freezes fading and displays sample messages for every category so you can preview your color and layout choices without leaving town.

### Minimap Button

A LibDBIcon minimap button provides one-click access to the settings panel. Compatible with Titan Panel, ChocolateBar, ElvUI, and other broker display addons. The button can be hidden from the Customization tab, and its left, right, and middle clicks are each configurable — open settings, print the session recap, toggle window lock, or do nothing.

### New-Appearance Marker

When you loot a weapon or armor piece whose transmog appearance you have not collected from any source yet, its loot line is tagged with a cyan **(new look)**, so a fresh appearance is never vendored or disenchanted by mistake. Off by default; enable it on the Alerts tab. Retail only, since BCC Anniversary has no transmog system.

### Notable-Item Alerts

The rare-drop alert can optionally fire for mounts, pets, and toys even when they fall below your quality threshold, so an uncommon mount or a blue battle pet still gets your configured flash, sound, and line coloring. Off by default; enable "Also alert on notable items" on the Alerts tab.

### Vendor Sell Price in Tooltips

Item tooltips can show the vendor sell price, plus the full stack value when you hover a stack in your bags — handy for deciding what to keep or sell. Off by default; enable it on the Vendor tab. Quest items and items with no sell value show nothing.

### Loot Feed Quality-of-Life

Two optional behaviors on the Customization tab: pause fading while your cursor is over a readout so a busy feed can be read, and keep busy feeds visible longer by extending how long lines stay up during a big pull. Both off by default.

---

## Installation

### From CurseForge

1. Install via the [CurseForge app](https://www.curseforge.com/) or download manually
2. The addon will be placed automatically in your AddOns folder

### Manual Install

1. Download the latest release from the [Releases](https://github.com/wheelbarrel00/LootPro/releases) page
2. Extract the `LootPro` folder into:
   ```
   World of Warcraft/_retail_/Interface/AddOns/
   ```
   For BCC Anniversary, use `_classic_era_` instead of `_retail_`.
3. Restart WoW or type `/reload` if already in-game
4. Enable **Loot Pro** at the character select screen

---

## Commands

| Command | Action |
|---|---|
| `/lp` | Toggle the settings window |
| `/lpro` | Toggle the settings window (alternate) |
| `/lp recap` | Print the current session recap (gold, items, currencies, notable drops) |
| `/lp recap reset` | Start a fresh recap session |

The config UI has seven tabs: Layout, Colors, Notifs, Custom, Recap, Alerts, and Vendor. A Reset to Defaults button at the bottom of every tab restores all settings to their original values.

---

## Dependencies

**Required:** None — Loot Pro is fully standalone.

**Optional:**
- [LibSharedMedia-3.0](https://www.curseforge.com/wow/addons/libsharedmedia-3.0) — unlocks dozens of additional fonts from within the Loot Pro settings panel

LibStub, LibDataBroker-1.1, CallbackHandler-1.0, and LibDBIcon-1.0 are bundled with the addon.

---

## Gallery

<img width="3838" height="2155" alt="Screenshot 2026-04-14 152345" src="https://github.com/user-attachments/assets/e367cdb9-63c0-4410-825d-232c3f6ccce6" />
<img width="3839" height="2159" alt="Screenshot 2026-04-14 152320" src="https://github.com/user-attachments/assets/3b3c8b40-54a1-470f-9464-ddc3184dec35" />
<img width="3830" height="2142" alt="Screenshot 2026-04-14 152241" src="https://github.com/user-attachments/assets/dc4d4e64-9003-4637-b16d-91a0932fb33e" />
<img width="3839" height="2159" alt="Screenshot 2026-04-14 152112" src="https://github.com/user-attachments/assets/f52e12aa-5ec7-48ca-8295-e8084c738c91" />
<img width="935" height="1227" alt="Screenshot 2026-04-14 152026" src="https://github.com/user-attachments/assets/585e322c-7621-47a9-9c5d-7f752a2ab18e" />
<img width="937" height="1223" alt="Screenshot 2026-04-14 151950" src="https://github.com/user-attachments/assets/e26d50d1-b011-4af7-ac97-ead30785a113" />
<img width="933" height="1226" alt="Screenshot 2026-04-14 151943" src="https://github.com/user-attachments/assets/a8caccb6-60a4-4f61-aa65-7b3780a61aff" />
<img width="936" height="1227" alt="Screenshot 2026-04-14 151933" src="https://github.com/user-attachments/assets/1f831a0c-6a54-4cef-8e82-3208f92de3cb" />

---

## License

This project is licensed under the [MIT License](LICENSE).

---

<p align="center">
  <sub>Built by Wheelbarrel00 for the Midnight expansion and BCC Anniversary</sub>
</p>
