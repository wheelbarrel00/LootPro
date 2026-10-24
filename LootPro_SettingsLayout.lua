local _, ns = ...
local addon = ns.addon
local Settings = ns.Settings
local ui = Settings.ui

local OUTLINES = {
    { value = "NONE",         label = "None" },
    { value = "OUTLINE",      label = "Thin" },
    { value = "THICKOUTLINE", label = "Thick" },
    { value = "MONOCHROME",   label = "Pixel" },
}

local ALIGNMENTS = {
    { value = "LEFT",   label = "Left" },
    { value = "CENTER", label = "Center" },
    { value = "RIGHT",  label = "Right" },
}

local POSITIONS = {
    { value = "TOP",    label = "Top" },
    { value = "MIDDLE", label = "Middle" },
    { value = "BOTTOM", label = "Bottom" },
}

local NEWEST = {
    { value = "TOP",    label = "Top" },
    { value = "BOTTOM", label = "Bottom" },
}

local MATCHED = { "font", "size", "outline", "align", "position", "newest", "fade", "width", "height", "maxLines" }

local TIP = {
    font = "The font this feed's lines are drawn in. Fonts from your media addons are listed too.",
    size = "The size of this feed's text.",
    outline = "The outline around this feed's text. None draws a soft shadow instead.",
    lootAlign = "Lines this feed's text up with the left edge, the center or the right edge of its area. Framed item rows keep their icon on the left with the name beside it, and Right mirrors them.",
    combatAlign = "Lines this feed's text up with the left edge, the center or the right edge of its area.",
    position = "Where this feed's lines sit in its area when they do not fill it: against the top, in the middle or against the bottom. Unlock Windows to see the area.",
    newest = "Whether a new line appears above the lines already showing or below them.",
    fade = "How many seconds a line stays before it fades out.",
    width = "The width of this feed's area, in pixels. Unlock Windows to see the area.",
    height = "The height of this feed's area, in pixels. Unlock Windows to see the area.",
    lines = "The most lines this feed shows at once. A new line pushes the oldest one out.",
    lootScale = "Resizes the whole loot readout, text, icons and framed rows together. 100% is the normal size. The readout keeps its place on screen as it scales.",
    combatScale = "Resizes the whole combat readout, text and framed rows together. 100% is the normal size. The readout keeps its place on screen as it scales.",
    framedLoot = "Draws each loot line as its own bordered row with the item icon, like XLoot. The border is colored by item quality.",
    framedCombat = "Draws each combat, skill, and reputation line as its own bordered row. The border is colored to match that line's color.",
    merge = "In framed loot mode, repeats of the same item stack into one growing row, and gray junk collapses into a single row. Reduces clutter during AoE looting.",
    clickThrough = "While the readout is locked, clicks pass through framed rows to whatever is behind them. Trades away shift-clicking a row to link its item.",
    hoverPause = "Hovering a readout freezes its fade so you can read it. Clicks still pass through to whatever is behind it.",
    fadeScale = "Lengthens how long lines stay visible when many arrive at once (e.g. an AoE pull), easing back to your fade setting as they clear.",
    match = "Copies the Combat Feed's font, text size, outline, text alignment, text position, newest line, fade, frame size, max lines and frame scale to the Loot Feed.",
}

local fontCache

