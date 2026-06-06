local addonName, ns = ...
local addon = ns.addon
local U = ns.U

ns.UI = {}

-- v2.2.9: Restyled to match the Everything Delves visual style — flat
-- near-black background with a thin red border, custom title and close
-- button, flat ED-style tab row, and red/gold buttons. All widget logic
-- and saved variables are unchanged; this is shell-only chrome.
--
-- BackdropTemplate is required on both retail and BCC (the 2021 client
-- shares the Shadowlands-era SetBackdrop change), so we use the same
-- flat backdrop on every supported client — no template fork.
local function CreateVersionedMainFrame(name, parent)
    local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.95)        -- #0D0D0D
    f:SetBackdropBorderColor(0.427, 0.020, 0.004, 1.0) -- #6D0501
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    return f
end

-- ED-style flat close button (top-right "X").
local function CreateCloseButton(parent)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(20, 20)
    b:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -6)
    b:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    b:SetBackdropColor(0.30, 0.00, 0.00, 0.80)
    b:SetBackdropBorderColor(0.427, 0.020, 0.004, 1.0)

    local lbl = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("CENTER", 0, 1)
    lbl:SetFont(lbl:GetFont(), 12, "OUTLINE")
    lbl:SetText("|cFFFFFFFFX|r")

    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.55, 0.05, 0.05, 1.0)
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.30, 0.00, 0.00, 0.80)
    end)
    b:SetScript("OnClick", function() parent:Hide() end)
    return b
end

-- ED-style flat red/gold action button. Returns a Button with `.label`
-- font string, plus injected `SetText` / `GetFontString` shims so call
-- sites that used GameMenuButtonTemplate keep working unchanged.
local function CreateStyledButton(parent, width, height, label)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.427, 0.020, 0.004, 1.0)        -- #6D0501
    btn:SetBackdropBorderColor(0.10, 0.00, 0.00, 1.0)

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetFont(text:GetFont(), 11)
    text:SetText(label or "")
    text:SetTextColor(0.922, 0.718, 0.024, 1.0)            -- #EBB706
    btn.label = text

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.541, 0.024, 0.004, 1.0)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.427, 0.020, 0.004, 1.0)
    end)

    btn.SetText = function(self, t) self.label:SetText(t) end
    btn.GetFontString = function(self) return self.label end
    return btn
end

