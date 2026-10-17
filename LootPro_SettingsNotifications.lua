local _, ns = ...
local addon = ns.addon
local Settings = ns.Settings
local ui = Settings.ui

local QUALITY = {
    { value = 0, label = "Poor+ (All)" },
    { value = 1, label = "Common+" },
    { value = 2, label = "Uncommon+" },
    { value = 3, label = "Rare+" },
    { value = 4, label = "Epic+" },
    { value = 5, label = "Legendary+" },
}

local FILTERS = {
    { key = "hideTradeGoods",  label = "Trade Goods" },
    { key = "hideConsumable",  label = "Consumables" },
    { key = "hideQuest",       label = "Quest Items" },
    { key = "hideRecipe",      label = "Recipes" },
    { key = "hideGear",        label = "Gear" },
    { key = "hideGem",         label = "Gems" },
    { key = "hideEnhancement", label = "Enhancements" },
    { key = "hideMisc",        label = "Misc" },
    { key = "hideGlyph",       label = "Glyphs" },
}

local COLOR_NAMES = {
    money = "Money", currency = "Currency", loot = "Loot", questItem = "Quest Items", combatEnter = "Combat Start",
    combatLeave = "Combat End", xp = "Experience", delver = "Delver XP", skill = "Skill", honor = "Honor",
    repGain = "Rep Gain", repLoss = "Rep Loss",
}

local TIP = {
    itemLoot = "Shows the items you loot in the loot feed. Party loot, quest item colors, both quality limits and the Hide from Loot Feed boxes all work through it.",
    partyLoot = "Also shows what the rest of your group loots, in the Loot color, filtered by its own minimum quality below.",
    qualityOwn = "Hides your own drops below this quality. Quest items still show, so the drops Color quest items highlights are never hidden by it.",
    qualityOther = "Hides your group's drops below this quality.",
    questColor = "Paints your own quest drops in the Quest Items color instead of their quality color, so they stand out. Framed rows take the color on the name and the borders, plain lines take it on the whole line. Covers both quest-type items and ordinary items your active quests ask you to collect, and shows them even when they fall below your minimum quality. Loot filters and the block list still hide whatever they are set to hide.",
    questClass = "Colors quest items with your own class color and ignores the Quest Items swatch above. Picks up a class color addon's palette when one is installed.",
    currencyCap = "Tags a currency in the loot feed with (capped) or (weekly cap) when you have hit its maximum, so you know it is being wasted.",
    hideCard = "Hides looted items of the ticked kinds from the loot feed, yours and your group's. They still count in the session recap, and watch and rare drop alerts still fire.",
    clean = "Strips text like 'You receive loot:' from loot, money and currency lines, leaving the amount and the item.",
    totalsWarband = "Adds how many of an item you now own in parentheses after a loot line, like Linen Cloth (14). It counts your bags, your bank, and your warband bank. Needs Clean Mode. Off shows only what just dropped.",
    totals = "Adds how many of an item you now own in parentheses after a loot line, like Linen Cloth (14). It counts your bags and your bank. Needs Clean Mode. Off shows only what just dropped.",
    coins = "Shows looted money as gold, silver, and copper coin icons instead of the words. Applies while Clean Mode is on, and always on framed loot rows that combine repeated drops.",
    toasts = "Stops Blizzard's loot popups, which repeat what the loot feed already shows. That covers item drops along with the money, currency, and honor that share the same popup, won rolls, and item upgrades. Legendary items, new mounts, pets, and toys, achievements, and quest rewards still get their popups.",
    combatStart = "Shows a line in the combat feed as you enter combat.",
    combatEnd = "Shows a line in the combat feed as you leave combat.",
    startText = "The words shown as you enter combat. Enter or a click away keeps them, Escape undoes.",
    endText = "The words shown as you leave combat. Enter or a click away keeps them, Escape undoes.",
    follower = "Also shows experience gained by your pet, battle pet, or follower in the combat feed, in the Experience color. Needs Display Experience on.",
    swatch = "The color of these lines in the feed. Click to change it.",
}

local function config() return LootProConfig end

