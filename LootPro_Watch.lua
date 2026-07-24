local addonName, ns = ...
local addon = ns.addon

local _GetItemInfoInstant = GetItemInfoInstant
local _GetItemInfo = GetItemInfo
local _GetItemNameByID = C_Item and C_Item.GetItemNameByID
local _select = select
local _tonumber = tonumber
local SOUNDKIT = _G.SOUNDKIT
local QUESTION_MARK_ICON = 134400 -- Interface\Icons\INV_Misc_QuestionMark

local CLASS_MISC, CLASS_BATTLEPET = 15, 17
local SUBCLASS_PET, SUBCLASS_MOUNT = 2, 5
local _GetToyInfo = C_ToyBox and C_ToyBox.GetToyInfo
local _PlayerHasToy = _G.PlayerHasToy
local _GetMountFromItem = C_MountJournal and C_MountJournal.GetMountFromItem
local _GetMountInfoByID = C_MountJournal and C_MountJournal.GetMountInfoByID
local _GetPetInfoByItemID = C_PetJournal and C_PetJournal.GetPetInfoByItemID
local _GetNumCollectedInfo = C_PetJournal and C_PetJournal.GetNumCollectedInfo

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

function addon:WatchList()
    local wl = LootProConfig and LootProConfig.watchlist
    return (wl and wl.items) or {}
end

function addon:WatchAdd(text)
    local wl = LootProConfig and LootProConfig.watchlist
    if not wl or not wl.items then return false, "notready" end

    text = text and text:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if text == "" then return false, "empty" end
    if #wl.items >= WATCH_CAP then return false, "full" end

    local id = _tonumber(text:match("|Hitem:(%d+)"))
    if not id and text:match("^%d+$") then id = _tonumber(text) end

    local entry
    if id then
        for _, e in ipairs(wl.items) do
            if e.id == id then return false, "dupe" end
        end
        local icon = _GetItemInfoInstant and _select(5, _GetItemInfoInstant(id)) or nil
        local name = text:match("|h%[(.-)%]|h") or ResolveName(id) or ("Item #" .. id)
        entry = { id = id, label = name, icon = icon }
    else
        local name = text:match("|h%[(.-)%]|h") or text
        local key = name:lower()
        for _, e in ipairs(wl.items) do
            if e.key == key then return false, "dupe" end
        end
        entry = { key = key, label = name }
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

function addon:WatchMatch(itemID, name)
    local wl = LootProConfig and LootProConfig.watchlist
    if not wl or not wl.items then return nil end
    local lname
    for _, e in ipairs(wl.items) do
        if e.id and itemID and e.id == itemID then
            return e
        elseif e.key and name then
            lname = lname or name:lower()
            if lname:find(e.key, 1, true) then
                return e
            end
        end
    end
    return nil
end

local BLOCK_CAP = 50

function addon:BlockList()
    local bl = LootProConfig and LootProConfig.lootBlacklist
    return (bl and bl.items) or {}
end

function addon:BlockAdd(text)
    local bl = LootProConfig and LootProConfig.lootBlacklist
    if not bl or not bl.items then return false, "notready" end

    text = text and text:gsub("^%s+", ""):gsub("%s+$", "") or ""
    local name = text:match("|h%[(.-)%]|h") or text
    if name == "" then return false, "empty" end
    if #bl.items >= BLOCK_CAP then return false, "full" end

    local key = name:lower()
    for _, e in ipairs(bl.items) do
        if e.key == key then return false, "dupe" end
    end
    local entry = { key = key, label = name }
    bl.items[#bl.items + 1] = entry
    return true, entry
end

function addon:BlockRemove(index)
    local bl = LootProConfig and LootProConfig.lootBlacklist
    if not bl or not bl.items then return false end
    if index and bl.items[index] then
        table.remove(bl.items, index)
        return true
    end
    return false
end

function addon:BlockMatch(name)
    local bl = LootProConfig and LootProConfig.lootBlacklist
    if not bl or not bl.items or not name then return false end
    if #bl.items == 0 then return false end
    local lname = name:lower()
    for _, e in ipairs(bl.items) do
        if e.key and lname:find(e.key, 1, true) then
            return true
        end
    end
    return false
end

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
    f:SetBackdropBorderColor(0.427, 0.020, 0.004, 1.0)

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
    f.name:SetText(link or entry.label or name or "Watched item")

    f:Show()
    f:SetAlpha(0)
    f.anim:Stop()
    f.anim:Play()

    if LootProConfig.watchlist and LootProConfig.watchlist.sound and SOUNDKIT then
        PlaySound(SOUNDKIT.RAID_WARNING)
    end
end

function addon:WatchOnLoot(itemID, name, link)
    local wl = LootProConfig and LootProConfig.watchlist
    if not wl or not wl.enabled then return end
    local entry = self:WatchMatch(itemID, name)
    if entry then
        self:WatchAlert(entry, link, name)
    end
end

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

    local qc = _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[quality]
    if qc then
        flash:SetColorTexture(qc.r, qc.g, qc.b, 0.30)
    end

    flash._ag:Stop()
    flash:SetAlpha(0)
    flash._ag:Play()
end

local function MountOwned(itemID)
    if not (_GetMountFromItem and _GetMountInfoByID and itemID) then return nil end
    local mountID = _GetMountFromItem(itemID)
    if not mountID then return nil end
    return _select(11, _GetMountInfoByID(mountID)) and true or false
end

local function PetOwned(itemID, link)
    if not _GetNumCollectedInfo then return nil end
    local speciesID = link and _tonumber(link:match("battlepet:(%d+)"))
    if not speciesID and _GetPetInfoByItemID and itemID then
        speciesID = _GetPetInfoByItemID(itemID)
    end
    if not speciesID then return nil end
    local num = _GetNumCollectedInfo(speciesID)
    if num == nil then return nil end
    return num > 0
end

local function ToyOwned(itemID)
    if not (_PlayerHasToy and itemID) then return nil end
    return _PlayerHasToy(itemID) and true or false
end

-- owned is true/false, or nil when unknown (no journal API). kind is nil for a non-collectible.
function addon:CollectibleOwned(itemID, link)
    if not _GetItemInfoInstant or (not itemID and not link) then return nil, nil end
    local _, _, _, _, _, classID, subclassID = _GetItemInfoInstant(itemID or link)
    if classID == CLASS_BATTLEPET then
        return PetOwned(itemID, link), "pet"
    elseif classID == CLASS_MISC then
        if subclassID == SUBCLASS_MOUNT then return MountOwned(itemID), "mount" end
        if subclassID == SUBCLASS_PET then return PetOwned(itemID, link), "pet" end
        if _GetToyInfo and itemID and _GetToyInfo(itemID) ~= nil then return ToyOwned(itemID), "toy" end
    end
    return nil, nil
end

-- Notable = an uncollected mount, pet, or toy.
function addon:IsNotableItem(itemID, link)
    local owned, kind = self:CollectibleOwned(itemID, link)
    if not kind then return false end
    return owned ~= true
end

function addon:RareOnLoot(quality, isNotable, isValuable)
    local ra = LootProConfig and LootProConfig.rareAlert
    if not ra then return end
    if not ((quality and quality >= (ra.threshold or 5)) or isNotable or isValuable) then return end
    if ra.flash then RareFlash(quality or 0) end
    if ra.sound and RARE_SOUND then PlaySound(RARE_SOUND) end
end

function addon:RareTest()
    local ra = LootProConfig and LootProConfig.rareAlert
    RareFlash((ra and ra.threshold) or 5)
    if ra and ra.sound and RARE_SOUND then PlaySound(RARE_SOUND) end
end
