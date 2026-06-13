local addonName, ns = ...
local addon = ns.addon

-- New-appearance detection (feature: "Mark new transmog appearances").
--
-- Reports whether a freshly looted weapon/armor piece carries a transmog
-- APPEARANCE the player has not collected from ANY source -- so an item whose
-- look you already own from a different item is NOT flagged (appearance-level,
-- not source-level). The loot path in LootPro_Core appends a "(new look)" tag
-- to the feed line when this returns true.
--
-- API chain (all C_TransmogCollection):
--   GetItemInfo(item)                       -> appearanceID, sourceID
--   GetAllAppearanceSources(appearanceID)   -> { sourceID, ... }
--   PlayerHasTransmogItemModifiedAppearance(sourceID) -> bool (THIS source only)
-- There is no single "do I own this appearance" boolean: PlayerHasTransmog*
-- and PlayerHasTransmogByItemInfo are per-source / documented-unreliable, so we
-- resolve appearance-level by OR-ing the collected state of every source.

local C_TC = _G.C_TransmogCollection
local GetSource         = C_TC and C_TC.GetItemInfo
local GetAllSources     = C_TC and C_TC.GetAllAppearanceSources
local PlayerHasSource   = C_TC and C_TC.PlayerHasTransmogItemModifiedAppearance
local _GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
local _wipe   = wipe
local _select = select

-- Only Weapon (2) and Armor (4) classes carry appearances we flag.
local CLASS_WEAPON, CLASS_ARMOR = 2, 4

-- Pre-transmog clients (e.g. BCC Anniversary) lack C_TransmogCollection
-- entirely. Expose a no-op so the loot path can call unconditionally, and
-- skip building any state.
if not (GetSource and GetAllSources and PlayerHasSource and _GetItemInfoInstant) then
    function addon:IsNewAppearance() return false end
    return
end

-- Verdict cache: itemModifiedAppearanceID (the looted item's OWN sourceID)
-- -> isNew (bool). Repeat drops of the same source are then O(1) with zero
-- allocation. `false` is a real cached value, so presence is tested with
-- `~= nil`, never truthiness. Bounded by a full wipe on overflow -- cheaper
-- and lower-churn than per-entry eviction, and the cap is far above the
-- distinct-gear count of a normal session.
local cache = {}
local cacheCount = 0
local CACHE_CAP = 256

-- Collecting (or losing) an appearance can flip any cached verdict, so the
-- whole cache is dropped on a collection change. The event is rare; a wipe is
-- far cheaper than tracking which entries an appearance touches. The frame is
-- created lazily on first real lookup, so players who never enable the feature
-- pay nothing for it.
local invalidator
local function EnsureInvalidator()
    if invalidator then return end
    invalidator = CreateFrame("Frame")
    invalidator:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_ADDED")
    invalidator:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_REMOVED")
    invalidator:SetScript("OnEvent", function()
        _wipe(cache)
        cacheCount = 0
    end)
end

-- True when `link` is gear whose transmog appearance is uncollected from every
-- source. The caller MUST gate on the feature toggle + self-loot first; this is
-- cheap (class gate short-circuits non-gear, cache short-circuits repeats) but
-- a cold lookup allocates one table via GetAllAppearanceSources.
function addon:IsNewAppearance(link)
    if not link then return false end

    -- Cheap class gate: skip every transmog call for things that can't carry an
    -- appearance (trade goods, consumables, quest items, currencies, ...).
    local classID = _select(6, _GetItemInfoInstant(link))
    if classID ~= CLASS_WEAPON and classID ~= CLASS_ARMOR then return false end

    local appearanceID, sourceID = GetSource(link)
    if not appearanceID or not sourceID or sourceID == 0 then return false end

    local cached = cache[sourceID]
    if cached ~= nil then return cached end

    -- Cold path: resolve appearance-level. Bail without caching if the sources
    -- aren't available yet (transient nil) so a guess is never cached as truth.
    local sources = GetAllSources(appearanceID)
    if not sources then return false end

    EnsureInvalidator()
    local isNew = true
    for i = 1, #sources do
        if PlayerHasSource(sources[i]) then
            isNew = false
            break
        end
    end

    if cacheCount >= CACHE_CAP then
        _wipe(cache)
        cacheCount = 0
    end
    cache[sourceID] = isNew
    cacheCount = cacheCount + 1
    return isNew
end
