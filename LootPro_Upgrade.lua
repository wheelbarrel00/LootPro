local addonName, ns = ...
local addon = ns.addon

local _GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
local _GetDetailedItemLevelInfo = (C_Item and C_Item.GetDetailedItemLevelInfo) or GetDetailedItemLevelInfo
local _GetInventoryItemLink = GetInventoryItemLink
local _RequestItemData = C_Item and C_Item.RequestLoadItemDataByID
local _GetItemStats = C_Item and C_Item.GetItemStats
local _GetItemUpgradeInfo = C_Item and C_Item.GetItemUpgradeInfo
local _IsItemDataCached = C_Item and C_Item.IsItemDataCachedByID
local _select = select
local _format = string.format

local CLASS_WEAPON, CLASS_ARMOR = 2, 4
local ARMOR_COSMETIC = 5

-- Equip location -> the inventory slot(s) it competes with. Multi-slot types (rings/trinkets/one-hand weapons) win if they beat any one of them.
local SLOTS = {
    INVTYPE_HEAD            = { INVSLOT_HEAD },
    INVTYPE_NECK            = { INVSLOT_NECK },
    INVTYPE_SHOULDER        = { INVSLOT_SHOULDER },
    INVTYPE_CHEST           = { INVSLOT_CHEST },
    INVTYPE_ROBE            = { INVSLOT_CHEST },
    INVTYPE_WAIST           = { INVSLOT_WAIST },
    INVTYPE_LEGS            = { INVSLOT_LEGS },
    INVTYPE_FEET            = { INVSLOT_FEET },
    INVTYPE_WRIST           = { INVSLOT_WRIST },
    INVTYPE_HAND            = { INVSLOT_HAND },
    INVTYPE_FINGER          = { INVSLOT_FINGER1, INVSLOT_FINGER2 },
    INVTYPE_TRINKET         = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 },
    INVTYPE_CLOAK           = { INVSLOT_BACK },
    INVTYPE_WEAPON          = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
    INVTYPE_2HWEAPON        = { INVSLOT_MAINHAND },
    INVTYPE_WEAPONMAINHAND  = { INVSLOT_MAINHAND },
    INVTYPE_WEAPONOFFHAND   = { INVSLOT_OFFHAND },
    INVTYPE_HOLDABLE        = { INVSLOT_OFFHAND },
    INVTYPE_SHIELD          = { INVSLOT_OFFHAND },
    INVTYPE_RANGED          = { INVSLOT_MAINHAND },
    INVTYPE_RANGEDRIGHT     = { INVSLOT_MAINHAND },
}

-- Gated on the API rather than IS_RETAIL, since item level is meaningful on Classic too (unlike IsUpgrade below).
if _GetDetailedItemLevelInfo and _GetItemInfoInstant then
    local ILVL_TAG_CAP = 128
    local ilvlTags = {}
    local ilvlTagCount = 0

    local function GearLevel(itemID, link)
        if not link then return nil end

        local _, _, _, equipLoc, _, classID, subclassID = _GetItemInfoInstant(link)
        if classID ~= CLASS_WEAPON and classID ~= CLASS_ARMOR then return nil end
        -- Shirts, tabards and cosmetic armor carry no meaningful item level and would all read [1].
        if equipLoc == "INVTYPE_BODY" or equipLoc == "INVTYPE_TABARD"
           or (addon.IS_RETAIL and classID == CLASS_ARMOR and subclassID == ARMOR_COSMETIC) then
            return nil
        end

        local ilvl = _GetDetailedItemLevelInfo(link)
        if not ilvl or ilvl == 0 then
            if itemID and _RequestItemData then _RequestItemData(itemID) end
            return nil
        end
        return ilvl
    end

    function addon.GearItemLevel(_, itemID, link)
        return GearLevel(itemID, link)
    end

    function addon:LootItemLevel(itemID, link)
        local ilvl = GearLevel(itemID, link)
        if not ilvl then return nil end

        local tag = ilvlTags[ilvl]
        if not tag then
            if ilvlTagCount >= ILVL_TAG_CAP then
                wipe(ilvlTags)
                ilvlTagCount = 0
            end
            tag = _format(" |cffffd100[%d]|r", ilvl)
            ilvlTags[ilvl] = tag
            ilvlTagCount = ilvlTagCount + 1
        end
        return tag
    end
else
    function addon.LootItemLevel() return nil end
    function addon.GearItemLevel() return nil end
end

if not (addon.IS_RETAIL and _GetDetailedItemLevelInfo and _GetItemInfoInstant and _GetInventoryItemLink) then
    function addon:IsUpgrade() return false end
    function addon:TertiaryStatTag() return nil end
    function addon.UpgradeTrackTag() return nil end
    return
end

