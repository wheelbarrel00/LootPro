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
    local gui = CreateVersionedMainFrame("LootProGUI", UIParent)
    gui:SetSize(520, 680)
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

    local pages = { 
        layout = CreateFrame("Frame", nil, gui), 
        colors = CreateFrame("Frame", nil, gui), 
        notifications = CreateFrame("Frame", nil, gui),
        customization = CreateFrame("Frame", nil, gui)
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

    local cFont = U.CreateFontCycler("LPRO_CF", "Combat Font", pages.customization, "combat")
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

    local lFont = U.CreateFontCycler("LPRO_LF", "Loot Font", pages.customization, "loot") 
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

    function ns.UI:RefreshAllWidgets()
        cSize:SetValue(LootProConfig.combat.size); cFade:SetValue(LootProConfig.combat.fade); cWidth:SetValue(LootProConfig.combat.width); cHeight:SetValue(LootProConfig.combat.height); cMaxLines:SetValue(LootProConfig.combat.maxLines)
        lSize:SetValue(LootProConfig.loot.size); lFade:SetValue(LootProConfig.loot.fade); lWidth:SetValue(LootProConfig.loot.width); lHeight:SetValue(LootProConfig.loot.height); lMaxLines:SetValue(LootProConfig.loot.maxLines)
        cFont:Refresh(); cOut:Refresh(); lFont:Refresh(); lOut:Refresh()
        mQual:Refresh()
        cEntEB:SetText(LootProConfig.combatEnterText); cLveEB:SetText(LootProConfig.combatLeaveText)
        cleanCheck:SetChecked(LootProConfig.cleanMode); countCheck:SetChecked(LootProConfig.showLootCounts); gIconCheck:SetChecked(LootProConfig.showMoneyIcons); fxpCheck:SetChecked(LootProConfig.showFollowerXP)
        mmCheck:SetChecked(not LootProConfig.minimap.hide)
        for _, row in ipairs(colorRows) do row:Refresh() end
        for key, cb in pairs(toggles) do cb:SetChecked(LootProConfig.notifications[key]) end
        for key, cb in pairs(toggles) do if LootProConfig.colors[key] then local c = LootProConfig.colors[key]; _G[cb:GetName().."Text"]:SetTextColor(c.r, c.g, c.b) end end
    end

    ns.UI:RefreshAllWidgets()
    SetActiveTab("layout")
    -- L7: Slash command is registered at file-load time in LootPro.lua so it
    -- works during loading screens; this just wires the GUI reference.
    ns.UI.toggleGUI = function() if addon:IsReady() then if gui:IsShown() then gui:Hide() else gui:Show() end end end
end