local addonName, ns = ...
local addon = ns.addon

addon.DEFAULTS = {
    locked = true, -- Changed to true so windows are invisible by default
    cleanMode = true, 
    minQuality = 0, 
    showFollowerXP = false,
    showLootIcons = true,
    showMoneyIcons = true,
    showLootCounts = true,
    recapEnabled = false, -- Session recap tally (off by default; opt in to track loot)
    tooltipLoots = true, -- Show "Looted Nx this session" on item tooltips (needs recap on)
    currencyCap = true, -- Flag a currency line when it hits its max / weekly cap (#8)
    -- Per-class display filters for the loot feed (false = show). These hide
    -- matching items from the readout only; the recap still tallies them.
    lootFilters = { hideTradeGoods = false, hideConsumable = false, hideQuest = false, hideRecipe = false },
    combatEnterText = "Combat Start",
    combatLeaveText = "Combat End",
    hideWelcome = false, -- New variable to track the popup state
    whatsNewSeen = 0, -- Highest "What's New" revision the user has seen (see addon.WHATS_NEW)
    -- Minimap button: per-click actions (#12). Values: settings|recap|lock|none.
    minimap = { hide = false, minimapPos = 220, leftClick = "settings", rightClick = "recap", middleClick = "lock" },
    -- Watched-item alerts. `items` is a user-managed list (persisted) of
    -- { id = <itemID> } or { key = "<lowercased name substring>" } entries,
    -- each carrying a `label` (and `icon` for id-based entries) for display.
    -- Disabled by default; users opt in on the Alerts tab.
    watchlist = { enabled = false, sound = true, items = {} },
    -- Rare-drop alerts: when a looted item's quality >= threshold, optionally
    -- color its loot line by quality, flash the loot frame, and play a sound.
    -- All effects off by default; threshold pre-set to Legendary for when the
    -- user enables them.
    rareAlert = { threshold = 5, color = false, flash = false, sound = false },
    loot = { size = 22, font = "Friz Quadrata TT", fade = 6, outline = "OUTLINE", width = 200, height = 200, point = "CENTER", relativePoint = "CENTER", x = 0, y = 50, maxLines = 4 }, -- Resized to 200x200
    combat = { size = 20, font = "Friz Quadrata TT", fade = 6, outline = "OUTLINE", width = 200, height = 200, point = "CENTER", relativePoint = "CENTER", x = 0, y = 150, maxLines = 4 }, -- Resized to 200x200
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

function addon:InitSettings()
    if not LootProConfig then
        LootProConfig = addon:DeepCopy(addon.DEFAULTS)
        -- Brand-new install: this is a first-time user who gets the welcome
        -- popup, not the "what's new" popup -- mark the current revision seen
        -- so we don't show both. Existing users (else branch) keep the default
        -- 0 and will see what changed.
        LootProConfig.whatsNewSeen = addon.WHATS_NEW

    else
        local function validate(src, dst)
            for k, v in pairs(src) do
                if type(v) == "table" then
                    if not dst[k] then dst[k] = {} end
                    validate(v, dst[k])
                else
                    if dst[k] == nil then dst[k] = v end
                end
            end
        end
        validate(addon.DEFAULTS, LootProConfig)

        -- L3: Prune keys that no longer exist in the schema. Only prunes inside
        -- tables defined by DEFAULTS (e.g. colors, notifications, loot, combat,
        -- minimap); user-side tables outside of DEFAULTS are never touched.
        --
        -- An EMPTY table in DEFAULTS (e.g. watchlist.items) denotes free-form
        -- user data: we leave its contents intact rather than deleting every
        -- entry as an "unknown key". Without this guard the watchlist would be
        -- wiped on every load.
        local function prune(src, dst)
            for k, v in pairs(dst) do
                if src[k] == nil then
                    dst[k] = nil
                elseif type(v) == "table" and type(src[k]) == "table" and next(src[k]) ~= nil then
                    prune(src[k], v)
                end
            end
        end
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