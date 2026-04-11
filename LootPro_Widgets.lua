local addonName, ns = ...
local U = ns.U
local addon = ns.addon

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"

function U.CreateFontCycler(name, title, parent, configKey)
    local l = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal") 
    l:SetText(title)
    
    local c = CreateFrame("Frame", name, parent, "BackdropTemplate") 
    c:SetSize(180, 28) 
    c:SetPoint("TOP", l, "BOTTOM", 0, -5)
    c:SetBackdrop({ 
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
        tile = true, 
        tileSize = 16, 
        edgeSize = 12, 
        insets = {left=3, right=3, top=3, bottom=3} 
    })
    c:SetBackdropColor(0,0,0,0.8)
    
    local t = c:CreateFontString(nil, "OVERLAY", "GameFontHighlight") 
    t:SetPoint("CENTER") 
    t:SetWidth(140) 
    t:SetWordWrap(false)
    
    local function Update()
        local cfg = LootProConfig[configKey]
        local fonts = {} 
        
        if LSM then 
            for n in pairs(LSM:HashTable("font")) do 
                table.insert(fonts, n) 
            end 
        else 
            fonts = {"Friz Quadrata TT"} 
        end 
        table.sort(fonts) 
        
        t:SetText(cfg.font or "Friz Quadrata TT") 
        local p = LSM and LSM:Fetch("font", cfg.font) or DEFAULT_FONT 
        pcall(function() t:SetFont(p, 13, "") end) 
        
        if addon.UpdateAllVisuals then 
            addon:UpdateAllVisuals() 
        end
    end
    
    local function Cycle(d) 
        local cfg = LootProConfig[configKey]
        local fonts = {} 
        
        if LSM then 
            for n in pairs(LSM:HashTable("font")) do 
                table.insert(fonts, n) 
            end 
        else 
            fonts = {"Friz Quadrata TT"} 
        end 
        table.sort(fonts) 
        
        local idx = 1 
        for i, v in ipairs(fonts) do 
            if v == cfg.font then 
                idx = i 
                break 
            end 
        end 
        
        idx = idx + d 
        if idx > #fonts then 
            idx = 1 
        elseif idx < 1 then 
            idx = #fonts 
        end 
        
        cfg.font = fonts[idx] 
        Update() 
    end
    
    local pb = CreateFrame("Button", nil, c)
    pb:SetSize(20,20)
    pb:SetPoint("LEFT", 5, 0)
    pb:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    pb:SetScript("OnClick", function() Cycle(-1) end)
    
    local nb = CreateFrame("Button", nil, c)
    nb:SetSize(20,20)
    nb:SetPoint("RIGHT", -5, 0)
    nb:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    nb:SetScript("OnClick", function() Cycle(1) end)
    
    c.Refresh = Update
    c.label = l 
    return c
end

function U.CreateGenericCycler(name, title, parent, list, settingKey, configKey)
    local l = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal") 
    l:SetText(title)
    
    local c = CreateFrame("Frame", name, parent, "BackdropTemplate") 
    c:SetSize(140, 26) 
    c:SetPoint("TOP", l, "BOTTOM", 0, -5)
    c:SetBackdrop({ 
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
        tile = true, 
        tileSize = 16, 
        edgeSize = 12, 
        insets = {left=2, right=2, top=2, bottom=2} 
    })
    c:SetBackdropColor(0,0,0,0.8)
    
    local t = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall") 
    t:SetPoint("CENTER")
    
    local function UpdateText() 
        local cfg = LootProConfig[configKey]
        
        for _, v in ipairs(list) do 
            if v.val == cfg[settingKey] then 
                t:SetText(v.lbl) 
            end 
        end 
        
        local p = LSM and LSM:Fetch("font", cfg.font) or DEFAULT_FONT
        local f = (cfg[settingKey] == "NONE") and "" or cfg[settingKey]
        pcall(function() t:SetFont(p, 13, f) end)
        
        if addon.UpdateAllVisuals then 
            addon:UpdateAllVisuals() 
        end 
    end
    
    local function Cycle(d) 
        local cfg = LootProConfig[configKey]
        local idx = 1 
        
        for i, v in ipairs(list) do 
            if v.val == cfg[settingKey] then 
                idx = i 
                break 
            end 
        end 
        
        idx = idx + d 
        if idx > #list then 
            idx = 1 
        elseif idx < 1 then 
            idx = #list 
        end 
        
        cfg[settingKey] =