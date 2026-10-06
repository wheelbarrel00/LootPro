local addonName, ns = ...
local addon = ns.addon

local _GetTime = GetTime
local _floor = math.floor
local _format = string.format
local _tremove = table.remove
local _GetRealZoneText = GetRealZoneText
local _time = time
local _GetMoney = GetMoney
local _After = C_Timer and C_Timer.After

local NOTABLE_CAP = 10
local NOTABLE_QUALITY = 4
local PER_ITEM_CAP = 500
-- Only honor the reload flag if stamped within this window. A crash after a /reload leaves a stale flagged blob, and a relaunch always takes far longer than a real /reload.
local RELOAD_MAX_GAP = 120

-- Stored lowercase because both readers render them mid-sentence, as in "5 epic, 3 rare".
local RARITY_NAMES = {
    [0] = "poor",
    [1] = "common",
    [2] = "uncommon",
    [3] = "rare",
    [4] = "epic",
    [5] = "legendary",
    [6] = "artifact",
    [7] = "heirloom",
}

local session

local function NewSession()
    local zone = _GetRealZoneText and _GetRealZoneText()
    if zone == "" then zone = nil end
    return {
        startTime = _GetTime(),
        pausedTotal = 0,
        copper = 0,
        vendorCopper = 0,
        questCopper = 0,
        mailCopper = 0,
        tradeCopper = 0,
        graySold = 0,
        grayCopper = 0,
        zone = zone,
        itemTotal = 0,
        byRarity = {},
        currencies = {},
        currencyOrder = {},
        notable = {},
        byItem = {},
        byItemKeys = 0,
        -- version bumps on every change. The GUI tab rebuilds its text only when it moves (avoids per-frame churn).
        version = 0,
    }
end

session = NewSession()

-- isReloadingUi misfires on a true login (12.0). Detect a /reload directly so only a real reload restores the session.
local recapLoaded = false
local reloadIntent = false
if type(_G.ReloadUI) == "function" then
    hooksecurefunc("ReloadUI", function() reloadIntent = true end)
end
if _G.C_UI and _G.C_UI.Reload then
    hooksecurefunc(_G.C_UI, "Reload", function() reloadIntent = true end)
end

-- GetRealZoneText() is usually "" at login/reload (PLAYER_ENTERING_WORLD fires before the zone name resolves), so backfill the session zone once it's available.
local function EnsureZone(s)
    if s and not s.zone and _GetRealZoneText then
        local z = _GetRealZoneText()
        if z and z ~= "" then s.zone = z end
    end
end

function addon:RecapReset()
    session = NewSession()
    if addon.VendorRefreshSession then addon:VendorRefreshSession() end
end

local function RestoreSession(saved)
    local s = NewSession()
    -- GetTime() is continuous across a /reload, so the saved startTime and pause stamp stay valid on restore.
    s.startTime     = tonumber(saved.startTime) or s.startTime
    s.pausedTotal   = tonumber(saved.pausedTotal) or 0
    s.pauseStart    = tonumber(saved.pauseStart) or nil
    s.copper        = tonumber(saved.copper) or 0
    s.vendorCopper  = tonumber(saved.vendorCopper) or 0
    s.questCopper   = tonumber(saved.questCopper) or 0
    s.mailCopper    = tonumber(saved.mailCopper) or 0
    s.tradeCopper   = tonumber(saved.tradeCopper) or 0
    s.graySold      = tonumber(saved.graySold) or 0
    s.grayCopper    = tonumber(saved.grayCopper) or 0
    s.zone          = saved.zone or s.zone
    s.itemTotal     = tonumber(saved.itemTotal) or 0
    s.byRarity      = type(saved.byRarity) == "table" and saved.byRarity or {}
    s.currencies    = type(saved.currencies) == "table" and saved.currencies or {}
    s.currencyOrder = type(saved.currencyOrder) == "table" and saved.currencyOrder or {}
    s.notable       = type(saved.notable) == "table" and saved.notable or {}
    s.byItem        = type(saved.byItem) == "table" and saved.byItem or {}
    s.byItemKeys    = tonumber(saved.byItemKeys) or 0
    s.version       = (tonumber(saved.version) or 0) + 1
    return s
end

function addon:RecapLoad()
    if recapLoaded then return end
    recapLoaded = true
    local saved = _G.LootProSession
    local stamp = type(saved) == "table" and tonumber(saved.__stamp)
    if stamp and saved.__reload and (_time() - stamp) < RELOAD_MAX_GAP then
        session = RestoreSession(saved)
    else
        session = NewSession()
    end
    _G.LootProSession = nil
