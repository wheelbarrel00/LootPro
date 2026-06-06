local addonName, ns = ...
local addon = ns.addon

-- =====================================================================
-- Auto-Vendor Grays  (ElvUI "Vendor Grays" parity)
-- ---------------------------------------------------------------------
-- When enabled, opening a merchant auto-sells every poor-quality (gray)
-- item in your bags. Selling is paced one item per `interval` seconds so
-- the optional on-screen progress bar is meaningful, and `details` prints
-- each item + sale price to chat. A "Sell Grays Now" button on the Vendor
-- tab runs the same routine on demand (it bypasses the enable gate but
-- still requires an open merchant).
--
-- Selling is done with the container "use" API at an open merchant, which
-- vendors the item; this is insecure (no taint) and safe to call from our
-- handler. We snapshot (bag, slot, link, count, price) up front into a
-- reused entry pool, then RE-READ each slot just before selling and only
-- vendor it if the slot still holds the same gray. Selling does not compact
-- bags, but a paced run spans seconds, so anything else that touches bags
-- mid-run (looting, an auto-stacker, a stack split) could otherwise put a
-- different item under a snapshotted (bag, slot) -- the re-read prevents us
-- from ever selling an item that wandered into the slot.
--
-- Cross-client: retail exposes the C_Container.* table API
-- (GetContainerItemInfo returns a record); BCC 2.5.x exposes the legacy
-- globals (multi-return GetContainerItemInfo). We normalize both through
-- ReadSlot so the rest of the file is version-agnostic.
-- =====================================================================

local _format = string.format
local _select = select
local _GetItemInfo = GetItemInfo
local _GetItemInfoInstant = GetItemInfoInstant
local _After = C_Timer and C_Timer.After
-- 12.0 "secret value" probe. nil on pre-12.0 (BCC); safe to call on any value.
-- A merchant can be open inside an active instance (repair NPCs, scenarios),
-- where container hyperlinks may be secret -- guard before any string op.
local _issecret = issecretvalue

local _Container = C_Container
local _GetNumSlots  = (_Container and _Container.GetContainerNumSlots)  or GetContainerNumSlots
local _GetSlotInfo  = (_Container and _Container.GetContainerItemInfo)  or GetContainerItemInfo
local _UseContainer = (_Container and _Container.UseContainerItem)      or UseContainerItem

-- Backpack(0) + the four general bags. Gray vendor trash never lives in
-- reagent / profession / special bags, so this range is sufficient and
-- matches ElvUI's scan.
local NUM_BAGS = (NUM_BAG_SLOTS or 4)

-- Quest items can occasionally be poor quality; never auto-sell those.
-- classID 12 == Enum.ItemClass.Questitem (cheap, cache-free lookup).
local CLASS_QUEST = 12

-- Normalized slot read across the two container APIs.
-- Returns: hyperlink, quality, hasNoValue, isLocked, itemID, stackCount
local function ReadSlot(bag, slot)
    if _Container then
        local info = _GetSlotInfo(bag, slot)
        if not info then return nil end
        return info.hyperlink, info.quality, info.hasNoValue, info.isLocked, info.itemID, info.stackCount
    else
        -- Legacy multi-return:
        -- texture, count, locked, quality, readable, lootable, link, isFiltered, noValue, itemID
        local _, count, locked, quality, _, _, link, _, noValue, itemID = _GetSlotInfo(bag, slot)
        return link, quality, noValue, locked, itemID, count
    end
end

-- Pooled entry tables (see `info` below). Reused across runs so vendoring a
-- gray-heavy bag at every merchant doesn't churn one table per item per run.
local entryPool = {}

-- Scan bags for sellable gray items. With `collect` true, fills `entryPool`
-- (reusing tables) with {bag, slot, link, count, price} records; returns the
-- total value and item count either way. Skips no-value items, locked slots,
-- quest grays, and secret-link slots.
local function BuildGrayList(collect)
    local value, count = 0, 0
    for bag = 0, NUM_BAGS do
        local slots = _GetNumSlots(bag) or 0
        for slot = 1, slots do
            local link, quality, noValue, locked, itemID, stackCount = ReadSlot(bag, slot)
            -- A secret hyperlink would throw on the GetItemInfo string op
            -- below, so skip it before touching `link` as a string.
            if link and not (_issecret and _issecret(link))
               and quality == 0 and not noValue and not locked then
                local classID = itemID and _GetItemInfoInstant and _select(6, _GetItemInfoInstant(itemID))
                -- Quest grays stay put. If GetItemInfoInstant is unavailable
                -- classID is nil, so the item falls through to "sell" -- gray
                -- quest items are vanishingly rare and noValue already filters
                -- most non-sellables, so this is an accepted trade-off.
                if classID ~= CLASS_QUEST then
                    stackCount = stackCount or 1
                    local sellPrice = _select(11, _GetItemInfo(link)) or 0
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

-- Total vendor value of current grays. Used by the tooltip on the "Sell
-- Grays Now" button so the user knows what's about to happen.
function addon:VendorGrayValue()
    local value = BuildGrayList(false)
    return value
end

