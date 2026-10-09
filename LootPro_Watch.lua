local addonName, ns = ...
local addon = ns.addon

local _GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
local _GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local _GetItemNameByID = C_Item and C_Item.GetItemNameByID
local _select = select
local _tonumber = tonumber
local SOUNDKIT = _G.SOUNDKIT
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local _PlaySoundFile = PlaySoundFile
local _After = C_Timer and C_Timer.After
local _HasLootSpecs = HasLootSpecializations
local _GetLootSpec = GetLootSpecialization
local _GetSpecialization = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
local _GetSpecInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
local _IsInInstance = IsInInstance
local _IsDelveInProgress = C_PartyInfo and C_PartyInfo.IsDelveInProgress
local QUESTION_MARK_ICON = 134400 -- Interface\Icons\INV_Misc_QuestionMark

local CLASS_MISC, CLASS_BATTLEPET = 15, 17
local SUBCLASS_PET, SUBCLASS_MOUNT = 2, 5
local _GetToyInfo = C_ToyBox and C_ToyBox.GetToyInfo
local _PlayerHasToy = _G.PlayerHasToy
local _GetMountFromItem = C_MountJournal and C_MountJournal.GetMountFromItem
local _GetMountInfoByID = C_MountJournal and C_MountJournal.GetMountInfoByID
local _GetPetInfoByItemID = C_PetJournal and C_PetJournal.GetPetInfoByItemID
local _GetNumCollectedInfo = C_PetJournal and C_PetJournal.GetNumCollectedInfo
local _RequestItemData = C_Item and C_Item.RequestLoadItemDataByID
local _IsItemDataCached = C_Item and C_Item.IsItemDataCachedByID
local _GetItemQualityByID = C_Item and C_Item.GetItemQualityByID
local HAS_JOURNAL = {
    mount = (_GetMountFromItem and _GetMountInfoByID) and true or false,
    pet = (_GetNumCollectedInfo and _GetPetInfoByItemID) and true or false,
    toy = _PlayerHasToy and true or false,
}

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

-- The watch and block matchers lowercase the same loot name on the same event, so the last one is kept.
local _lowerFrom, _lowerTo
local function LowerName(name)
    if name ~= _lowerFrom then
        _lowerFrom, _lowerTo = name, name:lower()
    end
    return _lowerTo
end

function addon:WatchMatch(itemID, name)
    local wl = LootProConfig and LootProConfig.watchlist
    if not wl or not wl.items then return nil end
    local lname
    for _, e in ipairs(wl.items) do
        if e.id and itemID and e.id == itemID then
            return e
        elseif e.key and name then
            lname = lname or LowerName(name)
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
    local lname = LowerName(name)
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
    f.title:SetText("|cFFFF2222WATCHED ITEM LOOTED|r")
    f.icon:SetTexture(icon or QUESTION_MARK_ICON)
    f.name:SetText(link or entry.label or name or "Watched item")

    f:Show()
    f:SetAlpha(0)
    f.anim:Stop()
    f.anim:Play()

    if LootProConfig.watchlist and LootProConfig.watchlist.sound then
        self:PlayAlertSound("watchlist")
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

local SOUND_CHANNEL = "Master"
local DEFAULT_SOUND = "Default"
local DEFAULT_KIT = {
    watchlist = SOUNDKIT and SOUNDKIT.RAID_WARNING,
    rareAlert = RARE_SOUND,
}
local BUILTIN_SOUNDS = {
    { "Blizzard: Raid Warning", "RAID_WARNING" },
    { "Blizzard: Epic Loot", "UI_EPICLOOT_TOAST" },
    { "Blizzard: Legendary Loot", "UI_LEGENDARY_LOOT_TOAST" },
    { "Blizzard: Ready Check", "READY_CHECK" },
    { "Blizzard: Alarm Clock", "ALARM_CLOCK_WARNING_3" },
    { "Blizzard: Quest Complete", "IG_QUEST_LIST_COMPLETE" },
    { "Blizzard: Boss Whisper", "UI_RAID_BOSS_WHISPER_WARNING" },
    { "Blizzard: Coin", "IG_BACKPACK_COIN_OK" },
}
local builtinKit = {}
for i = 1, #BUILTIN_SOUNDS do
    builtinKit[BUILTIN_SOUNDS[i][1]] = SOUNDKIT and SOUNDKIT[BUILTIN_SOUNDS[i][2]]
