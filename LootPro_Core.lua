local addonName, ns = ...
local addon = ns.addon
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"

local function GetIconString(msg)
    if not msg or type(msg) ~= "string" then return "" end
    
    local itemID = msg:match("item:(%d+)")
    if itemID and LootProConfig.showLootIcons then
        local _, _, _, _, icon = GetItemInfoInstant(itemID)
        if icon then 
            return "|T" .. icon .. ":0|t " 
        end
    end
    return ""
end

local function CleanMessage(msg, event)
    if not msg or type(msg) ~= "string" then return msg end
    
    if event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        local amt, fac = msg:match("gain.- ([%d,]+) reputation with (.+)%.")
        if amt and fac then return fac end
        
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        local amount = msg:match("You gain ([%d,]+) experience")
        if amount then return "+ " .. amount .. " XP" end
        
        local name, amount2 = msg:match("(.+) has gained ([%d,]+) experience")
        if name and amount2 then 
            name = name:gsub("|c%x+", ""):gsub("|r", "")
            return "+ " .. amount2 .. " XP (" .. name .. ")" 
        end
        
    elseif event:find("CHAT_MSG_LOOT") or event:find("CHAT_MSG_CURRENCY") then
        local cleaned = msg:gsub("^You receive loot: ", ""):gsub("^You receive item: ", ""):gsub("^You receive currency: ", ""):gsub("^You loot ", ""):gsub("%.%s*$", ""):gsub("%[", ""):gsub("%]", "")
        cleaned = cleaned:gsub("x%d+$", "") 
        return cleaned
    end
    
    return msg
end

local function CreateReadoutFrame(name, labelText, defaultY, configKey)
    local f = CreateFrame("Frame", name.."Anchor", UIParent, "BackdropTemplate")
    f.configKey = configKey
    f.defaultY = defaultY
    f:SetPoint("CENTER", 0, defaultY) 
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving) 
    
    f:SetScript("OnDragStop", function(self) 
        self:StopMovingOrSizing()
        if addon:IsReady() then 
            local p, _, _, x, y = self:GetPoint()
            LootProConfig[self.configKey].point = p
            LootProConfig[self.configKey].x = x
            LootProConfig[self.configKey].y = y 
        end 
    end)
    
    f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    f.label:SetPoint("CENTER")
    f.label:SetText(labelText)
    f.label:Hide()
    
    f.display = CreateFrame("ScrollingMessageFrame", name.."Display", f)
    f.display:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)
    f.display:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    f.display:SetInsertMode("TOP")
    f.display:SetFading(true)
    f.display:SetFadeDuration(1)
    f.display:SetJustifyH("CENTER")
    f.display:SetJustifyV("TOP")
    
    return f
end

local function CreateMinimapButton()
    local mmBtn = CreateFrame("Button", "LootProMinimapButton", Minimap)
    mmBtn:SetSize(32, 32)
    mmBtn:SetFrameStrata("MEDIUM")
    mmBtn:SetFrameLevel(8)
    mmBtn:RegisterForClicks("AnyUp")
    mmBtn:RegisterForDrag("LeftButton")
    mmBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    local bg = mmBtn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", mmBtn, "TOPLEFT", 6, -6)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    
    local icon = mmBtn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", mmBtn, "TOPLEFT", 6, -6)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08") 
    icon:SetVertexColor(0.6, 0.2, 1.0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    local mask = mmBtn:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    mask:SetSize(20, 20)
    mask:SetPoint("TOPLEFT", mmBtn, "TOPLEFT", 6, -6)
    icon:AddMaskTexture(mask)
    bg:AddMaskTexture(mask)
    
    local border = mmBtn:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", mmBtn, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    
    mmBtn:SetScript("OnClick", function()
        if ns.UI and LootProGUI then
            if LootProGUI:IsShown() then LootProGUI:Hide() else LootProGUI:Show() end
        end
    end)
    
    mmBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Loot Pro ("..addon.VERSION..")", 1, 1, 1)
        GameTooltip:AddLine("Left-Click to open settings.")
        GameTooltip:Show()
    end)
    mmBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    mmBtn:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            local cx, cy = Minimap:GetCenter()
            local x, y = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            x, y = x / scale, y / scale
            local angle = math.deg(math.atan2(y - cy, x - cx))
            LootProConfig.minimap.minimapPos = angle
            addon:UpdateMinimapPosition()
        end)
    end)
    
    mmBtn:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)
    
    return mmBtn
end

