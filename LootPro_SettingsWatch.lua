local _, ns = ...
local addon = ns.addon
local Settings = ns.Settings
local ui = Settings.ui

local TIP = {
    watchEnable = "Shows the watched item banner when you loot an item on the list below.",
    watchSound = "Plays the sound below with the banner.",
    watchList = "Alerts fire when you loot a watched item. Name entries match any item containing that text, links and IDs match exactly.",
    watchAdd = "Type an item's name or ID and press Enter, or shift-click an item into the box. A name matches any item whose name contains it. An ID or a shift-clicked item matches that item only.",
    testAlert = "Shows the watched item banner, and plays the alert sound if it is on.",
}

local function watch() return LootProConfig.watchlist end

local function alertsCard(self, content, stack, deps)
    local card = stack(self:CreateGroup(content, "Watch Alerts"))
    card:Add(self:CreateCheckbox(content, "Enable Watch Alerts",
        function() return watch().enabled end,
        function(v)
            watch().enabled = v
            deps.sync()
        end, TIP.watchEnable))
    local sound = self:CreateCheckbox(content, "Play Alert Sound",
        function() return watch().sound end,
        function(v)
            watch().sound = v
            deps.sync()
        end, TIP.watchSound)
    deps[#deps + 1] = { control = sound, on = function() return watch().enabled end }
    card:Add(sound)
    local pick = Settings.SoundDropdown(self, content, "watchlist")
    deps[#deps + 1] = { control = pick, on = function() return watch().enabled and watch().sound end }
    card:Add(pick, { dependent = true })
end

ui:RegisterTab({
    id     = "watch",
    title  = "Watch",
    order  = 50,
    icon   = Settings.Icon("icon-watch"),
    footer = function(self, bar)
        local test = self:CreateButton(bar, "Test Alert", nil, function()
            addon:WatchAlert({ label = "|cFFA335EE[Test Item]|r" }, nil, "Test Item")
        end, TIP.testAlert)
        test:SetPoint("RIGHT")
    end,
    build  = function(self, content)
        local stack = Settings.CardStack()
        local deps = {}
        deps.sync = function()
            for _, d in ipairs(deps) do self:SetDependent(d.control, d.on() and true or false) end
        end
        content._sync = deps.sync
        alertsCard(self, content, stack, deps)
        Settings.ListCard(self, content, stack, {
            label = "Watch List", tip = TIP.watchList, addLabel = "Add Item", addTip = TIP.watchAdd, cap = 30,
            empty = "No watched items yet. Add one above.", watch = true,
            items = function() return addon:WatchList() end,
            add = function(text) return addon:WatchAdd(text) end,
            remove = function(i) return addon:WatchRemove(i) end,
        })
        deps.sync()
    end,
    refresh = function(_, content)
        if content._sync then content._sync() end
    end,
})
