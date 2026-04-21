local addonName, ns = ...
local U = ns.U
local addon = ns.addon

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"

local function SafeSetFont(region, path, size, flags)
    if addon._SafeSetFont then return addon._SafeSetFont(region, path, size, flags) end
    pcall(function() region:SetFont(path, size, flags) end)
end

-- H2: Cache the SharedMedia font list. Rebuilding + sorting this table on
-- every slider-driven refresh is pure waste. Cache is invalidated whenever a
-- new font is registered with LSM.
local _fontCache
local function GetFonts()
    if _fontCache then return _fontCache end
    local t = {}
    if LSM then
        for n in pairs(LSM:HashTable("font")) do t[#t+1] = n end
    end
    if #t == 0 then t[1] = "Friz Quadrata TT" end
    table.sort(t)
    _fontCache = t
    return t
end
if LSM and LSM.RegisterCallback then
    local sink = {}
    LSM.RegisterCallback(sink, "LibSharedMedia_Registered", function(_, mediatype)
        if mediatype == "font" then _fontCache = nil end
    end)
end

-- Helper so widgets can target root-level config keys (e.g. minQuality) as
-- well as nested tables (e.g. LootProConfig.combat.size).
local function GetCfg(configKey)
    if configKey == "root" then return LootProConfig end
    return LootProConfig[configKey]
end

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
        local fonts = GetFonts()
        
        t:SetText(cfg.font or "Friz Quadrata TT") 
        local p = LSM and LSM:Fetch("font", cfg.font) or DEFAULT_FONT 
        SafeSetFont(t, p, 13, "") 
        
        if addon.UpdateAllVisuals then 
            addon:UpdateAllVisuals() 
        end
    end
    
    local function Cycle(d) 
        local cfg = LootProConfig[configKey]
        local fonts = GetFonts()
        
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
        local cfg = GetCfg(configKey)
        local cur = cfg[settingKey]
        
        for _, v in ipairs(list) do 
            if v.val == cur then 
                t:SetText(v.lbl) 
            end 
        end 
        
        -- Font styling is only meaningful when the cycler represents an outline
        -- value for a nested readout config. Root-level cyclers just show text.
        if configKey ~= "root" then
            local p = LSM and LSM:Fetch("font", cfg.font) or DEFAULT_FONT
            local f = (cur == "NONE") and "" or cur
            if type(f) == "string" then
                SafeSetFont(t, p, 13, f)
            end
        end
        
        if addon.UpdateAllVisuals then 
            addon:UpdateAllVisuals() 
        end 
    end
    
    local function Cycle(d) 
        local cfg = GetCfg(configKey)
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
        
        cfg[settingKey] = list[idx].val 
        UpdateText() 
    end
    
    local pb = CreateFrame("Button", nil, c)
    pb:SetSize(18,18)
    pb:SetPoint("LEFT", 2, 0)
    pb:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    pb:SetScript("OnClick", function() Cycle(-1) end)
    
    local nb = CreateFrame("Button", nil, c)
    nb:SetSize(18,18)
    nb:SetPoint("RIGHT", -2, 0)
    nb:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    nb:SetScript("OnClick", function() Cycle(1) end)
    
    c.Refresh = UpdateText
    c.label = l 
    return c
end

function U.CreateSlider(name, title, parent, minVal, maxVal, step, settingKey, configKey)
    local l = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal") 
    l:SetText(title)
    l:Hide()
    
    local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate") 
    s:SetPoint("TOP", l, "BOTTOM", 0, -10) 
    s:SetMinMaxValues(minVal, maxVal) 
    s:SetValueStep(step) 
    s:SetObeyStepOnDrag(true)
    
    _G[name.."Text"]:SetFontObject("GameFontNormal")
    
    s:SetScript("OnValueChanged", function(self, value) 
        if not addon:IsReady() then return end 
        local val = math.floor(value + 0.5) 
        
        if configKey == "root" then 
            LootProConfig[settingKey] = val 
        else 
            LootProConfig[configKey][settingKey] = val 
        end 
        
        _G[self:GetName().."Text"]:SetText(title .. ": " .. val .. ((settingKey == "fade") and "s" or "")) 
        
        if addon.UpdateAllVisuals then 
            addon:UpdateAllVisuals() 
        end 
    end)
    
    s.label = l 
    return s
end

function U.CreateEditBox(name, title, parent, settingKey)
    local l = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal") 
    l:SetText(title)
    
    local eb = CreateFrame("EditBox", name, parent, "InputBoxTemplate") 
    eb:SetSize(180, 20) 
    eb:SetAutoFocus(false)
    
    eb:SetScript("OnShow", function(self) 
        self:SetText(LootProConfig[settingKey] or "") 
    end)
    
    eb:SetScript("OnEnterPressed", function(self) 
        LootProConfig[settingKey] = self:GetText()
        self:ClearFocus()
        if addon.isTesting and addon.PostTestMessages then 
            addon:PostTestMessages() 
        end 
    end)
    
    eb:SetScript("OnEscapePressed", function(self) 
        self:SetText(LootProConfig[settingKey] or "")
        self:ClearFocus() 
    end)
    
    eb.label = l 
    return eb
end

function U.CreateColorRow(name, parent, colorKey, previewFunc)
    local f = CreateFrame("Button", name, parent, "BackdropTemplate")
    f:SetSize(400, 28)
    f:SetBackdrop({ 
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
        tile = true, 
        tileSize = 16, 
        edgeSize = 14, 
        insets = {left=3, right=3, top=3, bottom=3} 
    })
    f:SetBackdropColor(0,0,0,0.5)
    
    local tex = f:CreateTexture(nil, "ARTWORK")
    tex:SetSize(16, 16) 
    tex:SetPoint("LEFT", 10, 0)
    
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") 
    title:SetPoint("LEFT", tex, "RIGHT", 10, 0) 
    title:SetText(name:gsub("LPRO_CLR_", ""))
    
    local preview = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    preview:SetPoint("RIGHT", -12, 0)
    
    local function Update()
        local c = LootProConfig.colors[colorKey]
        tex:SetColorTexture(c.r, c.g, c.b)
        preview:SetText(previewFunc())
        preview:SetTextColor(c.r, c.g, c.b)
    end
    
    local function OnColorChanged()
        local r, g, b
        if ColorPickerFrame.GetColorRGB then 
            r, g, b = ColorPickerFrame:GetColorRGB() 
        elseif ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then 
            r, g, b = ColorPickerFrame.Content.ColorPicker:GetColorRGB() 
        end
        
        if r and g and b then 
            LootProConfig.colors[colorKey] = {r=r, g=g, b=b}
            Update()
            if addon.isTesting and addon.PostTestMessages then 
                addon:PostTestMessages() 
            end 
        end
    end
    
    f:SetScript("OnClick", function()
        local c = LootProConfig.colors[colorKey]
        if ColorPickerFrame.SetupColorPickerAndShow then 
            ColorPickerFrame:SetupColorPickerAndShow({ 
                r = c.r, g = c.g, b = c.b, 
                swatchFunc = OnColorChanged, 
                cancelFunc = function(prev) 
                    LootProConfig.colors[colorKey] = {r=prev.r, g=prev.g, b=prev.b}
                    Update() 
                end, 
            })
        else 
            ColorPickerFrame.func = OnColorChanged
            ColorPickerFrame.cancelFunc = function(prev) 
                LootProConfig.colors[colorKey] = {r=prev.r, g=prev.g, b=prev.b}
                Update() 
            end
            ColorPickerFrame.previousValues = {r = c.r, g = c.g, b = c.b}
            ColorPickerFrame:SetColorRGB(c.r, c.g, c.b)
            ColorPickerFrame:Show() 
        end
    end)
    
    f.Refresh = Update 
    return f
end