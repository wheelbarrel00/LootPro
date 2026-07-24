local addonName, ns = ...
local addon = ns.addon

local _format = string.format
local _select = select
local _GetItemInfo = GetItemInfo
local _GetItemInfoInstant = GetItemInfoInstant
local _RequestItemData = C_Item and C_Item.RequestLoadItemDataByID
local _GetMoney = GetMoney
local _After = C_Timer and C_Timer.After
-- 12.0 "secret value" probe (nil pre-12.0). Container links can be secret inside active instances; guard before any string op.
local _issecret = issecretvalue

local _Container = C_Container
local _GetNumSlots  = (_Container and _Container.GetContainerNumSlots)  or GetContainerNumSlots
local _GetSlotInfo  = (_Container and _Container.GetContainerItemInfo)  or GetContainerItemInfo
local _UseContainer = (_Container and _Container.UseContainerItem)      or UseContainerItem

local NUM_BAGS = (NUM_BAG_SLOTS or 4)

-- Quest items can be poor quality; never auto-sell them. classID 12 == Enum.ItemClass.Questitem.
local CLASS_QUEST = 12

local function ReadSlot(bag, slot)
    if _Container then
        local info = _GetSlotInfo(bag, slot)
        if not info then return nil end
        return info.hyperlink, info.quality, info.hasNoValue, info.isLocked, info.itemID, info.stackCount
    else
        -- Legacy multi-return order: texture, count, locked, quality, readable, lootable, link, isFiltered, noValue, itemID
        local _, count, locked, quality, _, _, link, _, noValue, itemID = _GetSlotInfo(bag, slot)
        return link, quality, noValue, locked, itemID, count
    end
end

local entryPool = {}

local function BuildGrayList(collect)
    local value, count = 0, 0
    for bag = 0, NUM_BAGS do
        local slots = _GetNumSlots(bag) or 0
        for slot = 1, slots do
            local link, quality, noValue, locked, itemID, stackCount = ReadSlot(bag, slot)
            if link and not (_issecret and _issecret(link))
               and quality == 0 and not noValue and not locked then
                local classID = itemID and _GetItemInfoInstant and _select(6, _GetItemInfoInstant(itemID))
                if classID ~= CLASS_QUEST then
                    stackCount = stackCount or 1
                    -- GetItemInfo's sell price is nil until the item is cached (first vendor visit after login); warm it so the next scan reports the real value.
                    local sellPrice = _select(11, _GetItemInfo(link))
                    if not sellPrice then
                        if itemID and _RequestItemData then _RequestItemData(itemID) end
                        sellPrice = 0
                    end
                    local stackPrice = sellPrice * stackCount
                    count = count + 1
                    value = value + stackPrice
                    if collect then
                        local e = entryPool[count]
                        if not e then e = {}; entryPool[count] = e end
                        e.bag, e.slot, e.link, e.count, e.price = bag, slot, link, stackCount, stackPrice
                    end
                end
            end
        end
    end
    return value, count
end

function addon:VendorGrayValue()
    local value = BuildGrayList(false)
    return value
end

-- Best-available unit value in copper. Vendor sell price for now, extendable to a market source later.
function addon:ItemValue(link)
    if not link then return 0 end
    return (_select(11, _GetItemInfo(link))) or 0
end

local sellFrame = CreateFrame("Frame", "LootProVendorFrame", UIParent, "BackdropTemplate")
sellFrame:SetSize(220, 42)
sellFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
sellFrame:SetFrameStrata("HIGH")
sellFrame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
sellFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
sellFrame:SetBackdropBorderColor(0.427, 0.020, 0.004, 1.0)
sellFrame:Hide()

sellFrame.title = sellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
sellFrame.title:SetPoint("TOP", sellFrame, "TOP", 0, -4)
sellFrame.title:SetFont(sellFrame.title:GetFont(), 12, "OUTLINE")
sellFrame.title:SetText("|cFFFF2222Selling Grays|r")

local bar = CreateFrame("StatusBar", nil, sellFrame)
bar:SetSize(200, 16)
bar:SetPoint("BOTTOM", sellFrame, "BOTTOM", 0, 5)
bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
bar:SetStatusBarColor(0.427, 0.020, 0.004, 1.0)
bar:SetMinMaxValues(0, 1)
bar:SetValue(0)
local barBG = bar:CreateTexture(nil, "BACKGROUND")
barBG:SetAllPoints()
barBG:SetColorTexture(0, 0, 0, 0.6)
bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
bar.text:SetPoint("CENTER")
bar.text:SetText("0 / 0")
sellFrame.bar = bar

local info = {
    timer    = 0,
    interval = 0.2,
    count    = 0,
    cursor   = 1,
    sold     = 0,
    gold     = 0,
}
sellFrame.Info = info

