local _, ns = ...
local addon = ns.addon
local Settings = ns.Settings
local ui = Settings.ui

local QUALITY = {
    { value = 2, label = "Uncommon+" },
    { value = 3, label = "Rare+" },
    { value = 4, label = "Epic+" },
    { value = 5, label = "Legendary+" },
}

local TIP = {
    rareCard = "Rare drop alerts fire on your own loot. Turn on at least one of these for the triggers below to do anything.",
    rareColor = "Paints an alerting drop's loot line in its item quality color.",
    rareFlash = "Flashes the loot feed in the drop's quality color.",
    rareSound = "Plays the sound below when one of your drops alerts.",
    triggers = "What makes a drop alert. Any one of them is enough. They need at least one way to alert, above.",
    threshold = "Alerts on any drop of this quality or better.",
    notable = "Mounts, pets, and toys trigger the alert even below the quality threshold.",
    upgradeAlert = "Weapons and armor with a higher item level than what you have equipped in that slot trigger the alert, even below the quality threshold. Uses the same check as the (upgrade) marker, whether or not the marker is on.",
    value = "Fires the rare-drop alert when a single drop's sell value is at least this many gold. Set 0 to turn it off.",
    ilvlAlert = "Fires the rare-drop alert when a weapon or armor piece you loot is at least this item level, whatever its quality. Set 0 to turn it off.",
    testRare = "Flashes the loot feed as a rare drop would, and plays the alert sound if it is on. It flashes even while Flash the loot frame is off.",
    markers = "Tags added to gear lines in the loot feed. They mark a drop without firing an alert.",
    ilvl = "Adds the item level in the loot feed, as [485], to every weapon or armor piece looted. Applies to your own drops and the group's.",
    newApp = "Adds a (new look) tag in the loot feed to gear whose appearance you haven't collected from any source yet.",
    upgrade = "Adds an (upgrade) tag in the loot feed when you loot weapon or armor with a higher item level than what you have equipped in that slot (same armor or weapon type).",
    tertiary = "Some weapons and armor roll a bonus \"tertiary\" stat: Leech, Avoidance, Speed, or Indestructible. This tags those drops in the loot feed and names the stat, so you can spot them before vendoring.",
    track = "Adds the upgrade track and level to looted weapons and armor in the loot feed, as (Hero 4/6). The track decides how far a piece can be upgraded. Gear that can't be upgraded gets no tag.",
    trackGroup = "Also tags the upgrade track on gear other players in your group loot. Off by default, so only your own drops are tagged.",
    specRetail = "When you enter a dungeon, raid, or delve while your loot specialization is set to a different spec than the one you are playing, Loot Pro shows a banner and a chat message. It never changes your loot spec for you.",
    specMists = "When you enter a dungeon or raid while your loot specialization is set to a different spec than the one you are playing, Loot Pro shows a banner and a chat message. It never changes your loot spec for you.",
}

local NUMBER_WIDTH = 140

local function config() return LootProConfig end
local function rare() return LootProConfig.rareAlert end

