local _, ns = ...
local addon = ns.addon
local Settings = ns.Settings
local ui = Settings.ui

local TIP = {
    recap = "Tracks the gold, items, currency and notable drops of this play session. Turning it on or off starts a fresh session.",
    looted = "Adds how many of an item you looted this session to its tooltip. Needs the session recap on, because nothing is counted while it is off.",
    owned = "Adds whether you already own a mount, pet, or toy to its tooltip.",
    session = "Counts reset when you log out or press Reset Session, and a /reload keeps them. Type /lp recap to print this to chat.",
    notable = "Your epic and better drops this session, newest first, up to ten. Shift-click one to link it in chat.",
    reset = "Starts a fresh session. The gray-selling total on the Vendor page clears with it.",
    pause = "Stops the session clock, so the per-hour rates leave out a break. Loot is still counted while paused.",
    resume = "Starts the session clock again.",
}

local OFF = "Session recap is turned off. Enable it above to start tracking gold, items, currency, and notable drops."
local CAPTIONS = { "Session", "Total gold", "Gold per hour, from loot, quests and vendor", "Items looted" }
local INCOME = { { "questCopper", "Quest rewards" }, { "vendorCopper", "Vendor income" }, { "mailCopper", "Mailbox" },
                 { "tradeCopper", "Trade" } }
local FIG_HEIGHT, FIG_TOP, FIG_GAP, FIG_PAD, FIG_RIGHT, FIG_TAG_GAP, NOTE_HEIGHT = 78, 14, 2, 16, 8, 8, 72

local function config() return LootProConfig end
local function money(copper) return addon:RecapFormatMoney(copper) end

local footer = {}

local function paintFooter()
    if not footer.reset then return end
    local paused = addon:RecapIsPaused()
    footer.pause:SetShown(not paused)
    footer.resume:SetShown(paused)
    footer.reset:ClearAllPoints()
    footer.reset:SetPoint("RIGHT", paused and footer.resume or footer.pause, "LEFT", -ui:Spacing("buttonGap"), 0)
    local on = config().recapEnabled and true or false
    for _, b in ipairs({ footer.reset, footer.pause, footer.resume }) do ui:SetDependent(b, on) end
end

