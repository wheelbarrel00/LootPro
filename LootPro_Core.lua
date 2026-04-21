local addonName, ns = ...
local addon = ns.addon
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"

-- M4: Report font load failures once per bad path so users aren't left with a
-- silently-broken readout. Warnings are rate-limited to one print per path.
addon._badFonts = addon._badFonts or {}
local function SafeSetFont(region, path, size, flags)
    local ok = pcall(function() region:SetFont(path, size, flags) end)
    if ok then return true end
    if not addon._badFonts[path or "?"] then
        addon._badFonts[path or "?"] = true
        print("|cFFFF6060[LootPro]|r Failed to load font '"..tostring(path).."', falling back to default.")
    end
    pcall(function() region:SetFont(DEFAULT_FONT, size, flags) end)
    return false
end
addon._SafeSetFont = SafeSetFont

-- M2: Convert a Blizzard format string (e.g. FACTION_STANDING_INCREASED)
-- into a Lua pattern. Handles locales with different thousands-separators.
local function ToPattern(s)
    if not s then return nil end
    s = s:gsub("([%.%[%]%(%)%+%-%?%^%$])", "%%%1")
    s = s:gsub("%%s", "(.-)")
    s = s:gsub("%%d", "([%%d%%p%%s]+)")
    return s
end

local PAT_FACTION_UP   = ToPattern(_G.FACTION_STANDING_INCREASED or "Reputation with %s increased by %d.")
local PAT_FACTION_DOWN = ToPattern(_G.FACTION_STANDING_DECREASED or "Reputation with %s decreased by %d.")

local function LeadIn(fmt)
    if not fmt then return nil end
    local head = fmt:match("^(.-)%%s")
    if not head or head == "" then return nil end
    return head
end
local function EscapeLiteral(s)
    return (s:gsub("([%.%[%]%(%)%+%-%?%^%$%%])", "%%%1"))