local function dims(deps, control, on)
    deps[#deps + 1] = { control = control, on = on }
    return control
end

local function box(self, content, label, read, write, tip, deps)
    return self:CreateCheckbox(content, label, read, function(v)
        write(v)
        deps.sync()
    end, tip)
end

local function rareBox(self, content, label, key, tip, deps)
    return box(self, content, label, function() return rare()[key] end, function(v) rare()[key] = v end, tip, deps)
end

local function rootBox(self, content, label, key, tip, deps)
    return box(self, content, label, function() return config()[key] end, function(v) config()[key] = v end, tip, deps)
end

local function number(self, content, label, maxLetters, read, write, tip)
    local holder = self:CreateTextField(content, label,
        function() return read() end,
        function(v) write(tonumber(v) or 0) end, tip, { numeric = true, maxLetters = maxLetters })
    holder.field:ClearAllPoints()
    holder.field:SetWidth(NUMBER_WIDTH)
    holder:SetLabelWidth(ui:Spacing("labelColumn"))
    return holder
end

local function alertsCard(self, content, stack, deps)
    local card = stack(self:CreateGroup(content, "Rare Drop Alerts"))
    self:AttachTooltip(card.label, "Rare Drop Alerts", TIP.rareCard)
    card:Add(rareBox(self, content, "Color loot line by rarity", "color", TIP.rareColor, deps))
    card:Add(rareBox(self, content, "Flash the loot frame", "flash", TIP.rareFlash, deps))
    card:Add(rareBox(self, content, "Play alert sound", "sound", TIP.rareSound, deps))
    card:Add(dims(deps, Settings.SoundDropdown(self, content, "rareAlert"), function() return rare().sound end),
        { dependent = true })
end

local function triggersCard(self, content, stack, deps)
    local card = stack(self:CreateGroup(content, "Triggers"))
    self:AttachTooltip(card.label, "Triggers", TIP.triggers)
    -- A trigger only colors the line, flashes the feed or plays the sound, so with all three off it does nothing
    local function anyOutput()
        local ra = rare()
        return ra.color or ra.flash or ra.sound
    end
    card:Add(dims(deps, self:CreateDropdown(content, "Alert on quality", QUALITY,
        function() return rare().threshold end, function(v) rare().threshold = v end, TIP.threshold), anyOutput))
    card:Add(dims(deps, rareBox(self, content, "Also alert on notable items", "notable", TIP.notable, deps), anyOutput))
    if addon.IS_RETAIL then
        card:Add(dims(deps, rareBox(self, content, "Also alert on gear upgrades", "upgrade", TIP.upgradeAlert, deps),
            anyOutput))
    end
    card:Add(dims(deps, number(self, content, "Alert on value (gold, 0 = off)", 9,
        function() return math.floor((rare().value or 0) / 10000) end,
        function(gold) rare().value = gold * 10000 end, TIP.value), anyOutput))
    card:Add(dims(deps, number(self, content, "Alert on item level (0 = off)", 4,
        function() return rare().ilvl or 0 end,
        function(ilvl) rare().ilvl = ilvl end, TIP.ilvlAlert), anyOutput))
end

local function markersCard(self, content, stack, deps)
    local card = stack(self:CreateGroup(content, "Gear Markers"))
    self:AttachTooltip(card.label, "Gear Markers", TIP.markers)
    card:Add(rootBox(self, content, "Show item level on gear", "lootIlvl", TIP.ilvl, deps))
    if not addon.IS_RETAIL then return end
    card:Add(rootBox(self, content, "Mark new transmog appearances", "newAppearance", TIP.newApp, deps))
    card:Add(rootBox(self, content, "Mark gear upgrades", "lootUpgrade", TIP.upgrade, deps))
    card:Add(rootBox(self, content, "Mark gear with a tertiary stat", "tertiaryStat", TIP.tertiary, deps))
    card:Add(rootBox(self, content, "Show upgrade track on gear", "upgradeTrack", TIP.track, deps))
    card:Add(dims(deps, rootBox(self, content, "Include the group's loot", "upgradeTrackGroup", TIP.trackGroup, deps),
        function() return config().upgradeTrack end), { dependent = true })
end

local function specCard(self, content, stack, deps)
    if not addon:LootSpecsAvailable() then return end
    local card = stack(self:CreateGroup(content, "Loot Spec"))
    card:Add(rootBox(self, content, "Warn when my loot spec isn't my current spec", "lootSpecReminder",
        addon.IS_RETAIL and TIP.specRetail or TIP.specMists, deps))
end

ui:RegisterTab({
    id     = "rare",
    title  = "Rare Drops",
    order  = 60,
    icon   = Settings.Icon("icon-rare"),
    footer = function(self, bar)
        local test = self:CreateButton(bar, "Test Rare Drop", nil, function() addon:RareTest() end, TIP.testRare)
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
        triggersCard(self, content, stack, deps)
        markersCard(self, content, stack, deps)
        specCard(self, content, stack, deps)
        deps.sync()
    end,
    refresh = function(_, content)
        if content._sync then content._sync() end
    end,
})
