local addonName, ns = ...
local addon = ns.addon

local _find = string.find
local _select = select
local _GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local _GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
local _GetContainerItemInfo = C_Container and C_Container.GetContainerItemInfo
local _GetContainerItemID = C_Container and C_Container.GetContainerItemID
local _issecret = issecretvalue

-- GameTooltip reruns its setter about five times a second while the cursor rests on an item, so each line is memoized against what it was built from.
local _lootID, _lootN, _lootLine
local _sellID, _sellV, _sellLine
local _stackID, _stackN, _stackLine
local OWNED_LINE = {}

local function GetTipItemLink(tooltip)
    if tooltip and tooltip.GetItem then
        local _, link = tooltip:GetItem()
        if link then return link end
    end
    if _G.TooltipUtil and _G.TooltipUtil.GetDisplayedItem then
        local _, link = _G.TooltipUtil.GetDisplayedItem(tooltip)
        return link
    end
    return nil
end

local function AddInfo(tooltip)
    if not LootProConfig then return end
    local wantLoot = LootProConfig.tooltipLoots and addon.RecapItemCount
    local wantSell = LootProConfig.tooltipSell and addon.RecapFormatMoney
    local wantColl = LootProConfig.tooltipCollected and addon.CollectibleOwned
    if not (wantLoot or wantSell or wantColl) then return end

    local link = GetTipItemLink(tooltip)
    if not link or (_issecret and _issecret(link)) then return end
    local itemID = _GetItemInfoInstant and _GetItemInfoInstant(link)
    -- A caged pet has a battlepet link and no item id, so only the collectible check can read it.
    local caged = not itemID and _find(link, "|Hbattlepet:", 1, true) ~= nil
    if not (itemID or caged) then return end

    if wantLoot and itemID then
        local n = addon:RecapItemCount(itemID)
        if n and n > 0 then
            if itemID ~= _lootID or n ~= _lootN then
                _lootID, _lootN = itemID, n
                _lootLine = "|cFFFF2222LootPro|r  Looted " .. n .. "x this session"
            end
            tooltip:AddLine(_lootLine, 1, 1, 1)
        end
    end

    -- Vendor sell price is field 11 of GetItemInfo (copper).
    if wantSell and itemID then
        local sell = _select(11, _GetItemInfo(link))
        if sell and sell > 0 then
            if itemID ~= _sellID or sell ~= _sellV then
                _sellID, _sellV = itemID, sell
                _sellLine = "|cFFFF2222LootPro|r  Sell: " .. addon:RecapFormatMoney(sell)
            end
            tooltip:AddLine(_sellLine, 1, 1, 1)
        end
    end

    if wantColl then
        local owned, kind = addon:CollectibleOwned(itemID, link)
        if owned == true and kind then
            local line = OWNED_LINE[kind]
            if not line then
                line = "|cFFFF2222LootPro|r  You already own this " .. kind .. "."
                OWNED_LINE[kind] = line
            end
            tooltip:AddLine(line, 1, 1, 1)
        end
    end
end

-- Retail uses TooltipDataProcessor; clients that predate it (e.g. BCC) use the OnTooltipSetItem hook.
local TDP = _G.TooltipDataProcessor
if TDP and TDP.AddTooltipPostCall and _G.Enum and _G.Enum.TooltipDataType and _G.Enum.TooltipDataType.Item then
    TDP.AddTooltipPostCall(_G.Enum.TooltipDataType.Item, function(tooltip)
        if tooltip == _G.GameTooltip or tooltip == _G.ItemRefTooltip then
            AddInfo(tooltip)
        end
    end)
elseif _G.GameTooltip and _G.GameTooltip.HookScript then
    _G.GameTooltip:HookScript("OnTooltipSetItem", AddInfo)
    if _G.ItemRefTooltip and _G.ItemRefTooltip.HookScript then
        _G.ItemRefTooltip:HookScript("OnTooltipSetItem", AddInfo)
    end
end

if _GetContainerItemInfo and _GetContainerItemID and _G.GameTooltip and _G.GameTooltip.SetBagItem then
    hooksecurefunc(_G.GameTooltip, "SetBagItem", function(self, bag, slot)
        if not (LootProConfig and LootProConfig.tooltipSell and addon.RecapFormatMoney) then return end
        -- GetContainerItemInfo builds a table per call, and the item id already settles whether this slot can stack or sell at all.
        local id = _GetContainerItemID(bag, slot)
        if not id then return end
        local maxStack, _, _, sell = _select(8, _GetItemInfo(id))
        if not maxStack or maxStack <= 1 or not sell or sell <= 0 then return end
        local info = _GetContainerItemInfo(bag, slot)
        if not info or info.hasNoValue or not info.stackCount or info.stackCount <= 1 then return end
        if id ~= _stackID or info.stackCount ~= _stackN then
            _stackID, _stackN = id, info.stackCount
            _stackLine = "|cFFFF2222LootPro|r  Stack of " .. info.stackCount .. ": "
                .. addon:RecapFormatMoney(sell * info.stackCount)
        end
        self:AddLine(_stackLine, 1, 1, 1)
        self:Show()
    end)
end
