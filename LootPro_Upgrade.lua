local addonName, ns = ...
local addon = ns.addon

local _GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
local _GetDetailedItemLevelInfo = (C_Item and C_Item.GetDetailedItemLevelInfo) or GetDetailedItemLevelInfo
local _GetInventoryItemLink = GetInventoryItemLink
local _RequestItemData = C_Item and C_Item.RequestLoadItemDataByID
local _select = select

local CLASS_WEAPON, CLASS_ARMOR = 2, 4

-- Equip location -> the inventory slot(s) it competes with; multi-slot types (rings/trinkets/one-hand weapons) win if they beat any one of them.
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

if not (addon.IS_RETAIL and _GetDetailedItemLevelInfo and _GetItemInfoInstant and _GetInventoryItemLink) then
    function addon:IsUpgrade() return false end
    return
end

function addon:IsUpgrade(itemID, link)
    if not link then return false end

    local _, _, _, equipLoc, _, classID, subclassID = _GetItemInfoInstant(link)
    if classID ~= CLASS_WEAPON and classID ~= CLASS_ARMOR then return false end
    local slots = equipLoc and SLOTS[equipLoc]
    if not slots then return false end

    local lootedIlvl = _GetDetailedItemLevelInfo(link)
    if not lootedIlvl or lootedIlvl == 0 then
        -- ilvl not cached yet; warm it and skip this time (better to miss a tag than show a wrong one).
        if itemID and _RequestItemData then _RequestItemData(itemID) end
        return false
    end

    -- Flag only when an equipped slot holds the SAME armor/weapon type at a lower ilvl: this proves the player can use it, avoiding false "(upgrade)" on gear they can't equip. Conservative for cross-type weapon swaps.
    for i = 1, #slots do
        local equipped = _GetInventoryItemLink("player", slots[i])
        if equipped and _select(7, _GetItemInfoInstant(equipped)) == subclassID then
            local equippedIlvl = _GetDetailedItemLevelInfo(equipped)
            if equippedIlvl and lootedIlvl > equippedIlvl then return true end
        end
    end
    return false
end
