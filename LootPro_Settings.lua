local _, ns = ...
local addon = ns.addon

local EUI = LibStub("EverythingUI-1.0")
local ACCENT = EUI.tokens.accents.LootPro
local MEDIA = "Interface\\AddOns\\LootPro\\Media\\Textures\\"

local Settings = {}
ns.Settings = Settings

local ui = EUI:NewContext({
    id         = "LootPro",
    title      = "Loot Pro",
    version    = addon.VERSION,
    accent     = ACCENT.accent,
    accentText = ACCENT.accentText,
    L          = {},
    tooltip    = function() return GameTooltip end,
    discord    = function() addon:ShowDiscord() end,
    labels     = {
        discord         = "Join our Discord",
        discordTipTitle = "Join our Discord",
        discordTip      = "Click to copy the invite link.",
        testSound       = "Plays the currently selected sound.",
        clear           = "Clear",
    },
    getLastTab     = function() return LootProConfig and LootProConfig.lastSettingsPage end,
    setLastTab     = function(id) if LootProConfig then LootProConfig.lastSettingsPage = id end end,
    getWindowScale = function() return LootProConfig and LootProConfig.uiScale end,
    setWindowScale = function(v) if LootProConfig then LootProConfig.uiScale = v end end,
})
Settings.ui = ui

function Settings.Icon(name)
    return MEDIA .. name
end

-- Field by field, because the library raises on a field it does not know
function Settings.ShowDialog(opts)
    ui:ShowDialog({
        title       = "Loot Pro",
        text        = opts.text,
        button1     = opts.button1,
        button2     = opts.button2,
        onAccept    = opts.onAccept,
        onCancel    = opts.onCancel,
        hasEditBox  = opts.hasEditBox and true or nil,
        maxLetters  = opts.maxLetters,
        editBoxText = opts.editBoxText,
        readOnly    = opts.readOnly and true or nil,
        danger      = opts.danger and true or nil,
    })
end

function Settings.ShowURL(url, intro)
    if not url or url == "" then return end
    Settings.ShowDialog({
        text        = (intro and (intro .. "\n\n") or "") .. "Press Ctrl+C to copy, then Escape to close.",
        button1     = "Close",
        hasEditBox  = true,
        readOnly    = true,
        editBoxText = url,
    })
end

function addon:ShowDiscord()
    Settings.ShowURL(self.DISCORD_URL, "Join the Loot Pro community for help, feedback, and updates.")
end

function addon.ShowURL(_, url)
    Settings.ShowURL(url)
end

