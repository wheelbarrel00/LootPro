local addonName, ns = ...
local U = ns.U
local addon = ns.addon

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"

local function SafeSetFont(region, path, size, flags)
    if addon._SafeSetFont then return addon._SafeSetFont(region, path, size, flags) end
    pcall(region.SetFont, region, path, size, flags)
end

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

local function GetCfg(configKey)
    if configKey == "root" then return LootProConfig end
    return LootProConfig[configKey]
end

-- SetBackdrop copies values out and keeps no reference, so these style tables are safe to share across widgets.
local BACKDROP_DROPDOWN = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
local BACKDROP_POPUP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
}
local BACKDROP_CYCLER = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}
local BACKDROP_COLORROW = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

function U.CreateFontDropdown(name, title, parent, configKey)
    local l = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    l:SetText(title)

    local c = CreateFrame("Button", name, parent, "BackdropTemplate")
    c:SetSize(180, 24)
    c:SetPoint("TOP", l, "BOTTOM", 0, -5)
    c:SetBackdrop(BACKDROP_DROPDOWN)
    c:SetBackdropColor(0, 0, 0, 0.85)
    c:SetBackdropBorderColor(0.427, 0.020, 0.004, 1.0)

    local t = c:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    t:SetPoint("LEFT", 8, 0)
    t:SetPoint("RIGHT", -22, 0)
    t:SetJustifyH("LEFT")
    t:SetWordWrap(false)
    t:SetTextColor(0.922, 0.718, 0.024, 1.0)

    local arrow = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arrow:SetPoint("RIGHT", -6, -1)
    arrow:SetText("v")
    arrow:SetTextColor(0.922, 0.718, 0.024, 1.0)

    local ROW_H, MAX_VISIBLE = 22, 12
    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetBackdrop(BACKDROP_POPUP)
    popup:SetBackdropColor(0.05, 0.05, 0.05, 0.98)
    popup:SetBackdropBorderColor(0.427, 0.020, 0.004, 1.0)
    popup:Hide()

    local scroll = CreateFrame("ScrollFrame", nil, popup, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", -24, 4)
    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(1, 1)
    scroll:SetScrollChild(scrollChild)

    local rows = {}
    local function rebuildRows()
        local fonts = GetFonts()
        local cfg = LootProConfig[configKey]
        for _, row in ipairs(rows) do row:Hide() end
        for i, fontName in ipairs(fonts) do
            local row = rows[i]
            if not row then
                row = CreateFrame("Button", nil, scrollChild)
                row:SetHeight(ROW_H)
                local hl = row:CreateTexture(nil, "HIGHLIGHT")
                hl:SetAllPoints()
                hl:SetColorTexture(0.541, 0.024, 0.004, 0.45)
                row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.text:SetPoint("LEFT", 6, 0)
                row.text:SetPoint("RIGHT", -6, 0)
                row.text:SetJustifyH("LEFT")
                row.text:SetWordWrap(false)
                row:SetScript("OnClick", function(self)
                    LootProConfig[configKey].font = self.fontName
                    popup:Hide()
                    c.Refresh()
                end)
                rows[i] = row
            end
            if row._builtFont ~= fontName then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * ROW_H)
                row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -(i - 1) * ROW_H)
                row.text:SetText(fontName)
                row.fontName = fontName
                local p = LSM and LSM:Fetch("font", fontName) or DEFAULT_FONT
                SafeSetFont(row.text, p, 13, "")
                row._builtFont = fontName
            end
            if fontName == cfg.font then
                row.text:SetTextColor(0.922, 0.718, 0.024, 1.0)
            else
                row.text:SetTextColor(0.90, 0.90, 0.90, 1.0)
            end
            row:Show()
        end
        scrollChild:SetSize(math.max(1, scroll:GetWidth()), math.max(1, #fonts * ROW_H))
    end

    local function Update()
        local cfg = LootProConfig[configKey]
        t:SetText(cfg.font or "Friz Quadrata TT")
        local p = LSM and LSM:Fetch("font", cfg.font) or DEFAULT_FONT
        SafeSetFont(t, p, 13, "")
        if addon.UpdateAllVisuals then
            addon:UpdateAllVisuals()
        end
    end

    c:SetScript("OnClick", function()
        if popup:IsShown() then popup:Hide(); return end
        local fonts = GetFonts()
        popup:ClearAllPoints()
        popup:SetPoint("TOPLEFT",  c, "BOTTOMLEFT",  0, -2)
        popup:SetWidth(c:GetWidth() + 40)
        local visible = math.min(#fonts, MAX_VISIBLE)
        popup:SetHeight(visible * ROW_H + 8)
        rebuildRows()
        popup:Show()
    end)

    popup:SetScript("OnShow", function(self)
        if not self._closer then
            local closer = CreateFrame("Button", nil, UIParent)
            closer:SetAllPoints(UIParent)
            closer:SetFrameStrata("FULLSCREEN")
            closer:RegisterForClicks("AnyDown")
            closer:SetScript("OnClick", function() self:Hide() end)
            self._closer = closer
        end
        self._closer:Show()
    end)
    popup:SetScript("OnHide", function(self)
        if self._closer then self._closer:Hide() end
    end)

    -- popup is parented to UIParent, so hide it explicitly when the owning page hides.
    parent:HookScript("OnHide", function() popup:Hide() end)

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
    c:SetBackdrop(BACKDROP_CYCLER)
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
        
        if configKey ~= "root" and cfg.font then
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
    
    local valText = _G[name.."Text"]
    valText:SetFontObject("GameFontNormal")
    local valFmt = title .. ": %d" .. ((settingKey == "fade") and "s" or "")
    local lastVal

    s:SetScript("OnValueChanged", function(_, value)
        if not addon:IsReady() then return end
        local val = math.floor(value + 0.5)
        if val == lastVal then return end
        lastVal = val

        if configKey == "root" then
            LootProConfig[settingKey] = val
        else
            LootProConfig[configKey][settingKey] = val
        end

        valText:SetText(valFmt:format(val))

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

function U.CreateColorRow(name, parent, colorKey, previewFunc, label)
    local f = CreateFrame("Button", name, parent, "BackdropTemplate")
    f:SetSize(400, 28)
    f:SetBackdrop(BACKDROP_COLORROW)
    f:SetBackdropColor(0,0,0,0.5)
    
    local tex = f:CreateTexture(nil, "ARTWORK")
    tex:SetSize(16, 16) 
    tex:SetPoint("LEFT", 10, 0)
    
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") 
    title:SetPoint("LEFT", tex, "RIGHT", 10, 0) 
    title:SetText(label or (name:gsub("LPRO_CLR_", "")))
    
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
            local cc = LootProConfig.colors[colorKey]
            cc.r, cc.g, cc.b = r, g, b
            Update()
            if addon.isTesting and addon.PostTestMessages then
                addon:PostTestMessages()
            end
        end
    end
    
    local function CancelColor(prev)
        prev = prev or ColorPickerFrame.previousValues
        if not prev then return end
        local cc = LootProConfig.colors[colorKey]
        cc.r, cc.g, cc.b = prev.r, prev.g, prev.b
        Update()
    end

    local pickerInfo = { swatchFunc = OnColorChanged, cancelFunc = CancelColor }
    local prevValues = {}

    f:SetScript("OnClick", function()
        local c = LootProConfig.colors[colorKey]
        if ColorPickerFrame.SetupColorPickerAndShow then
            pickerInfo.r, pickerInfo.g, pickerInfo.b = c.r, c.g, c.b
            ColorPickerFrame:SetupColorPickerAndShow(pickerInfo)
        else
            ColorPickerFrame.func = OnColorChanged
            ColorPickerFrame.cancelFunc = CancelColor
            prevValues.r, prevValues.g, prevValues.b = c.r, c.g, c.b
            ColorPickerFrame.previousValues = prevValues
            ColorPickerFrame:SetColorRGB(c.r, c.g, c.b)
            ColorPickerFrame:Show()
        end
    end)
    
    f.Refresh = Update
    return f
end

function U.CreateDiscordButton(parent)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetHeight(24)

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.10, 0.10, 0.10, 0.95)

    b.icon = b:CreateTexture(nil, "OVERLAY")
    b.icon:SetSize(16, 16)
    b.icon:SetPoint("LEFT", 10, 0)
    b.icon:SetTexture("Interface\\AddOns\\LootPro\\Media\\Textures\\discord.tga")

    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.text:SetPoint("LEFT", b.icon, "RIGHT", 6, 0)
    b.text:SetText("Join our Discord!")
    b.text:SetTextColor(1.0, 0.133, 0.133)
    b:SetWidth(10 + 16 + 6 + b.text:GetStringWidth() + 12)

    b:SetScript("OnClick", function() addon:ShowDiscord() end)
    b:SetScript("OnEnter", function(s) s.text:SetTextColor(1, 1, 1) end)
    b:SetScript("OnLeave", function(s) s.text:SetTextColor(1.0, 0.133, 0.133) end)
    return b
end