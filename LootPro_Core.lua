local addonName, ns = ...
local addon = ns.addon
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"

local function GetIconString(msg)
    if not msg or type(msg) ~= "string" then return "" end
    
    local itemID = msg:match("item:(%d+)")
    if itemID and LootProConfig.showLootIcons then
        local icon
        if addon.IS_RETAIL then
            local _, _, _, _, _icon = GetItemInfoInstant(itemID)
            icon = _icon
        else
            icon = select(10, GetItemInfo(itemID))  -- returns nil if not yet cached
        end
        if icon then
            return "|T" .. icon .. ":0|t "
        end
    end
    return ""
end

local function CleanMessage(msg, event)
    if not msg or type(msg) ~= "string" then return msg end
    
    if event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        local fac, amt = msg:match("Reputation with (.+) increased by ([%d,]+)%.")
        if amt and fac then return fac end
        local lossFac, lossAmt = msg:match("Reputation with (.+) decreased by ([%d,]+)%.")
        if lossAmt and lossFac then return lossFac end
        
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

-- Minimap icon via LibDataBroker + LibDBIcon
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

addon.lootProLDB = LDB:NewDataObject("LootPro", {
    type = "launcher",
    text = "Loot Pro",
    icon = "Interface\\Icons\\INV_Misc_Bag_08",
    iconR = 0.6, iconG = 0.2, iconB = 1.0,
    OnClick = function(_, button)
        if ns.UI and LootProGUI then
            if LootProGUI:IsShown() then LootProGUI:Hide() else LootProGUI:Show() end
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Loot Pro ("..addon.VERSION..")", 1, 1, 1)
        tooltip:AddLine("Left-Click to open settings.")
    end,
})
addon.LDBIcon = LDBIcon

addon.combatFrame = CreateReadoutFrame("LootProCombat", "COMBAT & SYSTEM", 150, "combat")
addon.lootFrame = CreateReadoutFrame("LootProLoot", "LOOT & MONEY", 50, "loot")

function addon:UpdateAllVisuals()
    if not self:IsReady() then return end
    
    if LootProConfig.minimap.hide then
        self.LDBIcon:Hide("LootPro")
    else
        self.LDBIcon:Show("LootPro")
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
    "CHAT_MSG_CURRENCY", 
    "CHAT_MSG_MONEY", 
    "CHAT_MSG_SKILL", 
    "CHAT_MSG_SYSTEM",
    "CHAT_MSG_COMBAT_FACTION_CHANGE", 
    "CHAT_MSG_COMBAT_XP_GAIN", 
    "CHAT_MSG_COMBAT_HONOR_GAIN"
}

for _, v in ipairs(evts) do 
    addon:RegisterEvent(v) 
end