end

function addon:RecapPersist()
    session.__reload = reloadIntent or nil
    session.__stamp = reloadIntent and _time() or nil
    -- Only a /reload restores this, so a normal logout would write the whole session to disk for nothing.
    _G.LootProSession = reloadIntent and session or nil
end

function addon:RecapDetachSession()
    local prev = session
    session = NewSession()
    return prev
end

function addon:RecapAttachSession(prev)
    if prev then session = prev end
end

function addon:RecapGetSession()
    EnsureZone(session)
    return session
end

function addon:RecapElapsed()
    local paused = session.pausedTotal or 0
    if session.pauseStart then paused = paused + (_GetTime() - session.pauseStart) end
    return _GetTime() - session.startTime - paused
end

function addon:RecapIsPaused()
    return session.pauseStart ~= nil
end

-- Freezes the elapsed clock only. Loot is still tallied while paused.
function addon:RecapPauseToggle()
    if session.pauseStart then
        session.pausedTotal = (session.pausedTotal or 0) + (_GetTime() - session.pauseStart)
        session.pauseStart = nil
    else
        session.pauseStart = _GetTime()
    end
    session.version = session.version + 1
    return session.pauseStart ~= nil
end

function addon:RecapItemCount(itemID)
    if not itemID then return 0 end
    return session.byItem[itemID] or 0
end

function addon:RecapAddMoney(copper)
    copper = tonumber(copper)
    if not copper or copper <= 0 then return end
    EnsureZone(session)
    session.copper = session.copper + copper
    session.version = session.version + 1
end

local INCOME_FIELD = { vendor = "vendorCopper", quest = "questCopper", mail = "mailCopper", trade = "tradeCopper" }

function addon:RecapAddIncome(kind, copper)
    local field = INCOME_FIELD[kind]
    copper = tonumber(copper)
    if not field or not copper or copper <= 0 then return end
    EnsureZone(session)
    session[field] = (session[field] or 0) + copper
    session.version = session.version + 1
end

-- Mail and trade are transfers (auction payouts, alts), so they count toward the total but not the per-hour rate.
function addon.RecapGoldTotals()
    local s = session
    local quest, vendor = s.questCopper or 0, s.vendorCopper or 0
    local mail, trade = s.mailCopper or 0, s.tradeCopper or 0
    local earned = s.copper + quest + vendor
    local sources = (s.copper > 0 and 1 or 0) + (quest > 0 and 1 or 0) + (vendor > 0 and 1 or 0)
        + (mail > 0 and 1 or 0) + (trade > 0 and 1 or 0)
    return earned, earned + mail + trade, sources
end

-- Vendor-tab tally only. grayCopper is a subset of vendorCopper, so it must not feed the recap totals or bump version.
function addon:RecapAddGraySale(count, copper)
    count = tonumber(count)
    if not count or count <= 0 then return end
    session.graySold = (session.graySold or 0) + count
    session.grayCopper = (session.grayCopper or 0) + (tonumber(copper) or 0)
end

-- PLAYER_MONEY also fires for spending, so only positive deltas count as income.
local WINDOW_OPEN = { MERCHANT_SHOW = "vendor", MAIL_SHOW = "mail", TRADE_SHOW = "trade" }
local WINDOW_CLOSE = { MERCHANT_CLOSED = "vendor", MAIL_CLOSED = "mail", TRADE_CLOSED = "trade" }
local lastMoney = 0
local pendingGain, otherCredit, flushPending, flushSession, flushKind = 0, 0, false, nil, nil
local openKind, trackKind = nil, nil
local closeCount, graceCount = 0, 0
local flushScheduled, flushFired = 0, 0
local FLUSH_DELAY, CLOSE_GRACE = 0.5, 1

local incomeEvents = CreateFrame("Frame")

local function FlushIncome()
    flushPending = false
    local gain = pendingGain - otherCredit
    local owner, kind = flushSession, flushKind
    pendingGain, otherCredit, flushSession, flushKind = 0, 0, nil, nil
    if gain > 0 and LootProConfig.recapEnabled and session == owner then
        addon:RecapAddIncome(kind, gain)
    end
end

-- Opening a different window books the pending batch early, so a timer left over from that batch must not flush the next one before its netting delay.
local function FlushOnTimer()
    flushFired = flushFired + 1
    if flushFired ~= flushScheduled or not flushPending then return end
    FlushIncome()
end

