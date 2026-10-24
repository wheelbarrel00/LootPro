local addonName, ns = ...
local addon = ns.addon

addon.DEFAULTS = {
    locked = true,
    cleanMode = true,
    minQualityOwn = 0,
    minQualityOther = 0,
    showFollowerXP = false,
    showLootIcons = true,
    showMoneyIcons = true,
    showLootCounts = true,
    recapEnabled = false,
    tooltipLoots = true,
    tooltipSell = false,
    tooltipCollected = false,
    currencyCap = true,
    hoverPause = false,
    fadeScale = false,
    framedLoot = false,
    framedCombat = false,
    rowClickThrough = false,
    mergeRows = true,
    speedyAutoLoot = false,
    uiScale = 1.0,
    lastSettingsPage = "general",
    lootFilters = { hideTradeGoods = false, hideConsumable = false, hideQuest = false, hideRecipe = false, hideGear = false, hideGem = false, hideEnhancement = false, hideMisc = false, hideGlyph = false },
    lootBlacklist = { items = {} },
    combatEnterText = "Combat Start",
    combatLeaveText = "Combat End",
    whatsNewSeen = "",
    whatsNewAnnounced = "",
    whatsNewMode = "popup",
    minimap = { hide = false, minimapPos = 220, leftClick = "settings", rightClick = "recap", middleClick = "lock" },
    watchlist = { enabled = false, sound = true, soundName = "Default", items = {} },
    rareAlert = { threshold = 5, color = false, flash = false, sound = false, soundName = "Default", notable = false, value = 0, upgrade = false, ilvl = 0 },
    questColor = { enabled = false, classColor = false },
    newAppearance = false,
    lootUpgrade = false,
    lootIlvl = false,
    tertiaryStat = false,
    upgradeTrack = false,
    upgradeTrackGroup = false,
    lootSpecReminder = true,
    hideLootToasts = false,
    vendorGrays = { enabled = false, interval = 0.2, details = false, progressBar = true },
    loot = { size = 22, font = "Friz Quadrata TT", fade = 6, outline = "OUTLINE", width = 200, height = 200, point = "CENTER", relativePoint = "CENTER", x = 0, y = 50, maxLines = 4, scale = 1.0, align = "CENTER", position = "BOTTOM", newest = "BOTTOM" },
    combat = { size = 20, font = "Friz Quadrata TT", fade = 6, outline = "OUTLINE", width = 200, height = 200, point = "CENTER", relativePoint = "CENTER", x = 0, y = 150, maxLines = 4, scale = 1.0, align = "CENTER", position = "BOTTOM", newest = "BOTTOM" },
    colors = {
        money = {r = 1.0, g = 0.82, b = 0.0},
        currency = {r = 0.65, g = 0.85, b = 1.0},
        loot = {r = 1.0, g = 1.0, b = 1.0},
        questItem = {r = 1.0, g = 0.82, b = 0.1},
        combatEnter = {r = 1.0, g = 0.1, b = 0.1},
        combatLeave = {r = 0.1, g = 1.0, b = 0.1},
        skill = {r = 0.0, g = 0.6, b = 1.0},
        honor = {r = 0.8, g = 0.1, b = 0.1},
        repGain = {r = 0.1, g = 0.8, b = 0.8},
        repLoss = {r = 0.8, g = 0.1, b = 0.1},
        xp = {r = 0.7, g = 0.3, b = 1.0},
        delver = {r = 1.0, g = 0.7, b = 0.2}
    },
    notifications = {
        money = true, currency = true, loot = true, skill = true,
        honor = true, repGain = true, repLoss = true, delver = false,
        xp = true, combatEnter = true, combatLeave = true, partyLoot = true
    }
}

function addon:DeepCopy(t)
    if type(t) ~= 'table' then return t end
    local mt = getmetatable(t)
    local res = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then res[k] = self:DeepCopy(v) else res[k] = v end
    end
    setmetatable(res, mt)
    return res
end

local function validate(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            validate(v, dst[k])
        else
            if dst[k] == nil then dst[k] = v end
        end
    end
end

-- An empty table in DEFAULTS (e.g. watchlist.items) is free-form user data. The next()~=nil guard keeps prune from wiping it.
local function prune(src, dst)
    for k, v in pairs(dst) do
        if src[k] == nil then
            dst[k] = nil
        elseif type(v) == "table" and type(src[k]) == "table" and next(src[k]) ~= nil then
            prune(src[k], v)
        end
    end
end

local function newestRelease()
    local c = ns.about and ns.about.changelog
    return c and c[1] and c[1].version or ""
end

-- A save from before Text Position keeps the old stacking: a text feed sat at the bottom with the newest line last, and framed rows at the top with the newest first
local function keepOldStacking(s, framed)
    if type(s) ~= "table" or s.position ~= nil then return end
    s.position = framed and "TOP" or "BOTTOM"
    s.newest = framed and "TOP" or "BOTTOM"
end

function addon:InitSettings()
    if not LootProConfig then
        LootProConfig = addon:DeepCopy(addon.DEFAULTS)
        -- Fresh install: mark the newest release seen so a first-time user gets the welcome, not What's New too.
        LootProConfig.whatsNewSeen = newestRelease()
        LootProConfig.whatsNewAnnounced = newestRelease()
        addon.firstInstall = true

    else
        -- 2.22.0 and older saved a popup revision number, or none before 2.5.0, and either counts as told up to 2.22.0
        local seen = LootProConfig.whatsNewSeen
        if type(seen) ~= "string" or seen == "" then LootProConfig.whatsNewSeen = "2.22.0" end
        if LootProConfig.minQuality ~= nil and LootProConfig.minQualityOwn == nil and LootProConfig.minQualityOther == nil then
            LootProConfig.minQualityOwn = LootProConfig.minQuality
            LootProConfig.minQualityOther = LootProConfig.minQuality
        end
        keepOldStacking(LootProConfig.loot, LootProConfig.framedLoot)
        keepOldStacking(LootProConfig.combat, LootProConfig.framedCombat)
        validate(addon.DEFAULTS, LootProConfig)
        prune(addon.DEFAULTS, LootProConfig)
    end
end


function addon:IsReady()
    return LootProConfig and LootProConfig.loot and LootProConfig.combat and LootProConfig.colors and LootProConfig.notifications and LootProConfig.minimap
end

function addon:ResetDefaults()
    LootProConfig = self:DeepCopy(addon.DEFAULTS)
    LootProConfig.whatsNewSeen = newestRelease()
    -- LibDBIcon captured the old minimap table when it registered, so hand it the new one or drag positions stop persisting.
    if self.LDBIcon then self.LDBIcon:Refresh("LootPro", LootProConfig.minimap) end
    self:UpdateAllVisuals()
    if self.ApplyLootToasts then self:ApplyLootToasts() end
    if ns.Settings then ns.Settings.Redraw() end
    print("|cFF00FF00[LootPro]|r Settings reset to defaults.")
end