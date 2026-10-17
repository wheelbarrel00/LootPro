local _, ns = ...
local addon = ns.addon
local Settings = ns.Settings
local ui = Settings.ui

ui:RegisterTab({
    id    = "block",
    title = "Block",
    order = 70,
    icon  = Settings.Icon("icon-block"),
    build = function(self, content)
        Settings.ListCard(self, content, Settings.CardStack(), {
            label = "Block List",
            tip = "Items whose name contains any word below are hidden from the loot feed, yours and your group's. Matching ignores letter case and takes part of a name. Blocked items still count in the session recap, and watch and rare drop alerts still fire on them.",
            addLabel = "Add Word",
            addTip = "Type a word or name and press Enter, or shift-click an item into the box. Any item whose name contains it is hidden.",
            cap = 50,
            empty = "Nothing blocked yet. Add a word above.",
            items = function() return addon:BlockList() end,
            add = function(text) return addon:BlockAdd(text) end,
            remove = function(i) return addon:BlockRemove(i) end,
        })
    end,
})