-- Coin looted (a party split) or a quest finished while a window is open raises PLAYER_MONEY too, and both are booked on their own. Hold each gain briefly so the two net out whichever event lands first.
local function ScheduleFlush()
    if flushPending then return end
    flushPending = true
    flushSession, flushKind = session, trackKind
    flushScheduled = flushScheduled + 1
    if _After then _After(FLUSH_DELAY, FlushOnTimer) else FlushIncome() end
end

function addon.RecapNoteOtherMoney(_, copper)
    if not trackKind or not copper or copper <= 0 then return end
    otherCredit = otherCredit + copper
    ScheduleFlush()
end

-- A sale or trade that settles just after a fast close still reports its money, so tracking outlives the close. Grace timers fire in close order, so only the latest may end it, and a reopen cancels it.
local function EndTracking()
    graceCount = graceCount + 1
    if openKind or graceCount ~= closeCount then return end
    trackKind = nil
    incomeEvents:UnregisterEvent("PLAYER_MONEY")
end

incomeEvents:RegisterEvent("MERCHANT_SHOW")
incomeEvents:RegisterEvent("MERCHANT_CLOSED")
incomeEvents:RegisterEvent("MAIL_SHOW")
incomeEvents:RegisterEvent("MAIL_CLOSED")
incomeEvents:RegisterEvent("TRADE_SHOW")
incomeEvents:RegisterEvent("TRADE_CLOSED")
incomeEvents:RegisterEvent("QUEST_TURNED_IN")
incomeEvents:RegisterEvent("PLAYER_LOGOUT")
incomeEvents:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_MONEY" then
        local now = _GetMoney()
        local delta = now - lastMoney
        lastMoney = now
        if delta > 0 then
            pendingGain = pendingGain + delta
            ScheduleFlush()
        end
    elseif event == "QUEST_TURNED_IN" then
        local money = tonumber((select(3, ...)))
        if money and money > 0 and LootProConfig.recapEnabled then
            addon:RecapAddIncome("quest", money)
        end
        addon:RecapNoteOtherMoney(money)
    elseif WINDOW_OPEN[event] then
        local kind = WINDOW_OPEN[event]
        if flushPending and flushKind ~= kind then FlushIncome() end
        openKind, trackKind = kind, kind
        lastMoney = _GetMoney()
        incomeEvents:RegisterEvent("PLAYER_MONEY")
    elseif WINDOW_CLOSE[event] then
        -- MAIL_CLOSED and MERCHANT_CLOSED can fire twice, so only the close that matches the open window counts.
        if WINDOW_CLOSE[event] ~= openKind then return end
        openKind = nil
        closeCount = closeCount + 1
        if _After then _After(CLOSE_GRACE, EndTracking) else EndTracking() end
    elseif event == "PLAYER_LOGOUT" then
        if flushPending then FlushIncome() end
    end
end)