function ns.UI:Initialize()
    -- Widened from 560 to 600 to fit the seventh tab (Vendor) on the row
    -- without clipping. Pages are centered, so the extra width is just margin.
    local gui = CreateVersionedMainFrame("LootProGUI", UIParent)
    gui:SetSize(600, 680)
    gui:SetPoint("CENTER")
    gui:Hide()

    -- ED parity: Escape closes the settings window.
    tinsert(UISpecialFrames, "LootProGUI")

    CreateCloseButton(gui)

    gui.title = gui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    gui.title:SetPoint("TOP", gui, "TOP", 0, -18)
    gui.title:SetFont(gui.title:GetFont(), 25, "OUTLINE")
    gui.title:SetText("|cFFFF2222Loot Pro|r")

    -- Version label, top-right next to the close button (ED parity).
    -- closeBtn is anchored TOPRIGHT (-6,-6) with 20px width, so we place
    -- the version string just to its left.
    local verLabel = gui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    verLabel:SetPoint("TOPRIGHT", gui, "TOPRIGHT", -30, -10)
    verLabel:SetFont(verLabel:GetFont(), 11)
    verLabel:SetText("|cFF999999v" .. addon.VERSION .. "|r")

    -- "Join our Discord!" link, top-left -- mirrors the version label on the
    -- right and flanks the centered title. The Discord logo chip sits before
    -- the text as a brand accent; text uses the #FF2222 accent (matches the
    -- title and section headers). Click pops a copyable invite
    -- (addon:ShowDiscord) -- WoW can't open a web browser.
    local discord = CreateFrame("Button", nil, gui)
    discord:SetFrameStrata("HIGH")
    discord.icon = discord:CreateTexture(nil, "OVERLAY")
    discord.icon:SetSize(16, 16)
    discord.icon:SetPoint("LEFT", 0, 0)
    -- White 64x64 TGA with alpha at Media\Textures\discord.tga. If the file
    -- is ever missing, WoW draws a placeholder square -- replace the asset.
    discord.icon:SetTexture("Interface\\AddOns\\LootPro\\Media\\Textures\\discord.tga")
    discord.text = discord:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    discord.text:SetPoint("LEFT", discord.icon, "RIGHT", 5, 0)
    discord.text:SetText("Join our Discord!")
    discord.text:SetTextColor(1.0, 0.133, 0.133)            -- #FF2222
    discord:SetSize(16 + 5 + discord.text:GetStringWidth() + 4, 18)
    discord:SetPoint("TOPLEFT", gui, "TOPLEFT", 14, -12)
    discord:SetScript("OnClick", function() addon:ShowDiscord() end)
    discord:SetScript("OnEnter", function(s)
        s.text:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Join our Discord", 1.0, 0.133, 0.133)
        GameTooltip:AddLine("Click to copy the invite link.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    discord:SetScript("OnLeave", function(s)
        s.text:SetTextColor(1.0, 0.133, 0.133)
        GameTooltip:Hide()
    end)
    gui.discordButton = discord

    local pages = {
        layout = CreateFrame("Frame", nil, gui),
        colors = CreateFrame("Frame", nil, gui),
        notifications = CreateFrame("Frame", nil, gui),
        customization = CreateFrame("Frame", nil, gui),
        recap = CreateFrame("Frame", nil, gui),
        watchlist = CreateFrame("Frame", nil, gui),
        vendor = CreateFrame("Frame", nil, gui)
    }

    for _, p in pairs(pages) do 
        p:SetSize(500, 550) 
        p:SetPoint("TOP", 0, -140) 
        p:Hide() 
    end

    local function ShowPage(name) 
        for k, p in pairs(pages) do 
            if k == name then p:Show() else p:Hide() end 
        end 
    end

    local tabs = {}
    local currentActiveTab = nil

    local function SetActiveTab(activeName)
        currentActiveTab = activeName
        for tName, btn in pairs(tabs) do
            if tName == activeName then
                btn:SetBackdropColor(0.427, 0.020, 0.004, 1.0)
                btn:SetBackdropBorderColor(0.55, 0.02, 0.00, 1.0)
                btn.label:SetText("|cFFFFFFFF" .. btn._labelText .. "|r")
            else
                btn:SetBackdropColor(0.15, 0.15, 0.15, 1.0)
                btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.50)
                btn.label:SetText("|cFFE0E0E0" .. btn._labelText .. "|r")
            end
        end
        ShowPage(activeName)
    end

    -- Hidden font string for measuring tab labels so each tab auto-sizes
    -- to fit its text with consistent padding (matches ED's tab row).
    local measure = gui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    measure:Hide()

    local TAB_HEIGHT  = 28
    local TAB_Y       = -54
    local TAB_PADDING = 4
    local tabIndex    = 0
    local lastTab     = nil

    local function CreateTab(name, label)
        tabIndex = tabIndex + 1
        local tab = CreateFrame("Button", nil, gui, "BackdropTemplate")
        tab:SetHeight(TAB_HEIGHT)

        measure:SetText(label)
        tab:SetWidth(measure:GetStringWidth() + 24)

        if tabIndex == 1 then
            tab:SetPoint("TOPLEFT", gui, "TOPLEFT", 10, TAB_Y)
        else
            tab:SetPoint("LEFT", lastTab, "RIGHT", TAB_PADDING, 0)
        end

        tab:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        tab:SetBackdropColor(0.15, 0.15, 0.15, 1.0)
        tab:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.50)

        local tabLabel = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabLabel:SetPoint("CENTER")
        tabLabel:SetFont(tabLabel:GetFont(), 11)
        tabLabel:SetText("|cFFE0E0E0" .. label .. "|r")
        tab.label = tabLabel
        tab._labelText = label
        tab._tabIndex = tabIndex

        tab:SetScript("OnClick", function() SetActiveTab(name) end)
        tab:SetScript("OnEnter", function(self)
            if self ~= tabs[currentActiveTab] then
                self:SetBackdropColor(0.25, 0.00, 0.00, 0.80)
            end
        end)
        tab:SetScript("OnLeave", function(self)
            if self ~= tabs[currentActiveTab] then
                self:SetBackdropColor(0.15, 0.15, 0.15, 1.0)
            end
        end)

        tabs[name] = tab
        lastTab = tab
        return tab
    end

    CreateTab("layout", "Layout")
    CreateTab("colors", "Colors")
    CreateTab("notifications", "Notifications")
    CreateTab("customization", "Custom")
    CreateTab("recap", "Recap")
    CreateTab("watchlist", "Alerts")
    CreateTab("vendor", "Vendor")

    -- Thin red accent divider below the tab row.
    local divider = gui:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT",  gui, "TOPLEFT",   6, TAB_Y - TAB_HEIGHT - 4)
    divider:SetPoint("TOPRIGHT", gui, "TOPRIGHT", -6, TAB_Y - TAB_HEIGHT - 4)
    divider:SetColorTexture(0.427, 0.020, 0.004, 0.80)

    local lockBtn = CreateStyledButton(gui, 140, 26, LootProConfig.locked and "Unlock Windows" or "Lock Windows")
    lockBtn:SetPoint("TOPLEFT", 25, -100)
    lockBtn:SetScript("OnClick", function() 
        LootProConfig.locked = not LootProConfig.locked 
        addon:UpdateAllVisuals() 
        lockBtn:SetText(LootProConfig.locked and "Unlock Windows" or "Lock Windows") 
    end)

    local testBtn = CreateStyledButton(gui, 140, 26, "Start Test Mode")
    testBtn:SetPoint("TOPRIGHT", -25, -100)
    testBtn:SetScript("OnClick", function() 
        addon.isTesting = not addon.isTesting 
        if addon.isTesting then 
            testBtn:SetText("Stop Test Mode") 
            addon.combatFrame.display:SetFading(false) 
            addon.lootFrame.display:SetFading(false) 
            addon:PostTestMessages()
        else 
            testBtn:SetText("Start Test Mode") 
            addon:UpdateAllVisuals() 
            addon.combatFrame.display:Clear() 
            addon.lootFrame.display:Clear() 
        end
    end)

    gui:SetScript("OnHide", function()
        if not LootProConfig.locked then
            LootProConfig.locked = true
            addon:UpdateAllVisuals()
            lockBtn:SetText("Unlock Windows")
        end
        if addon.isTesting then
            addon.isTesting = false
            testBtn:SetText("Start Test Mode")
            addon:UpdateAllVisuals()
            addon.combatFrame.display:Clear()
            addon.lootFrame.display:Clear()
        end
    end)

    local outList = {{val="NONE",lbl="None"},{val="OUTLINE",lbl="Thin"},{val="THICKOUTLINE",lbl="Thick"},{val="MONOCHROME",lbl="Pixel"}}

    local cSize = U.CreateSlider("LPRO_CS", "Combat Text Size", pages.layout, 10, 50, 1, "size", "combat")
    cSize.label:SetPoint("TOPLEFT", 30, 0); cSize:SetPoint("TOPLEFT", cSize.label, "BOTTOMLEFT", 0, -10); cSize:SetValue(LootProConfig.combat.size)
    local cFade = U.CreateSlider("LPRO_CFA", "Combat Fade (sec)", pages.layout, 1, 30, 1, "fade", "combat")
    cFade.label:SetPoint("TOPLEFT", cSize, "BOTTOMLEFT", 0, -20); cFade:SetPoint("TOPLEFT", cFade.label, "BOTTOMLEFT", 0, -10); cFade:SetValue(LootProConfig.combat.fade)
    local cWidth = U.CreateSlider("LPRO_CW", "Combat Frame Width", pages.layout, 200, 1200, 10, "width", "combat")
    cWidth.label:SetPoint("TOPLEFT", cFade, "BOTTOMLEFT", 0, -20); cWidth:SetPoint("TOPLEFT", cWidth.label, "BOTTOMLEFT", 0, -10); cWidth:SetValue(LootProConfig.combat.width)
    local cHeight = U.CreateSlider("LPRO_CH", "Combat Frame Height", pages.layout, 50, 800, 10, "height", "combat")
    cHeight.label:SetPoint("TOPLEFT", cWidth, "BOTTOMLEFT", 0, -20); cHeight:SetPoint("TOPLEFT", cHeight.label, "BOTTOMLEFT", 0, -10); cHeight:SetValue(LootProConfig.combat.height)
    local cMaxLines = U.CreateSlider("LPRO_CML", "Max Combat Lines", pages.layout, 1, 20, 1, "maxLines", "combat")
    cMaxLines.label:SetPoint("TOPLEFT", cHeight, "BOTTOMLEFT", 0, -20); cMaxLines:SetPoint("TOPLEFT", cMaxLines.label, "BOTTOMLEFT", 0, -10); cMaxLines:SetValue(LootProConfig.combat.maxLines)

    local lSize = U.CreateSlider("LPRO_LS", "Loot Text Size", pages.layout, 10, 50, 1, "size", "loot")
    lSize.label:SetPoint("TOPRIGHT", -50, 0); lSize:SetPoint("TOPRIGHT", lSize.label, "BOTTOMRIGHT", 0, -10); lSize:SetValue(LootProConfig.loot.size)
    local lFade = U.CreateSlider("LPRO_LFA", "Loot Fade (sec)", pages.layout, 1, 30, 1, "fade", "loot")
    lFade.label:SetPoint("TOPRIGHT", lSize, "BOTTOMRIGHT", 0, -20); lFade:SetPoint("TOPRIGHT", lFade.label, "BOTTOMRIGHT", 0, -10); lFade:SetValue(LootProConfig.loot.fade)
    local lWidth = U.CreateSlider("LPRO_LW", "Loot Frame Width", pages.layout, 200, 1200, 10, "width", "loot")
    lWidth.label:SetPoint("TOPRIGHT", lFade, "BOTTOMRIGHT", 0, -20); lWidth:SetPoint("TOPRIGHT", lWidth.label, "BOTTOMRIGHT", 0, -10); lWidth:SetValue(LootProConfig.loot.width)
    local lHeight = U.CreateSlider("LPRO_LH", "Loot Frame Height", pages.layout, 50, 800, 10, "height", "loot")
    lHeight.label:SetPoint("TOPRIGHT", lWidth, "BOTTOMRIGHT", 0, -20); lHeight:SetPoint("TOPRIGHT", lHeight.label, "BOTTOMRIGHT", 0, -10); lHeight:SetValue(LootProConfig.loot.height)
    local lMaxLines = U.CreateSlider("LPRO_LML", "Max Loot Lines", pages.layout, 1, 20, 1, "maxLines", "loot")
    lMaxLines.label:SetPoint("TOPRIGHT", lHeight, "BOTTOMRIGHT", 0, -20); lMaxLines:SetPoint("TOPRIGHT", lMaxLines.label, "BOTTOMRIGHT", 0, -10); lMaxLines:SetValue(LootProConfig.loot.maxLines)

    local syncLayout = CreateStyledButton(pages.layout, 220, 25, "Sync Combat Layout to Loot")
    syncLayout:SetPoint("BOTTOM", 0, 80)
    syncLayout:SetScript("OnClick", function() 
        LootProConfig.loot.size = LootProConfig.combat.size
        LootProConfig.loot.fade = LootProConfig.combat.fade
        LootProConfig.loot.width = LootProConfig.combat.width
        LootProConfig.loot.height = LootProConfig.combat.height
        LootProConfig.loot.maxLines = LootProConfig.combat.maxLines
        lSize:SetValue(LootProConfig.combat.size); lFade:SetValue(LootProConfig.combat.fade); lWidth:SetValue(LootProConfig.combat.width); lHeight:SetValue(LootProConfig.combat.height); lMaxLines:SetValue(LootProConfig.combat.maxLines)
        addon:UpdateAllVisuals() 
    end)

    local colorRows = {}
    local function AddColor(key, title, func)
        local row = U.CreateColorRow("LPRO_CLR_"..title, pages.colors, key, func)
        if #colorRows == 0 then row:SetPoint("TOP", 0, 0) else row:SetPoint("TOP", colorRows[#colorRows], "BOTTOM", 0, -3) end
        table.insert(colorRows, row) 
        row:Refresh()
    end
    
    AddColor("money", "Money", function() return "10 Gold 75 Silver 20 Copper" end)
    AddColor("currency", "Currency", function() return "+ 25 Kej" end)
    -- Use Hearthstone (itemID 6948, icon 134414) -- an evergreen item present
    -- in every client from classic onwards, so the preview is real on retail
    -- and BCC alike.
    AddColor("loot", "Loot", function() return "+1 |T134414:0|t Hearthstone (1)" end)
    AddColor("combatEnter", "Combat Start", function() return LootProConfig.combatEnterText end)
    AddColor("combatLeave", "Combat End", function() return LootProConfig.combatLeaveText end)
    AddColor("xp", "Experience", function() return "+ 1,500 XP" end)
    AddColor("delver", "Delver XP", function() return "+ 125 Delver XP" end)
    AddColor("skill", "Skill", function() return "Blacksmithing (Midnight) (50)" end)
    AddColor("honor", "Honor", function() return "+ 15 Honor" end)
    AddColor("repGain", "Rep Gain", function() return "+ 250 Rep: Silvermoon Court" end)
    AddColor("repLoss", "Rep Loss", function() return "- 25 Rep: Bloodsail Buccaneers" end)

    local resetBtn = CreateStyledButton(gui, 160, 28, "Reset to Defaults")
    resetBtn:SetPoint("BOTTOM", gui, "BOTTOM", 0, 35)
    resetBtn:SetScript("OnClick", function() addon:ResetDefaults() end)
    local stubC = gui:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); stubC:SetPoint("TOP", resetBtn, "BOTTOM", 0, -3); stubC:SetText("Clears all colors, layout, and toggles.")

    local toggles = {}
    local function AddToggle(key, title, colorKey, parentAnchor)
        local cb = CreateFrame("CheckButton", "LPRO_TGL_"..key, pages.notifications, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", parentAnchor, "BOTTOMLEFT", 0, -5)
        local fs = _G[cb:GetName().."Text"]; fs:SetText(title)
        if colorKey and LootProConfig.colors[colorKey] then local c = LootProConfig.colors[colorKey]; fs:SetTextColor(c.r, c.g, c.b) end
        cb:SetChecked(LootProConfig.notifications[key])
        cb:SetScript("OnClick", function(self) LootProConfig.notifications[key] = self:GetChecked(); if addon.isTesting then addon:PostTestMessages() end end)
        toggles[key] = cb return cb
    end

    local moneyT = CreateFrame("CheckButton", "LPRO_TGL_money", pages.notifications, "InterfaceOptionsCheckButtonTemplate")
    moneyT:SetPoint("TOPLEFT", 40, 0); _G[moneyT:GetName().."Text"]:SetText("Display Money")
    local cM = LootProConfig.colors["money"] or {r=1, g=1, b=1}; _G[moneyT:GetName().."Text"]:SetTextColor(cM.r, cM.g, cM.b)
    moneyT:SetChecked(LootProConfig.notifications["money"])
    moneyT:SetScript("OnClick", function(self) LootProConfig.notifications["money"] = self:GetChecked(); if addon.isTesting then addon:PostTestMessages() end end)
    toggles["money"] = moneyT

    local currT = AddToggle("currency", "Display Currency", "currency", moneyT)
    local lootT = AddToggle("loot", "Display Item Loot", "loot", currT)

    local countCheck = CreateFrame("CheckButton", "LPRO_CountToggle_N", pages.notifications, "InterfaceOptionsCheckButtonTemplate")
    countCheck:SetPoint("TOPLEFT", lootT, "BOTTOMLEFT", 0, -5); _G[countCheck:GetName().."Text"]:SetText("Inject Item Totals (e.g. 14)"); countCheck:SetChecked(LootProConfig.showLootCounts)
    countCheck:SetScript("OnClick", function(self) LootProConfig.showLootCounts = self:GetChecked(); if addon.isTesting then addon:PostTestMessages() end end)

    local gIconCheck = CreateFrame("CheckButton", "LPRO_GoldToggle_N", pages.notifications, "InterfaceOptionsCheckButtonTemplate")
    gIconCheck:SetPoint("TOPLEFT", countCheck, "BOTTOMLEFT", 0, -5); _G[gIconCheck:GetName().."Text"]:SetText("Use Coin Icons (Clean Mode only)"); gIconCheck:SetChecked(LootProConfig.showMoneyIcons)
    gIconCheck:SetScript("OnClick", function(self) LootProConfig.showMoneyIcons = self:GetChecked(); if addon.isTesting then addon:PostTestMessages() end end)

    local cleanCheck = CreateFrame("CheckButton", "LPRO_CleanToggle_N", pages.notifications, "InterfaceOptionsCheckButtonTemplate")
    cleanCheck:SetPoint("TOPLEFT", gIconCheck, "BOTTOMLEFT", 0, -5); _G[cleanCheck:GetName().."Text"]:SetText("Enable Clean Mode"); cleanCheck:SetChecked(LootProConfig.cleanMode)
    cleanCheck:SetScript("OnClick", function(self) LootProConfig.cleanMode = self:GetChecked(); if addon.isTesting then addon:PostTestMessages() end end)
    
    local cleanDesc = pages.notifications:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cleanDesc:SetPoint("TOPLEFT", cleanCheck, "BOTTOMLEFT", 25, 0); cleanDesc:SetTextColor(0.6, 0.6, 0.6); cleanDesc:SetText("(Strips text like 'You receive loot:')")

    -- Display Party Loot: suppresses other group members' loot lines while
    -- keeping your own. Anchored so it sits between cleanDesc and xpT in the
    -- left column.
    local partyT = CreateFrame("CheckButton", "LPRO_TGL_partyLoot", pages.notifications, "InterfaceOptionsCheckButtonTemplate")
    partyT:SetPoint("TOPLEFT", cleanDesc, "BOTTOMLEFT", -25, -10)
    local partyFs = _G[partyT:GetName().."Text"]; partyFs:SetText("Display Party Loot")
    local cLoot = LootProConfig.colors["loot"] or {r=1,g=1,b=1}; partyFs:SetTextColor(cLoot.r, cLoot.g, cLoot.b)
    partyT:SetChecked(LootProConfig.notifications["partyLoot"])
    partyT:SetScript("OnClick", function(self) LootProConfig.notifications["partyLoot"] = self:GetChecked(); if addon.isTesting then addon:PostTestMessages() end end)
    toggles["partyLoot"] = partyT

    local cStrT = CreateFrame("CheckButton", "LPRO_TGL_combatEnter", pages.notifications, "InterfaceOptionsCheckButtonTemplate")
    cStrT:SetPoint("TOPLEFT", 285, 0); _G[cStrT:GetName().."Text"]:SetText("Display Combat START")
    local cCE = LootProConfig.colors["combatEnter"] or {r=1, g=1, b=1}; _G[cStrT:GetName().."Text"]:SetTextColor(cCE.r, cCE.g, cCE.b)
    cStrT:SetChecked(LootProConfig.notifications["combatEnter"])
    cStrT:SetScript("OnClick", function(self) LootProConfig.notifications["combatEnter"] = self:GetChecked(); if addon.isTesting then addon:PostTestMessages() end end)
    toggles["combatEnter"] = cStrT

    local cEndT = AddToggle("combatLeave", "Display Combat END", "combatLeave", cStrT)

    -- Round 3: Show Combat Follower XP sits on the RIGHT (under Combat END);
    -- Display Experience sits on the LEFT (under the Clean Mode description).
    -- Both swapped from the Round 2 layout so the column flow reads better.
    local fxpCheck = CreateFrame("CheckButton", "LPRO_FollowerToggle_N", pages.notifications, "InterfaceOptionsCheckButtonTemplate")
    fxpCheck:SetPoint("TOPLEFT", cEndT, "BOTTOMLEFT", 0, -5); _G[fxpCheck:GetName().."Text"]:SetText("Show Combat Follower XP"); fxpCheck:SetChecked(LootProConfig.showFollowerXP)
    fxpCheck:SetScript("OnClick", function(self) LootProConfig.showFollowerXP = self:GetChecked(); if addon.isTesting then addon:PostTestMessages() end end)

    -- Display Experience: inline (rather than AddToggle) so we can chain
    -- directly off the Party Loot checkbox in the left column.
    local xpT = CreateFrame("CheckButton", "LPRO_TGL_xp", pages.notifications, "InterfaceOptionsCheckButtonTemplate")
    xpT:SetPoint("TOPLEFT", partyT, "BOTTOMLEFT", 0, -5)
    local xpFs = _G[xpT:GetName().."Text"]; xpFs:SetText("Display Experience")
    local cXP = LootProConfig.colors["xp"] or {r=1,g=1,b=1}; xpFs:SetTextColor(cXP.r, cXP.g, cXP.b)
    xpT:SetChecked(LootProConfig.notifications["xp"])
    xpT:SetScript("OnClick", function(self) LootProConfig.notifications["xp"] = self:GetChecked(); if addon.isTesting then addon:PostTestMessages() end end)
    toggles["xp"] = xpT

    local delvT = AddToggle("delver", "Display Delve Companion XP", "delver", fxpCheck) 
    local skillT = AddToggle("skill", "Display Skill Gains", "skill", delvT)
    local honorT = AddToggle("honor", "Display Honor Gains", "honor", skillT)
    local repGT = AddToggle("repGain", "Display Reputation GAIN", "repGain", honorT)
    local repLT = AddToggle("repLoss", "Display Reputation LOSS", "repLoss", repGT)

    -- H4: Expose minQuality so users can actually filter loot without hand
    -- editing SavedVariables. Uses quality-color-aware labels.
    local qualityList = {
        {val=0, lbl="Poor+ (All)"},
        {val=1, lbl="Common+"},
        {val=2, lbl="Uncommon+"},
        {val=3, lbl="Rare+"},
        {val=4, lbl="Epic+"},
        {val=5, lbl="Legendary+"},
    }
    local mQual = U.CreateGenericCycler("LPRO_MQ", "Minimum Loot Quality", pages.notifications, qualityList, "minQuality", "root")
    -- Round 3: center under both columns instead of trailing the right column.
    mQual.label:ClearAllPoints()
    mQual.label:SetPoint("TOP", pages.notifications, "TOP", 0, -285)
    mQual.label:SetJustifyH("CENTER")
    mQual:ClearAllPoints()
    mQual:SetPoint("TOP", mQual.label, "BOTTOM", 0, -5)
    mQual:Refresh()

    -- #6: per-class loot-feed filters, below the minimum-quality cycler. These
    -- hide matching classes from the readout; the recap still tallies them.
    local filterHeader = pages.notifications:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterHeader:SetPoint("TOP", pages.notifications, "TOP", 0, -350)
    filterHeader:SetText("Hide from loot feed:")

    local function AddFilter(key, label, x, y)
        local cb = CreateFrame("CheckButton", "LPRO_FILT_"..key, pages.notifications, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", x, y)
        _G[cb:GetName().."Text"]:SetText(label)
        cb:SetChecked(LootProConfig.lootFilters[key])
        cb:SetScript("OnClick", function(self) LootProConfig.lootFilters[key] = self:GetChecked() and true or false end)
        return cb
    end
    local fTrade  = AddFilter("hideTradeGoods", "Trade Goods", 95, -372)
    local fConsum = AddFilter("hideConsumable", "Consumables", 95, -397)
    local fQuest  = AddFilter("hideQuest",      "Quest Items", 280, -372)
    local fRecipe = AddFilter("hideRecipe",     "Recipes",     280, -397)

    local cFont = U.CreateFontDropdown("LPRO_CF", "Combat Font", pages.customization, "combat")
    cFont.label:SetPoint("TOPLEFT", 30, 0); cFont:SetPoint("TOPLEFT", cFont.label, "BOTTOMLEFT", 0, -5)

    local cOut = U.CreateGenericCycler("LPRO_CO", "Combat Outline", pages.customization, outList, "outline", "combat")
    cOut.label:SetPoint("TOPLEFT", cFont, "BOTTOMLEFT", 0, -15); cOut:SetPoint("TOPLEFT", cOut.label, "BOTTOMLEFT", 0, -5)

    local cEntEB = U.CreateEditBox("LPRO_CE", "Combat Start Text (Enter to Save)", pages.customization, "combatEnterText")
    cEntEB.label:SetPoint("TOPLEFT", cOut, "BOTTOMLEFT", 0, -20); cEntEB:SetPoint("TOPLEFT", cEntEB.label, "BOTTOMLEFT", 5, -5)

    local cLveEB = U.CreateEditBox("LPRO_CL", "Combat End Text (Enter to Save)", pages.customization, "combatLeaveText")
    cLveEB.label:SetPoint("TOPLEFT", cEntEB, "BOTTOMLEFT", -5, -15); cLveEB:SetPoint("TOPLEFT", cLveEB.label, "BOTTOMLEFT", 5, -5)

    local mmCheck = CreateFrame("CheckButton", "LPRO_MinimapToggle", pages.customization, "InterfaceOptionsCheckButtonTemplate")
    mmCheck:SetPoint("TOPLEFT", cLveEB, "BOTTOMLEFT", -5, -20)
    _G[mmCheck:GetName().."Text"]:SetText("Show Minimap Icon")
    mmCheck:SetChecked(not LootProConfig.minimap.hide)
    mmCheck:SetScript("OnClick", function(self)
        LootProConfig.minimap.hide = not self:GetChecked()
        addon:UpdateAllVisuals()
    end)

    local qlCheck = CreateFrame("CheckButton", "LPRO_QuickLootToggle", pages.customization, "InterfaceOptionsCheckButtonTemplate")
    qlCheck:SetPoint("TOPLEFT", mmCheck, "BOTTOMLEFT", 0, -5)
    _G[qlCheck:GetName().."Text"]:SetText("Enable Quick Loot")
    qlCheck:SetChecked(GetCVar("enableQuickLoot") == "1")
    qlCheck:SetScript("OnClick", function(cb)
        SetCVar("enableQuickLoot", cb:GetChecked() and "1" or "0")
    end)

    -- #8: currency cap warning toggle.
    local capCheck = CreateFrame("CheckButton", "LPRO_CurrencyCap", pages.customization, "InterfaceOptionsCheckButtonTemplate")
    capCheck:SetPoint("TOPLEFT", qlCheck, "BOTTOMLEFT", 0, -5)
    _G[capCheck:GetName().."Text"]:SetText("Warn on currency cap")
    capCheck:SetChecked(LootProConfig.currencyCap)
    capCheck:SetScript("OnClick", function(self) LootProConfig.currencyCap = self:GetChecked() and true or false end)

    -- #12: per-click minimap actions (three cyclers in a row).
    local mmHeader = pages.customization:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mmHeader:SetPoint("TOPLEFT", capCheck, "BOTTOMLEFT", 4, -14)
    mmHeader:SetText("Minimap Button Clicks:")

    local mmActions = {
        { val = "settings", lbl = "Open Settings" },
        { val = "recap",    lbl = "Print Recap" },
        { val = "lock",     lbl = "Toggle Lock" },
        { val = "none",     lbl = "Nothing" },
    }
    local mmLeft = U.CreateGenericCycler("LPRO_MMLeft", "Left Click", pages.customization, mmActions, "leftClick", "minimap")
    mmLeft.label:ClearAllPoints(); mmLeft.label:SetPoint("TOPLEFT", mmHeader, "BOTTOMLEFT", 0, -8)
    mmLeft:ClearAllPoints(); mmLeft:SetPoint("TOPLEFT", mmLeft.label, "BOTTOMLEFT", 0, -4)

    local mmRight = U.CreateGenericCycler("LPRO_MMRight", "Right Click", pages.customization, mmActions, "rightClick", "minimap")
    mmRight.label:ClearAllPoints(); mmRight.label:SetPoint("LEFT", mmLeft.label, "LEFT", 150, 0)
    mmRight:ClearAllPoints(); mmRight:SetPoint("TOPLEFT", mmRight.label, "BOTTOMLEFT", 0, -4)

    local mmMid = U.CreateGenericCycler("LPRO_MMMid", "Middle Click", pages.customization, mmActions, "middleClick", "minimap")
    mmMid.label:ClearAllPoints(); mmMid.label:SetPoint("LEFT", mmRight.label, "LEFT", 150, 0)
    mmMid:ClearAllPoints(); mmMid:SetPoint("TOPLEFT", mmMid.label, "BOTTOMLEFT", 0, -4)

    local lFont = U.CreateFontDropdown("LPRO_LF", "Loot Font", pages.customization, "loot")
    lFont.label:SetPoint("TOPRIGHT", -50, 0); lFont:SetPoint("TOPRIGHT", lFont.label, "BOTTOMRIGHT", 0, -5); pages.customization.lF = lFont

    local lOut = U.CreateGenericCycler("LPRO_LO", "Loot Outline", pages.customization, outList, "outline", "loot") 
    lOut.label:SetPoint("TOPRIGHT", lFont, "BOTTOMRIGHT", -40, -15); lOut:SetPoint("TOPRIGHT", lOut.label, "BOTTOMRIGHT", 0, -5); pages.customization.lO = lOut

    local syncCustom = CreateStyledButton(pages.customization, 220, 25, "Sync Combat Fonts to Loot")
    syncCustom:SetPoint("BOTTOM", 0, 80)
    syncCustom:SetScript("OnClick", function() 
        LootProConfig.loot.font = LootProConfig.combat.font; LootProConfig.loot.outline = LootProConfig.combat.outline
        pages.customization.lF:Refresh(); pages.customization.lO:Refresh(); addon:UpdateAllVisuals() 
    end)

    -------------------------------------------------
    -- SESSION RECAP TAB
    -------------------------------------------------
    -- Live view of the in-memory session tally maintained by LootPro_Recap.
    -- The header (duration) and body are refreshed on a throttled OnUpdate
    -- that only fires while this page is the active tab, so there is zero
    -- background cost when the GUI is closed or another tab is shown.
    do
        local page = pages.recap

        local recapEnable = CreateFrame("CheckButton", "LPRO_RecapEnable", page, "InterfaceOptionsCheckButtonTemplate")
        recapEnable:SetPoint("TOPLEFT", 26, -6)
        _G[recapEnable:GetName().."Text"]:SetText("Enable Session Recap")
        recapEnable:SetChecked(LootProConfig.recapEnabled)

        local resetSession = CreateStyledButton(page, 130, 24, "Reset Session")
        resetSession:SetPoint("TOPRIGHT", -30, -8)

        local recapHeader = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        recapHeader:SetPoint("TOPLEFT", 30, -40)
        recapHeader:SetText("|cFFFF2222Session:|r 0s")

        local recapBody = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        recapBody:SetPoint("TOPLEFT", 30, -68)
        recapBody:SetWidth(440)
        recapBody:SetJustifyH("LEFT")
        recapBody:SetJustifyV("TOP")
        recapBody:SetSpacing(3)

        local tooltipCheck = CreateFrame("CheckButton", "LPRO_TooltipLoots", page, "InterfaceOptionsCheckButtonTemplate")
        tooltipCheck:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 26, 134)
        _G[tooltipCheck:GetName().."Text"]:SetText("Show \"looted this session\" on item tooltips")
        tooltipCheck:SetScript("OnClick", function(self)
            LootProConfig.tooltipLoots = self:GetChecked() and true or false
        end)

        local recapHint = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        recapHint:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 30, 110)
        recapHint:SetWidth(440)
        recapHint:SetJustifyH("LEFT")
        recapHint:SetText("Counts reset on login, /reload, or Reset Session. Also available via /lp recap.")

        -- Scratch reused across rebuilds. BuildRecapBody returns a finished
        -- string, so the arrays can be wiped and refilled instead of
        -- reallocated each time the body refreshes.
        local _lines, _parts = {}, {}
        local function BuildRecapBody()
            local s = addon:RecapGetSession()
            local lines = _lines
            wipe(lines)
            lines[#lines + 1] = "|cFFFFD700Gold gained:|r  +" .. addon:RecapFormatMoney(s.copper)

            if s.itemTotal > 0 then
                lines[#lines + 1] = "|cFFFFFFFFItems looted:|r  " .. s.itemTotal
                local parts = _parts
                wipe(parts)
                local qc = _G.ITEM_QUALITY_COLORS
                for _, r in ipairs(addon:RecapRarityList()) do
                    local hex = (qc and qc[r.quality] and qc[r.quality].hex) or "|cFFFFFFFF"
                    parts[#parts + 1] = hex .. r.count .. " " .. string.lower(r.name) .. "|r"
                end
                if #parts > 0 then
                    lines[#lines + 1] = "    " .. table.concat(parts, ", ")
                end
            else
                lines[#lines + 1] = "|cFFFFFFFFItems looted:|r  none yet"
            end

            if #s.currencyOrder > 0 then
                lines[#lines + 1] = " "
                for _, id in ipairs(s.currencyOrder) do
                    local e = s.currencies[id]
                    if e then
                        local iconStr = e.icon and ("|T" .. e.icon .. ":0|t ") or ""
                        lines[#lines + 1] = "|cFFA6D8FF" .. (e.name or ("#" .. id)) .. ":|r  +" .. e.amount .. " " .. iconStr
                    end
                end
            end

            if #s.notable > 0 then
                lines[#lines + 1] = " "
                lines[#lines + 1] = "|cFFA335EENotable drops:|r"
                -- newest first
                for i = #s.notable, 1, -1 do
                    lines[#lines + 1] = "    " .. s.notable[i]
                end
            end

            return table.concat(lines, "\n")
        end

        local function RefreshRecap()
            -- Invalidate the OnUpdate header cache so the next tick re-syncs
            -- the duration string after a manual refresh / enable / reset.
            page._lastDur = nil
            if not LootProConfig.recapEnabled then
                recapHeader:SetText("|cFFFF2222Session:|r |cFF888888disabled|r")
                recapBody:SetText("|cFF888888Session recap is turned off. Enable it above to start tracking gold, items, currency, and notable drops.|r")
                return
            end
            recapHeader:SetText("|cFFFF2222Session:|r " .. addon:RecapFormatDuration(addon:RecapElapsed()))
            recapBody:SetText(BuildRecapBody())
        end

        recapEnable:SetScript("OnClick", function(self)
            LootProConfig.recapEnabled = self:GetChecked() and true or false
            -- Fresh session on enable; empties the bounded table on disable.
            addon:RecapReset()
            page._lastVer = -1
            RefreshRecap()
        end)

        resetSession:SetScript("OnClick", function()
            addon:RecapReset()
            page._lastVer = -1
            RefreshRecap()
        end)

        page._lastVer = -1
        page._throttle = 1
        page:SetScript("OnShow", function(self)
            self._lastVer = -1   -- force a body rebuild on (re)entry
            self._throttle = 1
            recapEnable:SetChecked(LootProConfig.recapEnabled)
            tooltipCheck:SetChecked(LootProConfig.tooltipLoots)
            RefreshRecap()
        end)
        page:SetScript("OnUpdate", function(self, dt)
            self._throttle = self._throttle + dt
            if self._throttle < 0.5 then return end
            self._throttle = 0
            if not LootProConfig.recapEnabled then return end
            -- Duration ticks twice a second but only changes once a second, so
            -- skip the concat + SetText when the formatted value is unchanged.
            local dur = addon:RecapFormatDuration(addon:RecapElapsed())
            if self._lastDur ~= dur then
                self._lastDur = dur
                recapHeader:SetText("|cFFFF2222Session:|r " .. dur)
            end
            -- The body is rebuilt only when the session actually changed
            -- (version guard) to avoid string churn.
            local s = addon:RecapGetSession()
            if self._lastVer ~= s.version then
                self._lastVer = s.version
                recapBody:SetText(BuildRecapBody())
            end
        end)
    end

    -------------------------------------------------
    -- ALERTS TAB (watched items + rare-drop alerts)
    -------------------------------------------------
    -- Top section manages watched items; bottom section configures rarity-
    -- based alerts. List rows are pooled and reused across refreshes; the
    -- scroll child only grows to fit the entries.
    do
        local page = pages.watchlist

        local enableCheck = CreateFrame("CheckButton", "LPRO_WatchEnable", page, "InterfaceOptionsCheckButtonTemplate")
        enableCheck:SetPoint("TOPLEFT", 26, -6)
        _G[enableCheck:GetName().."Text"]:SetText("Enable Watch Alerts")
        enableCheck:SetScript("OnClick", function(self)
            LootProConfig.watchlist.enabled = self:GetChecked() and true or false
        end)

        local soundCheck = CreateFrame("CheckButton", "LPRO_WatchSound", page, "InterfaceOptionsCheckButtonTemplate")
        soundCheck:SetPoint("TOPLEFT", 235, -6)
        _G[soundCheck:GetName().."Text"]:SetText("Play Alert Sound")
        soundCheck:SetScript("OnClick", function(self)
            LootProConfig.watchlist.sound = self:GetChecked() and true or false
        end)

        local watchTestBtn = CreateStyledButton(page, 90, 22, "Test Alert")
        watchTestBtn:SetPoint("TOPRIGHT", -22, -8)
        watchTestBtn:SetScript("OnClick", function()
            addon:WatchAlert({ label = "|cFFA335EE[Test Item]|r" }, nil, "Test Item")
        end)

        local addLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        addLabel:SetPoint("TOPLEFT", 30, -40)
        addLabel:SetText("Add item (type a name or ID, or shift-click an item into the box):")

        local addBox = CreateFrame("EditBox", "LPRO_WatchAdd", page, "InputBoxTemplate")
        addBox:SetSize(300, 22)
        addBox:SetPoint("TOPLEFT", 34, -58)
        addBox:SetAutoFocus(false)
        addBox:SetMaxLetters(200)

        local addBtn = CreateStyledButton(page, 64, 22, "Add")
        addBtn:SetPoint("LEFT", addBox, "RIGHT", 12, 0)

        -- Scrollable list of current entries.
        local scroll = CreateFrame("ScrollFrame", "LPRO_WatchScroll", page, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 30, -92)
        scroll:SetSize(430, 184)
        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(410, 1)
        scroll:SetScrollChild(content)

        local rows = {}
        local ROW_H = 26
        local RefreshList  -- forward declaration (row remove buttons call it)

        RefreshList = function()
            local items = addon:WatchList()
            for i, e in ipairs(items) do
                local row = rows[i]
                if not row then
                    row = CreateFrame("Frame", nil, content)
                    row:SetSize(400, ROW_H)
                    row.icon = row:CreateTexture(nil, "ARTWORK")
                    row.icon:SetSize(20, 20)
                    row.icon:SetPoint("LEFT", 2, 0)
                    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
                    row.label:SetWidth(290)
                    row.label:SetJustifyH("LEFT")
                    row.remove = CreateStyledButton(row, 64, 18, "Remove")
                    row.remove:SetPoint("RIGHT", 0, 0)
                    row.remove:SetScript("OnClick", function()
                        addon:WatchRemove(row._index)
                        RefreshList()
                    end)
                    rows[i] = row
                end
                row._index = i
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", 0, -((i - 1) * ROW_H))

                local icon = e.icon
                if not icon and e.id and GetItemInfoInstant then
                    icon = select(5, GetItemInfoInstant(e.id))
                end
                row.icon:SetTexture(icon or 134400)
                row.label:SetText(e.label or (e.id and ("Item #" .. e.id)) or e.key or "?")
                row:Show()
            end
            for i = #items + 1, #rows do rows[i]:Hide() end
            content:SetHeight(math.max(1, #items * ROW_H))
        end

        local function DoAdd()
            local ok, reason = addon:WatchAdd(addBox:GetText())
            if ok then
                addBox:SetText("")
                addBox:ClearFocus()
                RefreshList()
            elseif reason == "dupe" then
                print("|cFFFF6060[LootPro]|r That item is already on the watchlist.")
            elseif reason == "full" then
                print("|cFFFF6060[LootPro]|r Watchlist is full (max 30 items).")
            end
        end
        addBtn:SetScript("OnClick", DoAdd)
        addBox:SetScript("OnEnterPressed", DoAdd)
        addBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        -- Shift-click an item (e.g. from your bags) while the add box is
        -- focused to drop its link in. hooksecurefunc is post-only and never
        -- alters the default click behavior.
        if HandleModifiedItemClick then
            hooksecurefunc("HandleModifiedItemClick", function(link)
                if link and addBox:HasFocus() and IsShiftKeyDown() then
                    addBox:SetText(link)
                end
            end)
        end

        local watchHint = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        watchHint:SetPoint("TOPLEFT", scroll, "BOTTOMLEFT", 0, -8)
        watchHint:SetWidth(430)
        watchHint:SetJustifyH("LEFT")
        watchHint:SetText("Alerts fire when YOU loot a watched item. Name entries match any item containing that text; links and IDs match exactly.")

        -- ---- Rare Drop Alerts section (#3 sound + #4 color/flash) ----
        local rareDivider = page:CreateTexture(nil, "ARTWORK")
        rareDivider:SetHeight(1)
        rareDivider:SetPoint("TOPLEFT", 30, -296)
        rareDivider:SetPoint("TOPRIGHT", -30, -296)
        rareDivider:SetColorTexture(0.427, 0.020, 0.004, 0.7)

        local rareHeader = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rareHeader:SetPoint("TOPLEFT", 30, -304)
        rareHeader:SetText("|cFFFF2222Rare Drop Alerts|r")

        local rareColor = CreateFrame("CheckButton", "LPRO_RareColor", page, "InterfaceOptionsCheckButtonTemplate")
        rareColor:SetPoint("TOPLEFT", 26, -326)
        _G[rareColor:GetName().."Text"]:SetText("Color loot line by rarity")
        rareColor:SetScript("OnClick", function(self)
            LootProConfig.rareAlert.color = self:GetChecked() and true or false
        end)

        local rareFlash = CreateFrame("CheckButton", "LPRO_RareFlash", page, "InterfaceOptionsCheckButtonTemplate")
        rareFlash:SetPoint("TOPLEFT", rareColor, "BOTTOMLEFT", 0, -2)
        _G[rareFlash:GetName().."Text"]:SetText("Flash the loot frame")
        rareFlash:SetScript("OnClick", function(self)
            LootProConfig.rareAlert.flash = self:GetChecked() and true or false
        end)

        local rareSound = CreateFrame("CheckButton", "LPRO_RareSound", page, "InterfaceOptionsCheckButtonTemplate")
        rareSound:SetPoint("TOPLEFT", rareFlash, "BOTTOMLEFT", 0, -2)
        _G[rareSound:GetName().."Text"]:SetText("Play alert sound")
        rareSound:SetScript("OnClick", function(self)
            LootProConfig.rareAlert.sound = self:GetChecked() and true or false
        end)

        local rareQualList = {
            { val = 2, lbl = "Uncommon+" },
            { val = 3, lbl = "Rare+" },
            { val = 4, lbl = "Epic+" },
            { val = 5, lbl = "Legendary+" },
        }
        local rareThresh = U.CreateGenericCycler("LPRO_RareThresh", "Alert on quality", page, rareQualList, "threshold", "rareAlert")
        rareThresh.label:ClearAllPoints()
        rareThresh.label:SetPoint("TOPLEFT", 280, -320)
        rareThresh:ClearAllPoints()
        rareThresh:SetPoint("TOPLEFT", rareThresh.label, "BOTTOMLEFT", 0, -6)

        local rareTestBtn = CreateStyledButton(page, 110, 22, "Test Rare Drop")
        rareTestBtn:SetPoint("TOPLEFT", 280, -392)
        rareTestBtn:SetScript("OnClick", function()
            if addon.RareTest then addon:RareTest() end
        end)

        page:SetScript("OnShow", function()
            enableCheck:SetChecked(LootProConfig.watchlist.enabled)
            soundCheck:SetChecked(LootProConfig.watchlist.sound)
            rareColor:SetChecked(LootProConfig.rareAlert.color)
            rareFlash:SetChecked(LootProConfig.rareAlert.flash)
            rareSound:SetChecked(LootProConfig.rareAlert.sound)
            rareThresh:Refresh()
            RefreshList()
        end)
    end

    -------------------------------------------------
    -- VENDOR TAB (auto-sell gray items)
    -------------------------------------------------
    -- ElvUI "Vendor Grays" parity. The actual selling lives in
    -- LootPro_Vendor.lua (MERCHANT_SHOW hook + paced seller); this tab only
    -- edits the LootProConfig.vendorGrays knobs and offers an on-demand
    -- "Sell Grays Now" button. Widgets re-sync from OnShow, matching the
    -- Recap/Alerts tabs.
    do
        local page = pages.vendor

        local enableCheck = CreateFrame("CheckButton", "LPRO_VendorEnable", page, "InterfaceOptionsCheckButtonTemplate")
        enableCheck:SetPoint("TOPLEFT", 26, -6)
        _G[enableCheck:GetName().."Text"]:SetText("Automatically sell gray items at vendors")
        enableCheck:SetScript("OnClick", function(self)
            LootProConfig.vendorGrays.enabled = self:GetChecked() and true or false
        end)

        local enableDesc = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        enableDesc:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 25, -2)
        enableDesc:SetWidth(430)
        enableDesc:SetJustifyH("LEFT")
        enableDesc:SetText("When you open a merchant, every poor-quality (gray) item in your bags is sold automatically. Quest items and no-value items are never sold.")

        -- Fractional Sell Interval slider (0.1-1.0s). U.CreateSlider rounds to
        -- integers, so this tab builds a small dedicated slider instead.
        local intervalLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        intervalLabel:SetText("Sell Interval")
        intervalLabel:SetPoint("TOPLEFT", enableDesc, "BOTTOMLEFT", -25, -24)

        local interval = CreateFrame("Slider", "LPRO_VendorInterval", page, "OptionsSliderTemplate")
        interval:SetPoint("TOPLEFT", intervalLabel, "BOTTOMLEFT", 5, -18)
        interval:SetWidth(220)
        interval:SetMinMaxValues(0.1, 1.0)
        interval:SetValueStep(0.1)
        interval:SetObeyStepOnDrag(true)
        _G["LPRO_VendorIntervalText"]:SetFontObject("GameFontNormal")
        _G["LPRO_VendorIntervalLow"]:SetText("0.1s")
        _G["LPRO_VendorIntervalHigh"]:SetText("1.0s")
        interval:SetScript("OnValueChanged", function(self, value)
            if not addon:IsReady() then return end
            -- Snap to the nearest 0.1 (float steps can land on 0.30000004).
            local val = math.floor(value * 10 + 0.5) / 10
            LootProConfig.vendorGrays.interval = val
            _G[self:GetName().."Text"]:SetText(string.format("Sell Interval: %.1fs", val))
        end)

        local intervalDesc = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        intervalDesc:SetPoint("TOPLEFT", interval, "BOTTOMLEFT", -5, -12)
        intervalDesc:SetWidth(430)
        intervalDesc:SetJustifyH("LEFT")
        intervalDesc:SetText("Delay between each item sold. A longer interval is gentler and makes the progress bar easier to follow.")

        local progressCheck = CreateFrame("CheckButton", "LPRO_VendorProgress", page, "InterfaceOptionsCheckButtonTemplate")
        progressCheck:SetPoint("TOPLEFT", intervalDesc, "BOTTOMLEFT", -25, -16)
        _G[progressCheck:GetName().."Text"]:SetText("Show progress bar while selling")
        progressCheck:SetScript("OnClick", function(self)
            LootProConfig.vendorGrays.progressBar = self:GetChecked() and true or false
        end)

        local detailsCheck = CreateFrame("CheckButton", "LPRO_VendorDetails", page, "InterfaceOptionsCheckButtonTemplate")
        detailsCheck:SetPoint("TOPLEFT", progressCheck, "BOTTOMLEFT", 0, -2)
        _G[detailsCheck:GetName().."Text"]:SetText("Print each item sold to chat")
        detailsCheck:SetScript("OnClick", function(self)
            LootProConfig.vendorGrays.details = self:GetChecked() and true or false
        end)

        local sellNowBtn = CreateStyledButton(page, 150, 26, "Sell Grays Now")
        sellNowBtn:SetPoint("TOPLEFT", detailsCheck, "BOTTOMLEFT", 4, -20)
        sellNowBtn:SetScript("OnClick", function()
            addon:VendorStart(true)
        end)
        -- Override the default styled-button hover so we can attach a tooltip;
        -- the backdrop color change is replicated to keep the hover look.
        sellNowBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.541, 0.024, 0.004, 1.0)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Sell Grays Now", 1, 1, 1)
            if addon.VendorGrayValue then
                GameTooltip:AddLine("Current vendor value: " .. addon:RecapFormatMoney(addon:VendorGrayValue()), 0.8, 0.8, 0.8)
            end
            GameTooltip:AddLine("Requires an open merchant window.", 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end)
        sellNowBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.427, 0.020, 0.004, 1.0)
            GameTooltip:Hide()
        end)

        local vendorHint = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        vendorHint:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 30, 110)
        vendorHint:SetWidth(430)
        vendorHint:SetJustifyH("LEFT")
        vendorHint:SetText("The merchant's own \"Sell All Junk\" button sells everything at once. This adds automatic, paced selling with an optional on-screen progress bar.")

        page:SetScript("OnShow", function()
            enableCheck:SetChecked(LootProConfig.vendorGrays.enabled)
            progressCheck:SetChecked(LootProConfig.vendorGrays.progressBar)
            detailsCheck:SetChecked(LootProConfig.vendorGrays.details)
            interval:SetValue(LootProConfig.vendorGrays.interval or 0.2)
        end)
    end

    -------------------------------------------------
    -- FIRST-TIME WELCOME POPUP
    -------------------------------------------------
    local welcome = CreateVersionedMainFrame("LootProWelcome", UIParent)
    welcome:SetSize(320, 160)
    welcome:SetPoint("CENTER")
    welcome:SetFrameStrata("HIGH")
    welcome:Hide()

    CreateCloseButton(welcome)

    welcome.title = welcome:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    welcome.title:SetPoint("TOP", welcome, "TOP", 0, -18)
    welcome.title:SetFont(welcome.title:GetFont(), 25, "OUTLINE")
    welcome.title:SetText("|cFFFF2222Loot Pro|r")

    local msg = welcome:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    msg:SetPoint("TOP", 0, -55)
    msg:SetWidth(280)
    msg:SetJustifyH("CENTER")
    msg:SetText("Configure settings for first time use of Loot Pro")

    local openBtn = CreateStyledButton(welcome, 140, 28, "Open Settings")
    openBtn:SetPoint("CENTER", welcome, "CENTER", 0, -10)
    openBtn:SetScript("OnClick", function()
        -- M6: A user clicking "Open Settings" is clearly onboarding; never nag
        -- them with this popup again.
        LootProConfig.hideWelcome = true
        welcome:Hide()
        gui:Show()
    end)
    
    local hideCheck = CreateFrame("CheckButton", "LPRO_HideWelcome", welcome, "InterfaceOptionsCheckButtonTemplate")
    hideCheck:SetPoint("BOTTOMLEFT", 20, 15)
    _G[hideCheck:GetName().."Text"]:SetText("Don't show this again")
    -- M6: Set initial state at creation so the displayed check reflects the
    -- saved variable even if the template swallows our OnShow hook.
    hideCheck:SetChecked(LootProConfig.hideWelcome)
    hideCheck:HookScript("OnShow", function(self) self:SetChecked(LootProConfig.hideWelcome) end)
    hideCheck:SetScript("OnClick", function(self) LootProConfig.hideWelcome = self:GetChecked() and true or false end)
    
    -- M6: Closing via the X button also persists hideWelcome if the user
    -- checked the box mid-session (defensive; OnClick already writes it).
    welcome:HookScript("OnHide", function()
        if hideCheck:GetChecked() then
            LootProConfig.hideWelcome = true
        end
    end)
    
    ns.UI.welcomeFrame = welcome

    -------------------------------------------------
    -- ONE-TIME "WHAT'S NEW" POPUP
    -------------------------------------------------
    local wn = CreateVersionedMainFrame("LootProWhatsNew", UIParent)
    wn:SetSize(470, 250)
    wn:SetPoint("CENTER")
    wn:SetFrameStrata("HIGH")
    wn:Hide()
    tinsert(UISpecialFrames, "LootProWhatsNew")

    CreateCloseButton(wn)

    wn.title = wn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    wn.title:SetPoint("TOP", wn, "TOP", 0, -16)
    wn.title:SetFont(wn.title:GetFont(), 20, "OUTLINE")
    wn.title:SetText("|cFFFF2222What's New in Loot Pro|r")

    local wnBody = wn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    wnBody:SetPoint("TOPLEFT", wn, "TOPLEFT", 24, -54)
    wnBody:SetPoint("TOPRIGHT", wn, "TOPRIGHT", -24, -54)
    wnBody:SetJustifyH("LEFT")
    wnBody:SetJustifyV("TOP")
    wnBody:SetSpacing(5)
    wnBody:SetText(table.concat({
        "|cFFEBB706New: Auto-Sell Gray Items|r",
        " ",
        "A new Vendor tab can automatically sell your gray (junk) items whenever you open a merchant, with a configurable speed and an optional on-screen progress bar. It is OFF by default -- enable it on the Vendor tab if you want it.",
        " ",
        "Got an idea or found a bug? Join our Discord below -- feature requests and reports are always welcome!",
    }, "\n"))

    -- Primary button sits right-of-center so the Discord chip fits beside it
    -- (screenshot parity with the sibling addons).
    local wnOpen = CreateStyledButton(wn, 150, 26, "Open Settings")
    wnOpen:SetPoint("BOTTOM", wn, "BOTTOM", 75, 18)
    wnOpen:SetScript("OnClick", function()
        wn:Hide()
        gui:Show()
    end)

    -- "Join our Discord!" to the left of the primary button. Reusable popup
    -- chip from Widgets so every future popup gets the identical button. Does
    -- NOT mark the revision seen, so the player can copy the invite and keep
    -- reading (the auto-show in LootPro_Core marks it on login).
    local wnDiscord = U.CreateDiscordButton(wn)
    wnDiscord:SetPoint("RIGHT", wnOpen, "LEFT", -10, 0)

    -- The revision is marked seen when the popup AUTO-shows on login (see
    -- LootPro_Core's PLAYER_LOGIN). We deliberately do NOT mark it on hide, so
    -- a manual /lp whatsnew preview and reload-teardown can't flip the flag.
    ns.UI.whatsNewFrame = wn

    function ns.UI:RefreshAllWidgets()
        cSize:SetValue(LootProConfig.combat.size); cFade:SetValue(LootProConfig.combat.fade); cWidth:SetValue(LootProConfig.combat.width); cHeight:SetValue(LootProConfig.combat.height); cMaxLines:SetValue(LootProConfig.combat.maxLines)
        lSize:SetValue(LootProConfig.loot.size); lFade:SetValue(LootProConfig.loot.fade); lWidth:SetValue(LootProConfig.loot.width); lHeight:SetValue(LootProConfig.loot.height); lMaxLines:SetValue(LootProConfig.loot.maxLines)
        cFont:Refresh(); cOut:Refresh(); lFont:Refresh(); lOut:Refresh()
        mmLeft:Refresh(); mmRight:Refresh(); mmMid:Refresh(); capCheck:SetChecked(LootProConfig.currencyCap)
        mQual:Refresh()
        cEntEB:SetText(LootProConfig.combatEnterText); cLveEB:SetText(LootProConfig.combatLeaveText)
        cleanCheck:SetChecked(LootProConfig.cleanMode); countCheck:SetChecked(LootProConfig.showLootCounts); gIconCheck:SetChecked(LootProConfig.showMoneyIcons); fxpCheck:SetChecked(LootProConfig.showFollowerXP)
        mmCheck:SetChecked(not LootProConfig.minimap.hide)
        fTrade:SetChecked(LootProConfig.lootFilters.hideTradeGoods); fConsum:SetChecked(LootProConfig.lootFilters.hideConsumable); fQuest:SetChecked(LootProConfig.lootFilters.hideQuest); fRecipe:SetChecked(LootProConfig.lootFilters.hideRecipe)
        for _, row in ipairs(colorRows) do row:Refresh() end
        for key, cb in pairs(toggles) do cb:SetChecked(LootProConfig.notifications[key]) end
        for key, cb in pairs(toggles) do if LootProConfig.colors[key] then local c = LootProConfig.colors[key]; _G[cb:GetName().."Text"]:SetTextColor(c.r, c.g, c.b) end end
    end

    ns.UI:RefreshAllWidgets()
    SetActiveTab("layout")
    -- L7: Slash command is registered at file-load time in LootPro.lua so it
    -- works during loading screens; this just wires the GUI reference.
    ns.UI.toggleGUI = function() if addon:IsReady() then if gui:IsShown() then gui:Hide() else gui:Show() end end end

    -------------------------------------------------
    -- BLIZZARD ADDON OPTIONS ENTRY
    -------------------------------------------------
    -- A small panel in the game's Options > AddOns list that links to the full
    -- Loot Pro window. Supports the modern retail Settings API and falls back
    -- to the legacy InterfaceOptions API on older clients (BCC).
    do
        local panel = CreateFrame("Frame")
        panel.name = "Loot Pro" -- used by the legacy API; harmless for the new one

        local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText("|cFFFF2222Loot Pro|r")

        local ver = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        ver:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
        ver:SetText("Version " .. addon.VERSION)

        local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        desc:SetPoint("TOPLEFT", ver, "BOTTOMLEFT", 0, -16)
        desc:SetWidth(540)
        desc:SetJustifyH("LEFT")
        desc:SetText("Loot Pro opens its full options in a dedicated window. Click the button below, or type |cFFEBB706/lp|r in chat.")

        local openBtn = CreateStyledButton(panel, 220, 26, "Open Loot Pro Options")
        openBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -18)
        openBtn:SetScript("OnClick", function()
            -- Close the options window first so the Loot Pro frame isn't hidden
            -- behind it (the Settings panel sits at a higher strata).
            if SettingsPanel and SettingsPanel:IsShown() and HideUIPanel then
                HideUIPanel(SettingsPanel)
            elseif InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() and HideUIPanel then
                HideUIPanel(InterfaceOptionsFrame)
            end
            gui:Show()
        end)

        if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
            local category = Settings.RegisterCanvasLayoutCategory(panel, "Loot Pro")
            Settings.RegisterAddOnCategory(category)
        elseif InterfaceOptions_AddCategory then
            InterfaceOptions_AddCategory(panel)
        end
    end
end