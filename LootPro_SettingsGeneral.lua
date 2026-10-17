local _, ns = ...
local addon = ns.addon
local Settings = ns.Settings
local ui = Settings.ui

local MINIMAP_ACTIONS = {
    { value = "settings", label = "Open Settings" },
    { value = "recap",    label = "Print Recap" },
    { value = "lock",     label = "Toggle Lock" },
    { value = "none",     label = "Nothing" },
}

local MINIMAP_CLICKS = {
    { key = "leftClick",   label = "Left Click" },
    { key = "rightClick",  label = "Right Click" },
    { key = "middleClick", label = "Middle Click" },
}

-- Fast Loot is the game's autoLootDefault CVar, which persists on its own. "enableQuickLoot" is not a real CVar, which is why an older build's toggle never stuck.
local function getAutoLoot()
    if C_CVar and C_CVar.GetCVarBool then return C_CVar.GetCVarBool("autoLootDefault") end
    if GetCVarBool then return GetCVarBool("autoLootDefault") end
    return (GetCVar and GetCVar("autoLootDefault") == "1") or false
end

local function setAutoLoot(on)
    local v = on and "1" or "0"
    if C_CVar and C_CVar.SetCVar then C_CVar.SetCVar("autoLootDefault", v)
    elseif SetCVar then SetCVar("autoLootDefault", v) end
end

local function lootingCard(self, content, stack)
    local card = stack(self:CreateGroup(content, "Looting"))
    card:Add(self:CreateCheckbox(content, "Fast Loot", getAutoLoot, setAutoLoot,
        "Grabs everything from a corpse in a single click instead of opening the loot window. This is the game's built-in Auto Loot setting."))
    card:Add(self:CreateCheckbox(content, "Speedy AutoLoot",
        function() return LootProConfig.speedyAutoLoot end,
        function(v) LootProConfig.speedyAutoLoot = v end,
        "Auto-loots every item the moment loot is available, so the loot window never opens, even when Fast Loot is off. Hold your auto-loot key (default Shift) to open the window manually."))
end

local function minimapCard(self, content, stack)
    local card = stack(self:CreateGroup(content, "Minimap Button"))
    card:Add(self:CreateCheckbox(content, "Show Minimap Icon",
        function() return not LootProConfig.minimap.hide end,
        function(v)
            LootProConfig.minimap.hide = not v
            addon:UpdateAllVisuals()
        end,
        "Shows Loot Pro's button on the minimap. The clicks below also work from a data broker display."))
    for _, click in ipairs(MINIMAP_CLICKS) do
        local key = click.key
        card:Add(self:CreateDropdown(content, click.label, MINIMAP_ACTIONS,
            function() return LootProConfig.minimap[key] end,
            function(v) LootProConfig.minimap[key] = v end))
    end
end

local function percent(v)
    return ("%d%%"):format(math.floor(v + 0.5))
end

-- In percent, so a typed 110 means 110%. The saved uiScale stays a fraction.
local function windowCard(self, content, stack)
    local card = stack(self:CreateGroup(content, "Options Window"))
    local scale = self:CreateSlider(content, "Scale", 75, 125, 5,
        function() return math.floor((LootProConfig.uiScale or 1) * 100 + 0.5) end,
        function(v) LootProConfig.uiScale = v / 100 end,
        "Resizes this settings window only. To resize the loot or combat feeds, use the Frame Scale sliders on the Layout page.",
        percent).EnableTyping()
    card:Add(scale)
    -- The slider sits inside the window it scales, so applying SetScale live during a drag fights the drag and snaps to the ends. Preview the percent live and apply the scale on release.
    local function apply() self:ApplyWindowScale() end
    scale.slider:HookScript("OnMouseUp", apply)
    scale.entry:HookScript("OnEnterPressed", apply)
end

local UPDATE_MODES = {
    { value = "popup", label = "Popup window" },
    { value = "chat",  label = "Chat link" },
    { value = "none",  label = "Off" },
}

local function updatesCard(self, content, stack)
    local card = stack(self:CreateGroup(content, "Updates"))
    card:Add(self:CreateRadioGroup(content, "After an update", UPDATE_MODES,
        function() return LootProConfig.whatsNewMode end,
        function(v)
            LootProConfig.whatsNewMode = v
            ns.WhatsNew.Refresh()
        end, nil, nil, "After an update",
        "How Loot Pro tells you about a new version: a Popup window, a quiet clickable Chat link in your chat, or Off. Reopen the notes any time with /lp whatsnew."))
    Settings.ButtonRow(self, content, card, { { "Show What's New", function() ns.WhatsNew.Show() end, "Opens the notes for this version." } })
end

local function footer(self, bar)
    local reset = self:CreateButton(bar, "Reset All Settings", nil, function()
        Settings.ShowDialog({
            text     = "Reset all Loot Pro settings to defaults?\n\nThis clears your watch list, block list, colors, window layout, and every toggle. It cannot be undone.",
            button1  = "Reset",
            button2  = "Cancel",
            danger   = true,
            onAccept = Settings.ResetAll,
        })
    end, "Resets every Loot Pro setting to its default, including your watch list, block list, colors and window layout. Asks first.", "danger")
    reset:SetPoint("RIGHT")
end

ui:RegisterTab({
    id     = "general",
    title  = "General",
    order  = 10,
    icon   = ui:Texture("icon-general"),
    footer = footer,
    build  = function(self, content)
        local stack = Settings.CardStack()
        lootingCard(self, content, stack)
        minimapCard(self, content, stack)
        windowCard(self, content, stack)
        updatesCard(self, content, stack)
    end,
})
