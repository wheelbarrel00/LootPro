local addonName, ns = ...
local addon = ns.addon
local Settings = ns.Settings
local ui = Settings.ui

local COMMANDS = {
    { "/lp", "Open or close the Loot Pro window" },
    { "/lp recap", "Print the session recap to chat" },
    { "/lp recap reset", "Reset the session recap" },
    { "/lp pause", "Pause or resume the session timer" },
    { "/lp whatsnew", "Reopen the What's New window" },
    { "/lp about", "Open this About page" },
    { "/lp help", "List the commands" },
}

-- What each client reports as WOW_PROJECT_ID
local CLIENTS = { [1] = "Retail", [2] = "Classic Era", [5] = "TBC Anniversary", [18] = "WoW Forever",
                  [19] = "Mists of Pandaria Classic" }

local function about() return ns.about or {} end

local function colorCode(name)
    local r, g, b = ui:Color(name)
    return ("|cff%02x%02x%02x"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local function introCard(self, content, push)
    local card = push(self:CreateGroup(content, nil))
    local links = about().links or {}
    -- Read from the TOC so About matches the packaged build
    local version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version"))
        or addon.VERSION or "?"
    local client = CLIENTS[WOW_PROJECT_ID]
    local block = self:CreateTextBlock(content)
    block:AddLine("Loot Pro", "title")
    block:AddLine(version .. "    by Wheelbarrel00" .. (client and ("    -    " .. client) or ""), "hint")
    block:AddLine("A clean replacement for World of Warcraft's loot and combat text, with a session recap, watched-item "
        .. "alerts, gear markers, a block list and automatic gray selling.")
    card:Add(block, { fitHeight = true })
    Settings.ButtonRow(self, content, card, {
        { "Join our Discord", function() addon:ShowDiscord() end },
        { "CurseForge", function() addon:ShowURL(links.curseforge) end },
        { "GitHub", function() addon:ShowURL(links.github) end },
        { "Report a Bug", function() addon:ShowURL(links.bug) end },
        { "What's New", function() ns.WhatsNew.Show() end },
    })
end

local function commandsCard(self, content, push)
    local card = push(self:CreateGroup(content, "Commands"))
    for _, c in ipairs(COMMANDS) do
        local row = self:CreateTextRow(content, c[1], c[2])
        row.label:SetTextColor(ui:Color("text"))
        card:Add(row, { height = ui:Spacing("listRowHeight") })
    end
    local tip = self:CreateTextBlock(content)
    tip:AddLine("Tip: click the Loot Pro minimap button to open settings. Left, right, and middle clicks are each "
        .. "configurable on the General page.", "hint")
    card:Add(tip, { fitHeight = true })
end

local function noteCard(self, content, push, title, text, style)
    local card = push(self:CreateGroup(content, title))
    local block = self:CreateTextBlock(content)
    block:AddLine(text, style)
    card:Add(block, { fitHeight = true })
end

local function addonsCard(self, content, push)
    local card = push(self:CreateGroup(content, "More Add-ons by Wheelbarrel00"))
    for _, a in ipairs(about().moreAddons or {}) do
        local row = self:CreateTextRow(content, a.name, "")
        row.label:SetTextColor(ui:Color("text"))
        card:Add(row)
        -- On the row's text column, which the card moves past its widest name in any client font
        local prev
        for _, link in ipairs({ { "CurseForge", a.cf }, { "GitHub", a.gh } }) do
            if link[2] then
                local url = link[2]
                local b = self:CreateButton(content, link[1], nil, function() addon:ShowURL(url) end, nil, "ghost")
                if prev then b:SetPoint("LEFT", prev, "RIGHT", ui:Spacing("buttonGap"), 0) else b:SetPoint("LEFT", row.text, "LEFT", 0, 0) end
                prev = b
            end
        end
    end
end

local function thanksLine()
    local names = about().thanks or {}
    if #names == 0 then return nil end
    local bright = colorCode("text")
    return "Thanks to " .. bright .. table.concat(names, "|r and " .. bright) .. "|r for beta testing."
end

local function changelogCard(self, content, push)
    local card = push(self:CreateGroup(content, "Changelog"))
    local muted = colorCode("muted")
    -- A raise here would leave the window blank, so an entry or a line the changelog got wrong is skipped
    for _, entry in ipairs(about().changelog or {}) do
        if type(entry.version) == "string" then
            local block = self:CreateTextBlock(content)
            block:AddLine(entry.version .. "   " .. muted .. (entry.date or "") .. "|r", "value")
            for _, sec in ipairs(entry.sections or {}) do
                block:AddLine(sec.head or "", "groupLabel", { gap = 10 })
                for _, item in ipairs(sec.items or {}) do
                    if type(item) == "string" then block:AddLine(item, "label", { bullet = "-" }) end
                end
            end
            card:Add(block, { fitHeight = true })
        end
    end
    local older = about().changelogURL
    if older then
        Settings.ButtonRow(self, content, card, { { "Older versions on CurseForge", function() addon:ShowURL(older) end } },
            "ghost")
    end
end

ui:RegisterTab({
    id    = "about",
    title = "About",
    order = 90,
    icon  = ui:Texture("icon-about"),
    build = function(self, content)
        local push = Settings.CardStack()
        introCard(self, content, push)
        commandsCard(self, content, push)
        noteCard(self, content, push, "Tutorials", "Video tutorials coming soon.", "hint")
        addonsCard(self, content, push)
        local thanks = thanksLine()
        if thanks then noteCard(self, content, push, "Thanks", thanks) end
        changelogCard(self, content, push)
    end,
})
