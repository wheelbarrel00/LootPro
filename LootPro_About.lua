local addonName, ns = ...

-- Addons can't read CHANGELOG.md at runtime, so this table mirrors it. Update both every release, newest first.
ns.about = {
    links = {
        curseforge = "https://www.curseforge.com/wow/addons/loot-pro",
        github     = "https://github.com/wheelbarrel00/LootPro",
        bug        = "https://github.com/wheelbarrel00/LootPro/issues",
    },

    changelogURL = "https://www.curseforge.com/wow/addons/loot-pro/files",

    moreAddons = {
        {
            name = "Cooldown Master",
            cf   = "https://www.curseforge.com/wow/addons/cooldown-master",
            gh   = "https://github.com/wheelbarrel00/CooldownMaster",
        },
        {
            name = "Everything Delves",
            cf   = "https://www.curseforge.com/wow/addons/everything-delves",
            gh   = "https://github.com/wheelbarrel00/EverythingDelves",
        },
        {
            name = "Everything Quests",
            cf   = "https://www.curseforge.com/wow/addons/everything-quests",
            gh   = "https://github.com/wheelbarrel00/EverythingQuests",
        },
        {
            name = "EQ Objective Tracker",
            cf   = "https://www.curseforge.com/wow/addons/eq-objective-tracker",
            gh   = "https://github.com/wheelbarrel00/EQObjectiveTracker",
        },
    },

    thanks = { "Agaman", "Rhinoplasty" },

    changelog = {
        {
            version = "3.1.1", date = "2026-10-25",
            sections = {
                { head = "Bug Fixes", items = {
                    "Turning off \"Keep busy feeds up longer\" now takes effect right away. Lines kept lingering for the longer busy time until you reloaded, and with \"Pause fade while hovering the feed\" on, they could vanish early without fading.",
                    "Several gains of the same currency in quick succession now all count. When the amounts matched, as when AoE looting with Speedy AutoLoot, only the first gain reached the loot feed and the session recap. A gain the game reports twice still counts once.",
                    "Bonus roll loot now counts as your own loot. It reaches the session recap and Notable Drops, and it can trigger watch and rare drop alerts. Before, it was treated as a party member's loot. (Mists of Pandaria Classic)",
                    "Items you craft or get refunded now show as yours. They use your own minimum quality, still show with Display Party Loot turned off, show how many you own, and lose the \"You create:\" or \"You are refunded:\" text in Clean Mode. They stay out of the session recap and alerts, since they were not looted.",
                    "With Clean Mode on and Use Coin Icons off, looted money now shows as + 12g 50s 20c instead of the full chat sentence.",
                    "Test Mode's sample lines now follow Enable Clean Mode, Show Item Totals, and Use Coin Icons, so you can see those settings change while you tune them.",
                    "Shift-clicking a framed loot row to link it in chat now uses the game's current chat function, so it keeps working once Blizzard removes the old one.",
                    "Hide Blizzard's loot toasts no longer appears on Classic Era, TBC Anniversary, and Mists of Pandaria Classic, where it had nothing to hide.",
                    "A saved setting with the wrong kind of value, such as after hand-editing the saved variables file, now goes back to its default at login instead of causing an error on every loot.",
                    "A mistyped /lp command now says it is unknown instead of opening the settings window, and extra spaces between words no longer break a command. /lp config, /lp options, and /lp settings still open the window, and /lp help now lists /lp whatsnew reset.",
                    "The watch list no longer accepts a shift-clicked currency, which could never trigger an alert, and says so. A full watch or block list now says an entry is already on the list instead of calling the list full.",
                    "Automatic gray selling now credits the stack you actually sold when its size changed during the sale.",
                    "Loot quality is now read correctly from item links written with the game's named quality colors, keeping rare drop alerts, line colors, and quality limits accurate. (Retail and WoW Forever)",
                } },
                { head = "Improvements", items = {
                    "With Text Alignment set to Center, framed loot rows without an icon now center their text like the money and text rows beside them. Rows with an icon keep the icon on the left with the name beside it.",
                    "The settings window now runs on the newest version of the library the Everything addons share. Loot Pro's colors no longer pick up another addon's color when that addon opens the color picker while you are choosing a Loot Pro color.",
                    "The minimap button's tooltip now says Toggle Lock, the same as the General page.",
                    "Under the hood, the loot and chat handling was reorganized so future updates have room to grow, and finished feed rows let go of their item details sooner.",
                } },
            },
        },
        {
            version = "3.1.0", date = "2026-10-24",
            sections = {
                { head = "New Features", items = {
                    "Text Alignment, Text Position, and Newest Line, three new settings on each feed's card on the Layout page, set separately for the loot feed and the combat feed. Text Alignment lines the text up with the left edge, the center, or the right edge of the feed. Text Position places the lines at the top, in the middle, or at the bottom of the feed's area when they do not fill it. Newest Line chooses whether a new line appears above the others or below them. All three work in the text feed and in framed rows, where Right also moves item icons to the right edge. Your feeds look exactly as they did before until you change them. Thanks to berserk_mcnulty62 on CurseForge for the suggestion.",
                } },
                { head = "Improvements", items = {
                    "Match the Combat Feed now also copies the combat feed's text alignment, text position, and newest line.",
                } },
            },
        },
        {
            version = "3.0.0", date = "2026-10-17",
            sections = {
                { head = "New Features", items = {
                    "A brand new settings window. Loot Pro's options now open in the same window as Everything Quests, EQ Objective Tracker, Everything Delves, and Cooldown Master. A sidebar on the left holds nine pages: General, Layout, Notifications, Recap, Watch, Rare Drops, Block, Vendor, and About. Each page is laid out in cards. The window opens on the page you used last. Every setting carries over exactly as you left it, and nothing resets.",
                    "Unlock Windows and Start Test Mode sit at the bottom of the Layout and Notifications pages, so you can drag a feed or fill both feeds with sample lines without leaving the page you are tuning. Start Test Mode turns into Stop Test Mode while the samples run, and closing the window still locks the feeds and ends the test. Unlock Windows replaces the Lock Windows button, and the minimap's Toggle Lock keeps it in step.",
                    "Click any slider's number to type an exact value.",
                    "Match the Combat Feed, at the bottom of the Loot Feed card on the Layout page, gives your loot feed the combat feed's font, text size, outline, fade, frame size, max lines, and frame scale in one click. It replaces Sync Combat Layout to Loot and Sync Combat Fonts to Loot.",
                    "What's New now appears only for releases that bring new features. A release with only fixes stays quiet, and the next feature release lists it too, so nothing is missed. If you have been away for several versions, it lists everything since you last looked. Under Updates on the General page, choose a Popup window, a quiet Chat link, or Off, and Show What's New opens the notes any time.",
                } },
                { head = "Improvements", items = {
                    "The Colors and Custom tabs are gone. Each color now sits at the right end of the switch for the line it paints, on the Notifications page, with the Quest Items color beside Color quest items. Start Test Mode shows your colors in the real feeds. Custom's feed settings joined the Layout page, which has one card for the loot feed, one for the combat feed, and one for settings that cover both. Custom's other settings are on the General page.",
                    "Settings that do nothing while another one is off are dimmed until it is on. Show Item Totals dims while Clean Mode is off, Combine repeated drops while Framed loot rows is off, and the Rare Drops triggers until Color loot line by rarity, Flash the loot frame, or Play alert sound is on.",
                    "Many settings that had no tooltip now have one, and three are corrected. Show Item Totals says it needs Clean Mode, Use Coin Icons explains when framed rows show coin icons anyway, and Show Combat Follower XP says it needs Display Experience.",
                    "Clearer labels. \"Inject Item Totals (e.g. 14)\" is now \"Show Item Totals\", \"Use Coin Icons (Clean Mode only)\" is \"Use Coin Icons\", Display Combat Start, Display Combat End, Display Reputation Gain, and Display Reputation Loss are no longer in capitals, and the two combat text boxes no longer say \"(Enter to Save)\".",
                    "The Watch and Block lists show each entry on its own row with an X to remove it, and a watched item shows its icon and its name in its quality color. Press Enter or Add to add an entry, or shift-click an item into the box. The count beside the box shows how full the list is, and says so when the list is full or the entry is already on it.",
                    "The Recap page shows your session at a glance: Session time, Total gold, Gold per hour, and Items looted across the top, then where your gold came from, items per hour, and your loot by quality. Currencies and Notable Drops have their own cards, and Reset Session and Pause Timer sit at the bottom of the page.",
                    "The About page shows your version and the game client you are on, links to Discord, CurseForge, GitHub, Report a Bug, and What's New, every slash command (now with /lp pause), the tutorials, the other addons (now with EQ Objective Tracker), and the whole changelog.",
                    "Links open in a copy box you cannot accidentally type over.",
                    "The Options Window scale on the General page now stops at the largest size that fits your screen.",
                    "Escape closes the window out of combat. In combat, use its close button.",
                } },
                { head = "Bug Fixes", items = {
                    "Hiding the interface with Alt-Z, or a cinematic playing, while the settings window is open no longer locks your feeds and stops Test Mode.",
                } },
            },
        },
        {
            version = "2.22.0", date = "2026-10-08",
            sections = {
                { head = "New Features", items = {
                    "Choose the sound for your alerts. A sound box under \"Play Alert Sound\" on the Watch tab, and another under \"Play alert sound\" on the Rare Drops tab, offers Default, eight built-in Blizzard sounds, and any sound your media addons such as SharedMedia, BigWigs, or ElvUI provide. Picking a sound plays it so you can hear it, and a sound from a media addon you later remove falls back to Default.",
                    "Loot spec reminder. When you enter a dungeon, a raid, or on Retail a delve while your loot specialization is set to a different spec than the one you are playing, a banner and a chat line tell you. It is on by default and stays quiet unless something is wrong. The minimap tooltip also shows your loot spec, in red when it does not match. (Retail and Mists of Pandaria Classic)",
                    "Hide Blizzard's loot toasts, a new option on the Notifications tab. It stops the loot popups that repeat what the feed already shows, including won rolls and item upgrades. Legendary items, new mounts, pets, and toys, achievements, and quest rewards keep their popups. (Retail)",
                    "Hold your auto-loot key (Shift by default) as you open a merchant to skip the automatic gray sale for that visit. A chat line confirms it, and Sell Grays Now still works if you change your mind.",
                } },
                { head = "Improvements", items = {
                    "Item totals after a loot line now count your warband bank, so ore you keep there is included in the (14).",
                    "Alerts now play on the Master sound channel, so you hear them even with sound effects muted.",
                    "Automatic gray selling pauses while you hold an item on your cursor and picks up once you put it down, instead of skipping that slot for the rest of the run.",
                    "If ElvUI's own Vendor Grays option is also on, the Vendor tab and the skip message now say so, since ElvUI's seller ignores the skip key.",
                } },
            },
        },
        {
            version = "2.21.0", date = "2026-10-06",
            sections = {
                { head = "New Features", items = {
                    "The session recap splits your gold by where it came from: Gold looted, Quest rewards, Vendor income, Mailbox, and Trade, plus a Total gold line once more than one of them has paid out. Quest reward gold is counted for the first time and joins your gold per hour. Mailbox and trade gold, such as auction sales or gold sent from an alt, count toward the total but stay out of the hourly rate, so one big payout cannot inflate it.",
                    "Two new Rare Drop Alert triggers. \"Alert on item level\" goes off when a weapon or armor piece you loot is at least the item level you set, whatever its quality. \"Also alert on gear upgrades\" goes off when you loot a weapon or armor piece with a higher item level than what you have equipped in that slot, whether or not the upgrade marker is turned on. (Retail)",
                    "Show upgrade track on gear, a new gear marker. Looted weapons and armor show their upgrade track and level, as (Hero 4/6), so you can tell at a glance how far a piece can be upgraded. Tick \"Include the group's loot\" to tag gear other players loot too. (Retail)",
                } },
                { head = "Improvements", items = {
                    "The Alerts tab is now two tabs. Watch holds the watch list, which now shows more items at once. Rare Drops holds the rare drop alerts, with the gear markers (item level, new appearance, upgrade, tertiary stat, and upgrade track) in their own section below. Your settings carry over unchanged.",
                    "\"Gold gained\" in the session recap is now \"Gold looted\", since looted coin is no longer the only gold it shows.",
                } },
            },
        },
        {
            version = "2.20.1", date = "2026-10-03",
            sections = {
                { head = "Bug Fixes", items = {
                    "Loot Pro works properly on WoW Forever again. Forever's latest client update changed how the game identifies itself, and Loot Pro began treating it as Classic, so the gear upgrade and tertiary stat tags stopped appearing.",
                    "On WoW Forever, the settings for gear upgrades, tertiary stats, new transmog appearances, and \"already owned\" tooltips are back in the options window. They disappeared after the same update, which left the new appearance marker and the \"already owned\" tooltip line running for anyone who had them turned on, with no way to turn them off.",
                } },
            },
        },
        {
            version = "2.20.0", date = "2026-09-26",
            sections = {
                { head = "Bug Fixes", items = {
                    "XP lines no longer show a double space after the plus sign. \"+  1500 XP\" now reads \"+ 1500 XP\".",
                    "The Lock Windows button now keeps up when you lock or unlock the windows from the minimap button. It could be left describing the opposite of what it would do.",
                    "Vendor income in the session recap is accurate again. Gold from a party loot split that arrived while a merchant window was open was counted twice, once as looted gold and once as vendor income, which inflated your gold per hour. A sale that went through just as you closed the merchant window was also lost, and now counts.",
                    "The notable item alert no longer goes off for a mount, pet, or toy you already own when the game has not loaded that item's details yet. An uncollected one still alerts, a moment later, once its details arrive.",
                    "Toys outside the Miscellaneous item class, such as many older toys listed as consumables, are now recognized as toys. They can set off the notable item alert, and on Retail they show \"You already own this toy\" on their tooltip.",
                } },
                { head = "New Features", items = {
                    "Frame Scale sliders on the Layout tab, one for the combat readout and one for the loot readout. Each makes its whole readout bigger or smaller, text, icons, and framed rows together, from 50% to 200%. The readout stays where you placed it while it scales, and Sync Combat Layout to Loot copies the scale along with the rest.",
                } },
            },
        },
        {
            version = "2.19.0", date = "2026-09-17",
            sections = {
                { head = "New Features", items = {
                    "Loot Pro now runs on WoW Forever. Forever support is a work in progress, so expect some bugs while it settles in. Please report anything that looks off.",
                } },
            },
        },
        {
            version = "2.18.0", date = "2026-09-13",
            sections = {
                { head = "New Features", items = {
                    "Color quest items on the Colors tab. Turn it on and your own quest drops are painted in a color you pick instead of their item quality color, so they stand out in a busy feed. Framed rows take the color on the item name and the borders, plain text lines take it on the whole line. It is off by default.",
                    "\"Use my class color\" paints quest items in your class color instead of the \"Quest Items\" swatch, for anyone whose color picker does not already offer a class color.",
                    "Quest coloring covers both quest-type items and the ordinary items an active quest asks you to collect, such as the cloth or meat that only matters while you are on the quest. Those are shown even when they fall below your Minimum Loot Quality, since most of them are white or gray and would never reach the feed otherwise. Your loot filters and block list still hide anything they are set to hide.",
                    "A gray quest item keeps its own framed row instead of collapsing into the combined \"Junk Items\" row, so it still stands out while you are AoE looting.",
                } },
            },
        },
        {
            version = "2.17.3", date = "2026-09-09",
            sections = {
                { head = "Improvements", items = {
                    "Updated the supported client versions so the addon is no longer flagged as out of date.",
                } },
            },
        },
        {
            version = "2.17.2", date = "2026-08-26",
            sections = {
                { head = "Bug Fixes", items = {
                    "Looting a caged battle pet no longer throws a Lua error. With Framed loot rows and loot icons both turned on, every caged pet drop raised an error and the drop never reached the feed.",
                    "The session recap no longer undercounts currency. Two separate gains of the same currency arriving close together were read as one message delivered twice, so only the first counted toward the session total. This showed up most while looting a pile of mobs in quick succession.",
                    "The running total beside a loot line is accurate again. When your bags updated before the loot message arrived, the total was inflated by the size of the drop, and a party member's pickup was added to your own total instead of being left out of it.",
                    "Reset to Defaults now refreshes everything on screen. The Recap, Alerts, Block, and Vendor tabs kept showing your old settings until you switched tabs and back, and the Lock Windows button could be left describing the opposite of what it would do.",
                    "Reset to Defaults no longer stops the minimap button from remembering where you drag it, and no longer re-shows the What's New popup for a version you had already seen.",
                    "Shirts, tabards, and cosmetic armor no longer show a meaningless item level of 1 on loot lines.",
                    "Repeat drops of the same item during AoE looting are told apart more reliably, so fewer of them go missing from the feed or from a combined row's tally.",
                    "The gear upgrade tag no longer compares a weapon against a held off-hand item, which could tag a plain higher item level weapon as an upgrade over something it cannot actually replace. (Retail)",
                    "The new appearance marker no longer calls an outfit new while your collection is still loading in after login, and it updates once loading finishes. (Retail)",
                    "The Sell Grays progress bar now fills all the way when some items are skipped, and a skipped item no longer stalls the run for a moment.",
                } },
                { head = "Improvements", items = {
                    "Item tooltips do far less work while the cursor rests on them. The loot count, sell price, stack value, and already-owned lines are reused instead of being rebuilt several times a second, and hovering something that cannot stack skips the stack-value work entirely.",
                    "Scanning your bags for grays is much cheaper. Items already known not to be gray are ruled out before the costly check, which you will notice when opening a vendor and when hovering Sell Grays Now.",
                    "Gear drops read their stats once per line instead of up to four times, and the item level and tertiary stat tags are reused between drops.",
                    "The new appearance check now shares one answer across every source of the same look, so repeat drops of gear you have already seen resolve without re-checking. (Retail)",
                    "Less work per loot line all round: icons, row fonts, and matched names are reused rather than rebuilt, and the loot feed stops running timers once it has nothing left to fade.",
                    "Dragging a color on the Colors tab no longer rebuilds the whole test feed on every small movement.",
                    "Your session is no longer written to disk when you log out, since only a /reload can restore it.",
                } },
            },
        },
        {
            version = "2.17.0", date = "2026-08-08",
            sections = {
                { head = "Bug Fixes", items = {
                    "Gear tags now appear on framed loot rows. The item level tag, and on Retail the new appearance, upgrade, and tertiary-stat tags, were being worked out for every gear drop and then thrown away before the row was drawn, so with Framed loot rows turned on none of them ever showed. Item level, new appearance, and upgrade have been missing there since 2.14.0, and the tertiary-stat tag since it shipped in 2.15.0. A combined row also picks up a tag now when a later drop resolves one the first drop was too early to know.",
                    "Combined rows show their running tally when loot icons are turned off. The count badge sits on the icon, so with icons hidden the Junk Items row never appeared to change and every gray after the first looked like it had vanished. The tally now shows in the row name instead, alongside the item total rather than in place of it.",
                    "Fewer repeat drops go missing during AoE looting. Two identical loot lines arriving in the same instant could cancel each other out when the feed was not showing item totals, so the second drop was discarded instead of combining into the row.",
                    "Alert on value no longer treats a brand new item as worthless. An item the game client had not cached yet reported no sell price, which read as zero, so the first drop of something valuable never set off the alert. It now tells unknown apart from worthless, and asks the client for the price so the next drop is covered.",
                    "Click through locked rows no longer leaves an item tooltip stuck on screen. With the option turned on and the cursor resting where rows appear, looting popped a tooltip that nothing could close.",
                    "Items that report progress instead of a stack size, such as Companion Experience and Boon of Power, no longer show a meaningless quantity on framed rows.",
                } },
                { head = "Improvements", items = {
                    "Combining a repeat drop no longer re-positions every visible row, trimming wasted work during heavy AoE looting.",
                    "The What's New popup no longer describes Retail-only options to Classic players.",
                } },
            },
        },
        {
            version = "2.16.0", date = "2026-07-31",
            sections = {
                { head = "Bug Fixes", items = {
                    "Fixed a Lua error thrown every time you hovered a companion pet item in your bags while \"Show already owned on mount, pet, and toy tooltips\" was turned on. The already-owned check was reading the pet's name where the pet journal expected its species id, which also stopped the rest of that tooltip from being built. (Retail)",
                } },
                { head = "New Features", items = {
                    "Click through locked rows on the Customization tab. While the readout is locked, clicks pass through framed loot and combat rows to whatever is behind them, instead of the row catching them. Leave it off to keep shift-clicking a row to link its item.",
                } },
            },
        },
        {
            version = "2.15.0", date = "2026-07-23",
            sections = {
                { head = "New Features", items = {
                    "Combine repeated drops (on by default) for framed loot rows. Repeats of the same item stack into one row with a rolling count, gray junk collapses into a single Junk Items row, and rapid money pickups merge into one running total, keeping the feed readable during AoE looting.",
                    "Pause and resume the session timer from the Recap tab or with /lp pause, so AFK, mailbox, and loading time no longer drag down your gold-per-hour and items-per-hour. The header shows (paused) while stopped, loot is still counted, and the pause survives a /reload.",
                    "Alert on value box on the Alerts tab. Set a gold amount and the rare-drop alert also fires when a single drop is worth at least that much, on top of the quality and notable triggers. Set it to 0 to turn it off.",
                    "Mark gear with a tertiary stat on the Alerts tab tags looted weapons and armor that carry a tertiary stat (Leech, Avoidance, Speed, or Indestructible) in the loot feed, naming the stat. (Retail)",
                    "Show already owned on mount, pet, and toy tooltips on the Recap tab adds a line to those tooltips when you already have it, so you know it is safe to sell or skip. (Retail)",
                } },
                { head = "Improvements", items = {
                    "The notable-item alert now fires only for mounts, pets, and toys you have not collected yet, instead of every mount, pet, or toy. (Retail)",
                    "The gear-upgrade tag no longer marks a higher item-level piece that has the wrong primary stat for you, such as an Intellect piece for an Agility character. (Retail)",
                    "Option tooltips now appear when you hover the option's text, not only the small checkbox, and more options have explanatory tooltips.",
                } },
            },
        },
        {
            version = "2.14.2", date = "2026-07-22",
            sections = {
                { head = "Improvements", items = {
                    "Updated for Classic Era patch 1.15.9.",
                } },
            },
        },
        {
            version = "2.14.1", date = "2026-07-22",
            sections = {
                { head = "Improvements", items = {
                    "Updated for Burning Crusade Classic patch 2.5.6.",
                } },
            },
        },
        {
            version = "2.14.0", date = "2026-07-21",
            sections = {
                { head = "New Features", items = {
                    "Framed loot and combat feeds. On the Customization tab, turn on Framed loot rows and Framed combat rows to draw each line as its own bordered row. Loot rows show the item icon, name, running count, and category, colored by item quality. Combat, skill, and reputation lines get a matching bordered row colored by that line. Font, outline, size, colors, fade, and hover-to-pause all carry over.",
                    "Shift-click a framed loot row to link the item in chat. It opens a chat box for you if one is not already open. Control-click opens the dressing room, hovering shows the item tooltip, and while the feed is unlocked you can drag any row to move it.",
                    "Masque support for the framed loot icons. With Masque installed, a Loot Pro group appears in its settings so you can skin the icons. Without Masque, the icons keep a clean built-in border.",
                } },
            },
        },
        {
            version = "2.13.1", date = "2026-07-20",
            sections = {
                { head = "Bug Fixes", items = {
                    "Warband (account-wide) reputation gains and losses appear in the combat feed again, after patch 11.0 changed the wording for account-wide reputation.",
                    "Reputation lines show even if you have turned off the Reputation category in your chat windows.",
                    "Looting a brand-new item for the first time no longer shows a doubled count.",
                    "Currencies that fire both a loot and a currency message no longer show the line twice.",
                    "Looting a caged battle pet no longer triggers a Lua error that could cut off the loot feed.",
                    "The Discord and link copy popups no longer interfere with other addons' text-entry dialogs.",
                    "The bag tooltip's Stack of N sell-price line is no longer clipped.",
                    "The busy-feed and hover-pause checkboxes update immediately after Reset to Defaults.",
                    "Watch-list entries added by pasting a non-item link now match and alert correctly.",
                    "Combat and loot sliders no longer show a blank label when their value is at the minimum.",
                    "Layout sliders on the Customization tab render at a consistent width.",
                    "Classic: loot icons show for items not yet seen this session.",
                } },
                { head = "Improvements", items = {
                    "Item lookups use the modern C_Item API path consistently, guarding against future removal of the legacy global functions.",
                } },
            },
        },
        {
            version = "2.13.0", date = "2026-07-14",
            sections = {
                { head = "New Features", items = {
                    "Options window scale: a slider on the Customization tab resizes the settings window from 75% to 125%. It changes only this window, not the loot feed, combat text, or anything shown in the world.",
                    "Item level on gear: loot lines for weapons and armor can show the item level as [485]. Off by default; enable it on the Alerts tab. Applies to your own drops and the group's.",
                    "Vendor session totals: the Vendor tab shows a running tally of the gray items auto-sold and the gold earned this session.",
                } },
                { head = "Bug Fixes", items = {
                    "What's New popup now grows to fit long entries instead of overflowing its buttons.",
                    "Alerts and Vendor tabs no longer overlap the Reset to Defaults button; the window is taller.",
                    "Notifications tab: the Use Coin Icons label no longer runs into the right-hand options.",
                    "Reset to Defaults now asks for confirmation before clearing every setting.",
                    "The font-picker dropdown no longer lingers on screen after you close the settings window.",
                    "The session recap no longer wrongly carries over after a game crash; only a /reload keeps it going.",
                } },
                { head = "Improvements", items = {
                    "Recap tab tidied: Enable Session Recap and the tooltip option stack at the top.",
                    "Lower memory use on the loot path and in the settings window.",
                } },
            },
        },
        {
            version = "2.12.0", date = "2026-07-01",
            sections = {
                { head = "New Features", items = {
                    "Separate minimum loot quality for your own loot vs. other players' loot, on the Notifications tab. Your existing setting carries over to both.",
                    "More loot categories to hide: Gear, Gems, Enhancements, Miscellaneous, and Glyphs, alongside the existing Trade Goods, Consumables, Quest Items, and Recipes.",
                    "Name block list: a new Block tab hides items from the loot feed by name or keyword (type a word or shift-click an item). Blocked items are still counted in the session recap.",
                } },
            },
        },
        {
            version = "2.11.0", date = "2026-06-29",
            sections = {
                { head = "New Features", items = {
                    "WoW Classic support: Loot Pro now runs on Classic Era, Burning Crusade Classic, and Mists of Pandaria Classic alongside Retail. Loot feed, combat text, auto-vendor, tooltips, looted counts, quality coloring, and currency tracking work where each version supports them. Transmog and upgrade markers stay retail-only.",
                } },
                { head = "Bug Fixes", items = {
                    "First-run welcome popup: the Open Settings button could overlap the text on Classic when it wrapped; it now sits below the text on every version.",
                } },
            },
        },
        {
            version = "2.10.1", date = "2026-06-27",
            sections = {
                { head = "Bug Fixes", items = {
                    "Session Recap now resets when you log out. It read a reload flag that misfires on a normal login, so the session could survive logouts, character switches, and restarts, persisting until you used Reset Session. A /reload still keeps the session; logging out starts a fresh one.",
                } },
                { head = "Improvements", items = {
                    "New minimap, broker, and AddOns-list icon.",
                } },
            },
        },
        {
            version = "2.10.0", date = "2026-06-25",
            sections = {
                { head = "New Features", items = {
                    "Gear upgrade marker: looted weapons and armor above your equipped item level get a green (upgrade) tag in the feed (Alerts tab, off by default, retail only).",
                    "Session Recap now tracks vendor income from all vendor sales, gold and items per hour, and the zone where the session started.",
                } },
                { head = "Bug Fixes", items = {
                    "Vendor sell totals and gray values no longer under-report right after login, before item prices are cached.",
                } },
                { head = "Improvements", items = {
                    "Recap tab scrolls so long sessions no longer overflow the window; the tooltip toggle moved alongside it.",
                    "Minor memory and code cleanup in the settings window.",
                } },
            },
        },
        {
            version = "2.9.1", date = "2026-06-18",
            sections = {
                { head = "Maintenance", items = {
                    "Code comment cleanup across the addon and a TOC version bump. No functional changes.",
                } },
            },
        },
        {
            version = "2.9.0", date = "2026-06-13",
            sections = {
                { head = "New Features", items = {
                    "About tab: version, links, commands, sibling add-ons, credits, and the full changelog (/lp about).",
                    "Fast Loot (the game's one-click Auto Loot) and Speedy AutoLoot (instant looting, no loot window) on the Customization tab, each with a tooltip.",
                } },
                { head = "Bug Fixes", items = {
                    "Fast Loot now stays on -- the old Quick Loot toggle wrote to a CVar that doesn't exist and reverted every reload.",
                    "Mousing over a loot or combat feed no longer resurrects lines that already faded out.",
                } },
                { head = "Improvements", items = {
                    "Session Recap survives a /reload; only a logout or Reset Session clears it.",
                } },
            },
        },
        {
            version = "2.8.0", date = "2026-06-12",
            sections = {
                { head = "New Features", items = {
                    "New-appearance marker tags looted gear whose transmog look you haven't collected yet (Alerts tab, retail only).",
                    "Notable-item alerts fire for mounts, pets, and toys even below your quality threshold (Alerts tab).",
                    "Vendor sell price in tooltips, plus full stack value when hovering a stack in your bags (Vendor tab).",
                    "Loot feed polish: pause fading while hovering the feed, and keep busy feeds visible longer during big pulls (Customization tab).",
                } },
                { head = "Bug Fixes", items = {
                    "Collapse duplicate back-to-back loot/currency lines (count-aware, so a real second drop still shows).",
                } },
            },
        },
        {
            version = "2.7.0", date = "2026-06-06",
            sections = {
                { head = "New Features", items = {
                    "Auto-sell gray items at merchants, with sell speed, optional progress bar, and per-item chat (Vendor tab, off by default).",
                } },
                { head = "Improvements", items = {
                    "Lower memory use in the settings window (shared backdrops, fewer per-interaction allocations).",
                } },
            },
        },
        {
            version = "2.6.0", date = "2026-06-01",
            sections = {
                { head = "New Features", items = {
                    "Community Discord link in the settings window and the What's New popup.",
                } },
                { head = "Improvements", items = {
                    "Lower memory use while looting and in Session Recap.",
                } },
            },
        },
        {
            version = "2.5.2", date = "2026-05-30",
            sections = {
                { head = "Bug Fixes", items = {
                    "Fix \"secret string value\" Lua errors during Midnight (12.0) Mythic+, boss, and rated PvP encounters; notifications pause and auto-resume.",
                } },
            },
        },
        {
            version = "2.5.1", date = "2026-05-23",
            sections = {
                { head = "Bug Fixes", items = {
                    "Rare-drop alert no longer misfires on bonus-scaled items (quality is read from the looted link's color).",
                } },
                { head = "Improvements", items = {
                    "Loot Pro now appears in the game's Options > AddOns list.",
                } },
            },
        },
        {
            version = "2.5.0", date = "2026-05-23",
            sections = {
                { head = "New Features", items = {
                    "Session Recap tab and /lp recap: gold, items by rarity, currencies, and notable drops for the session.",
                    "Watched-item alerts by name, ID, or shift-clicked link (Alerts tab).",
                    "Rare Drop Alerts: color, flash, and sound at a quality threshold.",
                    "Tooltip loot counts, loot feed filters, currency-cap warnings, configurable minimap clicks, and a What's New popup.",
                } },
                { head = "Improvements", items = {
                    "Locale-aware money parsing for non-English clients.",
                } },
            },
        },
        {
            version = "2.4.5", date = "2026-05-13",
            sections = {
                { head = "New Features", items = {
                    "Scrollable font-dropdown pickers that preview each font in its own typeface (Custom tab).",
                } },
                { head = "Improvements", items = {
                    "LibSharedMedia-3.0 now bundled internally — no separate SharedMedia addon needed.",
                } },
            },
        },
        {
            version = "2.4.4", date = "2026-05-08",
            sections = {
                { head = "Improvements", items = {
                    "Multi-version Interface support (120001/120005/120007) — loads cleanly across current retail builds.",
                } },
            },
        },
        {
            version = "2.4.3", date = "2026-05-04",
            sections = {
                { head = "New Features", items = {
                    "Quick Loot toggle (Custom tab).",
                } },
            },
        },
    },
}
