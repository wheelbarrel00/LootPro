local addonName, ns = ...
local addon = ns.addon

-- GameTooltip enrichment (#5).
--
-- Adds a "Looted Nx this session" line to item tooltips, sourced from the
-- per-item recap counts in LootPro_Recap. The line only appears when the
-- tooltipLoots option is on, the recap feature is enabled (that's what
-- populates the counts), and you've actually looted the item this session.
--
-- Tooltip plumbing differs by client: retail (Dragonflight+ / Midnight) uses
-- TooltipDataProcessor; the old OnTooltipSetItem hook is the path on clients
-- that predate that system (e.g. BCC). We branch on which exists.

local _tonumber = tonumber
local _match = string.match

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
    if not LootProConfig or not LootProConfig.tooltipLoots then return end
    if not addon.RecapItemCount then return end

    local link = GetTipItemLink(tooltip)
    if not link then return end
    local itemID = _tonumber(_match(link, "item:(%d+)"))
    if not itemID then return end

    local n = addon:RecapItemCount(itemID)
    if n and n > 0 then
        tooltip:AddLine("|cFFFF2222LootPro|r  Looted " .. n .. "x this session", 1, 1, 1)
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