local function buildFooter(self, bar)
    local function pause()
        addon:RecapPauseToggle()
        Settings.Redraw()
    end
    footer.pause = self:CreateButton(bar, "Pause Timer", nil, pause, TIP.pause)
    footer.resume = self:CreateButton(bar, "Resume Timer", nil, pause, TIP.resume)
    footer.reset = self:CreateButton(bar, "Reset Session", nil, function()
        addon:RecapReset()
        Settings.Redraw()
    end, TIP.reset)
    footer.pause:SetPoint("RIGHT")
    footer.resume:SetPoint("RIGHT")
    bar._controls[#bar._controls + 1] = { Refresh = paintFooter }
    paintFooter()
end

local function figures(self, content, card)
    local f = CreateFrame("Frame", nil, content)
    f._euiFill = true
    f:SetHeight(FIG_HEIGHT)
    f.cells = {}
    for i, caption in ipairs(CAPTIONS) do
        local cell = CreateFrame("Frame", nil, f)
        local pad = i > 1 and FIG_PAD or 0
        cell.value = self:CreateText(cell, "", "figure")
        cell.value:SetPoint("TOPLEFT", pad, -FIG_TOP)
        cell.caption = self:CreateText(cell, caption, "hint")
        cell.caption:SetPoint("TOPLEFT", cell.value, "BOTTOMLEFT", 0, -FIG_GAP)
        cell.caption:SetPoint("RIGHT", cell, "RIGHT", -FIG_RIGHT, 0)
        cell.caption:SetWordWrap(true)
        if i > 1 then self:Paint(cell, nil, "divider", "L") end
        f.cells[i] = cell
    end
    f.tag = self:CreateTag(f.cells[1], "paused", "outline")
    f.tag:SetPoint("LEFT", f.cells[1].value, "RIGHT", FIG_TAG_GAP, 0)
    function f.Fit()
        local w = (f:GetWidth() or 0) / #f.cells
        for i, cell in ipairs(f.cells) do
            cell:ClearAllPoints()
            cell:SetPoint("TOPLEFT", f, "TOPLEFT", (i - 1) * w, 0)
            cell:SetSize(w, FIG_HEIGHT)
        end
        f.tag:Fit()
    end
    f.Fit()
    local fits = content._euiFit or {}
    content._euiFit = fits
    fits[#fits + 1] = f
    card:Add(f, { height = FIG_HEIGHT })
    return f
end

local function textRow(self, content, card, label)
    local row = self:CreateTextRow(content, label, "")
    row.text:SetTextColor(ui:Color("text"))
    card:Add(row, { height = ui:Spacing("listRowHeight") })
    return row
end

local function offNote(self, content, card)
    local f = CreateFrame("Frame", nil, content)
    f._euiFill = true
    f:SetHeight(NOTE_HEIGHT)
    f.text = self:CreateText(f, OFF, "label")
    f.text:SetTextColor(ui:Color("muted"))
    f.text:SetPoint("LEFT")
    f.text:SetPoint("RIGHT")
    f.text:SetJustifyH("CENTER")
    f.text:SetWordWrap(true)
    card:Add(f, { height = NOTE_HEIGHT })
    return f
end

local function notableRow(self, content, card)
    local row = CreateFrame("Button", nil, content)
    row._euiFill = true
    row:SetHeight(ui:Spacing("listRowHeight"))
    row:RegisterForClicks("LeftButtonUp")
    row.text = self:CreateText(row, "", "label")
    row.text:SetTextColor(ui:Color("text"))
    row.text:SetPoint("LEFT")
    row.text:SetWordWrap(false)
    row:SetScript("OnClick", function(b)
        if b.link and HandleModifiedItemClick then HandleModifiedItemClick(b.link) end
    end)
    row:SetScript("OnEnter", function(b)
        if not (b.link and b.link:find("|Hitem:", 1, true)) then return end
        GameTooltip:SetOwner(b, "ANCHOR_NONE")
        GameTooltip:SetPoint("BOTTOMLEFT", b.text, "TOPLEFT", 0, 4)
        GameTooltip:SetHyperlink(b.link)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    card:Add(row, { height = ui:Spacing("listRowHeight") })
    return row
end

local function qualityText(s)
    if s.itemTotal <= 0 then return nil end
    local parts, qc = {}, ITEM_QUALITY_COLORS
    for _, r in ipairs(addon:RecapRarityList()) do
        local hex = (qc and qc[r.quality] and qc[r.quality].hex) or "|cFFFFFFFF"
        parts[#parts + 1] = hex .. r.count .. " " .. r.name .. "|r"
    end
    return table.concat(parts, ", ")
end

local function build(self, content)
    local stack, restack = Settings.CardStack()
    local p = { rows = {}, currencies = {}, notables = {} }

    local top = stack(self:CreateGroup(content, "Session Recap"))
    top:Add(self:CreateCheckbox(content, "Enable Session Recap",
        function() return config().recapEnabled end,
        function(v)
            config().recapEnabled = v
            addon:RecapReset()
            Settings.Redraw()
        end, TIP.recap))
    p.looted = self:CreateCheckbox(content, "Show \"looted this session\" on item tooltips",
        function() return config().tooltipLoots end, function(v) config().tooltipLoots = v end, TIP.looted)
    top:Add(p.looted, { dependent = true })
    if addon.IS_RETAIL then
        top:Add(self:CreateCheckbox(content, "Show \"already owned\" on mount, pet, and toy tooltips",
            function() return config().tooltipCollected end, function(v) config().tooltipCollected = v end, TIP.owned))
    end

    p.session = stack(self:CreateGroup(content, "This Session"))
    self:AttachTooltip(p.session.label, "This Session", TIP.session)
    p.off = offNote(self, content, p.session)
    p.figs = figures(self, content, p.session)
    local rows = p.rows
    rows.zone = textRow(self, content, p.session, "Zone")
    rows.looted = textRow(self, content, p.session, "Gold looted")
    for _, income in ipairs(INCOME) do rows[income[1]] = textRow(self, content, p.session, income[2]) end
    rows.perHour = textRow(self, content, p.session, "Items per hour")
    rows.quality = textRow(self, content, p.session, "By quality")

    p.currencyCard = stack(self:CreateGroup(content, "Currencies"))
    p.notableCard = stack(self:CreateGroup(content, "Notable Drops"))
    self:AttachTooltip(p.notableCard.label, "Notable Drops", TIP.notable)

    local seen
    local function paintClock()
        p.figs.cells[1].value:SetText(addon:RecapFormatDuration(addon:RecapElapsed()))
        p.figs.tag:SetShown(addon:RecapIsPaused())
    end

    local function paintCurrencies(s)
        local n = 0
        for _, id in ipairs(s.currencyOrder) do
            local e = s.currencies[id]
            if e then
                n = n + 1
                local row = p.currencies[n] or textRow(self, content, p.currencyCard, "")
                p.currencies[n] = row
                local name = e.name or ("#" .. id)
                row.label:SetText(e.icon and ("|T" .. e.icon .. ":16:16|t " .. name) or name)
                row.text:SetText("+" .. e.amount)
                row:Show()
            end
        end
        for i = n + 1, #p.currencies do p.currencies[i]:Hide() end
        return n
    end

    local function paintNotables(s)
        local n = #s.notable
        for i = 1, n do
            local row = p.notables[i] or notableRow(self, content, p.notableCard)
            p.notables[i] = row
            row.link = s.notable[n - i + 1]
            row.text:SetText(row.link)
            row:Show()
        end
        for i = n + 1, #p.notables do p.notables[i]:Hide() end
        return n
    end

    local function paint()
        local on = config().recapEnabled and true or false
        self:SetDependent(p.looted, on)
        local s = addon:RecapGetSession()
        seen = s.version
        p.off:SetShown(not on)
        p.figs:SetShown(on)
        local currencies, notables = 0, 0
        if on then
            paintClock()
            local earned, total = addon:RecapGoldTotals()
            local elapsed = addon:RecapElapsed()
            local hourly = elapsed >= 60
            p.figs.cells[2].value:SetText(money(total))
            p.figs.cells[3].value:SetText(hourly and money(math.floor(earned / elapsed * 3600)) or "-")
            p.figs.cells[4].value:SetText(tostring(s.itemTotal))
            rows.zone.text:SetText(s.zone or "")
            rows.looted.text:SetText("+" .. money(s.copper))
            rows.perHour.text:SetText(hourly and tostring(math.floor(s.itemTotal / elapsed * 3600)) or "")
            local byQuality = qualityText(s)
            rows.quality.text:SetText(byQuality or "")
            rows.zone:SetShown(s.zone ~= nil)
            rows.looted:Show()
            for _, income in ipairs(INCOME) do
                local copper = s[income[1]] or 0
                rows[income[1]].text:SetText("+" .. money(copper))
                rows[income[1]]:SetShown(copper > 0)
            end
            rows.perHour:SetShown(hourly)
            rows.quality:SetShown(byQuality ~= nil)
            currencies, notables = paintCurrencies(s), paintNotables(s)
        else
            for _, row in pairs(rows) do row:Hide() end
            for _, row in ipairs(p.currencies) do row:Hide() end
            for _, row in ipairs(p.notables) do row:Hide() end
        end
        p.currencyCard:SetShown(currencies > 0)
        p.notableCard:SetShown(notables > 0)
        for _, card in ipairs({ top, p.session, p.currencyCard, p.notableCard }) do card:Layout() end
        restack()
        self:MeasureContent(content)
    end

    -- A child of the page, so it stops ticking while the page is hidden
    local ticker = CreateFrame("Frame", nil, content)
    local wait = 0
    ticker:SetScript("OnUpdate", function(_, dt)
        wait = wait + dt
        if wait < 1 then return end
        wait = 0
        if not config().recapEnabled then return end
        if addon:RecapGetSession().version ~= seen then paint() else paintClock() end
    end)
    content._paint = paint
    paint()
end

ui:RegisterTab({
    id      = "recap",
    title   = "Recap",
    order   = 40,
    icon    = ui:Texture("icon-stats"),
    footer  = buildFooter,
    build   = build,
    refresh = function(_, content)
        if content._paint then content._paint() end
    end,
})
