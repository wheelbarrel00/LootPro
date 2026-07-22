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
    currencyCap = true,
    hoverPause = false,
    fadeScale = false,
    framedLoot = false,
    framedCombat = false,
    speedyAutoLoot = false,
    uiScale = 1.0,
    lootFilters = { hideTradeGoods = false, hideConsumable = false, hideQuest = false, hideRecipe = false, hideGear = false, hideGem = false, hideEnhancement = false, hideMisc = false, hideGlyph = false },
    lootBlacklist = { items = {} },
    combatEnterText = "Combat Start",
    combatLeaveText = "Combat End",
    hideWelcome = false,
    whatsNewSeen = 0,
    minimap = { hide = false, minimapPos = 220, leftClick = "settings", rightClick = "recap", middleClick = "lock" },
    watchlist = { enabled = false, sound = true, items = {} },
    rareAlert = { threshold = 5, color = false, flash = false, sound = false, notable = false },
    newAppearance = false,
    lootUpgrade = false,
    lootIlvl = false,
    vendorGrays = { enabled = false, interval = 0.2, details = false, progressBar = true },
    loot = { size = 22, font = "Friz Quadrata TT", fade = 6, outline = "OUTLINE", width = 200, height = 200, point = "CENTER", relativePoint = "CENTER", x = 0, y = 50, maxLines = 4 },
    combat = { size = 20, font = "Friz Quadrata TT", fade = 6, outline = "OUTLINE", width = 200, height = 200, point = "CENTER", relativePoint = "CENTER", x = 0, y = 150, maxLines = 4 },
    colors = {
        money = {r = 1.0, g = 0.82, b = 0.0},
        currency = {r = 0.65, g = 0.85, b = 1.0},
        loot = {r = 1.0, g = 1.0, b = 1.0},
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

-- An empty table in DEFAULTS (e.g. watchlist.items) is free-form user data; the next()~=nil guard keeps prune from wiping it.
local function prune(src, dst)
    for k, v in pairs(dst) do
        if src[k] == nil then
            dst[k] = nil
        elseif type(v) == "table" and type(src[k]) == "table" and next(src[k]) ~= nil then
            prune(src[k], v)
        end
    end
end

function addon:InitSettings()
    if not LootProConfig then
        LootProConfig = addon:DeepCopy(addon.DEFAULTS)
        -- Fresh install: mark the current revision seen so a first-time user gets the welcome popup, not What's New too.
        LootProConfig.whatsNewSeen = addon.WHATS_NEW

    else
        if LootProConfig.minQuality ~= nil and LootProConfig.minQualityOwn == nil and LootProConfig.minQualityOther == nil then
            LootProConfig.minQualityOwn = LootProConfig.minQuality
            LootProConfig.minQualityOther = LootProConfig.minQuality
        end
        validate(addon.DEFAULTS, LootProConfig)
        prune(addon.DEFAULTS, LootProConfig)
    end
end


function addon:IsReady()
    return LootProConfig and LootProConfig.loot and LootProConfig.combat and LootProConfig.colors and LootProConfig.notifications and LootProConfig.minimap
end

function addon:ResetDefaults()
    LootProConfig = self:DeepCopy(addon.DEFAULTS)
    self:UpdateAllVisuals()
    if ns.UI and ns.UI.RefreshAllWidgets then ns.UI:RefreshAllWidgets() end
    print("|cFF00FF00[LootPro]|r Settings reset to defaults.")
end