addon.combatFrame = CreateReadoutFrame("LootProCombat", "COMBAT & SYSTEM", 150, "combat")
addon.lootFrame = CreateReadoutFrame("LootProLoot", "LOOT & MONEY", 50, "loot")
addon.minimapButton = CreateMinimapButton()

function addon:UpdateMinimapPosition()
    if not self:IsReady() then return end
    local pos = LootProConfig.minimap.minimapPos or 220
    local angle = math.rad(pos)
    
    local radius = (Minimap:GetWidth() / 2) + 5
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    
    local isSquare = false
    if GetMinimapShape and GetMinimapShape():find("SQUARE") then isSquare = true end
    if ElvUI or Tukui or SpartanUI then isSquare = true end
    
    if isSquare then
        local absX, absY = math.abs(math.cos(angle)), math.abs(math.sin(angle))
        local maxCoord = math.max(absX, absY)
        x = (math.cos(angle) / maxCoord) * radius
        y = (math.sin(angle) / maxCoord) * radius
    end
    
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function addon:UpdateAllVisuals()
    if not self:IsReady() then return end
    
    if LootProConfig.minimap.hide then 
        self.minimapButton:Hide() 
    else 
        self.minimapButton:Show() 
        self:UpdateMinimapPosition()
    end
    
    local configs = { 
        {f = self.combatFrame, s = LootProConfig.combat}, 
        {f = self.lootFrame, s = LootProConfig.loot} 
    }
    
    for _, cfg in ipairs(configs) do
        local f, s = cfg.f, cfg.s
        
        f:SetSize(s.width or 800, s.height or 250)
        f:ClearAllPoints()
        f:SetPoint(s.point or "CENTER", UIParent, s.point or "CENTER", s.x or 0, s.y or f.defaultY)
        
        f.display:SetMaxLines(s.maxLines or 4)
        
        f:SetBackdrop({ 
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
            tile = true, 
            tileSize = 16, 
            edgeSize = 16, 
            insets = { left = 3, right = 3, top = 3, bottom = 3 } 
        })
        
        if LootProConfig.locked then 
            f:SetBackdropColor(0,0,0,0)
            f:SetBackdropBorderColor(0,0,0,0)
            f:EnableMouse(false)
            f.label:Hide()
        else 
            f:SetBackdropColor(0,0,0,0.7)
            f:SetBackdropBorderColor(1,1,1,1)
            f:EnableMouse(true)
            f.label:Show() 
        end
        
        local fontPath = LSM and LSM:Fetch("font", s.font) or DEFAULT_FONT
        local flags = (s.outline == "NONE") and "" or (s.outline or "OUTLINE")
        
        if flags == "" then 
            f.display:SetShadowColor(0, 0, 0, 0.6)
            f.display:SetShadowOffset(1, -1) 
        else 
            f.display:SetShadowColor(0, 0, 0, 0)
            f.display:SetShadowOffset(0, 0) 
        end
        
        pcall(function() f.display:SetFont(fontPath, s.size, flags) end)
        f.display:SetTimeVisible(s.fade or 6)
        
        if not self.isTesting then 
            f.display:SetFading(true) 
        end
    end
end

function addon:PostTestMessages()
    self.combatFrame.display:Clear()
    self.lootFrame.display:Clear()
    
    local cc = LootProConfig.colors
    local cD = cc.delver or {r=1, g=0.7, b=0.2}
    
    self.combatFrame.display:AddMessage(LootProConfig.combatEnterText, cc.combatEnter.r, cc.combatEnter.g, cc.combatEnter.b)
    self.combatFrame.display:AddMessage("+ 500 XP", cc.xp.r, cc.xp.g, cc.xp.b)
    self.combatFrame.display:AddMessage("+ Brann Bronzebeard gains 125 Companion XP.", cD.r, cD.g, cD.b)
    self.combatFrame.display:AddMessage(LootProConfig.combatLeaveText, cc.combatLeave.r, cc.combatLeave.g, cc.combatLeave.b)
    
    local icon = LootProConfig.showLootIcons and "|T133644:0|t " or ""
    self.lootFrame.display:AddMessage("+12 |TInterface\\MoneyFrame\\UI-GoldIcon:0|t ", cc.money.r, cc.money.g, cc.money.b)
    self.lootFrame.display:AddMessage("+2 " .. icon .. "Test Item (20)", cc.loot.r, cc.loot.g, cc.loot.b)
end

local evts = {
    "ADDON_LOADED", 
    "PLAYER_LOGIN", 
    "PLAYER_REGEN_DISABLED", 
    "PLAYER_REGEN_ENABLED",
    "CHAT_MSG_LOOT", 
    "