function addon:RecapAddItem(itemID, amt, quality, link)
    amt = tonumber(amt) or 1
    if amt <= 0 then return end
    local s = session
    EnsureZone(s)
    s.itemTotal = s.itemTotal + amt

    local q = tonumber(quality) or 0
    s.byRarity[q] = (s.byRarity[q] or 0) + amt

    if itemID then
        local cur = s.byItem[itemID]
        if cur then
            s.byItem[itemID] = cur + amt
        elseif s.byItemKeys < PER_ITEM_CAP then
            s.byItem[itemID] = amt
            s.byItemKeys = s.byItemKeys + 1
        end
    end

    if q >= NOTABLE_QUALITY and link then
        local n = s.notable
        n[#n + 1] = link
        while #n > NOTABLE_CAP do
            _tremove(n, 1)
        end
    end

    s.version = s.version + 1
end

function addon:RecapAddCurrency(currencyID, amt, name, icon)
    currencyID = tonumber(currencyID)
    amt = tonumber(amt) or 1
    if not currencyID or amt <= 0 then return end
    local s = session
    EnsureZone(s)
    local entry = s.currencies[currencyID]
    if not entry then
        entry = { name = name, icon = icon, amount = 0 }
        s.currencies[currencyID] = entry
        s.currencyOrder[#s.currencyOrder + 1] = currencyID
    else
        if name and not entry.name then entry.name = name end
        if icon and not entry.icon then entry.icon = icon end
    end
    entry.amount = entry.amount + amt
    s.version = s.version + 1
end

function addon:RecapFormatDuration(seconds)
    seconds = _floor(seconds or 0)
    local h = _floor(seconds / 3600)
    local m = _floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return _format("%dh %02dm", h, m)
    elseif m > 0 then
        return _format("%dm %02ds", m, s)
    end
    return _format("%ds", s)
end

function addon:RecapFormatMoney(copper)
    copper = _floor(copper or 0)
    local g = _floor(copper / 10000)
    local s = _floor((copper % 10000) / 100)
    local c = copper % 100
    if g > 0 then
        return _format("%dg %02ds %02dc", g, s, c)
    elseif s > 0 then
        return _format("%ds %02dc", s, c)
    end
    return _format("%dc", c)
end

-- Returns a scratch list reused across calls. Do NOT hold it across another RecapRarityList() call.
local _rarityOut = {}
local _rarityPool = {}
local function ByQualityDesc(a, b) return a.quality > b.quality end

function addon:RecapRarityList()
    local out = _rarityOut
    wipe(out)
    for q, count in pairs(session.byRarity) do
        local n = #out + 1
        local e = _rarityPool[n]
        if not e then
            e = {}
            _rarityPool[n] = e
        end
        e.quality = q
        e.name = RARITY_NAMES[q] or "?"
        e.count = count
        out[n] = e
    end
    table.sort(out, ByQualityDesc)
    return out
end

function addon:RecapPrint()
    if LootProConfig and not LootProConfig.recapEnabled then
        print("|cFFFF2222[LootPro]|r Session recap is disabled. Enable it on the Recap tab to start tracking.")
        return
    end
    local s = session
    EnsureZone(s)
    local elapsed = self:RecapElapsed()
    local durStr = self:RecapFormatDuration(elapsed)
    if self:RecapIsPaused() then durStr = durStr .. " (paused)" end
    print(_format("|cFFFF2222[LootPro]|r Session Recap (%s)", durStr))

    if s.zone then
        print(_format("  |cFFAAAAAAZone:|r %s", s.zone))
    end

    print(_format("  |cFFFFD700Gold looted:|r +%s", self:RecapFormatMoney(s.copper)))
    if s.questCopper > 0 then
        print(_format("  |cFFFFD700Quest rewards:|r +%s", self:RecapFormatMoney(s.questCopper)))
    end
    if s.vendorCopper > 0 then
        print(_format("  |cFFFFD700Vendor income:|r +%s", self:RecapFormatMoney(s.vendorCopper)))
    end
    if s.mailCopper > 0 then
        print(_format("  |cFFFFD700Mailbox:|r +%s", self:RecapFormatMoney(s.mailCopper)))
    end
    if s.tradeCopper > 0 then
        print(_format("  |cFFFFD700Trade:|r +%s", self:RecapFormatMoney(s.tradeCopper)))
    end
    local earned, total, sources = self:RecapGoldTotals()
    if sources > 1 then
        print(_format("  |cFFFFD700Total gold:|r +%s", self:RecapFormatMoney(total)))
    end

    if elapsed >= 60 then
        local gph = self:RecapFormatMoney(_floor(earned / elapsed * 3600))
        local note = (total > earned) and " (loot, quests and vendor)" or ""
        print(_format("  |cFFB0E0E6Per hour:|r %s, %d items%s", gph, _floor(s.itemTotal / elapsed * 3600), note))
    end

    if s.itemTotal > 0 then
        print(_format("  |cFFFFFFFFItems:|r %d looted", s.itemTotal))
        local parts = {}
        local qc = _G.ITEM_QUALITY_COLORS
        for _, r in ipairs(self:RecapRarityList()) do
            local hex = (qc and qc[r.quality] and qc[r.quality].hex) or "|cFFFFFFFF"
            parts[#parts + 1] = _format("%s%d %s|r", hex, r.count, r.name)
        end
        if #parts > 0 then
            print("           " .. table.concat(parts, ", "))
        end
    else
        print("  |cFFFFFFFFItems:|r none")
    end

    if #s.currencyOrder > 0 then
        for _, id in ipairs(s.currencyOrder) do
            local e = s.currencies[id]
            if e then
                local iconStr = e.icon and ("|T" .. e.icon .. ":0|t ") or ""
                print(_format("  |cFFA6D8FFCurrency:|r +%d %s%s", e.amount, iconStr, e.name or ("#" .. id)))
            end
        end
    end

    if #s.notable > 0 then
        local links = {}
        for i = #s.notable, 1, -1 do
            links[#links + 1] = s.notable[i]
        end
        print("  |cFFA335EENotable:|r " .. table.concat(links, " "))
    end
end
