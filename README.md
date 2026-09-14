# Loot Pro

**A clean replacement for World of Warcraft's loot and combat text. Two repositionable readouts, one for combat and system messages and one for loot and money, with a color and a toggle for every kind of message. On top of the live feed it adds the loot tools the default UI never had: a session recap with gold per hour, watched-item alerts, gear markers, a name block list, and automatic gray selling. Install it and it works right away. Everything beyond the basics is off until you turn it on.**

[![Join our Discord](https://img.shields.io/badge/Discord-Join-5865F2?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/vm8K2WfQUE) [![Version](https://img.shields.io/github/v/release/wheelbarrel00/LootPro?color=6D0501&label=Version&style=flat-square)](https://github.com/wheelbarrel00/LootPro/releases) ![WoW Midnight](https://img.shields.io/badge/WoW-Midnight12.1-8B0000?style=flat-square) ![WoW Classic Era](https://img.shields.io/badge/WoW-ClassicEra1.15.9-8B0000?style=flat-square) ![WoW TBC](https://img.shields.io/badge/WoW-BurningCrusade2.5.6-8B0000?style=flat-square) ![WoW MoP](https://img.shields.io/badge/WoW-MoP5.5.4-8B0000?style=flat-square) ![Dependencies](https://img.shields.io/badge/Dependencies-None-6D0501?style=flat-square) [![License](https://img.shields.io/github/license/wheelbarrel00/LootPro?style=flat-square&color=333333)](https://github.com/wheelbarrel00/LootPro/blob/main/LICENSE)

***

# Contents

1. What it does
2. Quick start
3. Layout: sizing and placing the two readouts
4. Colors
5. Notifications: what shows up at all
6. Custom: fonts, framed rows, and behavior
7. Recap: your session at a glance
8. Alerts: watch list, rare drops, and gear markers
9. Block: hiding loot by name
10. Vendor: selling grays
11. Item tooltips
12. Slash commands
13. Minimap button
14. Flavor differences
15. Reset to Defaults
16. Dependencies
17. Gallery
18. Found a bug

***

# What it does

Loot Pro replaces the default scrolling combat and loot text with two frames you control.

**The combat readout** carries combat start and end, experience, skill gains, honor, reputation, and Delve companion experience.

**The loot readout** carries money, currency, and item loot.

Each one has its own size, width, height, fade time, maximum line count, font, and outline. Every kind of message has its own color and its own on and off switch. Out of the box you get clean text with inline item icons and a running total of how many of each item you own.

Everything past that is optional and off by default. Turn on only what you want.

Loot Pro never equips, trades, or destroys anything. Two features do act for you once you turn them on, and both are off by default: Speedy AutoLoot takes items from a corpse on your behalf, and the Vendor tab sells gray items while a merchant window is open.

***

# Quick start

1. Install and log in. Your loot and combat text is already running through Loot Pro.
2. Type **`/lp`**, or left-click the minimap button, to open the options.
3. Click **Unlock Windows** at the top left, drag the two readouts where you want them, then click **Lock Windows**.
4. Click **Start Test Mode** at the top right to fill both readouts with sample lines while you pick colors and sizes. Click it again to stop.

That is enough to use it. Everything below is optional.

The settings window has nine tabs: Layout, Colors, Notifications, Custom, Recap, Alerts, Block, Vendor, and About.

***

# Layout: sizing and placing the two readouts

**Options > Layout.** Ten sliders, five for each readout, plus a sync button.

| Slider | Range | Default | What it does |
|---|---|---|---|
| Combat Text Size | 10 to 50 | 20 | Font size of the combat readout |
| Combat Fade (sec) | 1 to 30 | 6 | How long a line stays before it fades |
| Combat Frame Width | 200 to 1200 | 200 | |
| Combat Frame Height | 50 to 800 | 200 | |
| Max Combat Lines | 1 to 20 | 4 | How many lines can be on screen at once |
| Loot Text Size | 10 to 50 | 22 | |
| Loot Fade (sec) | 1 to 30 | 6 | |
| Loot Frame Width | 200 to 1200 | 200 | |
| Loot Frame Height | 50 to 800 | 200 | |
| Max Loot Lines | 1 to 20 | 4 | |

**Sync Combat Layout to Loot** copies the five combat values onto the loot readout. It goes one way only, from combat to loot, and it overwrites whatever the loot readout had. There is no button for the other direction, so set up combat first if you plan to use it.

Frame width and height set the area a readout occupies, which decides where long lines wrap. To move a readout, use **Unlock Windows** at the top of the settings panel and drag it.

***

# Colors

**Options > Colors.** Twelve color swatches, one for each kind of message. Click a swatch to open the standard color picker. Next to each one is a live sample line in that color, so you can see the result as you drag.

Money, Currency, Loot, Quest Items, Combat Start, Combat End, Experience, Delver XP, Skill, Honor, Rep Gain, and Rep Loss.

Turn on **Start Test Mode** first and the real readouts fill with sample lines that recolor as you pick, which is a better preview than the swatch alone.

## Quest item coloring

Two checkboxes sit below the swatches, both off by default.

**Color quest items** paints your own quest drops in the **Quest Items** color instead of their item quality color, so they stand out in a busy feed. Framed rows take the color on the item name and the borders, plain text lines take it on the whole line.

It covers more than the items tagged Quest. When an active quest asks you to collect ordinary cloth, meat, or ore, those count too, which is the half that is easy to miss because the game does not flag them as quest items at all. Since most of them are white or gray, they are shown even when they fall below your Minimum Loot Quality, as otherwise the feature would do nothing on a filtered feed. Your **Hide from loot feed** categories and your block list still hide anything they are set to hide.

A gray quest item also keeps its own framed row instead of collapsing into the combined Junk Items row.

**Use my class color** paints them in your class color and ignores the swatch. It is there for anyone whose color picker does not already offer a class color of its own, and it picks up a class color addon's palette when one is installed.

***

# Notifications: what shows up at all

**Options > Notifications.** This tab decides which messages reach a readout, and how much of each item drop you see.

## Message toggles

Sixteen checkboxes. All are on by default except **Display Delve Companion XP** and **Show Combat Follower XP**.

The loot readout carries Display Money, Display Currency, Display Item Loot, and Display Party Loot. The combat readout carries Display Experience, Display Combat START, Display Combat END, Display Skill Gains, Display Honor Gains, Display Reputation GAIN, and Display Reputation LOSS.

Three of them change formatting rather than turning a message on or off:

**Enable Clean Mode** (on) strips the game's wrapper text, so "You receive loot: [Linen Cloth]" becomes just the item with its icon. Turn it off to see the original message.

**Inject Item Totals** (on) adds how many you now own in parentheses after the item, as in `Linen Cloth (14)`. Turn it off to see only what just dropped.

**Use Coin Icons** (on) shows looted money as gold, silver, and copper coin icons instead of the words. It only applies while Clean Mode is on.

**Show Combat Follower XP** (off) adds experience earned by your pet, battle pet, or follower. Your own experience is controlled separately by Display Experience.

## Minimum Loot Quality

Two dropdowns that hide drops below a quality you choose. Each cycles through Poor+ (All), Common+, Uncommon+, Rare+, Epic+, and Legendary+.

**Your Loot** applies to what you pick up. **Others' Loot** applies to what the group picks up. They are separate on purpose, so you can watch every scrap you loot while only hearing about the group's rares. Both default to Poor+ (All), which hides nothing.

If the game client has not cached an item yet, Loot Pro shows the line rather than risk hiding something you wanted.

## Hide from loot feed

Nine checkboxes that hide whole categories of item, all off by default: Trade Goods, Consumables, Quest Items, Recipes, Gear, Gems, Enhancements, Misc, and Glyphs.

Gear covers weapons and armor together. There is no separate weapon and armor split.

Hidden items still count toward the session recap. Only the line in the feed is suppressed, so your totals stay honest no matter how much you filter.

***

# Custom: fonts, framed rows, and behavior

**Options > Custom.**

## Fonts

**Combat Font** and **Loot Font** list every font registered with LibSharedMedia-3.0, so any font pack you already have shows up automatically. With no font pack installed you get the game's default.

**Combat Outline** and **Loot Outline** each offer None, Thin, Thick, and Pixel. Thin is the default. Choosing None adds a drop shadow instead, so text stays readable on a light background.

**Sync Combat Fonts to Loot** copies the font and outline from combat onto loot. Like the layout sync, it goes one way only.

## Framed rows

By default both readouts are scrolling text. Framed rows draw each line as its own bordered row instead.

**Framed loot rows** (off) gives every drop a row with the item icon, the name, your running total, and the item category. The border and the name are colored by item quality. You can shift-click a row to link the item in chat, control-click it for the dressing room, and hover it for the normal item tooltip.

**Framed combat rows** (off) does the same for combat, skill, and reputation lines, with the border colored to match that line.

**Combine repeated drops** (on) makes repeats of the same item stack into one growing row with a rolling count, collapses gray junk into a single Junk Items row, and merges rapid money pickups into one running total. This is what keeps the feed readable during an AoE pull. It only does anything while Framed loot rows is on.

**Click through locked rows** (off) is the fix for one trade-off. A framed row has to receive your click for shift-click linking to work, so a visible row keeps catching clicks even while the readout is locked. Turn this on and clicks pass through to whatever is behind the feed, at the cost of shift-click linking.

If you have Masque installed, the icons on framed loot rows take your chosen Masque skin.

## Behavior

**Fast Loot** is Blizzard's own Auto Loot setting, exposed here so you do not have to go looking for it. It grabs everything from a corpse in one click instead of opening the loot window. Because it is the game's own setting and not Loot Pro's, Reset to Defaults does not touch it.

**Speedy AutoLoot** (off) is Loot Pro's own, and it works even with Fast Loot off. When loot becomes available it takes every slot automatically, about thirty per second, so the loot window never opens. Hold your auto-loot modifier key (Shift by default) as you loot and it stands aside so you can open the window by hand.

**Warn on currency cap** (on) tags a currency line with a red `(capped)` or an orange `(weekly cap)` once you have hit its maximum, so you can see at a glance that further gains are being wasted. It is a tag on the line, not a popup or a sound.

**Keep busy feeds up longer** (off) stretches how long lines stay visible when many arrive at once, adding time per extra line and easing back to your normal fade setting as the feed clears.

**Pause fade while hovering the feed** (off) freezes fading while your cursor rests on a readout, so you can actually read a busy feed. Clicks still pass through to whatever is behind it.

**Show Minimap Icon** (on) hides or shows the minimap button.

## Minimap Button Clicks

Three dropdowns set what left, right, and middle click do. Each offers Open Settings, Print Recap, Toggle Lock, and Nothing. The defaults are Open Settings, Print Recap, and Toggle Lock.

## Options Window Scale

A slider from 75% to 125% that resizes the settings window and nothing else. Your readouts, the minimap icon, and the alert banner are unaffected. The percentage updates as you drag and the new size applies when you let go.

## Combat text

**Combat Start Text** and **Combat End Text** are edit boxes for the words shown when you enter and leave combat. Press Enter to save, or Escape to discard.

***

# Recap: your session at a glance

**Options > Recap.** Off by default. Tick **Enable Session Recap** to start tracking.

Once on, the tab shows a live panel with your current zone, gold gained, vendor income, gold and items per hour once a minute has passed, a count of items looted broken down by rarity, every currency you have earned, and up to ten of your most recent Epic-or-better drops.

**Reset Session** starts a fresh session. **Pause Timer** stops the clock without stopping the tracking, so a trip to the mailbox or a long queue does not drag your per-hour numbers down. Loot is still counted while paused, and the pause survives a `/reload`.

The session lives in memory. A `/reload` keeps it, logging out clears it, so it never bloats your saved variables.

You can print the same summary to chat at any time with **`/lp recap`**, which is handy for pasting into a group chat.

***

# Alerts: watch list, rare drops, and gear markers

**Options > Alerts.** Three groups of settings share this tab.

## Watch list

Tick **Enable Watch Alerts** (off by default) and build a list of items you do not want to miss. When one drops, Loot Pro shows a banner in the center of your screen and plays a sound.

Add an item by typing its name, typing its item ID, or shift-clicking it straight into the box. A name matches any item containing that text, so `Ore` catches every ore. A link or an ID matches that one item exactly. The list holds up to thirty entries and each has a Remove button.

Alerts fire only for items **you** loot, not the group's. **Play Alert Sound** (on) controls the sound, and **Test Alert** fires a sample banner so you can check placement.

## Rare Drop Alerts

A separate alert for anything valuable, whether or not it is on your watch list. There are four triggers and three effects, and you mix them freely.

**Alert on quality** sets the rarity that fires the alert. It offers Uncommon+, Rare+, Epic+, and Legendary+, and defaults to Legendary+.

**Also alert on notable items** (off) fires for mounts, pets, and toys even when they fall below that quality bar, so an uncommon mount still gets your attention. On Retail this only counts collectibles you do not already own.

**Alert on value (gold, 0 = off)** fires when a single drop is worth at least the number of gold you enter. This catches the expensive trade goods that never reach epic quality. Worth knowing: the figure used is the item's **vendor sell price** multiplied by the stack, not its auction house value, so a soulbound item with no sell price can never trigger it. Press Enter to save.

The three effects are **Color loot line by rarity**, **Flash the loot frame**, and **Play alert sound**, all off by default. Note that coloring by rarity is part of the alert rather than a general setting, so it applies to lines that trip one of the triggers above, not to every drop.

**Test Rare Drop** fires the flash and sound so you can judge them without waiting for a real drop.

## Gear markers

Four tags that get appended to a loot line so you can judge a drop without opening its tooltip. All are off by default.

| Marker | Looks like | What it means |
|---|---|---|
| **Show item level on gear** | `[485]` in gold | The item level of any looted weapon or armor. This one applies to the group's drops as well as your own, and works on every game version. Shirts, tabards, and cosmetic armor are skipped, since their item level is meaningless. |
| **Mark new transmog appearances** | `(new look)` in blue | You have not collected this appearance from any source yet, so it is not safe to vendor. Retail only. |
| **Mark gear upgrades** | `(upgrade)` in green | Higher item level than what you have equipped in that slot. It only fires when the drop is the same armor or weapon type you already wear, and when the primary stat matches, so an Intellect piece is never flagged for an Agility character. Retail only. |
| **Mark gear with a tertiary stat** | `(Leech)` in teal | The piece rolled a bonus tertiary stat, named on the line. Leech, Avoidance, Speed, or Indestructible. Retail only. |

The three Retail-only markers appear on your own drops. The item level tag is the one that also applies to loot the group picks up.

***

# Block: hiding loot by name

**Options > Block.** A list of words. Any drop whose name contains one of them never reaches the loot feed.

Matching is case-insensitive and partial, so `Tattered` hides every tattered thing. Add an entry by typing it or by shift-clicking an item into the box. The list holds up to fifty entries.

This is the tool for the specific junk that slips past a quality or category filter. As with every other filter, blocked items are still counted in the session recap.

***

# Vendor: selling grays

**Options > Vendor.** Off by default.

**Automatically sell gray items at vendors** (off) sells every poor-quality item in your bags as soon as you open a merchant. Quest items and items with no sell value are never sold, and each bag slot is checked again in the instant before it sells, so an item you moved mid-sale is never vendored by mistake.

**Sell Interval** (0.1 to 1.0 seconds, default 0.2) is the delay between each item. A longer interval is gentler on the server and makes the progress bar easier to follow.

**Show progress bar while selling** (on) shows a small on-screen bar counting through the run.

**Print each item sold to chat** (off) lists every item and what it sold for.

**Sell Grays Now** runs a pass on demand, even with automatic selling turned off. Hover it to see what your current grays are worth before you commit. It needs an open merchant window.

A **This Session** line shows how many grays you have sold and for how much. It covers both automatic and manual sales, and clears when the session recap does.

The merchant's own Sell All Junk button already sells everything at once. What this adds is doing it automatically, at a pace you can watch, with a running total.

***

# Item tooltips

Three optional lines that Loot Pro can add to item tooltips. They are spread across two tabs because each belongs with the feature that feeds it.

**Show "looted this session" on item tooltips** (**Recap** tab, on by default) adds how many of that item you have looted this session. It needs the session recap turned on to show anything.

**Show "already owned" on mount, pet, and toy tooltips** (**Recap** tab, off) tells you that you already have the mount, pet, or toy in your hands, so a duplicate is safe to sell or pass on without opening a journal to check. Retail only, since the Classic versions have no shared collection journals.

**Show vendor sell price on item tooltips** (**Vendor** tab, off) adds the sell price, plus the value of the whole stack when you hover a stack in your bags.

***

# Slash commands

| Command | What it does |
|---|---|
| **`/lp`** | Open or close the settings window |
| **`/lp recap`** | Print the session recap to chat |
| **`/lp recap reset`** | Start a fresh recap session |
| **`/lp pause`** | Pause or resume the session timer |
| **`/lp about`** | Open the About tab and the in-game changelog |
| **`/lp whatsnew`** | Show the What's New popup again |
| **`/lp whatsnew reset`** | Make What's New show once more on your next `/reload` |
| **`/lp test`** | Run a self-check that posts one of every message type and reports pass or fail |
| **`/lp help`** | List the commands |

***

# Minimap button

A LibDataBroker launcher with a LibDBIcon minimap button, so Titan Panel, ChocolateBar, Bazooka, and similar display addons pick it up automatically.

| Click | Default action |
|---|---|
| **Left** | Open Settings |
| **Right** | Print Recap |
| **Middle** | Toggle Lock |

All three are configurable on the Custom tab, and each can be set to Nothing. Hovering the icon shows the version and a reminder of what your three clicks currently do. The button itself can be hidden from the Custom tab.

***

# Flavor differences

Loot Pro runs on Midnight (12.1), Classic Era (1.15.9), Burning Crusade Classic (2.5.6), and Mists of Pandaria Classic (5.5.4) from one install. The differences all come down to features the older clients do not have.

| Feature | Retail (Midnight) | Classic |
|---|---|---|
| Item level on gear | Yes | Yes |
| New transmog appearance marker | Yes | Not available, no appearance collection |
| Gear upgrade marker | Yes | Not available |
| Tertiary stat marker | Yes | Not available, no tertiary stats |
| "Already owned" collectible tooltips | Yes | Not available, no shared journals |
| Quest item coloring | Yes | Yes |
| Notable-item alerts for uncollected mounts, pets, and toys | Yes | Fires for all mounts, pets, and toys |
| Everything else | Yes | Yes |

Options that do not apply are simply absent from the settings panel on those versions rather than present and broken.

***

# Reset to Defaults

A button at the bottom of every tab except About. It is behind a confirmation prompt, because it clears more than it might sound like: every color, every toggle, every slider, your window positions, **and both your watch list and your block list**. It cannot be undone.

Two things it leaves alone. Your current recap session keeps running, and Fast Loot is Blizzard's own setting so it stays as you had it.

***

# Dependencies

**Required: none.** Loot Pro is standalone.

**Optional:**

- **[LibSharedMedia-3.0](https://www.curseforge.com/wow/addons/libsharedmedia-3.0)** adds every font from any font pack you have to the two font pickers.
- **[Masque](https://www.curseforge.com/wow/addons/masque)** skins the item icons on framed loot rows.

LibStub, LibDataBroker-1.1, CallbackHandler-1.0, and LibDBIcon-1.0 are bundled, so there is nothing else to install.

## Manual install

Download the latest release, then extract the `LootPro` folder into `World of Warcraft/_retail_/Interface/AddOns/`. For the Classic versions use the matching folder instead of `_retail_`: `_classic_era_`, `_anniversary_` for Burning Crusade, or `_classic_` for Mists of Pandaria.

***

# Gallery

<img width="3838" height="2155" alt="Loot Pro in action" src="https://github.com/user-attachments/assets/e367cdb9-63c0-4410-825d-232c3f6ccce6" />
<img width="3839" height="2159" alt="Loot Pro loot feed" src="https://github.com/user-attachments/assets/3b3c8b40-54a1-470f-9464-ddc3184dec35" />
<img width="3830" height="2142" alt="Loot Pro combat feed" src="https://github.com/user-attachments/assets/dc4d4e64-9003-4637-b16d-91a0932fb33e" />
<img width="3839" height="2159" alt="Loot Pro settings" src="https://github.com/user-attachments/assets/f52e12aa-5ec7-48ca-8295-e8084c738c91" />
<img width="935" height="1227" alt="Layout tab" src="https://github.com/user-attachments/assets/585e322c-7621-47a9-9c5d-7f752a2ab18e" />
<img width="937" height="1223" alt="Colors tab" src="https://github.com/user-attachments/assets/e26d50d1-b011-4af7-ac97-ead30785a113" />
<img width="933" height="1226" alt="Notifications tab" src="https://github.com/user-attachments/assets/a8caccb6-60a4-4f61-aa65-7b3780a61aff" />
<img width="936" height="1227" alt="Custom tab" src="https://github.com/user-attachments/assets/1f831a0c-6a54-4cef-8e82-3208f92de3cb" />

***

# Found a bug or have an idea?

Report it on the **[GitHub Issues page](https://github.com/wheelbarrel00/LootPro/issues)**. Include the error text if you can grab it, since BugSack and BugGrabber make that easy, and what you were doing when it happened.

***

Made with care for the Midnight expansion and WoW Classic. **Got a question or want to hear about updates? [Join the Discord](https://discord.gg/vm8K2WfQUE)** If you like this one, check out my other addons: **[Cooldown Master](https://www.curseforge.com/wow/addons/cooldown-master)**, **[Everything Quests](https://www.curseforge.com/wow/addons/everything-quests)**, and **[Everything Delves](https://www.curseforge.com/wow/addons/everything-delves)**. Released under the MIT License.
