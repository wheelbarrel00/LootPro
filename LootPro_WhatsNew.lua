local _, ns = ...
local addon = ns.addon
local Settings = ns.Settings
local ui = Settings.ui

local WhatsNew = {}
ns.WhatsNew = WhatsNew

local WIDTH, HEIGHT = 600, 560
local PAD_TOP, PAD_SIDE, PAD_BOTTOM = 20, 24, 24
local HEAD_GAP, SECTION_GAP = 6, 16
local FOOTER_H, BAR_ROOM = 56, 10
local GOLD = "|cffffd100"
local FEATURES = "New Features"
local LINK = "addon:LootPro:whatsnew"

local function changelog() return ns.about and ns.about.changelog or {} end

local function latest()
    local c = changelog()
    return c[1] and c[1].version
end

local function mode() return (LootProConfig and LootProConfig.whatsNewMode) or "popup" end

local function indexOf(version)
    for i, release in ipairs(changelog()) do
        if release.version == version then return i end
    end
end

-- A version this build does not list comes from a newer one rolled back, which had told the player everything
local function toldUpTo(marker)
    if (marker or "") == "" then return math.huge end
    return indexOf(marker) or 1
end

-- A release either notice has covered counts as told, so a switch between popup and chat never repeats or skips one
local function unseen()
    local stop = math.min(toldUpTo(LootProConfig.whatsNewSeen), toldUpTo(LootProConfig.whatsNewAnnounced))
    local out = {}
    for i, release in ipairs(changelog()) do
        if i >= stop then break end
        out[#out + 1] = release
    end
    return out
end

local function hasFeatures(list)
    for _, release in ipairs(list) do
        for _, sec in ipairs(release.sections or {}) do
            if sec.head == FEATURES then return true end
        end
    end
    return false
end

local function colorCode(name)
    local r, g, b = ui:Color(name)
    return ("|cff%02x%02x%02x"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

-- A block per release, because a block measures all its lines again for every line added
local function fill(content, releases)
    local blocks = {}
    local function block()
        local b = ui:CreateTextBlock(content)
        local prev = blocks[#blocks]
        if prev then
            b:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -SECTION_GAP)
            b:SetPoint("TOPRIGHT", prev, "BOTTOMRIGHT", 0, -SECTION_GAP)
        else
            b:SetPoint("TOPLEFT", content, "TOPLEFT", PAD_SIDE, -PAD_TOP)
            b:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PAD_SIDE, -PAD_TOP)
        end
        blocks[#blocks + 1] = b
        return b
    end
    local bright, muted = colorCode("text"), colorCode("muted")
    local function lit(s) return bright .. s .. "|r" end
    local notes = block()
    notes:AddLine("Missed an update?", "title")
    notes:AddLine(("Every release's full notes live inside the addon: type %s, open the %s page, and read the Changelog there.")
        :format(lit("/lp"), lit("About")), "label", { gap = HEAD_GAP })
    local several = #releases > 1
    for _, release in ipairs(releases) do
        notes = block()
        if several then
            local date = release.date and ("   " .. muted .. "(" .. release.date .. ")|r") or ""
            notes:AddLine("Loot Pro " .. release.version .. date, "title")
        end
        for _, sec in ipairs(release.sections or {}) do
            notes:AddLine(sec.head or "", "groupLabel", { gap = several and HEAD_GAP or SECTION_GAP })
            for _, item in ipairs(sec.items or {}) do
                if type(item) == "string" then notes:AddLine(item, "label", { bullet = "-", gap = HEAD_GAP }) end
            end
        end
    end
    notes = block()
    notes:AddLine("Prefer quiet updates?", "title")
    notes:AddLine(("Switch these notices to a clickable chat link, or turn them off, under %s > %s > %s, or tick \"Don't show these again\" below.")
        :format(lit("/lp"), lit("General"), lit("After an update")), "label", { gap = HEAD_GAP })
    notes:AddLine("Thanks for using Loot Pro!", "title", { gap = SECTION_GAP })
    notes:AddLine("Found a bug or have an idea? Use the Discord button at the top of this window.", "label", { gap = HEAD_GAP })
    return blocks
end

local frame, pending, restoreMode

local function build(releases)
    if frame then return frame end
    local f = ui:CreateWindow({ name = "LootProWhatsNew", title = "What's New", width = WIDTH, height = HEIGHT })
    f:SetSection("Loot Pro " .. (latest() or ""))
    f:AddHeaderButton("icon-discord", "Join our Discord", "Click to copy the invite link.", function() addon:ShowDiscord() end)
    -- An ancestor hide (Alt-Z, a cinematic) fires OnHide with the window still shown, and is not a close
    f:HookScript("OnHide", function(self)
        if self:IsShown() then return end
        if LootProConfig then LootProConfig.whatsNewSeen = latest() end
    end)

    local area = ui:CreateScrollArea(f.body, {})
    area:SetPoint("TOPLEFT", f.body, "TOPLEFT")
    area:SetPoint("BOTTOMRIGHT", f.body, "BOTTOMRIGHT", 0, FOOTER_H)
    local blocks = fill(area.content, releases)

    local footer = CreateFrame("Frame", nil, f.body)
    footer:SetPoint("BOTTOMLEFT")
    footer:SetPoint("BOTTOMRIGHT")
    footer:SetHeight(FOOTER_H)
    footer._controls = {}
    ui:Paint(footer, "chrome", "divider", "T")

    f.dontShow = ui:CreateCheckbox(footer, "Don't show these again",
        function() return mode() == "none" end,
        function(on)
            if not LootProConfig then return end
            -- Unticking puts back the mode the player had this session, so a chat-link player is not moved to the popup
            local m = mode()
            if on and m ~= "none" then restoreMode = m end
            LootProConfig.whatsNewMode = on and "none" or restoreMode or "popup"
            Settings.Redraw()
        end,
        "Stops What's New notices entirely. You can turn them back on under /lp > General > After an update.")
    f.dontShow:SetPoint("LEFT", footer, "LEFT", PAD_SIDE, 0)

    f.gotIt = ui:CreateButton(footer, "Got it", nil, function() f:Hide() end, nil, "primary")
    f.gotIt:SetPoint("RIGHT", footer, "RIGHT", -PAD_SIDE, 0)
    f.options = ui:CreateButton(footer, "Open Settings", nil, function()
        f:Hide()
        Settings.Open()
    end)
    f.options:SetPoint("RIGHT", f.gotIt, "LEFT", -ui:Spacing("buttonGap"), 0)

    -- Text measured while hidden can be short of the text as drawn, so it is measured again once shown
    local function layout()
        local h = PAD_TOP + PAD_BOTTOM + SECTION_GAP * (#blocks - 1)
        for _, b in ipairs(blocks) do h = h + b:Measure() end
        local w = area.scroll:GetWidth() or 0
        if w <= 0 then w = WIDTH - BAR_ROOM end
        area:SetContentSize(w, h)
        f.gotIt:Fit()
        f.options:Fit()
    end
    layout()
    -- General writes the mode too, so the box is read again on every open
    f:HookScript("OnShow", function()
        f.dontShow:Refresh()
        C_Timer.After(0, layout)
    end)
    frame = f
    return f
end

local function show(releases)
    local f = build(releases)
    f:Show()
    -- Over the settings window, whose General page opens it
    f:Raise()
end

function WhatsNew.Show()
    if not latest() then return end
    local list = pending or unseen()
    if #list == 0 then list = { changelog()[1] } end
    show(list)
end

function WhatsNew.Refresh()
    if frame and frame:IsShown() then frame.dontShow:Refresh() end
end

-- The game hands an addon link to SetItemRef and draws nothing for it, so a click on ours opens the notes here
hooksecurefunc("SetItemRef", function(link)
    if link == LINK then WhatsNew.Show() end
end)

local function announce(list)
    pending = list
    local link = "|H" .. LINK .. "|h" .. GOLD .. "[See what's new]|r|h"
    DEFAULT_CHAT_FRAME:AddMessage(("%sLoot Pro|r updated to %s - %s"):format(GOLD, latest(), link))
    LootProConfig.whatsNewAnnounced = latest()
end

-- A first install never gets here: InitSettings marks the newest release told, and the welcome greets the player
function WhatsNew.OnLogin()
    if not (LootProConfig and latest()) then return end
    local m, list = mode(), unseen()
    -- A release with only fixes waits unmarked, so the next one with new features lists it too
    if m == "none" or not hasFeatures(list) then return end
    if m == "chat" then announce(list) else show(list) end
end

-- Only the newest release counts as unseen, so the next login treats it as a fresh update
function WhatsNew.ResetSeen()
    local previous = changelog()[2]
    LootProConfig.whatsNewSeen = previous and previous.version or ""
    LootProConfig.whatsNewAnnounced = ""
end

function WhatsNew.Welcome()
    Settings.ShowDialog({
        text     = "Thanks for installing Loot Pro. Open the settings to choose what your loot and combat feeds show, and where they sit.",
        button1  = "Open Settings",
        button2  = "Close",
        onAccept = function() Settings.Open() end,
    })
end
