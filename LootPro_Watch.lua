local addonName, ns = ...
local addon = ns.addon

-- Loot alerts: watched items, plus rare-drop flash/sound (see the bottom
-- section). Both surface through the "Alerts" tab in the settings window.
--
-- WATCHED ITEMS
-- The user keeps a small list of items they care about (mounts, recipes,
-- BiS pieces, transmog...). When one of those is looted by the player, we
-- fire a prominent center-screen toast plus an alert sound -- the normal
-- loot line still shows underneath.
--
-- Storage lives in LootProConfig.watchlist (SavedVariables, persisted):
--   { enabled = bool, sound = bool, items = { <entry>, ... } }
-- where each entry is one of:
--   { id = <itemID>, label = <name>, icon = <fileID> }   -- exact id match
--   { key = "<lowercased substring>", label = <text> }    -- name substring
-- id-based entries come from a pasted/shift-clicked link or a numeric id and
-- match precisely; text entries match when the looted item's name contains
-- the (case-insensitive) substring.
--
-- The toast frame is created lazily on the first alert, so players who never
-- use the watchlist pay nothing for it.

local _GetItemInfoInstant = GetItemInfoInstant
local _GetItemInfo = GetItemInfo
local _GetItemNameByID = C_Item and C_Item.GetItemNameByID
local _select = select
local _tonumber = tonumber
local SOUNDKIT = _G.SOUNDKIT
local QUESTION_MARK_ICON = 134400 -- Interface\Icons\INV_Misc_QuestionMark

-- Upper bound on watched items. The list is user-managed and persisted, so a
-- cap keeps a runaway paste from bloating SavedVariables.
local WATCH_CAP = 30

local function ResolveName(id)
    if _GetItemNameByID then
        local n = _GetItemNameByID(id)
        if n then return n end
    end
    if _GetItemInfo then
        local n = _GetItemInfo(id)
        if n then return n end
    end
    return nil
end

----------------------------------------------------------------------
-- List management (used by the Watchlist tab).
----------------------------------------------------------------------

function addon:WatchList()
    local wl = LootProConfig and LootProConfig.watchlist
    return (wl and wl.items) or {}
end

-- Add an entry from arbitrary text: an item link, a numeric itemID, or a
-- plain name substring. Returns (true, entry) on success or (false, reason).
function addon:WatchAdd(text)
    local wl = LootProConfig and LootProConfig.watchlist
    if not wl or not wl.items then return false, "notready" end

    text = text and text:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if text == "" then return false, "empty" end
    if #wl.items >= WATCH_CAP then return false, "full" end

    -- An item link embeds |Hitem:<id>:...|h[Name]|h; a bare number is an id.
    local id = _tonumber(text:match("|Hitem:(%d+)"))
    if not id and text:match("^%d+$") then id = _tonumber(text) end

    local entry
    if id then
        for _, e in ipairs(wl.items) do
            if e.id == id then return false, "dupe" end
        end
        local icon = _GetItemInfoInstant and _select(5, _GetItemInfoInstant(id)) or nil
        -- Prefer a pasted link's display name; else resolve from the id; else
        -- a placeholder that the matcher never relies on (id match is exact).
        local name = text:match("|h%[(.-)%]|h") or ResolveName(id) or ("Item #" .. id)
        entry = { id = id, label = name, icon = icon }
    else
        local key = text:lower()
        for _, e in ipairs(wl.items) do
            if e.key == key then return false, "dupe" end
        end
        entry = { key = key, label = text }
    end

    wl.items[#wl.items + 1] = entry
    return true, entry
end

function addon:WatchRemove(index)
    local wl = LootProConfig and LootProConfig.watchlist
    if not wl or not wl.items then return false end
    if index and wl.items[index] then
        table.remove(wl.items, index)
        return true
    end
    return false
end

----------------------------------------------------------------------
-- Matching + alerting (called from the loot path in LootPro_Core).
----------------------------------------------------------------------

-- Returns the matching entry for a looted item, or nil. id match is exact;
-- text entries match when `name` contains the stored substring.
function addon:WatchMatch(itemID, name)
    local wl = LootProConfig and LootProConfig.watchlist
    if not wl or not wl.items then return nil end
    local lname = name and name:lower() or nil
    for _, e in ipairs(wl.items) do
        if e.id and itemID and e.id == itemID then
            return e
        elseif e.key and lname and lname:find(e.key, 1, true) then
            return e
        end
    end
    return nil
end

-- Lazily build the toast frame on first use. Styled to match the ED chrome
-- (near-black fill, brand-red border). Non-interactive; fades itself out.
local alertFrame
local function EnsureAlert()
    if alertFrame then return alertFrame end

    local f = CreateFrame("Frame", "LootProAlert", UIParent, "BackdropTemplate")
    f:SetSize(380, 90)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 220)
    f:SetFrameStrata("HIGH")
    f:EnableMouse(false)
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.92)
    f:SetBackdropBorderColor(0.427, 0.020, 0.004, 1.0) -- #6D0501

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOP", 0, -12)
    f.title:SetFont(f.title:GetFont(), 14, "OUTLINE")
    f.title:SetText("|cFFFF2222WATCHED ITEM LOOTED|r")

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(36, 36)
    f.icon:SetPoint("BOTTOMLEFT", 70, 16)

    f.name = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.name:SetPoint("LEFT", f.icon, "RIGHT", 8, 0)
    f.name:SetFont(f.name:GetFont(), 18, "OUTLINE")

    -- Fade in -> hold -> fade out, then hide. AnimationGroups are supported on
    -- every client LootPro targets (retail + BCC).
    local ag = f:CreateAnimationGroup()
    local a1 = ag:CreateAnimation("Alpha"); a1:SetFromAlpha(0); a1:SetToAlpha(1); a1:SetDuration(0.20); a1:SetOrder(1)
    local a2 = ag:CreateAnimation("Alpha"); a2:SetFromAlpha(1); a2:SetToAlpha(1); a2:SetDuration(2.50); a2:SetOrder(2)
    local a3 = ag:CreateAnimation("Alpha"); a3:SetFromAlpha(1); a3:SetToAlpha(0); a3:SetDuration(0.80); a3:SetOrder(3)
    ag:SetScript("OnFinished", function() f:Hide() end)
    f.anim = ag
    f:Hide()

    alertFrame = f
    return f