end

local soundChoices
function addon.AlertSoundChoices()
    if soundChoices then return soundChoices end
    local list = { DEFAULT_SOUND }
    for i = 1, #BUILTIN_SOUNDS do
        local label = BUILTIN_SOUNDS[i][1]
        if builtinKit[label] then list[#list + 1] = label end
    end
    if LSM then
        local shared = {}
        for name in pairs(LSM:HashTable("sound")) do
            if name ~= "None" and name ~= DEFAULT_SOUND and not builtinKit[name] then shared[#shared + 1] = name end
        end
        table.sort(shared)
        for i = 1, #shared do list[#list + 1] = shared[i] end
    end
    soundChoices = list
    return list
end
if LSM and LSM.RegisterCallback then
    local sink = {}
    LSM.RegisterCallback(sink, "LibSharedMedia_Registered", function(_, mediatype)
        if mediatype == "sound" then soundChoices = nil end
    end)
end

function addon.PlayAlertSound(_, configKey)
    local cfg = LootProConfig and LootProConfig[configKey]
    local choice = cfg and cfg.soundName
    if choice and choice ~= DEFAULT_SOUND then
        if builtinKit[choice] then
            PlaySound(builtinKit[choice], SOUND_CHANNEL)
            return
        end
        -- noDefault, or LSM hands back its silent "None" sound for a media pack that was removed.
        local file = LSM and LSM:Fetch("sound", choice, true)
        if file then
            _PlaySoundFile(file, SOUND_CHANNEL)
            return
        end
    end
    if DEFAULT_KIT[configKey] then PlaySound(DEFAULT_KIT[configKey], SOUND_CHANNEL) end
end

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
        -- speciesID is return 13 of GetPetInfoByItemID. Return 1 is the pet name.
        speciesID = _select(13, _GetPetInfoByItemID(itemID))
    end
    speciesID = _tonumber(speciesID)
    if not speciesID then return nil end
    local num = _GetNumCollectedInfo(speciesID)
    if num == nil then return nil end
    return num > 0
end

local function ToyOwned(itemID)
    if not (_PlayerHasToy and itemID) then return nil end
    return _PlayerHasToy(itemID) and true or false
end

-- owned is true/false, or nil when unknown (no journal API, or one that cannot answer yet). kind is nil for a non-collectible.
function addon:CollectibleOwned(itemID, link)
    -- GetItemInfoInstant reports no classID for a caged pet, so classify the battlepet link first.
    if link and link:match("|Hbattlepet:") then return PetOwned(nil, link), "pet" end
    if not _GetItemInfoInstant or (not itemID and not link) then return nil, nil end
    local id, _, _, _, _, classID, subclassID = _GetItemInfoInstant(itemID or link)
    itemID = itemID or id
    if classID == CLASS_BATTLEPET then
        return PetOwned(itemID, link), "pet"
    elseif classID == CLASS_MISC then
        if subclassID == SUBCLASS_MOUNT then return MountOwned(itemID), "mount" end
        if subclassID == SUBCLASS_PET then return PetOwned(itemID, link), "pet" end
    end
    -- Older toys can carry other item classes, often Consumable, so check the toy box no matter the item class.
    if _GetToyInfo and itemID and _GetToyInfo(itemID) ~= nil then return ToyOwned(itemID), "toy" end
    return nil, nil
end

local lateNotable = {}
local lateFrame

local function LateNotable_OnEvent(_, _, itemID, success)
    if not lateNotable[itemID] then return end
    lateNotable[itemID] = nil
    if next(lateNotable) == nil then lateFrame:UnregisterEvent("ITEM_DATA_LOAD_RESULT") end
    if not success then return end
    local owned, kind = addon:CollectibleOwned(itemID)
    if not kind or owned ~= false then return end
    local q = _GetItemQualityByID and _GetItemQualityByID(itemID)
    local ra = LootProConfig and LootProConfig.rareAlert
    -- The loot line already alerted on quality for anything at or above the threshold.
    if q and ra and q >= (ra.threshold or 5) then return end
    addon:RareOnLoot(q, true)
end

local function RecheckWhenLoaded(itemID)
    if not (itemID and _RequestItemData and _IsItemDataCached) or _IsItemDataCached(itemID) then return end
    if not lateFrame then
        lateFrame = CreateFrame("Frame")
        lateFrame:SetScript("OnEvent", LateNotable_OnEvent)
    end
    if not pcall(lateFrame.RegisterEvent, lateFrame, "ITEM_DATA_LOAD_RESULT") then return end
    lateNotable[itemID] = true
    _RequestItemData(itemID)
end

-- Notable = an uncollected mount, pet, or toy. An unloaded item cannot answer ownership yet, so it is re-checked when its data arrives instead of guessed now.
function addon:IsNotableItem(itemID, link)
    local owned, kind = self:CollectibleOwned(itemID, link)
    if not kind then return false end
    if owned == nil then
        if not HAS_JOURNAL[kind] then return true end
        RecheckWhenLoaded(itemID)
        return false
    end
    return not owned
end

function addon:RareOnLoot(quality, triggered)
    local ra = LootProConfig and LootProConfig.rareAlert
    if not ra then return end
    if not ((quality and quality >= (ra.threshold or 5)) or triggered) then return end
    if ra.flash then RareFlash(quality or 0) end
    if ra.sound then self:PlayAlertSound("rareAlert") end
end

function addon:RareTest()
    local ra = LootProConfig and LootProConfig.rareAlert
    RareFlash((ra and ra.threshold) or 5)
    if ra and ra.sound then self:PlayAlertSound("rareAlert") end
end

-- The loot spec API exists on every flavor, even ones without specs, so ask the client whether loot specs apply.
function addon.LootSpecsAvailable()
    return (_HasLootSpecs and _HasLootSpecs() and _GetLootSpec and _GetSpecialization and _GetSpecInfo) and true or false
end

local function OwnSpecByID(specID)
    for i = 1, 4 do
        local id, name, _, icon = _GetSpecInfo(i)
        if not id or id == 0 then return nil end
        if id == specID then return name, icon end
    end
    return nil
end

function addon:LootSpecInfo()
    if not self:LootSpecsAvailable() then return nil end
    local index = _GetSpecialization()
    if not index or index == 0 then return nil end
    local curID, curName, _, curIcon = _GetSpecInfo(index)
    if not curID or curID == 0 or not curName then return nil end
    local lootID = _GetLootSpec() or 0
    if lootID == 0 or lootID == curID then
        return curName, curIcon, curName, lootID == 0, false, curID
    end
    local lootName, lootIcon = OwnSpecByID(lootID)
    if not lootName then return nil end
    return lootName, lootIcon, curName, false, true, curID, lootID
end

local function InLootSpecInstance()
    local inside, kind = _IsInInstance()
    if not inside then return false end
    if kind == "party" or kind == "raid" then return true end
    return kind == "scenario" and _IsDelveInProgress ~= nil and _IsDelveInProgress() and true or false
end

local warnedSpecs
local function CheckLootSpec()
    if not (LootProConfig and LootProConfig.lootSpecReminder) or not InLootSpecInstance() then
        warnedSpecs = nil
        return
    end
    local lootName, lootIcon, curName, _, mismatch, curID, lootID = addon:LootSpecInfo()
    if not mismatch then
        warnedSpecs = nil
        return
    end
    local key = curID * 100000 + lootID
    if key == warnedSpecs then return end
    warnedSpecs = key

    local f = EnsureAlert()
    f.title:SetText("|cFFFF2222LOOT SPEC MISMATCH|r")
    f.icon:SetTexture(lootIcon or QUESTION_MARK_ICON)
    f.name:SetText("Loot spec: " .. lootName)
    f:Show()
    f:SetAlpha(0)
    f.anim:Stop()
    f.anim:Play()
    print("|cFFFF2222[LootPro]|r Your loot spec is " .. lootName .. ", but you are playing " .. curName .. ". Right-click your portrait to change it.")
end

local specFrame = CreateFrame("Frame")
specFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
pcall(specFrame.RegisterEvent, specFrame, "PLAYER_LOOT_SPEC_UPDATED")
pcall(specFrame.RegisterEvent, specFrame, "PLAYER_SPECIALIZATION_CHANGED")
specFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_ENTERING_WORLD" then
        warnedSpecs = nil
        -- Wait out the loading screen, which would hide the banner, and give delve and spec data time to settle.
        if _After then _After(3, CheckLootSpec) else CheckLootSpec() end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit ~= "player" then
        return
    else
        CheckLootSpec()
    end
end)