-- Enum.BankType.Account and the warband bank exist only on retail and Forever (Blizzard's source, 2026-10-16)
local function hasWarbandBank()
    return Enum ~= nil and Enum.BankType ~= nil and Enum.BankType.Account ~= nil
end

local function repost()
    if addon.isTesting then addon:PostTestMessages() end
end

-- The color wheel fires this continuously while dragging, and each rebuild clears and repopulates both frames.
local testFeedPending
local function flushTestFeed()
    testFeedPending = false
    repost()
end

local function requestTestFeed()
    if not addon.isTesting then return end
    if not (C_Timer and C_Timer.After) then
        addon:PostTestMessages()
        return
    end
    if testFeedPending then return end
    testFeedPending = true
    C_Timer.After(0.1, flushTestFeed)
end

-- A setting a line reads as it is drawn, so a running test is posted again to show it
local function lineSetting(get, set, deps)
    return get, function(v)
        set(v)
        repost()
        deps.sync()
    end
end

local function notification(key, deps)
    return lineSetting(function() return config().notifications[key] end,
        function(v) config().notifications[key] = v end, deps)
end

local function rootSetting(key, deps)
    return lineSetting(function() return config()[key] end, function(v) config()[key] = v end, deps)
end

local function dims(deps, control, on)
    deps[#deps + 1] = { control = control, on = on }
    return control
end

local function swatch(self, content, row, key, deps, on)
    local picker = self:CreateColorPicker(content, "",
        function() return config().colors[key] end,
        function(v)
            if type(v) ~= "table" then return end
            local c = config().colors[key]
            if c.r == v.r and c.g == v.g and c.b == v.b then return end
            c.r, c.g, c.b = v.r, v.g, v.b
            requestTestFeed()
        end)
    self:AttachTooltip(picker, COLOR_NAMES[key], TIP.swatch)
    picker:SetPoint("RIGHT", row, "RIGHT", -ui:Spacing("rowPadding"), 0)
    dims(deps, picker, on)
    return picker
end

local function itemLootCard(self, content, stack, deps)
    local card = stack(self:CreateGroup(content, "Item Loot"))
    local c = config
    local get, set = notification("loot", deps)
    local row = card:Add(self:CreateCheckbox(content, "Display Item Loot", get, set, TIP.itemLoot))
    swatch(self, content, row, "loot", deps, function() return c().notifications.loot end)
    local lootOn = function() return c().notifications.loot end
    card:Add(dims(deps, self:CreateDropdown(content, "Minimum Quality", QUALITY,
        function() return c().minQualityOwn end, function(v) c().minQualityOwn = v end, TIP.qualityOwn), lootOn))
    get, set = notification("partyLoot", deps)
    card:Add(dims(deps, self:CreateCheckbox(content, "Display Party Loot", get, set, TIP.partyLoot), lootOn))
    card:Add(dims(deps, self:CreateDropdown(content, "Minimum Quality", QUALITY,
        function() return c().minQualityOther end, function(v) c().minQualityOther = v end, TIP.qualityOther),
        function() return c().notifications.loot and c().notifications.partyLoot end), { dependent = true })
    get, set = lineSetting(function() return c().questColor.enabled end,
        function(v) c().questColor.enabled = v end, deps)
    row = card:Add(dims(deps, self:CreateCheckbox(content, "Color quest items", get, set, TIP.questColor), lootOn))
    swatch(self, content, row, "questItem", deps, function()
        local q = c().questColor
        return c().notifications.loot and q.enabled and not q.classColor
    end)
    get, set = lineSetting(function() return c().questColor.classColor end,
        function(v) c().questColor.classColor = v end, deps)
    card:Add(dims(deps, self:CreateCheckbox(content, "Use my class color", get, set, TIP.questClass),
        function() return c().notifications.loot and c().questColor.enabled end), { dependent = true })
end

local function moneyCard(self, content, stack, deps)
    local card = stack(self:CreateGroup(content, "Money and Currency"))
    local c = config
    for _, line in ipairs({ { "money", "Display Money" }, { "currency", "Display Currency" } }) do
        local key = line[1]
        local get, set = notification(key, deps)
        local row = card:Add(self:CreateCheckbox(content, line[2], get, set))
        swatch(self, content, row, key, deps, function() return c().notifications[key] end)
    end
    card:Add(dims(deps, self:CreateCheckbox(content, "Warn on currency cap",
        function() return c().currencyCap end, function(v) c().currencyCap = v end, TIP.currencyCap),
        function() return c().notifications.currency end), { dependent = true })
end

-- The boxes stay the content's so every view refreshes them. Fit places them once the row has its width on screen.
local GRID_ROW, GRID_TOP, GRID_HEIGHT = 32, 16, 112

local function hideCard(self, content, stack, deps)
    local card = stack(self:CreateGroup(content, "Hide from Loot Feed"))
    self:AttachTooltip(card.label, "Hide from Loot Feed", TIP.hideCard)
    local grid = CreateFrame("Frame", nil, content)
    grid:SetHeight(GRID_HEIGHT)
    grid._euiFill = true
    local boxes = {}
    local lootOn = function() return config().notifications.loot end
    for i, f in ipairs(FILTERS) do
        local key = f.key
        boxes[i] = dims(deps, self:CreateCheckbox(content, f.label,
            function() return config().lootFilters[key] end,
            function(v) config().lootFilters[key] = v end), lootOn)
    end
    function grid.Fit()
        local column = (grid:GetWidth() or 0) / 3
        for i, box in ipairs(boxes) do
            box:ClearAllPoints()
            box:SetPoint("TOPLEFT", grid, "TOPLEFT", ((i - 1) % 3) * column, -(GRID_TOP + math.floor((i - 1) / 3) * GRID_ROW))
        end
    end
    grid.Fit()
    local fits = content._euiFit or {}
    content._euiFit = fits
    fits[#fits + 1] = grid
    grid.boxes = boxes
    card:Add(grid, { height = GRID_HEIGHT })
end

local function lootFeedCard(self, content, stack, deps)
    local card = stack(self:CreateGroup(content, "Loot Feed"))
    local c = config
    local get, set = rootSetting("cleanMode", deps)
    card:Add(self:CreateCheckbox(content, "Enable Clean Mode", get, set, TIP.clean))
    get, set = rootSetting("showLootCounts", deps)
    card:Add(dims(deps, self:CreateCheckbox(content, "Show Item Totals", get, set,
        hasWarbandBank() and TIP.totalsWarband or TIP.totals), function() return c().cleanMode end), { dependent = true })
    get, set = rootSetting("showMoneyIcons", deps)
    card:Add(dims(deps, self:CreateCheckbox(content, "Use Coin Icons", get, set, TIP.coins),
        function() return c().cleanMode or (c().framedLoot and c().mergeRows) end), { dependent = true })
    if addon.LootToastsAvailable and addon:LootToastsAvailable() then
        card:Add(self:CreateCheckbox(content, "Hide Blizzard's loot toasts",
            function() return c().hideLootToasts end,
            function(v)
                c().hideLootToasts = v
                addon:ApplyLootToasts()
            end, TIP.toasts))
    end
end

local function combatText(self, content, card, deps, label, key, switch, tip)
    card:Add(dims(deps, self:CreateTextField(content, label,
        function() return config()[key] or "" end,
        function(v)
            config()[key] = v
            repost()
        end, tip), function() return config().notifications[switch] end), { dependent = true })
end

local COMBAT_LINES = {
    { "xp", "Display Experience" },
    { "delver", "Display Delve Companion XP" },
    { "skill", "Display Skill Gains" },
    { "honor", "Display Honor Gains" },
    { "repGain", "Display Reputation Gain" },
    { "repLoss", "Display Reputation Loss" },
}

local function combatCard(self, content, stack, deps)
    local card = stack(self:CreateGroup(content, "Combat Feed"))
    local c = config
    local function line(key, label, tip)
        local get, set = notification(key, deps)
        local row = card:Add(self:CreateCheckbox(content, label, get, set, tip))
        swatch(self, content, row, key, deps, function() return c().notifications[key] end)
    end
    line("combatEnter", "Display Combat Start", TIP.combatStart)
    combatText(self, content, card, deps, "Combat Start Text", "combatEnterText", "combatEnter", TIP.startText)
    line("combatLeave", "Display Combat End", TIP.combatEnd)
    combatText(self, content, card, deps, "Combat End Text", "combatLeaveText", "combatLeave", TIP.endText)
    for i, l in ipairs(COMBAT_LINES) do
        line(l[1], l[2])
        if i == 1 then
            local get, set = rootSetting("showFollowerXP", deps)
            card:Add(dims(deps, self:CreateCheckbox(content, "Show Combat Follower XP", get, set, TIP.follower),
                function() return c().notifications.xp end), { dependent = true })
        end
    end
end

ui:RegisterTab({
    id     = "notifications",
    title  = "Notifications",
    order  = 30,
    icon   = ui:Texture("icon-tracker"),
    footer = Settings.FeedFooter,
    build  = function(self, content)
        local stack = Settings.CardStack()
        local deps = {}
        deps.sync = function()
            for _, d in ipairs(deps) do self:SetDependent(d.control, d.on() and true or false) end
        end
        content._sync = deps.sync
        itemLootCard(self, content, stack, deps)
        moneyCard(self, content, stack, deps)
        hideCard(self, content, stack, deps)
        lootFeedCard(self, content, stack, deps)
        combatCard(self, content, stack, deps)
        deps.sync()
    end,
    refresh = function(_, content)
        if content._sync then content._sync() end
    end,
})
