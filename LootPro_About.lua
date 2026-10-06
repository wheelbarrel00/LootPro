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
    },

    thanks = { "Agaman", "Rhinoplasty" },

    changelog = {
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