-- ---------------------------------------------------------------------
-- Progress-bar frame + incremental seller
-- ---------------------------------------------------------------------
local sellFrame = CreateFrame("Frame", "LootProVendorFrame", UIParent, "BackdropTemplate")
sellFrame:SetSize(220, 42)
sellFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
sellFrame:SetFrameStrata("HIGH")
sellFrame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
sellFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)         -- #0D0D0D
sellFrame:SetBackdropBorderColor(0.427, 0.020, 0.004, 1.0) -- #6D0501
sellFrame:Hide()

sellFrame.title = sellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
sellFrame.title:SetPoint("TOP", sellFrame, "TOP", 0, -4)
sellFrame.title:SetFont(sellFrame.title:GetFont(), 12, "OUTLINE")
sellFrame.title:SetText("|cFFFF2222Selling Grays|r")

local bar = CreateFrame("StatusBar", nil, sellFrame)
bar:SetSize(200, 16)
bar:SetPoint("BOTTOM", sellFrame, "BOTTOM", 0, 5)
bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
bar:SetStatusBarColor(0.427, 0.020, 0.004, 1.0)            -- brand red fill
bar:SetMinMaxValues(0, 1)
bar:SetValue(0)
local barBG = bar:CreateTexture(nil, "BACKGROUND")
barBG:SetAllPoints()
barBG:SetColorTexture(0, 0, 0, 0.6)
bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
bar.text:SetPoint("CENTER")
bar.text:SetText("0 / 0")
sellFrame.bar = bar

-- Per-run state. Entries live in the reused `entryPool`; `count` is the live
-- length and `cursor` is the next-to-sell index, so the seller advances by an
-- index instead of shifting an array head each tick.
local info = {
    timer    = 0,
    interval = 0.2,
    count    = 0,
    cursor   = 1,
    sold     = 0,
    gold     = 0,
}
sellFrame.Info = info

-- Clear run state between merchants. Nils the pool's link strings (up to the
-- old count) so they aren't retained until the next run overwrites them; the
-- pool tables themselves are kept for reuse.
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
    -- The end-of-run summary is chat output, so it honors the same "Print each
    -- item sold to chat" (details) toggle as the per-item lines. With details
    -- off the feature runs silently -- progress bar only, no chat feed.
    if info.sold > 0 and LootProConfig.vendorGrays and LootProConfig.vendorGrays.details then
        print(_format("|cFF00FF00[LootPro]|r Sold %d gray item%s for %s.",
            info.sold, info.sold == 1 and "" or "s", addon:RecapFormatMoney(info.gold)))
    end
    ResetRun()
end

sellFrame:SetScript("OnUpdate", function(_, elapsed)
    info.timer = info.timer - elapsed
    if info.timer > 0 then return end
    info.timer = info.interval

    -- Done with the list?
    if info.cursor > info.count then
        FinishRun()
        return
    end

    -- If the merchant closed mid-run, stop quietly (MERCHANT_CLOSED also
    -- hides us, but guard the OnUpdate tick too).
    if not (MerchantFrame and MerchantFrame:IsShown()) then
        FinishRun()
        return
    end

    local e = entryPool[info.cursor]
    info.cursor = info.cursor + 1

    -- A1: re-read the slot and only sell if it still holds the exact gray we
    -- listed. A different item that moved into this (bag, slot) since the
    -- scan -- or an emptied / now-locked slot -- is skipped, never sold. The
    -- secret guard goes first so we never compare/print a secret link.
    local link, _, _, locked = ReadSlot(e.bag, e.slot)
    if not (_issecret and _issecret(link)) and link == e.link and not locked then
        if LootProConfig.vendorGrays and LootProConfig.vendorGrays.details then
            print(_format("|cFF00DDDD[LootPro]|r Sold %s x%d (%s)",
                e.link, e.count or 1, addon:RecapFormatMoney(e.price or 0)))
        end
        _UseContainer(e.bag, e.slot)
        info.sold = info.sold + 1
        info.gold = info.gold + (e.price or 0)
        bar:SetValue(info.sold)
        bar.text:SetText(info.sold .. " / " .. info.count)
    end
end)

-- Kick off a sell run. `manual` = the on-demand button (bypasses the enable
-- gate and prints user feedback); auto-runs (manual=false) are silent when
-- there is nothing to do.
function addon:VendorStart(manual)
    if not self:IsReady() then return end
    local cfg = LootProConfig.vendorGrays
    if not cfg then return end
    if not manual and not cfg.enabled then return end
    if sellFrame:IsShown() then return end -- a run is already in progress

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
    -- Progress bar disabled: keep selling but hide the frame (alpha 0 still
    -- runs OnUpdate). Mirrors ElvUI's behavior.
    sellFrame:SetAlpha(cfg.progressBar and 1 or 0)
    sellFrame:Show()
end

-- ---------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------
local function OnMerchantShow()
    addon:VendorStart(false)
end

local evf = CreateFrame("Frame", "LootProVendorEvents")
evf:RegisterEvent("MERCHANT_SHOW")
evf:RegisterEvent("MERCHANT_CLOSED")
evf:SetScript("OnEvent", function(_, event)
    if event == "MERCHANT_SHOW" then
        -- Brief delay so item sell prices / bag state are settled before we
        -- scan and start vendoring (matches ElvUI's deferred start).
        if _After then _After(0.3, OnMerchantShow) else OnMerchantShow() end
    elseif event == "MERCHANT_CLOSED" then
        sellFrame:Hide()
        ResetRun()
    end
end)
