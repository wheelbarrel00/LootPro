local addonName, ns = ...
local addon = ns.addon
local U = ns.U

ns.UI = {}

function ns.UI:Initialize()
    local gui = CreateFrame("Frame", "LootProGUI", UIParent, "BasicFrameTemplateWithInset, BackdropTemplate")
    gui:SetSize(520, 680) 
    gui:SetPoint("CENTER") 
    gui:Hide() 
    gui:SetMovable(true) 
    gui:EnableMouse(true) 
    gui:RegisterForDrag("LeftButton")
    gui:SetScript("OnDragStart", gui.StartMoving) 
    gui:SetScript("OnDragStop", gui.StopMovingOrSizing)

    gui.title = gui:CreateFontString(nil, "OVERLAY", "GameFontHighlight") 
    gui.title:SetPoint("CENTER", gui.TitleBg, "CENTER", 0, 0) 
    gui.title:SetText("Loot Pro ("..addon.VERSION..")")

    local pages = { 
        layout = CreateFrame("Frame", nil, gui), 
        colors = CreateFrame("Frame", nil, gui), 
        notifications = CreateFrame("Frame", nil, gui),
        customization = CreateFrame("Frame", nil, gui)
    }

    for _, p in pairs(pages) do 
        p:SetSize(500, 550) 
        p:SetPoint("TOP", 0, -110) 
        p:Hide() 
    end

    local function ShowPage(name) 
        for k, p in pairs(pages) do 
            if k == name then p:Show() else p:Hide() end 
        end 
    end

    local function CreateTab(name, label, x)
        local b = CreateFrame("Button", nil, gui, "GameMenuButtonTemplate")
        b:SetSize(100, 25) 
        b:SetPoint("TOPLEFT", x, -30) 
        b:SetText(label)
        local fontString = b:GetFontString()
        if fontString then fontString:SetFont("Fonts\\FRIZQT__.TTF", 10, "") end
        b:SetScript("OnClick", function() ShowPage(name) end)
        return b
    end

    CreateTab("layout", "Layout", 25)
    CreateTab("colors", "Colors", 145)
    CreateTab("notifications", "Notifs", 265)
    CreateTab("customization", "Custom", 385)

    local lockBtn = CreateFrame("Button", nil, gui, "GameMenuButtonTemplate")
    lockBtn:SetPoint("TOPLEFT", 25, -65) 
    lockBtn:SetSize(140, 30)
    lockBtn:SetText(LootProConfig.locked and "Unlock Windows" or "Lock Windows")
    lockBtn:SetScript("OnClick", function() 
        LootProConfig.locked = not LootProConfig.locked 
        addon:UpdateAllVisuals() 
        lockBtn:SetText(LootProConfig.locked and "Unlock Windows" or "Lock Windows") 
    end)

    local testBtn = CreateFrame("Button", nil, gui, "GameMenuButtonTemplate")
    testBtn:SetPoint("TOPRIGHT", -25, -65) 
    testBtn:SetSize(140, 30) 
    testBtn:SetText("Start Test Mode")
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

    local syncLayout = CreateFrame("Button", nil, pages.layout, "GameMenuButtonTemplate") 
    syncLayout:SetPoint("BOTTOM", 0, 40); syncLayout:SetSize(220, 25); syncLayout:SetText("Sync Combat Layout to Loot")
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
    AddColor("loot", "Loot", function() return "+1 |T132338:0|t Earthen Shard (24)" end)
    AddColor("combatEnter", "Combat Start", function() return LootProConfig.combatEnterText end)
    AddColor("combatLeave", "Combat End", function() return LootProConfig.combatLeaveText end)
    AddColor("xp", "Experience", function() return "+ 1,500 XP" end)
    AddColor("delver", "Delver XP", function() return "+ 125 Delver XP" end)
    AddColor("skill", "Skill", function() return "Blacksmithing (Midnight) (50)" end)
    AddColor("honor", "Honor", function() return "+ 15 Honor" end)
    AddColor("repGain", "Rep Gain", function() return "+ 250 Rep: The Midnight Council" end)
    AddColor("repLoss", "Rep Loss", function() return "- 25 Rep: Bloodsail Buccaneers" end)

    local resetBtn = CreateFrame("Button", nil, pages.colors, "GameMenuButtonTemplate")
    resetBtn:SetSize(160, 28); resetBtn:SetPoint("TOP", colorRows[#colorRows], "BOTTOM", 0, -25); resetBtn:SetText("Reset to Defaults")
    resetBtn:SetScript("OnClick", function() addon:ResetDefaults() end)
    local stubC = pages.colors:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); stubC:SetPoint("TOP", resetBtn, "BOTTOM", 0, -5); stubC:SetText("Clears all colors, layout, and toggles.")

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
    moneyT:SetPoint("TOPLEFT", 15, 0); _G[moneyT:GetName().."Text"]:SetText("Display Money")
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

    local cStrT = CreateFrame("CheckButton", "LPRO_TGL_combatEnter", pages.notifications, "InterfaceOptionsCheckButtonTemplate")
    cStrT:SetPoint("TOPLEFT", 260, 0); _G[cStrT:GetName().."Text"]:SetText("Display Combat START")
    local cCE = LootProConfig.colors["combatEnter"] or {r=1, g=1, b=1}; _G[cStrT:GetName().."Text"]:SetTextColor(cCE.r, cCE.g, cCE.b)
    cStrT:SetChecked(LootProConfig.notifications["combatEnter"])
    cStrT:SetScript("OnClick", function(self) LootProConfig.notifications["combatEnter"] = self:GetChecked(); if addon.isTesting then addon:PostTestMessages() end end)
    toggles["combatEnter"] = cStrT

    local cEndT = AddToggle("combatLeave", "Display Combat END", "combatLeave", cStrT)
    local xpT = AddToggle("xp", "Display Experience", "xp", cEndT)
    
    local fxpCheck = CreateFrame("CheckButton", "LPRO_FollowerToggle_N", pages.notifications, "InterfaceOptionsCheckButtonTemplate")
    fxpCheck:SetPoint("TOPLEFT", xpT, "BOTTOMLEFT", 0, -5); _G[fxpCheck:GetName().."Text"]:SetText("Show Combat Follower XP"); fxpCheck:SetChecked(LootProConfig.showFollowerXP)
    fxpCheck:SetScript("OnClick", function(self) LootProConfig.showFollowerXP = self:GetChecked(); if addon.isTesting then addon:PostTestMessages() end end)

    local delvT = AddToggle("delver", "Display Delve Companion XP", "delver", fxpCheck) 
    local skillT = AddToggle("skill", "Display Skill Gains", "skill", delvT)
    local honorT = AddToggle("honor", "Display Honor Gains", "honor", skillT)
    local repGT = AddToggle("repGain", "Display Reputation GAIN", "repGain", honorT)
    local repLT = AddToggle("repLoss", "Display Reputation LOSS", "repLoss", repGT)

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

    local lFont = U.CreateFontCycler("LPRO_LF", "Loot Font", pages.customization, "loot") 
    lFont.label:SetPoint("TOPRIGHT", -50, 0); lFont:SetPoint("TOPRIGHT", lFont.label, "BOTTOMRIGHT", 0, -5); pages.customization.lF = lFont

    local lOut = U.CreateGenericCycler("LPRO_LO", "Loot Outline", pages.customization, outList, "outline", "loot") 
    lOut.label:SetPoint("TOPRIGHT", lFont, "BOTTOMRIGHT", -40, -15); lOut:SetPoint("TOPRIGHT", lOut.label, "BOTTOMRIGHT", 0, -5); pages.customization.lO = lOut

    local syncCustom = CreateFrame("Button", nil, pages.customization, "GameMenuButtonTemplate") 
    syncCustom:SetPoint("BOTTOM", 0, 80); syncCustom:SetSize(220, 25); syncCustom:SetText("Sync Combat Fonts to Loot")
    syncCustom:SetScript("OnClick", function() 
        LootProConfig.loot.font = LootProConfig.combat.font; LootProConfig.loot.outline = LootProConfig.combat.outline
        pages.customization.lF:Refresh(); pages.customization.lO:Refresh(); addon:UpdateAllVisuals() 
    end)

    -------------------------------------------------
    -- FIRST-TIME WELCOME POPUP
    -------------------------------------------------
    local welcome = CreateFrame("Frame", "LootProWelcome", UIParent, "BasicFrameTemplateWithInset, BackdropTemplate")
    welcome:SetSize(320, 160)
    welcome:SetPoint("CENTER")
    welcome:SetFrameStrata("HIGH")
    welcome:Hide()
    
    welcome.title = welcome:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    welcome.title:SetPoint("CENTER", welcome.TitleBg, "CENTER", 0, 0)
    welcome.title:SetText("Loot Pro")
    
    local msg = welcome:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    msg:SetPoint("TOP", 0, -40)
    msg:SetWidth(280)
    msg:SetText("Configure settings for first time use of Loot Pro")
    
    local openBtn = CreateFrame("Button", nil, welcome, "GameMenuButtonTemplate")
    openBtn:SetSize(140, 30)
    openBtn:SetPoint("CENTER", welcome, "CENTER", 0, -5)
    openBtn:SetText("Open Settings")
    openBtn:SetScript("OnClick", function()
        welcome:Hide()
        gui:Show()
    end)
    
    local hideCheck = CreateFrame("CheckButton", "LPRO_HideWelcome", welcome, "InterfaceOptionsCheckButtonTemplate")
    hideCheck:SetPoint("BOTTOMLEFT", 20, 15)
    _G[hideCheck:GetName().."Text"]:SetText("Don't show this again")
    hideCheck:SetScript("OnShow", function(self) self:SetChecked(LootProConfig.hideWelcome) end)
    hideCheck:SetScript("OnClick", function(self) LootProConfig.hideWelcome = self:GetChecked() end)
    
    ns.UI.welcomeFrame = welcome

    function ns.UI:RefreshAllWidgets()
        cSize:SetValue(LootProConfig.combat.size); cFade:SetValue(LootProConfig.combat.fade); cWidth:SetValue(LootProConfig.combat.width); cHeight:SetValue(LootProConfig.combat.height); cMaxLines:SetValue(LootProConfig.combat.maxLines)
        lSize:SetValue(LootProConfig.loot.size); lFade:SetValue(LootProConfig.loot.fade); lWidth:SetValue(LootProConfig.loot.width); lHeight:SetValue(LootProConfig.loot.height); lMaxLines:SetValue(LootProConfig.loot.maxLines)
        cFont:Refresh(); cOut:Refresh(); lFont:Refresh(); lOut:Refresh()
        cEntEB:SetText(LootProConfig.combatEnterText); cLveEB:SetText(LootProConfig.combatLeaveText)
        cleanCheck:SetChecked(LootProConfig.cleanMode); countCheck:SetChecked(LootProConfig.showLootCounts); gIconCheck:SetChecked(LootProConfig.showMoneyIcons); fxpCheck:SetChecked(LootProConfig.showFollowerXP)
        mmCheck:SetChecked(not LootProConfig.minimap.hide)
        for _, row in ipairs(colorRows) do row:Refresh() end
        for key, cb in pairs(toggles) do cb:SetChecked(LootProConfig.notifications[key]) end
        for key, cb in pairs(toggles) do if LootProConfig.colors[key] then local c = LootProConfig.colors[key]; _G[cb:GetName().."Text"]:SetTextColor(c.r, c.g, c.b) end end
    end

    ns.UI:RefreshAllWidgets()
    ShowPage("layout")
    SLASH_LOOTPRO1 = "/lp"
    SlashCmdList["LOOTPRO"] = function() if addon:IsReady() then if gui:IsShown() then gui:Hide() else gui:Show() end end end
end