local function ResetRun()
    for i = 1, info.count do
        local e = entryPool[i]
        if e then e.link = nil end
    end
    info.timer  = 0
    info.count  = 0
    info.cursor = 1
    info.sold   = 0
    info.gold   = 0
end

local function FinishRun()
    sellFrame:Hide()
    if info.sold > 0 then
        if addon.RecapAddGraySale then
            addon:RecapAddGraySale(info.sold, info.gold)
        end
        if LootProConfig.vendorGrays and LootProConfig.vendorGrays.details then
            print(_format("|cFF00FF00[LootPro]|r Sold %d gray item%s for %s.",
                info.sold, info.sold == 1 and "" or "s", addon:RecapFormatMoney(info.gold)))
        end
        if addon.VendorRefreshSession then
            addon:VendorRefreshSession()
        end
    end
    ResetRun()
end

function addon:VendorSessionTotals()
    local s = self.RecapGetSession and self:RecapGetSession()
    if not s then return 0, 0 end
    return s.graySold or 0, s.grayCopper or 0
end

sellFrame:SetScript("OnUpdate", function(_, elapsed)
    info.timer = info.timer - elapsed
    if info.timer > 0 then return end
    info.timer = info.interval

    if info.cursor > info.count then
        FinishRun()
        return
    end

    if not (MerchantFrame and MerchantFrame:IsShown()) then
        FinishRun()
        return
    end

    local e = entryPool[info.cursor]
    info.cursor = info.cursor + 1

    -- Re-read the slot and only sell if it still holds the exact gray we listed; a different/moved/locked item is skipped, never sold.
    local link, _, _, locked = ReadSlot(e.bag, e.slot)
    if not (_issecret and _issecret(link)) and link == e.link and not locked then
        -- Re-read the price at sell time: the cache is reliably warm by now, so this corrects any 0 from the snapshot scan.
        local unit = _select(11, _GetItemInfo(e.link))
        local gained = (unit and unit * (e.count or 1)) or (e.price or 0)
        if LootProConfig.vendorGrays and LootProConfig.vendorGrays.details then
            print(_format("|cFF00DDDD[LootPro]|r Sold %s x%d (%s)",
                e.link, e.count or 1, addon:RecapFormatMoney(gained)))
        end
        _UseContainer(e.bag, e.slot)
        info.sold = info.sold + 1
        info.gold = info.gold + gained
        bar:SetValue(info.sold)
        bar.text:SetText(_format("%d / %d", info.sold, info.count))
    end
end)

function addon:VendorStart(manual)
    if not self:IsReady() then return end
    local cfg = LootProConfig.vendorGrays
    if not cfg then return end
    if not manual and not cfg.enabled then return end
    if sellFrame:IsShown() then return end

    if not (MerchantFrame and MerchantFrame:IsShown()) then
        if manual then print("|cFFFF6060[LootPro]|r You must be at a vendor to sell grays.") end
        return
    end

    local _, count = BuildGrayList(true)
    if count < 1 then
        if manual then print("|cFFAAAAFF[LootPro]|r No gray items to sell.") end
        return
    end

    info.timer    = 0
    info.interval = cfg.interval or 0.2
    info.count    = count
    info.cursor   = 1
    info.sold     = 0
    info.gold     = 0

    bar:SetMinMaxValues(0, count)
    bar:SetValue(0)
    bar.text:SetText("0 / " .. count)
    sellFrame:SetAlpha(cfg.progressBar and 1 or 0)
    sellFrame:Show()
end

local function OnMerchantShow()
    addon:VendorStart(false)
end

-- Money gained while a merchant is open is vendor income (sales raise it; buying/repairing lowers it and is ignored). Listen for PLAYER_MONEY only while the window is open. Captures manual sales and the gray auto-seller alike.
local lastMoney = 0

local evf = CreateFrame("Frame", "LootProVendorEvents")
evf:RegisterEvent("MERCHANT_SHOW")
evf:RegisterEvent("MERCHANT_CLOSED")
evf:SetScript("OnEvent", function(_, event)
    if event == "MERCHANT_SHOW" then
        lastMoney = _GetMoney()
        evf:RegisterEvent("PLAYER_MONEY")
        if _After then _After(0.3, OnMerchantShow) else OnMerchantShow() end
    elseif event == "PLAYER_MONEY" then
        local now = _GetMoney()
        local delta = now - lastMoney
        lastMoney = now
        if delta > 0 and LootProConfig.recapEnabled and addon.RecapAddVendorGold then
            addon:RecapAddVendorGold(delta)
        end
    elseif event == "MERCHANT_CLOSED" then
        evf:UnregisterEvent("PLAYER_MONEY")
        -- Use FinishRun, not a bare reset, so closing the merchant mid-run still records the partial tally.
        FinishRun()
    end
end)
