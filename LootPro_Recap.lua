local addonName, ns = ...
local addon = ns.addon

-- Session Loot Recap.
--
-- Tallies what YOU loot during the current play session: gold, item count
-- with a per-rarity breakdown, currencies earned, and a short list of the
-- most recent epic-or-better drops. Surfaced via "/lp recap" (chat) and the
-- Recap tab in the settings window.
--
-- Lifetime / memory model: the session lives in module scope during play.
-- To survive a /reload (the player shouldn't lose a session's tally just for
-- reloading the UI) but still reset on a real logout, the session is
-- snapshotted to a per-character SavedVariable (LootProSession) at
-- PLAYER_LOGOUT and restored at the first PLAYER_ENTERING_WORLD *only when that
-- load was a UI reload*. A cold login (isInitialLogin) ignores the snapshot and
-- starts fresh, so the only ways to clear the recap are logging out or the
-- Reset Session button. The snapshot is bounded by the same caps as the live
-- tables (see below), so it stays tiny on disk and in memory.
--
-- All accumulators are bounded:
--   * byRarity      -> at most 8 integer keys (item quality 0-7)
--   * currencies    -> one entry per distinct currency earned (a handful)
--   * notable       -> hard-capped ring of NOTABLE_CAP item links
-- so a multi-hour farm cannot grow the table without bound.

local _GetTime = GetTime
local _floor = math.floor
local _format = string.format
local _tremove = table.remove

-- Cap on remembered epic+ drops. Newest kept; oldest evicted past the cap.
local NOTABLE_CAP = 10
-- Quality threshold for an item to count as "notable" (4 = Epic).
local NOTABLE_QUALITY = 4
-- Cap on distinct items tracked for the per-item "looted Nx this session"
-- tooltip line. Once reached we stop adding NEW item IDs (already-tracked
-- ones keep counting), so a long farm can't grow the table without bound.
local PER_ITEM_CAP = 500

-- Human-readable rarity names, indexed by item quality. Used by both the
-- chat printout and the GUI tab. Falls back to "?" for anything unexpected.
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

-- Module-scoped session. Recreated empty on every file load (login/reload).
local session

local function NewSession()
    return {
        startTime = _GetTime(),
        copper = 0,            -- total money looted, in copper
        itemTotal = 0,         -- total items looted (sum of stack sizes)
        byRarity = {},         -- [quality] = count
        currencies = {},       -- [currencyID] = { name=, icon=, amount= }
        currencyOrder = {},    -- currencyIDs in first-seen order (stable display)
        notable = {},          -- array of item link strings, newest last, <= NOTABLE_CAP
        byItem = {},           -- [itemID] = count looted this session (<= PER_ITEM_CAP keys)
        byItemKeys = 0,        -- distinct item count, for the PER_ITEM_CAP guard
        -- version bumps on every tally so the GUI tab only rebuilds its text
        -- when something actually changed (avoids per-frame string churn).
        version = 0,
    }
end

session = NewSession()

function addon:RecapReset()
    session = NewSession()
end

-- Rebuild a live session from a SavedVariable snapshot, backfilling any field
-- missing from an older schema so a format change can never error on restore.
local function RestoreSession(saved)
    local s = NewSession()
    s.startTime     = tonumber(saved.startTime) or s.startTime
    s.copper        = tonumber(saved.copper) or 0
    s.itemTotal     = tonumber(saved.itemTotal) or 0
    s.byRarity      = type(saved.byRarity) == "table" and saved.byRarity or {}
    s.currencies    = type(saved.currencies) == "table" and saved.currencies or {}
    s.currencyOrder = type(saved.currencyOrder) == "table" and saved.currencyOrder or {}
    s.notable       = type(saved.notable) == "table" and saved.notable or {}
    s.byItem        = type(saved.byItem) == "table" and saved.byItem or {}
    s.byItemKeys    = tonumber(saved.byItemKeys) or 0
    -- GetTime() is continuous across a /reload (the client process doesn't
    -- restart), so the saved startTime is still valid on the restore timeline
    -- and the session duration keeps counting.
    s.version       = (tonumber(saved.version) or 0) + 1
    return s
end

-- Restore on a UI reload, start fresh otherwise. Called from the first
-- PLAYER_ENTERING_WORLD with the isReload flag the game provides.
function addon:RecapLoad(isReload)
    if isReload and type(_G.LootProSession) == "table" then
        session = RestoreSession(_G.LootProSession)
    else
        session = NewSession()
    end
    -- Detach the on-disk copy now; a fresh snapshot is written at logout. This
    -- also discards a stale cold-login snapshot so it can't linger in memory.
    _G.LootProSession = nil
end

-- Snapshot the live session so a following /reload can restore it. Fires on
-- both /reload and a real logout; the cold-login path in RecapLoad is what
-- makes a real logout still reset the recap.
function addon:RecapPersist()
    _G.LootProSession = session