-- LibSharedMedia refills the same list in place when a font registers, so its length is compared too
local function fonts()
    local LSM = LibStub("LibSharedMedia-3.0", true)
    local list = LSM and LSM:List("font")
    if not fontCache or fontCache.list ~= list or fontCache.count ~= #(list or {}) then
        local opts = {}
        for i, name in ipairs(list or {}) do opts[i] = { value = name, label = name } end
        if #opts == 0 then opts[1] = { value = "Friz Quadrata TT", label = "Friz Quadrata TT" } end
        fontCache = { list = list, count = #(list or {}), opts = opts }
    end
    return fontCache.opts
end

local function fontFile(name)
    local LSM = LibStub("LibSharedMedia-3.0", true)
    return LSM and name and LSM:Fetch("font", name, true)
end

local function feedSetting(feed, field, fallback)
    return function()
        local v = LootProConfig[feed][field]
        if v == nil then return fallback end
        return v
    end, function(v)
        LootProConfig[feed][field] = v
        addon:UpdateAllVisuals()
    end
end

local function framedSetting(key, deps)
    return function() return LootProConfig[key] end, function(v)
        LootProConfig[key] = v
        addon:UpdateAllVisuals()
        if addon.isTesting then addon:PostTestMessages() end
        deps.sync()
    end
end

local function seconds(v)
    return ("%ds"):format(math.floor(v + 0.5))
end

local function percent(v)
    return ("%d%%"):format(math.floor(v + 0.5))
end

local function slider(self, content, label, lo, hi, step, get, set, tip, format)
    return self:CreateSlider(content, label, lo, hi, step, get, set, tip, format).EnableTyping()
end

local function matchCombat()
    local loot, combat = LootProConfig.loot, LootProConfig.combat
    for _, field in ipairs(MATCHED) do loot[field] = combat[field] end
    addon:SetReadoutScale("loot", combat.scale)
    addon:UpdateAllVisuals()
    Settings.Redraw()
end

local function feedCard(self, content, stack, deps, feed)
    local card = stack(self:CreateGroup(content, feed == "loot" and "Loot Feed" or "Combat Feed"))
    local get, set = feedSetting(feed, "font", "Friz Quadrata TT")
    card:Add(self:CreateDropdown(content, "Font", fonts, get, set, TIP.font, nil, nil, fontFile))
    get, set = feedSetting(feed, "size")
    card:Add(slider(self, content, "Text Size", 10, 50, 1, get, set, TIP.size))
    get, set = feedSetting(feed, "outline")
    card:Add(self:CreateDropdown(content, "Outline", OUTLINES, get, set, TIP.outline))
    get, set = feedSetting(feed, "align", "CENTER")
    card:Add(self:CreateDropdown(content, "Text Alignment", ALIGNMENTS, get, set,
        feed == "loot" and TIP.lootAlign or TIP.combatAlign))
    get, set = feedSetting(feed, "position", "BOTTOM")
    card:Add(self:CreateDropdown(content, "Text Position", POSITIONS, get, set, TIP.position))
    get, set = feedSetting(feed, "newest", "BOTTOM")
    card:Add(self:CreateDropdown(content, "Newest Line", NEWEST, get, set, TIP.newest))
    get, set = feedSetting(feed, "fade")
    card:Add(slider(self, content, "Fade", 1, 30, 1, get, set, TIP.fade, seconds))
    get, set = feedSetting(feed, "width")
    card:Add(slider(self, content, "Frame Width", 200, 1200, 10, get, set, TIP.width))
    get, set = feedSetting(feed, "height")
    card:Add(slider(self, content, "Frame Height", 50, 800, 10, get, set, TIP.height))
    get, set = feedSetting(feed, "maxLines")
    card:Add(slider(self, content, "Max Lines", 1, 20, 1, get, set, TIP.lines))
    -- In percent, so a typed 110 means 110%. The saved scale stays a fraction.
    card:Add(slider(self, content, "Frame Scale", 50, 200, 5,
        function() return math.floor((LootProConfig[feed].scale or 1) * 100 + 0.5) end,
        function(v) addon:SetReadoutScale(feed, v / 100) end,
        feed == "loot" and TIP.lootScale or TIP.combatScale, percent))
    if feed == "loot" then
        get, set = framedSetting("framedLoot", deps)
        card:Add(self:CreateCheckbox(content, "Framed loot rows", get, set, TIP.framedLoot))
        get, set = framedSetting("mergeRows", deps)
        local merge = self:CreateCheckbox(content, "Combine repeated drops", get, set, TIP.merge)
        card:Add(merge, { dependent = true })
        deps[#deps + 1] = { control = merge, on = function() return LootProConfig.framedLoot end }
        Settings.ButtonRow(self, content, card, { { "Match the Combat Feed", matchCombat, TIP.match } })
    else
        get, set = framedSetting("framedCombat", deps)
        card:Add(self:CreateCheckbox(content, "Framed combat rows", get, set, TIP.framedCombat))
    end
end

local function bothCard(self, content, stack, deps)
    local card = stack(self:CreateGroup(content, "Both Feeds"))
    local get, set = framedSetting("rowClickThrough", deps)
    local through = self:CreateCheckbox(content, "Click through locked rows", get, set, TIP.clickThrough)
    card:Add(through)
    deps[#deps + 1] = { control = through, on = function() return LootProConfig.framedLoot or LootProConfig.framedCombat end }
    card:Add(self:CreateCheckbox(content, "Pause fade while hovering the feed",
        function() return LootProConfig.hoverPause end,
        function(v)
            LootProConfig.hoverPause = v
            addon:UpdateAllVisuals()
        end, TIP.hoverPause))
    card:Add(self:CreateCheckbox(content, "Keep busy feeds up longer",
        function() return LootProConfig.fadeScale end,
        function(v) LootProConfig.fadeScale = v end, TIP.fadeScale))
end

ui:RegisterTab({
    id     = "layout",
    title  = "Layout",
    order  = 20,
    icon   = ui:Texture("icon-appearance"),
    footer = Settings.FeedFooter,
    build  = function(self, content)
        local stack = Settings.CardStack()
        local deps = {}
        deps.sync = function()
            for _, d in ipairs(deps) do self:SetDependent(d.control, d.on() and true or false) end
        end
        content._sync = deps.sync
        feedCard(self, content, stack, deps, "loot")
        feedCard(self, content, stack, deps, "combat")
        bothCard(self, content, stack, deps)
        deps.sync()
    end,
    refresh = function(_, content)
        if content._sync then content._sync() end
    end,
})
