local addonName, ns = ...
local addon = ns.addon

-- No single "do I own this appearance" API: PlayerHasTransmog* is per-source/unreliable, so OR the collected state of every source.
local C_TC = _G.C_TransmogCollection
local GetSource         = C_TC and C_TC.GetItemInfo
local GetAllSources     = C_TC and C_TC.GetAllAppearanceSources
local PlayerHasSource   = C_TC and C_TC.PlayerHasTransmogItemModifiedAppearance
local _GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
local _wipe   = wipe
local _select = select

local CLASS_WEAPON, CLASS_ARMOR = 2, 4

if not (GetSource and GetAllSources and PlayerHasSource and _GetItemInfoInstant) then
    function addon:IsNewAppearance() return false end
    return
end

-- `false` is a real cached verdict, so test presence with ~= nil, never truthiness.
local cache = {}
local cacheCount = 0
local CACHE_CAP = 256

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

function addon:IsNewAppearance(link)
    if not link then return false end

    local classID = _select(6, _GetItemInfoInstant(link))
    if classID ~= CLASS_WEAPON and classID ~= CLASS_ARMOR then return false end

    local appearanceID, sourceID = GetSource(link)
    if not appearanceID or not sourceID or sourceID == 0 then return false end

    local cached = cache[sourceID]
    if cached ~= nil then return cached end

    -- Transient nil sources: bail without caching, so a guess is never cached as truth.
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
