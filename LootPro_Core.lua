local addonName, ns = ...
local addon = ns.addon
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"

local _tonumber, _tostring = tonumber, tostring
local _match, _format, _gsub, _find = string.match, string.format, string.gsub, string.find
local _select = select
local _GetTime = GetTime
local _After = C_Timer and C_Timer.After
local _NewTicker = C_Timer and C_Timer.NewTicker
local _GetItemCount = (C_Item and C_Item.GetItemCount) or GetItemCount
local _GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local _GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
local _GetItemQualityByID = C_Item and C_Item.GetItemQualityByID
local _GetItemNameByID = C_Item and C_Item.GetItemNameByID
local _GetCurrencyInfo = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo
-- 12.0 "secret values": guard before any string op on a CHAT_MSG payload (nil pre-12.0).
local _issecret = issecretvalue

local NEW_APPEARANCE_TAG = " |cff66ccff(new look)|r"
local UPGRADE_TAG = " |cff1eff00(upgrade)|r"

local FADE_SCALE_PER_LINE = 0.6
local FADE_SCALE_MAX = 30

addon._badFonts = addon._badFonts or {}
local _badFontCount = 0
local _BAD_FONT_LIMIT = 50
local function SafeSetFont(region, path, size, flags)
    local ok = pcall(region.SetFont, region, path, size, flags)
    if ok then return true end
    if not addon._badFonts[path or "?"] and _badFontCount < _BAD_FONT_LIMIT then
        addon._badFonts[path or "?"] = true
        _badFontCount = _badFontCount + 1
        print("|cFFFF6060[LootPro]|r Failed to load font '".._tostring(path).."', falling back to default.")
    end
    pcall(region.SetFont, region, DEFAULT_FONT, size, flags)
    return false
end
addon._SafeSetFont = SafeSetFont

local function ToPattern(s)
    if not s then return nil end
    s = s:gsub("([%.%[%]%(%)%+%-%?%^%$])", "%%%1")
    s = s:gsub("%%s", "(.-)")
    s = s:gsub("%%d", "([%%d%%p%%s]+)")
    return s
end

