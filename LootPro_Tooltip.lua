local addonName, ns = ...
local addon = ns.addon

local _tonumber = tonumber
local _match = string.match
local _select = select
local _GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local _GetContainerItemInfo = C_Container and C_Container.GetContainerItemInfo
local _issecret = issecretvalue

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
    local wantSell = LootProConfig.tooltipSell
    if not (wantLoot or wantSell) then return end

    local link = GetTipItemLink(tooltip)
    if not link or (_issecret and _issecret(link)) then return end
    local itemID = _tonumber(_match(link, "item:(%d+)"))
    if not itemID then return end

    if wantLoot then
        local n = addon:RecapItemCount(itemID)
        if n and n > 0 then
            tooltip:AddLine("|cFFFF2222LootPro|r  Looted " .. n .. "x this session", 1, 1, 1)
        end
    end

    -- Vendor sell price is field 11 of GetItemInfo (copper).
    if wantSell then
        local sell = _select(11, _GetItemInfo(link))
        if sell and sell > 0 then
            tooltip:AddLine("|cFFFF2222LootPro|r  Sell: " .. addon:RecapFormatMoney(sell), 1, 1, 1)
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

if _GetContainerItemInfo and _G.GameTooltip and _G.GameTooltip.SetBagItem then
    hooksecurefunc(_G.GameTooltip, "SetBagItem", function(self, bag, slot)
        if not (LootProConfig and LootProConfig.tooltipSell) then return end
        local info = _GetContainerItemInfo(bag, slot)
        if not info or info.hasNoValue or not info.stackCount or info.stackCount <= 1 then return end
        local sell = info.itemID and _select(11, _GetItemInfo(info.itemID))
        if sell and sell > 0 then
            self:AddLine("|cFFFF2222LootPro|r  Stack of " .. info.stackCount .. ": "
                .. addon:RecapFormatMoney(sell * info.stackCount), 1, 1, 1)
            self:Show()
        end
    end)
end
