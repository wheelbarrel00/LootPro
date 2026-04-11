local addonName, ns = ...
local addon = {}
ns.addon = addon
addon.VERSION = "1.0.0"

-------------------------------------------------
-- VISUAL UPDATE ENGINE
-------------------------------------------------
local function UpdateFrameVisuals(frame, config)
    if not frame or not config then return end
    
    -- Update Display Properties
    frame.display:SetSize(config.width, config.height)
    
    local fontPath = LibStub("LibSharedMedia-3.0"):Fetch("font", config.font)
    frame.display:SetFont(fontPath, config.size, config.outline ~= "NONE" and config.outline or nil)
    
    frame.display:SetMaxLines(config.maxLines)
    frame.display:SetFading(not addon.isTesting)
    frame.display:SetFadeDuration(config.fade)
end

function addon:UpdateAllVisuals()
    if not LootProConfig then return end
    UpdateFrameVisuals(addon.combatFrame, LootProConfig.combat)
    UpdateFrameVisuals(addon.lootFrame, LootProConfig.loot)
end

-------------------------------------------------
-- UTILITIES & TESTING
-------------------------------------------------
function addon:IsReady()
    return LootProConfig and ns.UI and addon.combatFrame and addon.lootFrame
end

function addon:PostTestMessages()
    if not addon:IsReady() then return end
    
    addon.combatFrame.display:Clear()
    addon.lootFrame.display:Clear()
    
    if LootProConfig.notifications.combatEnter then
        local c = LootProConfig.colors.combatEnter
        addon.combatFrame.display:AddMessage(LootProConfig.combatEnterText, c.r, c.g, c.b)
    end
    
    if LootProConfig.notifications.loot then
        local c = LootProConfig.colors.loot
        addon.lootFrame.display:AddMessage("+1 |T132338:0|t Earthen Shard (24)", c.r, c.g, c.b)
    end
    
    if LootProConfig.notifications.money then
        local c = LootProConfig.colors.money
        addon.lootFrame.display:AddMessage("10 Gold 75 Silver 20 Copper", c.r, c.g, c.b)
    end
end

-------------------------------------------------
-- MAIN EVENT HANDLER
-------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- 1. Initialize Profile (Creates LootProConfig if it's nil)
        if ns.InitializeProfile then
            ns:InitializeProfile()
        end
        
        -- 2. Initialize UI (Now that LootProConfig exists)
        if ns.UI and ns.UI.Initialize then
            ns.UI:Initialize()
        end
        
        -- 3. Apply Visuals
        addon:UpdateAllVisuals()
        
        print("|cFF00FF00Loot Pro v" .. addon.VERSION .. " Loaded. Type /lp for settings.|r")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)