-- GetItemStats builds a fresh table per call and one gear line asks twice about the same looted item. Only a real table is memoized, since nil just means the data has not loaded yet.
local _statsLink, _statsTable
local function ItemStats(link)
    if link == _statsLink and _statsTable then return _statsTable end
    local stats = _GetItemStats and _GetItemStats(link)
    if stats then _statsLink, _statsTable = link, stats end
    return stats
end

local PRIMARY_STAT_KEYS = { "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_INTELLECT_SHORT" }
local function PrimaryStatOf(stats)
    if not stats then return nil end
    for i = 1, #PRIMARY_STAT_KEYS do
        local key = PRIMARY_STAT_KEYS[i]
        if (stats[key] or 0) > 0 then return key end
    end
    return nil
end

function addon:IsUpgrade(itemID, link)
    if not link then return false end

    local _, _, _, equipLoc, _, classID, subclassID = _GetItemInfoInstant(link)
    if classID ~= CLASS_WEAPON and classID ~= CLASS_ARMOR then return false end
    local slots = equipLoc and SLOTS[equipLoc]
    if not slots then return false end

    local lootedIlvl = _GetDetailedItemLevelInfo(link)
    if not lootedIlvl or lootedIlvl == 0 then
        -- ilvl is not cached yet. Warm it and skip this time (better to miss a tag than show a wrong one).
        if itemID and _RequestItemData then _RequestItemData(itemID) end
        return false
    end

    -- Flag only when an equipped slot holds the SAME armor/weapon type at a lower ilvl: this proves the player can use it, avoiding false "(upgrade)" on gear they can't equip. Conservative for cross-type weapon swaps.
    local lootedPrimary, primaryRead
    for i = 1, #slots do
        local equipped = _GetInventoryItemLink("player", slots[i])
        if equipped then
            -- Subclass ids repeat across item classes (a one-hand axe and a held-in-offhand are both subclass 0), so the class has to match too.
            local eqClass, eqSub = _select(6, _GetItemInfoInstant(equipped))
            if eqClass == classID and eqSub == subclassID then
                local equippedIlvl = _GetDetailedItemLevelInfo(equipped)
                if equippedIlvl and lootedIlvl > equippedIlvl then
                    -- Same subclass can still carry the wrong primary stat, so require a match when both have one.
                    if not primaryRead then
                        primaryRead = true
                        lootedPrimary = PrimaryStatOf(ItemStats(link))
                    end
                    local eqPrimary = PrimaryStatOf(_GetItemStats and _GetItemStats(equipped))
                    if not lootedPrimary or not eqPrimary or lootedPrimary == eqPrimary then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local TERTIARY_KEYS = {
    "ITEM_MOD_CR_LIFESTEAL_SHORT",
    "ITEM_MOD_CR_AVOIDANCE_SHORT",
    "ITEM_MOD_CR_SPEED_SHORT",
    "ITEM_MOD_CR_STURDINESS_SHORT",
}
local tertiaryTags = {}
function addon:TertiaryStatTag(link)
    if not (_GetItemStats and link) then return nil end
    local _, _, _, _, _, classID = _GetItemInfoInstant(link)
    if classID ~= CLASS_WEAPON and classID ~= CLASS_ARMOR then return nil end
    local stats = ItemStats(link)
    if not stats then return nil end
    for i = 1, #TERTIARY_KEYS do
        local key = TERTIARY_KEYS[i]
        if (stats[key] or 0) > 0 then
            local tag = tertiaryTags[key]
            if not tag then
                tag = " |cff00e6b8(" .. (_G[key] or "Tertiary") .. ")|r"
                tertiaryTags[key] = tag
            end
            return tag
        end
    end
    return nil
end

local trackTags = {}
function addon.UpgradeTrackTag(_, itemID, link)
    if not (_GetItemUpgradeInfo and link) then return nil end
    local _, _, _, _, _, classID = _GetItemInfoInstant(link)
    if classID ~= CLASS_WEAPON and classID ~= CLASS_ARMOR then return nil end
    local info = _GetItemUpgradeInfo(link)
    if not info then
        -- Gear that can't be upgraded also returns nil, so only an uncached item is worth a load request.
        if itemID and _RequestItemData and _IsItemDataCached and not _IsItemDataCached(itemID) then
            _RequestItemData(itemID)
        end
        return nil
    end
    local track = info.trackString
    local cur, max = info.currentLevel, info.maxLevel
    if not track or track == "" or not cur or not max or max <= 0 then return nil end
    local byTrack = trackTags[track]
    if not byTrack then
        byTrack = {}
        trackTags[track] = byTrack
    end
    local slot = cur * 100 + max
    local tag = byTrack[slot]
    if not tag then
        tag = _format(" |cffc8a8ff(%s %d/%d)|r", track, cur, max)
        byTrack[slot] = tag
    end
    return tag
end
