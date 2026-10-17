local _, ns = ...
local addon = ns.addon
local Settings = ns.Settings
local ui = Settings.ui

local TIP = {
    autoSell = "When you open a merchant, every poor-quality (gray) item in your bags is sold automatically. Quest items and no-value items are never sold. Hold your auto-loot key (Shift by default) as you open a merchant to skip it for that visit.",
    interval = "Delay between each item sold. A longer interval is gentler and makes the progress bar easier to follow. Sell Grays Now uses it too.",
    progress = "Shows an on-screen bar counting the sale, for automatic selling and for Sell Grays Now.",
    details = "Lists every item sold in chat, for automatic selling and for Sell Grays Now.",
    sellTip = "Adds the sell price to item tooltips, plus the full stack value when you hover a stack in your bags.",
    vendorSession = "The merchant's own Sell All Junk button sells everything at once. This adds automatic, paced selling with an optional on-screen progress bar. The session total covers automatic and Sell Grays Now sales, and clears when the session recap does.",
    sellNow = "Sells every gray item in your bags now, at the interval above. Current vendor value: %s. Requires an open merchant window.",
}

local WARN_HEIGHT, SESSION_HEIGHT = 32, 44

local function vendor() return LootProConfig.vendorGrays end

local function vendorBox(self, content, label, key, tip, after)
    return self:CreateCheckbox(content, label,
        function() return vendor()[key] end,
        function(v)
            vendor()[key] = v
            if after then after() end
        end, tip)
end

local function line(self, content, card, height, style, color, dependent)
    local f = CreateFrame("Frame", nil, content)
    f._euiFill = true
    f:SetHeight(height)
    f.text = self:CreateText(f, "", style)
    f.text:SetTextColor(ui:Color(color))
    f.text:SetPoint("LEFT")
    card:Add(f, { height = height, dependent = dependent })
    return f
end

local function intervalText(v)
    return ("%.1fs"):format(v)
end

local function build(self, content)
    local stack = Settings.CardStack()
    local gray, warn, session

    local function paintWarning()
        local other = vendor().enabled and addon.OtherGraySeller and addon.OtherGraySeller()
        warn.text:SetText(other and (other .. "'s Vendor Grays is also on, and holding Shift won't stop it.") or "")
        warn:SetShown(other and true or false)
        gray:Layout()
    end

    gray = stack(self:CreateGroup(content, "Gray Items"))
    gray:Add(vendorBox(self, content, "Automatically sell gray items at vendors", "enabled", TIP.autoSell, function()
        paintWarning()
        self:MeasureContent(content)
    end))
    warn = line(self, content, gray, WARN_HEIGHT, "hint", "danger", true)
    gray:Add(self:CreateSlider(content, "Sell Interval", 0.1, 1, 0.1,
        function() return vendor().interval or 0.2 end,
        function(v)
            -- Snap to the nearest 0.1 (float steps can land on 0.30000004).
            vendor().interval = math.floor(v * 10 + 0.5) / 10
        end, TIP.interval, intervalText).EnableTyping())
    gray:Add(vendorBox(self, content, "Show progress bar while selling", "progressBar", TIP.progress))
    gray:Add(vendorBox(self, content, "Print each item sold to chat", "details", TIP.details))

    local tips = stack(self:CreateGroup(content, "Item Tooltips"))
    tips:Add(self:CreateCheckbox(content, "Show vendor sell price on item tooltips",
        function() return LootProConfig.tooltipSell end, function(v) LootProConfig.tooltipSell = v end, TIP.sellTip))

    local sessionCard = stack(self:CreateGroup(content, "This Session"))
    self:AttachTooltip(sessionCard.label, "This Session", TIP.vendorSession)
    session = line(self, content, sessionCard, SESSION_HEIGHT, "label", "text")

    content._paint = function()
        local sold, gold = addon:VendorSessionTotals()
        session.text:SetText(sold > 0
            and ("Sold %d gray item%s for %s."):format(sold, sold == 1 and "" or "s", addon:RecapFormatMoney(gold))
            or "No gray items sold yet this session.")
        paintWarning()
        self:MeasureContent(content)
    end
    content._paint()
end

-- Each hover otherwise runs a full bag scan, and the bags cannot meaningfully change inside a second.
local valueAt, valueText
local function sellTip()
    local now = GetTime()
    if not valueText or now - valueAt > 1 then
        valueAt = now
        valueText = addon:RecapFormatMoney(addon:VendorGrayValue())
    end
    return TIP.sellNow:format(valueText)
end

ui:RegisterTab({
    id      = "vendor",
    title   = "Vendor",
    order   = 80,
    icon    = Settings.Icon("icon-vendor"),
    footer  = function(self, bar)
        local sell = self:CreateButton(bar, "Sell Grays Now", nil, function() addon:VendorStart(true) end)
        sell:SetPoint("RIGHT")
        sell:HookScript("OnEnter", function(b) self:ShowTooltip(b, "Sell Grays Now", sellTip()) end)
        sell:HookScript("OnLeave", function() self:HideTooltip() end)
    end,
    build   = build,
    refresh = function(_, content)
        if content._paint then content._paint() end
    end,
})
