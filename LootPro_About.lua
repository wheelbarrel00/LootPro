local addonName, ns = ...

-- MAINTENANCE: addons can't read CHANGELOG.md at runtime, so this table mirrors it -- update both every release. Newest-first.
ns.about = {
    links = {
        curseforge = "https://www.curseforge.com/wow/addons/loot-pro",
        github     = "https://github.com/wheelbarrel00/LootPro",
        bug        = "https://github.com/wheelbarrel00/lootpro/issues",
    },

    changelogURL = "https://www.curseforge.com/wow/addons/loot-pro/files",

    moreAddons = {
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
