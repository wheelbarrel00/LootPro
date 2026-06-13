local addonName, ns = ...
local addon = ns.addon

-- GameTooltip enrichment.
--
-- Two additions to item tooltips:
--   * "Looted Nx this session" -- per-item recap counts (LootPro_Recap). Shown
--     when tooltipLoots is on, recap is enabled (it populates the counts), and
--     you've looted the item this session.
--   * "Sell: <price>" -- the vendor sell price (and, for a bag stack, the stack
--     total). Shown when tooltipSell is on. The unit price comes from the
--     shared item handler (works on every item tooltip); the stack total needs
--     the slot's quantity, which the generic handler doesn't carry, so it is
--     added from a GameTooltip:SetBagItem hook.
--
-- Tooltip plumbing differs by client: retail (Dragonflight+ / Midnight) uses
-- TooltipDataProcessor; the old OnTooltipSetItem hook is the path on clients
-- that predate that system (e.g. BCC). We branch on which exists.

local _tonumber = tonumber
local _match = string.match
local _select = select
local _GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local _GetContainerItemInfo = C_Container and C_Container.GetContainerItemInfo

local function GetTipItemLink(tooltip)
    -- GetItem still works on retail and BCC; TooltipUtil is the modern API.
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
    if not link then return end
    local itemID = _tonumber(_match(link, "item:(%d+)"))
    if not itemID then return end

    if wantLoot then
        local n = addon:RecapItemCount(itemID)
        if n and n > 0 then
            tooltip:AddLine("|cFFFF2222LootPro|r  Looted " .. n .. "x this session", 1, 1, 1)
        end
    end

    -- Unit vendor sell price (field 11 of GetItemInfo, in copper). Shown on
    -- every item tooltip; the per-bag stack total is added separately below.
    if wantSell then
        local sell = _select(11, _GetItemInfo(link))
        if sell and sell > 0 then
            tooltip:AddLine("|cFFFF2222LootPro|r  Sell: " .. addon:RecapFormatMoney(sell), 1, 1, 1)
        end
    end
end

local TDP = _G.TooltipDataProcessor
if TDP and TDP.AddTooltipPostCall and _G.Enum and _G.Enum.TooltipDataType and _G.Enum.TooltipDataType.Item then
    -- Retail: post-call fires for every item tooltip. Limit to the tooltips
    -- a player actually reads so we don't append to comparison shopping tips.
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

-- Stack total for bag items. The generic handler above adds the unit price;
-- here we add "Stack of N: <total>" using the slot's quantity, which only the
-- container API exposes. Post-hook fires after the unit line is in place, so
-- the two read in order. Guarded by tooltipSell; one table alloc per bag-item
-- hover (user-driven, not a hot path). C_Container is absent on some older
-- clients -- the hook simply isn't installed there (unit price still shows).
if _GetContainerItemInfo and _G.GameTooltip and _G.GameTooltip.SetBagItem then
    hooksecurefunc(_G.GameTooltip, "SetBagItem", function(self, bag, slot)
        if not (LootProConfig and LootProConfig.tooltipSell) then return end
        local info = _GetContainerItemInfo(bag, slot)
        if not info or info.hasNoValue or not info.stackCount or info.stackCount <= 1 then return end
        local sell = info.itemID and _select(11, _GetItemInfo(info.itemID))
        if sell and sell > 0 then
            self:AddLine("|cFFFF2222LootPro|r  Stack of " .. info.stackCount .. ": "
                .. addon:RecapFormatMoney(sell * info.stackCount), 1, 1, 1)
        end
    end)
end