addon:SetScript("OnEvent", function(self, event, ...)
    local arg1 = ...
    
    if event == "ADDON_LOADED" and arg1 == addonName then 
        self:InitSettings()
        self.LDBIcon:Register("LootPro", self.lootProLDB, LootProConfig.minimap)
        
    elseif event == "PLAYER_LOGIN" then 
        if ns.UI then ns.UI:Initialize() end
        self:UpdateAllVisuals()
        
        -- Trigger welcome screen on login if not disabled
        if ns.UI and ns.UI.welcomeFrame and not LootProConfig.hideWelcome then
            ns.UI.welcomeFrame:Show()
        end
        
    elseif self:IsReady() then
        local c = LootProConfig.colors
        local n = LootProConfig.notifications
        
        if event == "PLAYER_REGEN_DISABLED" then
            if n.combatEnter then 
                self.combatFrame.display:AddMessage(LootProConfig.combatEnterText, c.combatEnter.r, c.combatEnter.g, c.combatEnter.b)
            end
            return
            
        elseif event == "PLAYER_REGEN_ENABLED" then
            if n.combatLeave then 
                self.combatFrame.display:AddMessage(LootProConfig.combatLeaveText, c.combatLeave.r, c.combatLeave.g, c.combatLeave.b)
            end
            return 
        end

        if not arg1 or type(arg1) ~= "string" then return end

        local isFollowerXP = arg1:find("experience") and not arg1:find("You gain")
        if isFollowerXP then
            if not LootProConfig.showFollowerXP then return end
            if n.xp then
                local name, amount2 = arg1:match("(.+) has gained ([%d,]+) experience")
                if name and amount2 then
                    name = name:gsub("|c%x+", ""):gsub("|r", "")
                    self.combatFrame.display:AddMessage("+ " .. amount2 .. " XP (" .. name .. ")", c.xp.r, c.xp.g, c.xp.b)
                else
                    self.combatFrame.display:AddMessage(arg1, c.xp.r, c.xp.g, c.xp.b)
                end
            end
            return
        end

        if event == "CHAT_MSG_COMBAT_XP_GAIN" and n.xp then
            self.combatFrame.display:AddMessage(CleanMessage(arg1, event), c.xp.r, c.xp.g, c.xp.b)
            
        elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
            local amt = arg1:match("Reputation with .+ increased by ([%d,]+)%.")
            local lossAmt = arg1:match("Reputation with .+ decreased by ([%d,]+)%.")
            if amt and n.repGain then 
                self.combatFrame.display:AddMessage("+ " .. amt .. " Rep: " .. CleanMessage(arg1, event), c.repGain.r, c.repGain.g, c.repGain.b)
            elseif lossAmt and n.repLoss then 
                self.combatFrame.display:AddMessage("- " .. lossAmt .. " Rep: " .. CleanMessage(arg1, event), c.repLoss.r, c.repLoss.g, c.repLoss.b) 
            end
            
        elseif event == "CHAT_MSG_SKILL" and n.skill then
            self.combatFrame.display:AddMessage(CleanMessage(arg1, event), c.skill.r, c.skill.g, c.skill.b)
            
        elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" and n.honor then
            self.combatFrame.display:AddMessage(CleanMessage(arg1, event), c.honor.r, c.honor.g, c.honor.b)
            
        elseif event == "CHAT_MSG_SYSTEM" and n.delver then
            if arg1:find("Companion XP") then
                local amt = arg1:match("gains ([%d,]+) Companion")
                if amt then
                    local cD = c.delver or {r=1, g=0.7, b=0.2}
                    self.combatFrame.display:AddMessage("+ " .. amt .. " Delver XP", cD.r, cD.g, cD.b)
                end
            end
            
        elseif event == "CHAT_MSG_MONEY" and n.money then
            if LootProConfig.cleanMode and LootProConfig.showMoneyIcons then
                local g = arg1:match("(%d+)%s*[Gg]old")
                local s = arg1:match("(%d+)%s*[Ss]ilver")
                local co = arg1:match("(%d+)%s*[Cc]opper")
                local st = ""
                
                if g then st = st .. g .. " |TInterface\\MoneyFrame\\UI-GoldIcon:0|t " end
                if s then st = st .. s .. " |TInterface\\MoneyFrame\\UI-SilverIcon:0|t " end
                if co then st = st .. co .. " |TInterface\\MoneyFrame\\UI-CopperIcon:0|t " end
                
                self.lootFrame.display:AddMessage("+ " .. st, c.money.r, c.money.g, c.money.b)
            else 
                self.lootFrame.display:AddMessage(GetIconString(arg1) .. arg1, c.money.r, c.money.g, c.money.b) 
            end
            
        elseif event == "CHAT_MSG_CURRENCY" and n.currency then
            self.lootFrame.display:AddMessage(GetIconString(arg1) .. CleanMessage(arg1, event), c.currency.r, c.currency.g, c.currency.b)
            
        elseif event == "CHAT_MSG_LOOT" and n.loot then
            local itemID = arg1:match("item:(%d+)")
            -- BCC/Task2 fix: if quality is nil (item not cached yet), fail open by using
            -- minQuality as the fallback so uncached items always pass the filter.
            local rawQ = itemID and (addon.IS_RETAIL and C_Item.GetItemQualityByID(itemID)
                                                      or select(3, GetItemInfo(itemID)))
            local q = rawQ or LootProConfig.minQuality

            if q >= LootProConfig.minQuality then
                local amt = tonumber(arg1:match("x(%d+)%.?$")) or 1

                if LootProConfig.cleanMode then
                    local function ShowLoot(countStr)
                        self.lootFrame.display:AddMessage("+" .. amt .. " " .. GetIconString(arg1) .. CleanMessage(arg1, event) .. countStr, c.loot.r, c.loot.g, c.loot.b)
                    end

                    if itemID and LootProConfig.showLootCounts and addon.IS_RETAIL then
                        C_Timer.After(0.1, function()
                            local total = C_Item.GetItemCount(tonumber(itemID), true)
                            ShowLoot(" (" .. total .. ")")
                        end)
                    elseif itemID and LootProConfig.showLootCounts and addon.IS_BCC then
                        -- C_Timer doesn't exist in BCC; GetItemCount does, show immediately
                        local total = GetItemCount(itemID, true) or 0
                        ShowLoot(" (" .. total .. ")")
                    else
                        ShowLoot("")
                    end
                else
                    self.lootFrame.display:AddMessage(GetIconString(arg1) .. arg1, c.loot.r, c.loot.g, c.loot.b)
                end
            end
        end
    end
end)