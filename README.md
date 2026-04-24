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
  <img src="https://img.shields.io/badge/Memory-~140KB-333333?style=flat-square" alt="Memory" />
</p>

---

## Overview

Loot Pro replaces WoW's default scrolling combat and loot text with two clean, repositionable display frames: one for Combat and System messages, one for Loot and Money. Every message type has its own color, toggle, and formatting controls. The addon runs at roughly 140 KB of memory, requires no external dependencies, and supports both WoW Retail (Midnight 12.0) and BCC Anniversary (2.5.5).

Open with **`/lp`** or the minimap button.

---

## Features

### Clean Mode

Strips the default "You receive loot:" and "You receive currency:" clutter from every message, leaving just the item name, inline icon, and current bag count. Money messages can optionally display gold, silver, and copper with coin icons instead of raw text.

### Smart Rarity Filtering

Set a minimum quality threshold so only items at or above that rarity appear in the loot frame. Common grey drops can be silenced entirely while greens, blues, and epics still show. When an item has not yet been cached by the client, Loot Pro fails open and displays the message rather than silently dropping it.

### Full Color Customization

All 11 message categories have independent color pickers: Money, Currency, Loot, Combat Start, Combat End, Experience, Delver XP, Skill Gains, Honor, Reputation Gain, and Reputation Loss. Colors are previewed live in the settings panel and applied instantly.

### Per-Frame Layout Controls

Each display frame (Combat and Loot) has its own text size, fade duration, frame width, frame height, and max visible lines. A sync button copies one frame's layout to the other. Font selection supports LibSharedMedia-3.0, unlocking dozens of additional fonts when installed. Outline modes include Thin, Thick, and None (with drop shadow).

### Notification Toggles

Every message type can be individually enabled or disabled. Additional toggles control loot count injection, coin icon display, Clean Mode, and combat follower XP visibility.

### Movable Frames and Test Mode

Unlock Windows mode makes both display frames draggable so you can reposition them anywhere on screen. Test Mode freezes fading and displays sample messages for every category so you can preview your color and layout choices without leaving town.

### Minimap Button

A LibDBIcon minimap button provides one-click access to the settings panel. Compatible with Titan Panel, ChocolateBar, ElvUI, and other broker display addons. The button can be hidden from the Customization tab.

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

The config UI has four tabs: Layout, Colors, Notifs, and Custom. A Reset to Defaults button at the bottom of every tab restores all settings to their original values.

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