-- Each card anchors to the last one shown, so a hidden card leaves no gap
function Settings.CardStack()
    local cards = {}
    local function restack()
        local gap = ui:Spacing("groupGap")
        local prev
        for _, card in ipairs(cards) do
            if card:IsShown() then
                card:ClearAllPoints()
                if prev then
                    card:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -gap)
                    card:SetPoint("TOPRIGHT", prev, "BOTTOMRIGHT", 0, -gap)
                else
                    card:SetPoint("TOPLEFT")
                    card:SetPoint("TOPRIGHT")
                end
                prev = card
            end
        end
    end
    return function(card)
        cards[#cards + 1] = card
        restack()
        return card
    end, restack
end

-- The buttons are the content's children, so the window sizes them again once the page is on screen
function Settings.ButtonRow(self, content, card, list, style)
    local row = CreateFrame("Frame", nil, content)
    row:SetHeight(ui:Spacing("buttonHeight"))
    row._euiFill = true
    local buttons, prev = {}, nil
    for i, b in ipairs(list) do
        local btn = self:CreateButton(content, b[1], nil, b[2], b[3], style)
        if prev then btn:SetPoint("LEFT", prev, "RIGHT", ui:Spacing("buttonGap"), 0) else btn:SetPoint("LEFT", row, "LEFT") end
        buttons[i], prev = btn, btn
    end
    row.buttons = buttons
    card:Add(row)
    return row
end

-- Mapped again only when Watch hands back a new list, which it builds when a media addon registers a sound
local soundSource, soundOptions
local function soundChoices()
    local source = addon.AlertSoundChoices()
    if source ~= soundSource then
        soundSource, soundOptions = source, {}
        for i, name in ipairs(source) do soundOptions[i] = { value = name, label = name } end
    end
    return soundOptions
end

function Settings.SoundDropdown(self, content, key)
    local function play() addon:PlayAlertSound(key) end
    return self:CreateDropdown(content, "Sound", soundChoices,
        function() return LootProConfig[key].soundName or "Default" end,
        function(v)
            LootProConfig[key].soundName = v
            play()
        end, "The sound to play. Picking one plays it, and the speaker plays it again.", nil, play)
end

local LIST_ROW, LIST_ICON, LIST_GAP, NAME_MAX = 28, 16, 8, 600
local REMOVE_SIZE, REMOVE_INSET = 24, 8
local COUNT_MIN, COUNT_GAP, ADD_GAP = 64, 14, 10
local QUESTION_MARK_ICON = 134400
local _GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local _GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

local function entryRow(self, list, i, watch, onRemove)
    local pad = ui:Spacing("rowPadding")
    -- Out past the card's inset to its edges, so the line between entries spans the card
    local row = CreateFrame("Frame", nil, list)
    row:SetHeight(LIST_ROW)
    row:SetPoint("TOPLEFT", list, "TOPLEFT", -pad, -(i - 1) * LIST_ROW)
    row:SetPoint("TOPRIGHT", list, "TOPRIGHT", pad, -(i - 1) * LIST_ROW)
    if i > 1 then self:Paint(row, nil, "divider", "T") end
    local left = pad
    if watch then
        row.slot = CreateFrame("Frame", nil, row)
        row.slot:SetSize(LIST_ICON, LIST_ICON)
        row.slot:SetPoint("LEFT", pad, 0)
        self:Paint(row.slot, "track", "borderStrong")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(LIST_ICON, LIST_ICON)
        row.icon:SetPoint("LEFT", pad, 0)
        left = pad + LIST_ICON + LIST_GAP
    end
    -- A name typed in another alphabet takes the client's own font object, which a SetFont would drop
    row.plain = self:CreateText(row, "", "label")
    row.data = row:CreateFontString(nil, "OVERLAY")
    row.data:SetFontObject(GameFontHighlight)
    row.data:SetShadowOffset(0, 0)
    for _, fs in ipairs({ row.plain, row.data }) do
        fs:SetPoint("LEFT", left, 0)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(false)
    end
    if watch then row.tag = self:CreateTag(row, "contains", "outline") end
    row.remove = self:CreateIconButton(row, "close", REMOVE_SIZE)
    row.remove:SetPoint("RIGHT", -REMOVE_INSET, 0)
    row.remove:SetScript("OnClick", function() onRemove(row.index) end)
    self:AttachTooltip(row.remove, "Remove", "Removes this entry.")
    return row
end

-- True while the client has yet to load the item, whose quality then arrives with GET_ITEM_INFO_RECEIVED
local function paintEntry(row, e, watch, failed)
    local text, pending = e.label or e.key or "?", false
    local r, g, b = ui:Color("text")
    if watch and e.id then
        local name, quality
        if _GetItemInfo and not failed[e.id] then name, _, quality = _GetItemInfo(e.id) end
        text = name or text
        local qc = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
        if qc then r, g, b = qc.r, qc.g, qc.b end
        pending = quality == nil and not failed[e.id]
        local icon = _GetItemInfoInstant and select(5, _GetItemInfoInstant(e.id))
        row.icon:SetTexture(e.icon or icon or QUESTION_MARK_ICON)
    end
    local useData = ui:NeedsClientFont(text)
    local fs = useData and row.data or row.plain
    row.plain:SetShown(not useData)
    row.data:SetShown(useData)
    fs:SetText(text)
    fs:SetTextColor(r, g, b)
    fs:SetWidth(0)
    if (fs:GetStringWidth() or 0) > NAME_MAX then fs:SetWidth(NAME_MAX) end
    if watch then
        local item = e.id ~= nil
        row.icon:SetShown(item)
        row.slot:SetShown(not item)
        row.tag:SetShown(not item)
        row.tag:ClearAllPoints()
        row.tag:SetPoint("LEFT", fs, "RIGHT", LIST_GAP, 0)
    end
    return pending
end

function Settings.ListCard(self, content, stack, spec)
    local card = stack(self:CreateGroup(content, spec.label))
    self:AttachTooltip(card.label, spec.label, spec.tip)
    local draft, message = "", nil
    local count, paint

    local function paintCount()
        count:SetText(message or (#spec.items() .. " of " .. spec.cap))
        count:SetTextColor(ui:Color(message and "danger" or "muted"))
        count:SetWidth(0)
        if (count:GetStringWidth() or 0) < COUNT_MIN then count:SetWidth(COUNT_MIN) end
    end

    local function setDraft(v)
        draft = v
        if message then
            message = nil
            paintCount()
        end
    end

    local addRow = self:CreateTextField(content, spec.addLabel, function() return draft end, setDraft, spec.addTip,
        { live = true, maxLetters = 200 })

    local function tryAdd()
        local ok, reason = spec.add(draft)
        if ok then
            draft, message = "", nil
            addRow:SetText("")
        elseif reason == "full" then
            message = ("The list is full (%d)"):format(spec.cap)
        elseif reason == "dupe" then
            message = "Already on the list"
        end
        paint()
    end

    local button = self:CreateButton(content, "Add", nil, tryAdd)
    count = self:CreateText(addRow, "", "hint")
    count:SetJustifyH("RIGHT")
    count:SetPoint("RIGHT", addRow, "RIGHT")
    button:SetPoint("RIGHT", count, "LEFT", -COUNT_GAP, 0)
    -- The row takes the mouse for its tooltip, so Add sits a level above it to get its own clicks
    button:SetFrameLevel(addRow:GetFrameLevel() + 1)
    addRow.field:SetPoint("RIGHT", button, "LEFT", -ADD_GAP, 0)
    addRow.box:HookScript("OnEnterPressed", tryAdd)
    if hooksecurefunc and HandleModifiedItemClick then
        hooksecurefunc("HandleModifiedItemClick", function(link)
            if link and addRow.box:HasFocus() and IsShiftKeyDown() then
                -- A SetText from code reaches no setter, so the draft is kept here too
                addRow:SetText(link)
                setDraft(link)
            end
        end)
    end

    local list = CreateFrame("Frame", nil, content)
    list._euiFill = true
    list:SetHeight(LIST_ROW)
    local empty = self:CreateText(list, spec.empty, "label")
    empty:SetTextColor(ui:Color("muted"))
    empty:SetPoint("LEFT")
    card:Add(addRow)
    card:Add(list, { height = LIST_ROW })

    local rows, waiter, waiting, failed = {}, nil, {}, {}
    local function onRemove(index)
        spec.remove(index)
        message = nil
        paint()
    end
    local function paintEntries()
        wipe(waiting)
        local pending = false
        for i, e in ipairs(spec.items()) do
            if rows[i] and paintEntry(rows[i], e, spec.watch, failed) then
                waiting[e.id] = true
                pending = true
            end
        end
        return pending
    end
    -- An ID the client reports it cannot find never resolves, so it is not asked for again
    local function onItemInfo(_, _, itemID, success)
        if not waiting[itemID] then return end
        if success == false then failed[itemID] = true end
        if not (list:IsVisible() and paintEntries()) then waiter:UnregisterEvent("GET_ITEM_INFO_RECEIVED") end
    end

    paint = function()
        local items = spec.items()
        for i = 1, #items do
            rows[i] = rows[i] or entryRow(self, list, i, spec.watch, onRemove)
            rows[i].index = i
            rows[i]:Show()
        end
        for i = #items + 1, #rows do rows[i]:Hide() end
        empty:SetShown(#items == 0)
        local h = math.max(1, #items) * LIST_ROW
        list:SetHeight(h)
        list._euiRow:SetHeight(h)
        card:Layout()
        self:MeasureContent(content)
        paintCount()
        -- The library paints a page before it shows it, so the listener is armed while the list is still hidden
        if paintEntries() then
            if not waiter then
                waiter = CreateFrame("Frame", nil, list)
                waiter:SetScript("OnEvent", onItemInfo)
            end
            pcall(waiter.RegisterEvent, waiter, "GET_ITEM_INFO_RECEIVED")
        end
    end
    list.Refresh, list.entries = paint, rows
    content._controls[#content._controls + 1] = list
    -- Measured again once the page is on screen, where a string reads its drawn width
    local fits = content._euiFit or {}
    content._euiFit = fits
    fits[#fits + 1] = { Fit = paintCount }
    paint()
    return card, addRow, list
end

-- Every page reads its settings through its getters, so a change made elsewhere only draws the shown page again
function Settings.Redraw()
    local f = Settings.frame
    if f and f:IsShown() and ui._current then ui:SelectTab(ui._current) end
end

-- A reset replaces LootProConfig whole, the window scale included. ResetDefaults draws the shown page again itself.
function Settings.ResetAll()
    addon:ResetDefaults()
    ui:ApplyWindowScale()
end

-- Vendor calls this after a sale and the recap after a reset, and either changes what Recap and Vendor show
function addon.VendorRefreshSession()
    Settings.Redraw()
end

-- Each page with the feed footer has its own pair, and every pair shows the same state
local testButtons = {}

local function paintTest()
    local on = addon.isTesting and true or false
    for _, pair in ipairs(testButtons) do
        pair.start:SetShown(not on)
        pair.stop:SetShown(on)
    end
end

local function startTest()
    if addon.isTesting then return end
    addon.isTesting = true
    addon.combatFrame.display:SetFading(false)
    addon.lootFrame.display:SetFading(false)
    addon:PostTestMessages()
    paintTest()
end

local function stopTest()
    if not addon.isTesting then return end
    addon.isTesting = false
    addon:UpdateAllVisuals()
    addon.combatFrame.display:Clear()
    addon.lootFrame.display:Clear()
    addon:ClearFramedRows()
    paintTest()
end

local function setLocked(locked)
    LootProConfig.locked = locked
    addon:UpdateAllVisuals()
end

function Settings.FeedFooter(self, bar)
    local unlock = self:CreateCheckbox(bar, "Unlock Windows",
        function() return not LootProConfig.locked end,
        function(v) setLocked(not v) end,
        "Unlocks the loot and combat feeds so you can drag them into place. They lock again when this window closes.")
    unlock:SetPoint("LEFT")
    local tip = "Fills both feeds with sample lines in your current settings, so you can see each change as you make it. Stops when this window closes."
    local pair = {
        start = self:CreateButton(bar, "Start Test Mode", nil, startTest, tip),
        stop  = self:CreateButton(bar, "Stop Test Mode", nil, stopTest, tip, "primary"),
    }
    pair.start:SetPoint("RIGHT")
    pair.stop:SetPoint("RIGHT")
    testButtons[#testButtons + 1] = pair
    bar._controls[#bar._controls + 1] = { Refresh = paintTest }
    paintTest()
end

local function lockAndStopTest(f)
    -- An ancestor hide (Alt-Z, a cinematic) fires OnHide with the window still shown, and is not a close
    if f:IsShown() or not LootProConfig then return end
    if not LootProConfig.locked then setLocked(true) end
    stopTest()
end

function Settings.Toggle()
    if not addon:IsReady() then return end
    if not Settings.frame then
        local f = ui:BuildSettings("LootProSettings")
        -- Unlocked feeds and test lines are for setting up, so leaving the window ends both
        f:HookScript("OnHide", lockAndStopTest)
        Settings.frame = f
    end
    ui:ToggleSettings()
end

function Settings.Open(page)
    if not (Settings.frame and Settings.frame:IsShown()) then Settings.Toggle() end
    if page and Settings.frame and Settings.frame:IsShown() then ui:SelectTab(page) end
end