local PAT_FACTION_UP   = ToPattern(_G.FACTION_STANDING_INCREASED or "Reputation with %s increased by %d.")
local PAT_FACTION_DOWN = ToPattern(_G.FACTION_STANDING_DECREASED or "Reputation with %s decreased by %d.")
-- 11.0+ account-wide (Warband) reputations use a differently-worded line ("Your Warband's reputation with...") that the base patterns cannot match. The globals are absent on Classic, so ToPattern returns nil there.
local PAT_FACTION_UP_AW   = ToPattern(_G.FACTION_STANDING_INCREASED_ACCOUNT_WIDE)
local PAT_FACTION_DOWN_AW = ToPattern(_G.FACTION_STANDING_DECREASED_ACCOUNT_WIDE)

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
LOOT_PREFIX_PATS[#LOOT_PREFIX_PATS+1] = "^You receive loot: "
LOOT_PREFIX_PATS[#LOOT_PREFIX_PATS+1] = "^You receive item: "
LOOT_PREFIX_PATS[#LOOT_PREFIX_PATS+1] = "^You receive currency: "
LOOT_PREFIX_PATS[#LOOT_PREFIX_PATS+1] = "^You loot "

do
    local seen = {}
    local deduped = {}
    for _, pat in ipairs(LOOT_PREFIX_PATS) do
        if not seen[pat] then
            seen[pat] = true
            deduped[#deduped + 1] = pat
        end
    end
    LOOT_PREFIX_PATS = deduped
    seen = nil
end

-- Locale-aware: derive money patterns from the GOLD/SILVER/COPPER_AMOUNT globals so parsing works on non-English clients.
local function MoneyPattern(fmt)
    if not fmt then return nil end
    fmt = fmt:gsub("([%.%[%]%(%)%+%-%?%^%$])", "%%%1")
    fmt = fmt:gsub("%%d", "([%%d%%p]+)")
    return fmt
end
local PAT_GOLD   = MoneyPattern(_G.GOLD_AMOUNT   or "%d Gold")
local PAT_SILVER = MoneyPattern(_G.SILVER_AMOUNT or "%d Silver")
local PAT_COPPER = MoneyPattern(_G.COPPER_AMOUNT or "%d Copper")

local function MoneyAmount(s)
    if not s then return 0 end
    return _tonumber((_gsub(s, "%D", ""))) or 0
end

-- Map link RGB -> quality. The link color is the ACTUAL (bonus-adjusted) quality; GetItemQualityByID returns BASE quality (a downscaled epic-base green would wrongly trip the rare alert) and needs the item cache.
local QUALITY_BY_RGB = {}
do
    local qc = _G.ITEM_QUALITY_COLORS
    if qc then
        for q = 0, 10 do
            local c = qc[q]
            if c and c.hex then
                QUALITY_BY_RGB[c.hex:sub(-6):lower()] = q
            end
        end
    end
end

local function IsSelfLoot(msg)
    if not msg or type(msg) ~= "string" then return false end
    for _, pat in ipairs(LOOT_PREFIX_PATS) do
        if _find(msg, pat) then return true end
    end
    return false
end

local function GetIconString(msg)
    if not msg or type(msg) ~= "string" then return "" end

    local itemID = _match(msg, "item:(%d+)")
    if itemID and LootProConfig.showLootIcons then
        local icon
        if _GetItemInfoInstant then
            local _, _, _, _, _icon = _GetItemInfoInstant(itemID)
            icon = _icon
        else
            icon = _select(10, _GetItemInfo(itemID))
        end
        if icon then
            return "|T" .. icon .. ":0|t "
        end
    end
    return ""
end

local function TrailerRepl(m)
    if m == "" then return m end
    if _find(m, "x%d") or _find(m, "%.") then return "" end
    return m
end

local function CleanMessage(msg, event)
    if not msg or type(msg) ~= "string" then return msg end
    
    if event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        if PAT_FACTION_UP then
            local fac = _match(msg, PAT_FACTION_UP)
            if fac then return fac end
        end
        if PAT_FACTION_DOWN then
            local fac = _match(msg, PAT_FACTION_DOWN)
            if fac then return fac end
        end
        
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        local amount = _match(msg, "([%d%p%s]*%d)")
        if amount then return "+ " .. amount .. " XP" end
        
    elseif _find(event, "CHAT_MSG_LOOT") or _find(event, "CHAT_MSG_CURRENCY") then
        local cleaned = msg
        local n
        for _, pat in ipairs(LOOT_PREFIX_PATS) do
            cleaned, n = _gsub(cleaned, pat, "")
            if n > 0 then break end
        end
        -- Retail loot messages embed their own |T..|t icon; strip it since GetIconString prepends ours (else double icons).
        cleaned = _gsub(cleaned, "|T[^|]-|t%s*", "")
        cleaned = _gsub(cleaned, "[%[%]]", "")
        cleaned = _gsub(cleaned, "x?%d*%s*%.?%s*$", TrailerRepl)
        return cleaned
    end
    
    return msg
end

-- These report XP or an instant consumable as the "quantity", not a stack count, so render them without a count.
local NO_COUNT_PATTERNS = {
    "Companion XP",
    "Companion Experience",
    "Boon of Power",
}
local function IsNoCountItem(cleanName)
    if not cleanName then return false end
    for _, pat in ipairs(NO_COUNT_PATTERNS) do
        if cleanName:find(pat, 1, true) then return true end
    end
    return false
end

-- Some items fire both CHAT_MSG_LOOT and CHAT_MSG_CURRENCY (vendor buys), or CURRENCY twice (delve events); dedup by name within a tight window so the line shows once.
local recentLoot = {}
local recentCurrency = {}
local DEDUP_WINDOW = 0.25
local CURRENCY_DEDUP_WINDOW = 0.5
-- Loot marks must outlive the currency deferral (which waits DEDUP_WINDOW) or a same-frame loot+currency pair reads the mark as just-expired and the line shows twice.
local LOOT_MARK_TTL = DEDUP_WINDOW * 2
local function ExtractItemName(s)
    if not s then return nil end
    return _match(s, "|h%[(.-)%]|h")
end
local function MarkLootSeen(name)
    if name then recentLoot[name] = _GetTime() end
end
local function IsRecentLoot(name)
    if not name then return false end
    local t = recentLoot[name]
    if not t then return false end
    if _GetTime() - t > LOOT_MARK_TTL then
        recentLoot[name] = nil
        return false
    end
    return true
end
local function MarkCurrencyShown(name)
    if name then recentCurrency[name] = _GetTime() end
end
local function IsRecentCurrency(name)
    if not name then return false end
    local t = recentCurrency[name]
    if not t then return false end
    if _GetTime() - t > CURRENCY_DEDUP_WINDOW then
        recentCurrency[name] = nil
        return false
    end
    return true
end

-- Final dedup on the fully-rendered line (count included) catches doubled LOOT lines the name dedup misses; a real second drop differs by count, so it still shows.
local DISPLAY_DEDUP_WINDOW = 0.3
local DISP_RING = 8
local _dispStr, _dispTime, _dispIdx = {}, {}, 0
local function IsDuplicateDisplay(line)
    local now = _GetTime()
    for i = 1, DISP_RING do
        if _dispStr[i] == line and (now - _dispTime[i]) <= DISPLAY_DEDUP_WINDOW then
            return true
        end
    end
    _dispIdx = (_dispIdx % DISP_RING) + 1
    _dispStr[_dispIdx] = line
    _dispTime[_dispIdx] = now
    return false
end

-- Lazy expiry-on-read leaks entries for items looted once and never seen again; this sweep clears stale dedup entries every 60s.
local function _SweepDedup()
    local now = _GetTime()
    for name, t in pairs(recentLoot) do
        if now - t > LOOT_MARK_TTL then
            recentLoot[name] = nil
        end
    end
    for name, t in pairs(recentCurrency) do
        if now - t > CURRENCY_DEDUP_WINDOW then
            recentCurrency[name] = nil
        end
    end
end
local _dedupTicker = _NewTicker and _NewTicker(60, _SweepDedup) or nil

-- Pooled param tables + pre-bound timer fns (rotated per event) so the hot loot path allocates zero closures; a slot is reused only after POOL_SIZE events.
local POOL_SIZE = 16
local _curParams = {}
local _curFns    = {}
local _lootParams = {}
local _lootFns    = {}
local _curSlot, _lootSlot = 0, 0

local function CountSuffix(nn)
    nn = _tonumber(nn) or 0
    if nn <= 0 then return "" end
    return " (" .. nn .. ")"
end

local function PostCurrency(p)
    if IsRecentLoot(p.currencyName) then return end
    local display = addon.lootFrame.display
    local cap = p.capStr or ""
    local line
    if p.noCount then
        line = p.iconStr .. p.text .. cap
    elseif p.cleanMode then
        line = "+" .. p.amt .. " " .. p.iconStr .. p.text .. CountSuffix(p.total) .. cap
    else
        line = p.iconStr .. p.text .. CountSuffix(p.total) .. cap
    end
    if IsDuplicateDisplay(line) then return end
    display:AddMessage(line, p.cR, p.cG, p.cB)
end

local function ShowLoot(p, countStr)
    local display = addon.lootFrame.display
    local marker = p.marker or ""
    local line
    if p.noCount then
        line = p.iconStr .. p.cleaned .. marker
    else
        line = "+" .. p.amt .. " " .. p.iconStr .. p.cleaned .. countStr .. marker
    end
    if IsDuplicateDisplay(line) then return end
    display:AddMessage(line, p.cR, p.cG, p.cB)
end

local function PostDeferredLoot(p)
    -- At +0.1s BAG_UPDATE has landed so GetItemCount is already post-loot. Take the larger of it and the pre-loot snapshot plus amt so we neither double-count nor under-count.
    local live = (_GetItemCount and _GetItemCount(p.itemID, true)) or 0
    local cnt = math.max((p.preCount or 0) + p.amt, live)
    ShowLoot(p, CountSuffix(cnt))
end

for i = 1, POOL_SIZE do
    _curParams[i]  = {}
    _lootParams[i] = {}
    local idx = i
    _curFns[i]  = function() PostCurrency(_curParams[idx]) end
    _lootFns[i] = function() PostDeferredLoot(_lootParams[idx]) end
end

local _lootSync = {}

-- Hover-pause calls SetFading(false), which snaps every buffered (faded) line back to full alpha; clear the buffer once the feed has fully faded so a later mouse-over can't resurrect old lines.
local FADE_OUT  = 1     -- must match SetFadeDuration below
local SWEEP_PAD = 0.3

local function LineLife(disp, configKey)
    local s = LootProConfig and LootProConfig[configKey]
    return (disp._timeVisible or (s and s.fade) or 6) + FADE_OUT + SWEEP_PAD
end

local function SweepReadout(f)
    f._sweepPending = false
    if addon.isTesting then return end
    local disp = f.display
    if disp:GetNumMessages() == 0 then return end
    local idle = _GetTime() - (disp._lastAdd or 0)
    local life = LineLife(disp, f.configKey)
    if idle < life or (f.IsMouseOver and f:IsMouseOver()) then
        f._sweepPending = true
        if _After then _After(math.max(0.3, life - idle), f._sweepFn) end
        return
    end
    disp:Clear()
end

local function ScheduleSweep(f)
    if f._sweepPending or not _After then return end
    f._sweepPending = true
    _After(LineLife(f.display, f.configKey), f._sweepFn)
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

    f._sweepFn = function() SweepReadout(f) end

    f:SetScript("OnEnter", function(self)
        if not (LootProConfig and LootProConfig.hoverPause) or addon.isTesting then return end
        local disp = self.display
        if _GetTime() - (disp._lastAdd or 0) >= LineLife(disp, self.configKey) then
            disp:Clear()
        else
            disp:SetFading(false)
        end
    end)
    f:SetScript("OnLeave", function(self)
        if not (LootProConfig and LootProConfig.hoverPause) then return end
        self.display:SetFading(not addon.isTesting)
        if not addon.isTesting then ScheduleSweep(self) end
    end)

    hooksecurefunc(f.display, "AddMessage", function(disp)
        disp._lastAdd = _GetTime()
        local s = LootProConfig and LootProConfig[configKey]
        local base = (s and s.fade) or 6
        if LootProConfig and LootProConfig.fadeScale then
            local n = disp:GetNumMessages() or 1
            local t = base + (n - 1) * FADE_SCALE_PER_LINE
            if t > FADE_SCALE_MAX then t = FADE_SCALE_MAX end
            disp:SetTimeVisible(t)
            disp._timeVisible = t
        else
            disp._timeVisible = base
        end
        if LootProConfig and LootProConfig.hoverPause and not addon.isTesting then
            ScheduleSweep(f)
        end
    end)

    return f
end

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local MM_ACTION_LABEL = {
    settings = "Open Settings",
    recap    = "Print Recap",
    lock     = "Toggle Window Lock",
    none     = "Nothing",
}

function addon:DoMinimapAction(action)
    if action == "settings" then
        if ns.UI and LootProGUI then
            if LootProGUI:IsShown() then LootProGUI:Hide() else LootProGUI:Show() end
        end
    elseif action == "recap" then
        if self.RecapPrint then self:RecapPrint() end
    elseif action == "lock" then
        if self:IsReady() then
            LootProConfig.locked = not LootProConfig.locked
            self:UpdateAllVisuals()
        end
    end
end

addon.lootProLDB = LDB:NewDataObject("LootPro", {
    type = "launcher",
    text = "Loot Pro",
    icon = "Interface\\AddOns\\LootPro\\Media\\LootProIcon",
    OnClick = function(_, button)
        local mm = LootProConfig and LootProConfig.minimap
        local action = "settings"
        if mm then
            if button == "RightButton" then action = mm.rightClick or "none"
            elseif button == "MiddleButton" then action = mm.middleClick or "none"
            else action = mm.leftClick or "settings" end
        end
        addon:DoMinimapAction(action)
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Loot Pro ("..addon.VERSION..")", 1, 1, 1)
        local mm = LootProConfig and LootProConfig.minimap
        if mm then
            tooltip:AddLine("Left: "  ..(MM_ACTION_LABEL[mm.leftClick]   or "Nothing"), 0.8, 0.8, 0.8)
            tooltip:AddLine("Right: " ..(MM_ACTION_LABEL[mm.rightClick]  or "Nothing"), 0.8, 0.8, 0.8)
            tooltip:AddLine("Middle: "..(MM_ACTION_LABEL[mm.middleClick] or "Nothing"), 0.8, 0.8, 0.8)
        end
    end,
})
addon.LDBIcon = LDBIcon

addon.combatFrame = CreateReadoutFrame("LootProCombat", "COMBAT & SYSTEM", 150, "combat")
addon.lootFrame = CreateReadoutFrame("LootProLoot", "LOOT & MONEY", 50, "loot")

local _updateConfigsBuf = { {}, {} }

function addon:UpdateAllVisuals()
    if not self:IsReady() then return end
    
    if LootProConfig.minimap.hide then
        self.LDBIcon:Hide("LootPro")
    else
        self.LDBIcon:Show("LootPro")
    end    
    
    _updateConfigsBuf[1].f, _updateConfigsBuf[1].s = self.combatFrame, LootProConfig.combat
    _updateConfigsBuf[2].f, _updateConfigsBuf[2].s = self.lootFrame,   LootProConfig.loot

    -- Guard each expensive setter with a cache key; UpdateAllVisuals fires on every slider tick, and re-applying SetMaxLines visibly clears the message buffer.
    for _, cfg in ipairs(_updateConfigsBuf) do
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
            -- hover-pause: motion-only mouse so OnEnter/OnLeave fire while clicks pass through the locked readout (retail-era API; else fully disabled).
            if LootProConfig.hoverPause and f.SetMouseMotionEnabled and f.SetMouseClickEnabled then
                f:SetMouseClickEnabled(false)
                f:SetMouseMotionEnabled(true)
            else
                f:EnableMouse(false)
            end
            f.label:Hide()
        else
            f:SetBackdropColor(0,0,0,0.7)
            f:SetBackdropBorderColor(1,1,1,1)
            f:EnableMouse(true)
            if f.SetMouseClickEnabled then f:SetMouseClickEnabled(true) end
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

        local fontKey = _tostring(fontPath).."|".._tostring(s.size).."|"..flags
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
    
    local money = "204 |TInterface\\MoneyFrame\\UI-GoldIcon:0|t "
        .. "5 |TInterface\\MoneyFrame\\UI-SilverIcon:0|t "
        .. "32 |TInterface\\MoneyFrame\\UI-CopperIcon:0|t "
    self.lootFrame.display:AddMessage("+ " .. money, cc.money.r, cc.money.g, cc.money.b)

    local function TestLootIcon(itemID, fallback)
        if not LootProConfig.showLootIcons then return "" end
        local instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
        local tex = instant and select(5, instant(itemID))
        return "|T" .. (tex or fallback) .. ":0|t "
    end
    self.lootFrame.display:AddMessage("+10 " .. TestLootIcon(241308, 134414) .. "Light's Potential (20)", cc.loot.r, cc.loot.g, cc.loot.b)
    self.lootFrame.display:AddMessage("+5 " .. TestLootIcon(259085, 134414) .. "Void-Touched Augment Rune (10)", cc.loot.r, cc.loot.g, cc.loot.b)
end

-- NOTE: synthetic args are plain strings, so this can't exercise the 12.0 secret-value guard (no API mints a secret string); verify that in-game in an active Mythic+/boss encounter.
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

    local n = LootProConfig.notifications
    local snapshot = {
        notifications = {},
        cleanMode = LootProConfig.cleanMode,
        showFollowerXP = LootProConfig.showFollowerXP,
        showLootCounts = LootProConfig.showLootCounts,
        showLootIcons = LootProConfig.showLootIcons,
        showMoneyIcons = LootProConfig.showMoneyIcons,
        minQualityOwn = LootProConfig.minQualityOwn,
        minQualityOther = LootProConfig.minQualityOther,
        lootFilters = {},
    }
    for k, v in pairs(n) do snapshot.notifications[k] = v end
    for k, v in pairs(LootProConfig.lootFilters) do snapshot.lootFilters[k] = v end
    local blSnapshot = LootProConfig.lootBlacklist

    for k in pairs(n) do n[k] = true end
    LootProConfig.cleanMode = true
    LootProConfig.showFollowerXP = true
    LootProConfig.showLootCounts = false
    LootProConfig.showLootIcons = true
    LootProConfig.showMoneyIcons = true
    LootProConfig.minQualityOwn = 0
    LootProConfig.minQualityOther = 0
    for k in pairs(LootProConfig.lootFilters) do LootProConfig.lootFilters[k] = false end
    LootProConfig.lootBlacklist = { items = {} }

    local recapPrev = self.RecapDetachSession and self:RecapDetachSession()

    local combat = self.combatFrame.display
    local loot = self.lootFrame.display
    combat:Clear()
    loot:Clear()

    local FACTION_UP   = (_G.FACTION_STANDING_INCREASED or "Reputation with %s increased by %d."):format("Silvermoon Court", 250)
    local FACTION_DOWN = (_G.FACTION_STANDING_DECREASED or "Reputation with %s decreased by %d."):format("Bloodsail Buccaneers", 25)
    local CURRENCY_MSG = (_G.CURRENCY_GAINED or "You receive currency: %s."):format("Kej")
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
        -- Clear first: maxLines caps GetNumMessages(), so without it later cases read before==after and report false FAILs.
        tc.target:Clear()
        local before = tc.target:GetNumMessages()
        local ok, err = pcall(handler, self, tc.event, tc.arg)
        local after = tc.target:GetNumMessages()
        local produced = after > before
        if ok and produced then
            pass = pass + 1
            print(_format("  |cFF00FF00[PASS]|r %-22s (+%d msg)", tc.name, after - before))
        else
            fail = fail + 1
            local reason = (not ok) and ("error: ".._tostring(err)) or "no output produced"
            print(_format("  |cFFFF4040[FAIL]|r %-22s (%s)", tc.name, reason))
        end
    end

    if self.RecapAttachSession then self:RecapAttachSession(recapPrev) end
    for k, v in pairs(snapshot.notifications) do n[k] = v end
    LootProConfig.cleanMode = snapshot.cleanMode
    LootProConfig.showFollowerXP = snapshot.showFollowerXP
    LootProConfig.showLootCounts = snapshot.showLootCounts
    LootProConfig.showLootIcons = snapshot.showLootIcons
    LootProConfig.showMoneyIcons = snapshot.showMoneyIcons
    LootProConfig.minQualityOwn = snapshot.minQualityOwn
    LootProConfig.minQualityOther = snapshot.minQualityOther
    for k, v in pairs(snapshot.lootFilters) do LootProConfig.lootFilters[k] = v end
    LootProConfig.lootBlacklist = blSnapshot

    print(_format("|cFFAAAAFF[LootPro]|r Result: |cFF00FF00%d passed|r, |cFFFF4040%d failed|r (of %d).",
        pass, fail, #cases))
end

-- Speedy AutoLoot: loot one slot per timer tick (~30/s), highest slot first. A tight full-loop loot can trip the server's rapid-loot disconnect on big AoE piles, and clearing low slots first would shift higher indices.
local _GetNumLootItems = GetNumLootItems
local _LootSlot        = LootSlot
local _LootSlotHasItem = LootSlotHasItem
local _IsModifiedClick = IsModifiedClick

local speedyLoot = { ticker = nil, lastCount = nil }

local function SpeedyStop()
    if speedyLoot.ticker then
        speedyLoot.ticker:Cancel()
        speedyLoot.ticker = nil
    end
end

local function SpeedyLootReady()
    if not (LootProConfig and LootProConfig.speedyAutoLoot) then return end
    if _IsModifiedClick and _IsModifiedClick("AUTOLOOTTOGGLE") then return end

    local n = _GetNumLootItems and _GetNumLootItems() or 0
    -- Same loot reported by both LOOT_READY and LOOT_OPENED -> process once.
    if n == 0 or speedyLoot.lastCount == n then return end
    speedyLoot.lastCount = n

    SpeedyStop()
    local slot = n
    speedyLoot.ticker = _NewTicker and _NewTicker(0.03, function()
        if slot >= 1 then
            if _LootSlotHasItem(slot) then _LootSlot(slot) end
            slot = slot - 1
        else
            SpeedyStop()
        end
    end, n + 1)
    if not speedyLoot.ticker then
        for i = n, 1, -1 do
            if _LootSlotHasItem(i) then _LootSlot(i) end
        end
    end
end

local function SpeedyLootClosed()
    speedyLoot.lastCount = nil
    SpeedyStop()
end

local speedyLootFrame = CreateFrame("Frame")
speedyLootFrame:RegisterEvent("LOOT_READY")
speedyLootFrame:RegisterEvent("LOOT_OPENED")
speedyLootFrame:RegisterEvent("LOOT_CLOSED")
speedyLootFrame:SetScript("OnEvent", function(_, event)
    if event == "LOOT_CLOSED" then
        SpeedyLootClosed()
    else
        SpeedyLootReady()
    end
end)

local evts = {
    "ADDON_LOADED",
    "PLAYER_LOGIN",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_LOGOUT",
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
evts = nil

addon:SetScript("OnEvent", function(self, event, ...)
    local arg1 = ...
    
    if event == "ADDON_LOADED" and arg1 == addonName then 
        self:InitSettings()
        self.LDBIcon:Register("LootPro", self.lootProLDB, LootProConfig.minimap)
        self:UnregisterEvent("ADDON_LOADED")
        return
        
    elseif event == "PLAYER_LOGIN" then
        if not self:IsReady() then self:InitSettings() end
        if ns.UI then ns.UI:Initialize() end
        self:UpdateAllVisuals()

        -- Show at most one login popup (what's-new for upgraders, else welcome), stamped at SHOW time so a /lp whatsnew preview or reload-teardown can't flip the flag. Deferred past the PLAYER_LOGIN burst, which won't render a popup reliably.
        local function ShowLoginPopup()
            if not (ns.UI and addon:IsReady()) then return end
            if ns.UI.whatsNewFrame and LootProConfig.whatsNewSeen ~= addon.WHATS_NEW then
                LootProConfig.whatsNewSeen = addon.WHATS_NEW
                ns.UI.whatsNewFrame:Show()
            elseif ns.UI.welcomeFrame and not LootProConfig.hideWelcome then
                ns.UI.welcomeFrame:Show()
            end
        end
        if _After then _After(1.5, ShowLoginPopup) else ShowLoginPopup() end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if self.RecapLoad then self:RecapLoad() end
        return

    elseif event == "PLAYER_LOGOUT" then
        if self.RecapPersist then self:RecapPersist() end
        return

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

        local msg = arg1

        -- 12.0 secret values: the CHAT_MSG payload is a secret string in active encounters; any string op throws, so skip the line.
        if _issecret and _issecret(msg) then return end

        if event == "CHAT_MSG_COMBAT_XP_GAIN" then
            local name, amount2 = _match(msg, "(.+) has gained ([%d%p%s]*%d)%s+%a+")
            if name and amount2 and not _match(msg, "^You") then
                if not LootProConfig.showFollowerXP then return end
                if n.xp then
                    name = _gsub(_gsub(name, "|c%x+", ""), "|r", "")
                    self.combatFrame.display:AddMessage("+ " .. amount2 .. " XP (" .. name .. ")", c.xp.r, c.xp.g, c.xp.b)
                end
                return
            end
        end

        if event == "CHAT_MSG_COMBAT_XP_GAIN" and n.xp then
            self.combatFrame.display:AddMessage(CleanMessage(msg, event), c.xp.r, c.xp.g, c.xp.b)

        elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
            local fac, amt = nil, nil
            if PAT_FACTION_UP then fac, amt = _match(msg, PAT_FACTION_UP) end
            if not amt and PAT_FACTION_UP_AW then fac, amt = _match(msg, PAT_FACTION_UP_AW) end
            local lossFac, lossAmt = nil, nil
            if not amt and PAT_FACTION_DOWN then lossFac, lossAmt = _match(msg, PAT_FACTION_DOWN) end
            if not amt and not lossAmt and PAT_FACTION_DOWN_AW then lossFac, lossAmt = _match(msg, PAT_FACTION_DOWN_AW) end
            if amt and n.repGain then
                self.combatFrame.display:AddMessage("+ " .. amt .. " Rep: " .. (fac or ""), c.repGain.r, c.repGain.g, c.repGain.b)
            elseif lossAmt and n.repLoss then
                self.combatFrame.display:AddMessage("- " .. lossAmt .. " Rep: " .. (lossFac or ""), c.repLoss.r, c.repLoss.g, c.repLoss.b)
            end

        elseif event == "CHAT_MSG_SKILL" and n.skill then
            self.combatFrame.display:AddMessage(CleanMessage(msg, event), c.skill.r, c.skill.g, c.skill.b)

        elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" and n.honor then
            self.combatFrame.display:AddMessage(CleanMessage(msg, event), c.honor.r, c.honor.g, c.honor.b)

        elseif event == "CHAT_MSG_SYSTEM" and n.delver then
            if _find(msg, "Companion XP") then
                local amt = _match(msg, "gains ([%d,]+) Companion")
                if amt then
                    local cD = c.delver or {r=1, g=0.7, b=0.2}
                    self.combatFrame.display:AddMessage("+ " .. amt .. " Delver XP", cD.r, cD.g, cD.b)
                end
            end

        elseif event == "CHAT_MSG_MONEY" then
            local g  = PAT_GOLD   and _match(msg, PAT_GOLD)
            local s  = PAT_SILVER and _match(msg, PAT_SILVER)
            local co = PAT_COPPER and _match(msg, PAT_COPPER)

            if LootProConfig.recapEnabled and self.RecapAddMoney then
                self:RecapAddMoney(MoneyAmount(g) * 10000 + MoneyAmount(s) * 100 + MoneyAmount(co))
            end

            if n.money then
                if LootProConfig.cleanMode and LootProConfig.showMoneyIcons then
                    local st = ""
                    if g  then st = st .. g  .. " |TInterface\\MoneyFrame\\UI-GoldIcon:0|t "   end
                    if s  then st = st .. s  .. " |TInterface\\MoneyFrame\\UI-SilverIcon:0|t " end
                    if co then st = st .. co .. " |TInterface\\MoneyFrame\\UI-CopperIcon:0|t " end

                    self.lootFrame.display:AddMessage("+ " .. st, c.money.r, c.money.g, c.money.b)
                else
                    self.lootFrame.display:AddMessage(GetIconString(msg) .. msg, c.money.r, c.money.g, c.money.b)
                end
            end

        elseif event == "CHAT_MSG_CURRENCY" then
            -- Currency uses |Hcurrency: links (not item:), so GetIconString can't make an icon; pull icon + total from C_CurrencyInfo.
            local currencyName = ExtractItemName(msg)
            local currencyID = _tonumber(_match(msg, "currency:(%d+)"))
            local amt = _tonumber(_match(msg, "x(%d+)%.?$")) or 1

            -- Mark/check the dedup synchronously (before scheduling): deferring to the timer would let two same-frame events both see an empty cache and both display.
            local dedupKey = currencyName or msg
            if IsRecentCurrency(dedupKey) then return end
            MarkCurrencyShown(dedupKey)

            local iconStr, total, iconFileID = "", nil, nil
            local capStr = ""
            if currencyID and _GetCurrencyInfo then
                local info = _GetCurrencyInfo(currencyID)
                if info then
                    iconFileID = info.iconFileID
                    if LootProConfig.showLootIcons and info.iconFileID then
                        iconStr = "|T" .. info.iconFileID .. ":0|t "
                    end
                    total = info.quantity
                    -- maxQuantity/maxWeeklyQuantity are 0 for uncapped currencies.
                    if LootProConfig.currencyCap then
                        local maxq = info.maxQuantity
                        local wk = info.maxWeeklyQuantity
                        if maxq and maxq > 0 and total and total >= maxq then
                            capStr = " |cFFFF4040(capped)|r"
                        elseif wk and wk > 0 and info.quantityEarnedThisWeek and info.quantityEarnedThisWeek >= wk then
                            capStr = " |cFFFFA000(weekly cap)|r"
                        end
                    end
                end
            end

            if LootProConfig.recapEnabled and currencyID and self.RecapAddCurrency then
                self:RecapAddCurrency(currencyID, amt, currencyName, iconFileID)
            end

            if n.currency then
                _curSlot = (_curSlot % POOL_SIZE) + 1
                local p = _curParams[_curSlot]
                p.currencyName = currencyName
                p.iconStr = iconStr
                p.amt     = amt
                p.total   = total
                p.capStr  = capStr
                p.cR, p.cG, p.cB = c.currency.r, c.currency.g, c.currency.b
                if LootProConfig.cleanMode then
                    local cleaned = CleanMessage(msg, event)
                    p.cleanMode = true
                    p.text      = cleaned
                    p.noCount   = IsNoCountItem(cleaned)
                else
                    local nc = IsNoCountItem(msg)
                    p.cleanMode = false
                    p.text      = nc and CleanMessage(msg, event) or msg
                    p.noCount   = nc
                end
                if _After then
                    _After(DEDUP_WINDOW, _curFns[_curSlot])
                else
                    PostCurrency(p)
                end
            end

        elseif event == "CHAT_MSG_LOOT" then
            local isSelf = IsSelfLoot(msg)
            if n.partyLoot == false and not isSelf then return end
            local lname = ExtractItemName(msg)
            MarkLootSeen(lname)
            local itemID = _tonumber(_match(msg, "item:(%d+)"))
            local link = _match(msg, "(|c%x+|Hitem:.-|h|r)") or _match(msg, "(|Hitem:.-|h%[.-%]|h)")
            local rgbHex = _match(msg, "|c%x%x(%x%x%x%x%x%x)")
            local rawQ = rgbHex and QUALITY_BY_RGB[rgbHex:lower()]
            if not rawQ and link then rawQ = _select(3, _GetItemInfo(link)) end
            if not rawQ and itemID then
                rawQ = (_GetItemQualityByID and _GetItemQualityByID(itemID))
                       or _select(3, _GetItemInfo(itemID))
            end
            local threshold = isSelf and LootProConfig.minQualityOwn or LootProConfig.minQualityOther
            local q = rawQ or threshold
            local amt = _tonumber(_match(msg, "x(%d+)%.?$")) or 1

            local isNewApp = false
            local isNotable = false
            local isUpgrade = false
            if isSelf then
                if LootProConfig.recapEnabled and self.RecapAddItem then
                    self:RecapAddItem(itemID, amt, q, link)
                end
                if self.WatchOnLoot then
                    self:WatchOnLoot(itemID, lname, link)
                end
                local ra = LootProConfig.rareAlert
                if ra and ra.notable and self.IsNotableItem then
                    isNotable = self:IsNotableItem(itemID, link)
                end
                if self.RareOnLoot then
                    self:RareOnLoot(q, isNotable)
                end
                if LootProConfig.newAppearance and self.IsNewAppearance then
                    isNewApp = self:IsNewAppearance(link)
                end
                if LootProConfig.lootUpgrade and self.IsUpgrade then
                    isUpgrade = self:IsUpgrade(itemID, link)
                end
            end

            -- Hidden items were still tallied above; only the visible line is suppressed. classIDs: 7=trade goods, 0=consumable, 12=quest, 9=recipe, 2/4=weapon/armor, 3=gem, 8=item enhancement, 15=miscellaneous, 16=glyph.
            local hidden = false
            local lfil = LootProConfig.lootFilters
            if itemID and lfil and (lfil.hideTradeGoods or lfil.hideConsumable or lfil.hideQuest or lfil.hideRecipe
                or lfil.hideGear or lfil.hideGem or lfil.hideEnhancement or lfil.hideMisc or lfil.hideGlyph) then
                local classID = _GetItemInfoInstant and _select(6, _GetItemInfoInstant(itemID))
                if classID == 7 then hidden = lfil.hideTradeGoods
                elseif classID == 0 then hidden = lfil.hideConsumable
                elseif classID == 12 then hidden = lfil.hideQuest
                elseif classID == 9 then hidden = lfil.hideRecipe
                elseif classID == 2 or classID == 4 then hidden = lfil.hideGear
                elseif classID == 3 then hidden = lfil.hideGem
                elseif classID == 8 then hidden = lfil.hideEnhancement
                elseif classID == 15 then hidden = lfil.hideMisc
                elseif classID == 16 then hidden = lfil.hideGlyph end
            end
            if not hidden and lname and addon.BlockMatch and addon:BlockMatch(lname) then
                hidden = true
            end

            if n.loot and q >= threshold and not hidden then
                local lr, lg, lb = c.loot.r, c.loot.g, c.loot.b
                local ra = LootProConfig.rareAlert
                if ra and ra.color and (q >= ra.threshold or isNotable) then
                    local qc = _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[q]
                    if qc then lr, lg, lb = qc.r, qc.g, qc.b end
                end
                local ilvlTag = ""
                if LootProConfig.lootIlvl and self.LootItemLevel then
                    ilvlTag = self:LootItemLevel(itemID, link) or ""
                end
                local marker = ilvlTag .. (isNewApp and NEW_APPEARANCE_TAG or "") .. (isUpgrade and UPGRADE_TAG or "")
                if LootProConfig.cleanMode then
                    local cleaned = CleanMessage(msg, event)
                    local noCount = IsNoCountItem(cleaned)

                    if itemID and LootProConfig.showLootCounts and _GetItemNameByID then
                        -- GetItemCount often returns the PRE-loot total, so add amt to reflect the post-loot count.
                        if itemID and _GetItemNameByID and _GetItemNameByID(itemID) then
                            local cnt = ((_GetItemCount and _GetItemCount(itemID, true)) or 0) + amt
                            local p = _lootSync
                            p.iconStr = GetIconString(msg); p.cleaned = cleaned
                            p.amt = amt; p.noCount = noCount
                            p.cR, p.cG, p.cB = lr, lg, lb
                            p.marker = marker
                            ShowLoot(p, CountSuffix(cnt))
                        else
                            _lootSlot = (_lootSlot % POOL_SIZE) + 1
                            local lp = _lootParams[_lootSlot]
                            lp.iconStr = GetIconString(msg)
                            lp.cleaned = cleaned
                            lp.amt     = amt
                            lp.noCount = noCount
                            lp.itemID  = itemID
                            lp.preCount = (_GetItemCount and _GetItemCount(itemID, true)) or 0
                            lp.cR, lp.cG, lp.cB = lr, lg, lb
                            lp.marker  = marker
                            _After(0.1, _lootFns[_lootSlot])
                        end
                    else
                        local p = _lootSync
                        p.iconStr = GetIconString(msg); p.cleaned = cleaned
                        p.amt = amt; p.noCount = noCount
                        p.cR, p.cG, p.cB = lr, lg, lb
                        p.marker = marker
                        ShowLoot(p, "")
                    end
                else
                    local line = GetIconString(msg) .. msg .. marker
                    if not IsDuplicateDisplay(line) then
                        self.lootFrame.display:AddMessage(line, lr, lg, lb)
                    end
                end
            end
        end
    end
end)