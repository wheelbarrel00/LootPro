local addonName, ns = ...
local addon = ns.addon

local _GetTime = GetTime
local _floor = math.floor
local _format = string.format
local _tremove = table.remove
local _GetRealZoneText = GetRealZoneText

local NOTABLE_CAP = 10
local NOTABLE_QUALITY = 4
local PER_ITEM_CAP = 500

local RARITY_NAMES = {
    [0] = "Poor",
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Artifact",
    [7] = "Heirloom",
}

local session

local function NewSession()
    local zone = _GetRealZoneText and _GetRealZoneText()
    if zone == "" then zone = nil end
    return {
        startTime = _GetTime(),
        copper = 0,
        vendorCopper = 0,
        zone = zone,
        itemTotal = 0,
        byRarity = {},
        currencies = {},
        currencyOrder = {},
        notable = {},
        byItem = {},
        byItemKeys = 0,
        -- version bumps on every change; the GUI tab rebuilds its text only when it moves (avoids per-frame churn).
        version = 0,
    }
end

session = NewSession()

-- GetRealZoneText() is usually "" at login/reload (PLAYER_ENTERING_WORLD fires before the zone name resolves), so backfill the session zone once it's available.
local function EnsureZone(s)
    if s and not s.zone and _GetRealZoneText then
        local z = _GetRealZoneText()
        if z and z ~= "" then s.zone = z end
    end
end

function addon:RecapReset()
    session = NewSession()
end

local function RestoreSession(saved)
    local s = NewSession()
    s.startTime     = tonumber(saved.startTime) or s.startTime
    s.copper        = tonumber(saved.copper) or 0
    s.vendorCopper  = tonumber(saved.vendorCopper) or 0
    s.zone          = saved.zone or s.zone
    s.itemTotal     = tonumber(saved.itemTotal) or 0
    s.byRarity      = type(saved.byRarity) == "table" and saved.byRarity or {}
    s.currencies    = type(saved.currencies) == "table" and saved.currencies or {}
    s.currencyOrder = type(saved.currencyOrder) == "table" and saved.currencyOrder or {}
    s.notable       = type(saved.notable) == "table" and saved.notable or {}
    s.byItem        = type(saved.byItem) == "table" and saved.byItem or {}
    s.byItemKeys    = tonumber(saved.byItemKeys) or 0
    -- GetTime() is continuous across a /reload, so the saved startTime stays valid on restore.
    s.version       = (tonumber(saved.version) or 0) + 1
    return s
end

function addon:RecapLoad(isReload)
    if isReload and type(_G.LootProSession) == "table" then
        session = RestoreSession(_G.LootProSession)
    else
        session = NewSession()
    end
    _G.LootProSession = nil
end

function addon:RecapPersist()
    _G.LootProSession = session
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
    return _GetTime() - session.startTime
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

function addon:RecapAddVendorGold(copper)
    copper = tonumber(copper)
    if not copper or copper <= 0 then return end
    EnsureZone(session)
    session.vendorCopper = session.vendorCopper + copper
    session.version = session.version + 1
end

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

-- Returns a scratch list reused across calls; do NOT hold it across another RecapRarityList() call.
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
    print(_format("|cFFFF2222[LootPro]|r Session Recap (%s)", self:RecapFormatDuration(elapsed)))

    if s.zone then
        print(_format("  |cFFAAAAAAZone:|r %s", s.zone))
    end

    print(_format("  |cFFFFD700Gold:|r +%s", self:RecapFormatMoney(s.copper)))

    if s.vendorCopper and s.vendorCopper > 0 then
        print(_format("  |cFFFFD700Vendor:|r +%s", self:RecapFormatMoney(s.vendorCopper)))
    end

    if elapsed >= 60 then
        local gph = self:RecapFormatMoney(_floor((s.copper + (s.vendorCopper or 0)) / elapsed * 3600))
        print(_format("  |cFFB0E0E6Per hour:|r %s, %d items", gph, _floor(s.itemTotal / elapsed * 3600)))
    end

    if s.itemTotal > 0 then
        print(_format("  |cFFFFFFFFItems:|r %d looted", s.itemTotal))
        local parts = {}
        local qc = _G.ITEM_QUALITY_COLORS
        for _, r in ipairs(self:RecapRarityList()) do
            local hex = (qc and qc[r.quality] and qc[r.quality].hex) or "|cFFFFFFFF"
            parts[#parts + 1] = _format("%s%d %s|r", hex, r.count, r.name:lower())
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