end

function addon:WatchAlert(entry, link, name)
    local f = EnsureAlert()

    local icon = entry.icon
    if not icon and entry.id and _GetItemInfoInstant then
        icon = _select(5, _GetItemInfoInstant(entry.id))
    end
    f.icon:SetTexture(icon or QUESTION_MARK_ICON)
    -- A link renders colored in a fontstring (not clickable, which is fine for
    -- a transient toast); fall back to the stored label or looted name.
    f.name:SetText(link or entry.label or name or "Watched item")

    f:Show()
    f:SetAlpha(0)
    f.anim:Stop()
    f.anim:Play()

    if LootProConfig.watchlist and LootProConfig.watchlist.sound and SOUNDKIT then
        PlaySound(SOUNDKIT.RAID_WARNING)
    end
end

-- Entry point from the loot handler. Cheap no-ops when the feature is off or
-- nothing matches; only does real work on an actual hit.
function addon:WatchOnLoot(itemID, name, link)
    local wl = LootProConfig and LootProConfig.watchlist
    if not wl or not wl.enabled then return end
    local entry = self:WatchMatch(itemID, name)
    if entry then
        self:WatchAlert(entry, link, name)
    end
end

----------------------------------------------------------------------
-- Rare-drop alerts (#3 sound + #4 frame flash). The per-line coloring half
-- of #4 lives in the loot display path in LootPro_Core; here we own the
-- frame flash and the sound. The flash overlay is created lazily on the loot
-- frame the first time it's needed.
----------------------------------------------------------------------

-- A loot-toast sound if the client has one, else the raid-warning ping.
local RARE_SOUND = (SOUNDKIT and (SOUNDKIT.UI_EPICLOOT_TOAST or SOUNDKIT.RAID_WARNING)) or nil

local function RareFlash(quality)
    local lf = addon.lootFrame
    if not lf then return end

    local flash = lf._rareFlash
    if not flash then
        flash = lf:CreateTexture(nil, "OVERLAY")
        flash:SetAllPoints(lf)
        flash:SetColorTexture(0.6, 0.2, 0.8, 0.30)
        flash:SetAlpha(0)
        local ag = flash:CreateAnimationGroup()
        local a1 = ag:CreateAnimation("Alpha"); a1:SetFromAlpha(0); a1:SetToAlpha(1); a1:SetDuration(0.12); a1:SetOrder(1)
        local a2 = ag:CreateAnimation("Alpha"); a2:SetFromAlpha(1); a2:SetToAlpha(0); a2:SetDuration(0.55); a2:SetOrder(2)
        ag:SetScript("OnFinished", function() flash:SetAlpha(0) end)
        flash._ag = ag
        lf._rareFlash = flash
    end

    -- Tint the pulse by the item's quality color for a richer cue.
    local qc = _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[quality]
    if qc then
        flash:SetColorTexture(qc.r, qc.g, qc.b, 0.30)
    end

    flash._ag:Stop()
    flash:SetAlpha(0)
    flash._ag:Play()
end

-- Entry point from the loot handler for a self-looted item of `quality`.
function addon:RareOnLoot(quality)
    local ra = LootProConfig and LootProConfig.rareAlert
    if not ra or not quality or quality < (ra.threshold or 4) then return end
    if ra.flash then RareFlash(quality) end
    if ra.sound and RARE_SOUND then PlaySound(RARE_SOUND) end
end

-- Preview for the Alerts tab's test button: flash + sound at the configured
-- threshold quality (so the tint matches what a real drop will look like).
function addon:RareTest()
    local ra = LootProConfig and LootProConfig.rareAlert
    RareFlash((ra and ra.threshold) or 4)
    if ra and ra.sound and RARE_SOUND then PlaySound(RARE_SOUND) end
end
