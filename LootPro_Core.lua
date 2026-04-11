local addonName, ns = ...
local addon = {}
ns.addon = addon
addon.VERSION = "1.0.0"

local function UpdateFrameVisuals(frame, config)
    if not frame then return end
    frame.display:SetSize(config.width, config.height)
    frame.display:SetFont(LibStub("LibSharedMedia-3.0"):Fetch("font", config.font), config.size, config.outline ~= "NONE" and config.outline or nil)
    frame.display:SetMaxLines(config.maxLines)
    frame.display:SetFading(not addon.isTesting)
    frame.display:SetFadeDuration(config.fade)
end

function addon:UpdateAllVisuals()
    UpdateFrameVisuals(addon.combatFrame, LootProConfig.combat)
    UpdateFrameVisuals(addon.lootFrame, LootProConfig.loot)
end

function addon:IsReady()
    return LootProConfig and ns.UI and addon.combatFrame and addon.lootFrame
end

function addon:PostTestMessages()
    if not addon:IsReady() then return end
    addon.combatFrame.display:Clear()
    addon.lootFrame.display:Clear()
    
    if LootProConfig.notifications.combatEnter then
        addon.combatFrame.display:AddMessage(LootProConfig.combatEnterText, LootProConfig.colors.combatEnter.r, LootProConfig.colors.combatEnter.g, LootProConfig.colors.combatEnter.b)
    end
    
    if LootProConfig.notifications.loot then
        addon.lootFrame.display:AddMessage("+1 |T132338:0|t Earthen Shard (24)", LootProConfig.colors.loot.r, LootProConfig.colors.loot.g, LootProConfig.colors.loot.b)
    end
    
    if LootProConfig.notifications.money then
        addon.lootFrame.display:AddMessage("10 Gold 75 Silver 20 Copper", LootProConfig.colors.money.r, LootProConfig.colors.money.g, LootProConfig.colors.money.b)
    end
end

-- Core Event Logic (Simplified for Rebrand)
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        ns.UI:Initialize()
        addon:UpdateAllVisuals()
        print("|cFF00FF00Loot Pro v" .. addon.VERSION .. " Loaded. Type /lp for settings.|r")
    end
end)