end

-- Test isolation: swap the live session out for a throwaway and hand the
-- caller the original to restore later. Used by "/lp test" so its synthetic
-- loot/money/currency events don't pollute the player's real tally.
function addon:RecapDetachSession()
    local prev = session
    session = NewSession()
    return prev
end

function addon:RecapAttachSession(prev)
    if prev then session = prev end
end

-- Accessor for the GUI tab. Returns the live session table (read-only by
-- convention; callers must not mutate it).
function addon:RecapGetSession()
    return session
end

-- Elapsed seconds since the session started.
function addon:RecapElapsed()
    return _GetTime() - session.startTime
end

-- How many of this item the player has looted this session (0 if untracked).
function addon:RecapItemCount(itemID)
    if not itemID then return 0 end
    return session.byItem[itemID] or 0
end

----------------------------------------------------------------------
-- Tally entry points (called from LootPro_Core's chat-event handler).
-- Each is a no-op-safe accumulator; all bump session.version.
----------------------------------------------------------------------

function addon:RecapAddMoney(copper)
    copper = tonumber(copper)
    if not copper or copper <= 0 then return end
    session.copper = session.copper + copper
    session.version = session.version + 1
end

function addon:RecapAddItem(itemID, amt, quality, link)
    amt = tonumber(amt) or 1
    if amt <= 0 then return end
    local s = session
    s.itemTotal = s.itemTotal + amt

    local q = tonumber(quality) or 0
    s.byRarity[q] = (s.byRarity[q] or 0) + amt

    -- Per-item count for the tooltip line. Bounded by PER_ITEM_CAP distinct IDs.
    if itemID then
        local cur = s.byItem[itemID]
        if cur then
            s.byItem[itemID] = cur + amt
        elseif s.byItemKeys < PER_ITEM_CAP then
            s.byItem[itemID] = amt
            s.byItemKeys = s.byItemKeys + 1
        end
    end

    -- Remember epic+ drops as a capped, newest-last ring.
    if q >= NOTABLE_QUALITY and link then
        local n = s.notable
        n[#n + 1] = link
        -- NOTABLE_CAP is tiny (10), so the occasional front-shift on overflow
        -- is negligible and keeps display order trivial.
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
    local entry = s.currencies[currencyID]
    if not entry then
        entry = { name = name, icon = icon, amount = 0 }
        s.currencies[currencyID] = entry
        s.currencyOrder[#s.currencyOrder + 1] = currencyID
    else
        -- Backfill name/icon if a later event resolved them.
        if name and not entry.name then entry.name = name end
        if icon and not entry.icon then entry.icon = icon end
    end
    entry.amount = entry.amount + amt
    s.version = s.version + 1
end

----------------------------------------------------------------------
-- Formatting helpers (shared by chat printout and GUI tab).
----------------------------------------------------------------------

-- "1h 24m", "24m 03s", or "03s".
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

-- Copper -> "12g 34s 56c", omitting zero leading denominations.
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

-- Returns the rarity breakdown as a list of { quality, name, count } sorted
-- high rarity first. Reused by both surfaces so ordering stays consistent.
--
-- The result is scratch: both callers (RecapPrint and the GUI's
-- BuildRecapBody) consume it synchronously and never retain it, so we reuse
-- one array plus a small pool of entry tables instead of reallocating the
-- array, the entries, and the sort comparator on every rebuild. Invariant:
-- do NOT hold the returned list across another RecapRarityList() call.
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

----------------------------------------------------------------------
-- Chat printout ("/lp recap").
----------------------------------------------------------------------

function addon:RecapPrint()
    if LootProConfig and not LootProConfig.recapEnabled then
        print("|cFFFF2222[LootPro]|r Session recap is disabled. Enable it on the Recap tab to start tracking.")
        return
    end
    local s = session
    print(_format("|cFFFF2222[LootPro]|r Session Recap (%s)", self:RecapFormatDuration(self:RecapElapsed())))

    -- Gold
    print(_format("  |cFFFFD700Gold:|r +%s", self:RecapFormatMoney(s.copper)))

    -- Items + rarity breakdown
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

    -- Currencies
    if #s.currencyOrder > 0 then
        for _, id in ipairs(s.currencyOrder) do
            local e = s.currencies[id]
            if e then
                local iconStr = e.icon and ("|T" .. e.icon .. ":0|t ") or ""
                print(_format("  |cFFA6D8FFCurrency:|r +%d %s%s", e.amount, iconStr, e.name or ("#" .. id)))
            end
        end
    end

    -- Notable drops (epic+)
    if #s.notable > 0 then
        -- Show newest first.
        local links = {}
        for i = #s.notable, 1, -1 do
            links[#links + 1] = s.notable[i]
        end
        print("  |cFFA335EENotable:|r " .. table.concat(links, " "))
    end
end
