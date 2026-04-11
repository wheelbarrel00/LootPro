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

    -------------------------------------------------
    -- GLOBAL HEADER AREA
    -------------------------------------------------
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

    -------------------------------------------------
    -- TAB 1: LAYOUT
    -------------------------------------------------
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

    -------------------------------------------------
    -- TAB 2: COLORS
    -------------------------------------------------
    local colorRows = {}
    local function AddColor(key, title, func)
        local row = U.CreateColorRow("LPRO_CLR_"..title, pages.colors, key, func)
        if #colorRows == 0 then row:SetPoint("TOP", 0, 0) else row:SetPoint("TOP", colorRows[#colorRows], "BOTTOM", 0, -3) end
        table.insert(colorRows, row) 
        row:Refresh()
    end
    
    AddColor("money", "Money", function() return