end
local LOOT_PREFIX_PATS = {}
for _, fmt in ipairs({
    _G.LOOT_ITEM_SELF, _G.LOOT_ITEM_PUSHED_SELF, _G.CURRENCY_GAINED,
    _G.LOOT_ITEM_SELF_MULTIPLE, _G.LOOT_ITEM_PUSHED_SELF_MULTIPLE,
}) do
    local head = LeadIn(fmt)
    if head then LOOT_PREFIX_PATS[#LOOT_PREFIX_PATS+1] = "^"..EscapeLiteral(head) end
end
-- English fallbacks for clients where globals are missing.
LOOT_PREFIX_PATS[#LOOT_PREFIX_PATS+1] = "^You receive loot: "
LOOT_PREFIX_PATS[#LOOT_PREFIX_PATS+1] = "^You receive item: "
LOOT_PREFIX_PATS[#LOOT_PREFIX_PATS+1] = "^You receive currency: "
LOOT_PREFIX_PATS[#LOOT_PREFIX_PATS+1] = "^You loot "

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
        if PAT_FACTION_UP then
            local fac = msg:match(PAT_FACTION_UP)
            if fac then return fac end
        end
        if PAT_FACTION_DOWN then
            local fac = msg:match(PAT_FACTION_DOWN)
            if fac then return fac end
        end
        
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        -- Locale-agnostic: grab the first number sequence from the message.
        local amount = msg:match("([%d%p%s]*%d)")
        if amount then return "+ " .. amount .. " XP" end
        
    elseif event:find("CHAT_MSG_LOOT") or event:find("CHAT_MSG_CURRENCY") then
        local cleaned = msg
        for _, pat in ipairs(LOOT_PREFIX_PATS) do
            cleaned = cleaned:gsub(pat, "")
        end
        cleaned = cleaned:gsub("%.%s*$", ""):gsub("%[", ""):gsub("%]", "")
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
            -- M3: Capture BOTH the self-anchor and the relative-anchor so we can
            -- round-trip position exactly. GetPoint returns
            -- (point, relativeTo, relativePoint, x, y).
            local p, _, rp, x, y = self:GetPoint()
            LootProConfig[self.configKey].point = p
            LootProConfig[self.configKey].relativePoint = rp or p
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
    
    -- H1: Many of the setters below are expensive (SetBackdrop rebuilds border
    -- textures; SetMaxLines clears the message buffer and is visible to the
    -- user). UpdateAllVisuals is called from every slider tick, every checkbox
    -- click, every color change -- so we guard each expensive op with a cache
    -- key and only re-apply when the relevant inputs actually changed.
    for _, cfg in ipairs(configs) do
        local f, s = cfg.f, cfg.s

        local width, height = s.width or 800, s.height or 250
        if f._w ~= width or f._h ~= height then
            f:SetSize(width, height)
            f._w, f._h = width, height
        end

        local point = s.point or "CENTER"
        local relPoint = s.relativePoint or point
        local x, y = s.x or 0, s.y or f.defaultY
        if f._point ~= point or f._relPoint ~= relPoint or f._x ~= x or f._y ~= y then
            f:ClearAllPoints()
            f:SetPoint(point, UIParent, relPoint, x, y)
            f._point, f._relPoint, f._x, f._y = point, relPoint, x, y
        end

        local maxLines = s.maxLines or 4
        if f.display._maxLines ~= maxLines then
            f.display:SetMaxLines(maxLines)
            f.display._maxLines = maxLines
        end

        if not f._backdropApplied then
            f:SetBackdrop({ 
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
                tile = true, 
                tileSize = 16, 
                edgeSize = 16, 
                insets = { left = 3, right = 3, top = 3, bottom = 3 } 
            })
            f._backdropApplied = true
        end
        
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

        local fontKey = tostring(fontPath).."|"..tostring(s.size).."|"..flags
        if f.display._fontKey ~= fontKey then
            SafeSetFont(f.display, fontPath, s.size, flags)
            f.display._fontKey = fontKey
        end
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
    
    self.combatFrame.display:AddMessage(LootProConfig.combatEnterText, cc.combatEnter.r, cc.combatEnter.g, cc.combatEnter.b)
    self.combatFrame.display:AddMessage("+ 500 XP", cc.xp.r, cc.xp.g, cc.xp.b)
    self.combatFrame.display:AddMessage(LootProConfig.combatLeaveText, cc.combatLeave.r, cc.combatLeave.g, cc.combatLeave.b)
    
    local icon = LootProConfig.showLootIcons and "|T134414:0|t " or ""
    self.lootFrame.display:AddMessage("+12 |TInterface\\MoneyFrame\\UI-GoldIcon:0|t ", cc.money.r, cc.money.g, cc.money.b)
    self.lootFrame.display:AddMessage("+1 " .. icon .. "Hearthstone (1)", cc.loot.r, cc.loot.g, cc.loot.b)
end

-- Regression harness. Invoked via "/lp test". Fires synthetic chat events
-- through the real OnEvent handler and checks each readout's message count
-- to verify the path produced output. Uses evergreen in-game references
-- (Hearthstone itemID 6948, Stormwind and Bloodsail Buccaneers factions).
function addon:RunRegressionTest()
    if not self:IsReady() then
        print("|cFFFF6060[LootPro]|r Cannot run test: addon not initialized.")
        return
    end

    local handler = self:GetScript("OnEvent")
    if not handler then
        print("|cFFFF6060[LootPro]|r OnEvent handler missing.")
        return
    end

    -- Snapshot every config knob the test flips so we restore cleanly.
    local n = LootProConfig.notifications
    local snapshot = {
        notifications = {},
        cleanMode = LootProConfig.cleanMode,
        showFollowerXP = LootProConfig.showFollowerXP,
        showLootCounts = LootProConfig.showLootCounts,
        showLootIcons = LootProConfig.showLootIcons,
        showMoneyIcons = LootProConfig.showMoneyIcons,
        minQuality = LootProConfig.minQuality,
    }
    for k, v in pairs(n) do snapshot.notifications[k] = v end

    -- Force all paths on for the duration of the run.
    for k in pairs(n) do n[k] = true end
    LootProConfig.cleanMode = true
    LootProConfig.showFollowerXP = true
    LootProConfig.showLootCounts = false -- suppress the C_Timer.After path
    LootProConfig.showLootIcons = true
    LootProConfig.showMoneyIcons = true
    LootProConfig.minQuality = 0

    local combat = self.combatFrame.display
    local loot = self.lootFrame.display
    combat:Clear()
    loot:Clear()

    local FACTION_UP   = (_G.FACTION_STANDING_INCREASED or "Reputation with %s increased by %d."):format("Silvermoon Court", 250)
    local FACTION_DOWN = (_G.FACTION_STANDING_DECREASED or "Reputation with %s decreased by %d."):format("Bloodsail Buccaneers", 25)
    local CURRENCY_MSG = (_G.CURRENCY_GAINED or "You receive currency: %s."):format("Kej")
    -- Hearthstone (itemID 6948) link form the client accepts.
    local HEARTHSTONE_LOOT = "You receive loot: |cff9d9d9d|Hitem:6948::::::::70:::::::|h[Hearthstone]|h|r."

    local cases = {
        { name = "Combat Start", event = "PLAYER_REGEN_DISABLED",        arg = nil,                target = combat },
        { name = "Combat End",   event = "PLAYER_REGEN_ENABLED",         arg = nil,                target = combat },
        { name = "XP Gain",      event = "CHAT_MSG_COMBAT_XP_GAIN",      arg = "You gain 1500 experience.", target = combat },
        { name = "Follower XP",  event = "CHAT_MSG_COMBAT_XP_GAIN",      arg = "Pet has gained 500 experience.", target = combat },
        { name = "Skill Gain",   event = "CHAT_MSG_SKILL",               arg = "Your skill in Blacksmithing (Midnight) has increased to 50.", target = combat },
        { name = "Honor",        event = "CHAT_MSG_COMBAT_HONOR_GAIN",   arg = "You have been awarded 15 honor points.", target = combat },
        { name = "Rep Gain",     event = "CHAT_MSG_COMBAT_FACTION_CHANGE", arg = FACTION_UP,       target = combat },
        { name = "Rep Loss",     event = "CHAT_MSG_COMBAT_FACTION_CHANGE", arg = FACTION_DOWN,     target = combat },
        { name = "Delver XP",    event = "CHAT_MSG_SYSTEM",              arg = "Brann Bronzebeard gains 125 Companion XP.", target = combat },
        { name = "Money",        event = "CHAT_MSG_MONEY",               arg = "You loot 12 Gold, 50 Silver, 20 Copper.", target = loot },
        { name = "Currency",     event = "CHAT_MSG_CURRENCY",            arg = CURRENCY_MSG,       target = loot },
        { name = "Loot (item 6948)", event = "CHAT_MSG_LOOT",            arg = HEARTHSTONE_LOOT,   target = loot },
    }

    print("|cFFAAAAFF[LootPro]|r Running regression test (12 cases)...")
    local pass, fail = 0, 0
    for _, tc in ipairs(cases) do
        local before = tc.target:GetNumMessages()
        local ok, err = pcall(handler, self, tc.event, tc.arg)
        local after = tc.target:GetNumMessages()
        local produced = after > before
        if ok and produced then
            pass = pass + 1
            print(string.format("  |cFF00FF00[PASS]|r %-22s (+%d msg)", tc.name, after - before))
        else
            fail = fail + 1
            local reason = (not ok) and ("error: "..tostring(err)) or "no output produced"
            print(string.format("  |cFFFF4040[FAIL]|r %-22s (%s)", tc.name, reason))
        end
    end

    -- Restore.
    for k, v in pairs(snapshot.notifications) do n[k] = v end
    LootProConfig.cleanMode = snapshot.cleanMode
    LootProConfig.showFollowerXP = snapshot.showFollowerXP
    LootProConfig.showLootCounts = snapshot.showLootCounts
    LootProConfig.showLootIcons = snapshot.showLootIcons
    LootProConfig.showMoneyIcons = snapshot.showMoneyIcons
    LootProConfig.minQuality = snapshot.minQuality

    print(string.format("|cFFAAAAFF[LootPro]|r Result: |cFF00FF00%d passed|r, |cFFFF4040%d failed|r (of %d).",
        pass, fail, #cases))
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
        -- H3: We only care about our own ADDON_LOADED. Stop receiving every
        -- other addon's load event for the rest of the session.
        self:UnregisterEvent("ADDON_LOADED")
        return
        
    elseif event == "PLAYER_LOGIN" then 
        -- M1: Defensive guard in case saved variables didn't initialize via
        -- the normal ADDON_LOADED path (e.g. event ordering quirks).
        if not self:IsReady() then self:InitSettings() end
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

        -- L2: Follower-XP detection only makes sense for XP events. Previously
        -- this ran on every chat/faction/currency/money event.
        if event == "CHAT_MSG_COMBAT_XP_GAIN" then
            local name, amount2 = arg1:match("(.+) has gained ([%d%p%s]*%d)%s+%a+")
            -- If there's a named subject, treat as follower/pet XP.
            if name and amount2 and not arg1:match("^You") then
                if not LootProConfig.showFollowerXP then return end
                if n.xp then
                    name = name:gsub("|c%x+", ""):gsub("|r", "")
                    self.combatFrame.display:AddMessage("+ " .. amount2 .. " XP (" .. name .. ")", c.xp.r, c.xp.g, c.xp.b)
                end
                return
            end
        end

        if event == "CHAT_MSG_COMBAT_XP_GAIN" and n.xp then
            self.combatFrame.display:AddMessage(CleanMessage(arg1, event), c.xp.r, c.xp.g, c.xp.b)
            
        elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
            -- M2: Use Blizzard's localized format string to parse faction +/-.
            local fac, amt = nil, nil
            if PAT_FACTION_UP then fac, amt = arg1:match(PAT_FACTION_UP) end
            local lossFac, lossAmt = nil, nil
            if not amt and PAT_FACTION_DOWN then lossFac, lossAmt = arg1:match(PAT_FACTION_DOWN) end
            if amt and n.repGain then 
                self.combatFrame.display:AddMessage("+ " .. amt .. " Rep: " .. (fac or ""), c.repGain.r, c.repGain.g, c.repGain.b)
            elseif lossAmt and n.repLoss then 
                self.combatFrame.display:AddMessage("- " .. lossAmt .. " Rep: " .. (lossFac or ""), c.repLoss.r, c.repLoss.g, c.repLoss.b) 
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
                        -- M5: Skip the 100 ms defer when the item is already cached.
                        -- Under AoE loot this avoids scheduling dozens of timers per pull.
                        local id = tonumber(itemID)
                        if id and C_Item.GetItemNameByID(id) then
                            ShowLoot(" (" .. (C_Item.GetItemCount(id, true) or 0) .. ")")
                        else
                            C_Timer.After(0.1, function()
                                ShowLoot(" (" .. (C_Item.GetItemCount(id, true) or 0) .. ")")
                            end)
                        end
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