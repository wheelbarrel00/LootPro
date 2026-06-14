local addonName, ns = ...

-- Create the master addon frame and shared namespace
ns.addon = CreateFrame("Frame", addonName .. "EventFrame")
ns.addon.VERSION = "2.9.0"
-- Bump when there is a new "What's New" popup to show existing users. The
-- popup fires once per revision (tracked in LootProConfig.whatsNewSeen).
ns.addon.WHATS_NEW = 5
ns.addon.isTesting = false
ns.addon.IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
ns.addon.IS_BCC    = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

-- Create a table specifically for UI Widgets/Helpers
ns.U = {}

-- Expose to global environment
_G[addonName] = ns.addon

------------------------------------------------------------------------
-- Community Discord
-- WoW can't open a web browser, so the "Join our Discord!" link in the
-- main window title bar pops a copyable invite instead. The edit box is
-- pre-selected so the player just presses Ctrl+C.
------------------------------------------------------------------------
ns.addon.DISCORD_URL = "https://discord.gg/vm8K2WfQUE"

-- Edit-box scripts for the copyable-invite popup, hoisted so the popup's
-- OnShow doesn't build a fresh closure pair on every open. Both read
-- DISCORD_URL at call time, so they carry no per-show state.
local function DiscordBox_OnEscape(box)
    box:GetParent():Hide()
end
local function DiscordBox_OnTextChanged(box)
    -- Keep the link intact: re-fill + re-select if the player edits it.
    if box:GetText() ~= ns.addon.DISCORD_URL then
        box:SetText(ns.addon.DISCORD_URL)
        box:HighlightText()
    end
end

StaticPopupDialogs["LOOTPRO_DISCORD"] = {
    text = "Join the Loot Pro community for help, feedback, and updates.\n\nCopy the invite below (it's pre-selected — just press Ctrl+C):",
    button1 = "Close",
    hasEditBox = true,
    editBoxWidth = 220,
    OnShow = function(self)
        local eb = self.editBox or (self.EditBox)
        if eb then
            eb:SetText(ns.addon.DISCORD_URL)
            eb:HighlightText()
            eb:SetFocus()
            eb:SetScript("OnEscapePressed", DiscordBox_OnEscape)
            eb:SetScript("OnTextChanged", DiscordBox_OnTextChanged)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function ns.addon:ShowDiscord()
    StaticPopup_Show("LOOTPRO_DISCORD")
end

------------------------------------------------------------------------
-- Generic copyable-URL popup
-- WoW can't open a web browser, so every external link in the addon (the
-- About tab's CurseForge/GitHub/bug/sibling-addon links) pops a pre-selected
-- edit box the player copies with Ctrl+C. One helper, one popup; callers just
-- pass the URL via addon:ShowURL(url).
------------------------------------------------------------------------
ns.addon._urlToCopy = ""

local function URLBox_OnEscape(box)
    box:GetParent():Hide()
end
local function URLBox_OnTextChanged(box)
    -- Keep the link intact: re-fill + re-select if the player edits it.
    if box:GetText() ~= ns.addon._urlToCopy then
        box:SetText(ns.addon._urlToCopy)
        box:HighlightText()
    end
end

StaticPopupDialogs["LOOTPRO_URL"] = {
    text = "Copy the link below (it's pre-selected — just press Ctrl+C):",
    button1 = "Close",
    hasEditBox = true,
    editBoxWidth = 320,
    OnShow = function(self)
        local eb = self.editBox or (self.EditBox)
        if eb then
            eb:SetText(ns.addon._urlToCopy)
            eb:HighlightText()
            eb:SetFocus()
            eb:SetScript("OnEscapePressed", URLBox_OnEscape)
            eb:SetScript("OnTextChanged", URLBox_OnTextChanged)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function ns.addon:ShowURL(url)
    self._urlToCopy = url or ""
    StaticPopup_Show("LOOTPRO_URL")
end

-- L7: Register slash command at file-load time so it is usable during the
-- loading screen rather than only after PLAYER_LOGIN.
SLASH_LOOTPRO1 = "/lp"
SlashCmdList["LOOTPRO"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$") or ""
    if msg == "test" then
        if ns.addon.RunRegressionTest then
            ns.addon:RunRegressionTest()
        else
            print("|cFFFF6060[LootPro]|r Test harness not available yet.")
        end
        return
    elseif msg == "recap" then
        if ns.addon.RecapPrint then
            ns.addon:RecapPrint()
        else
            print("|cFFFF6060[LootPro]|r Recap not available yet.")
        end
        return
    elseif msg == "recap reset" then
        if ns.addon.RecapReset then
            ns.addon:RecapReset()
            print("|cFF00FF00[LootPro]|r Session recap reset.")
        end
        return
    elseif msg == "whatsnew" then
        if ns.UI and ns.UI.whatsNewFrame then
            ns.UI.whatsNewFrame:Show()
        else
            print("|cFFFF6060[LootPro]|r What's New popup not available yet.")
        end
        return
    elseif msg == "whatsnew reset" then
        if LootProConfig then
            LootProConfig.whatsNewSeen = 0
            print("|cFF00FF00[LootPro]|r What's New flag reset; it will show on next /reload.")
        end
        return
    elseif msg == "about" then
        if ns.UI and ns.UI.showAbout then
            ns.UI.showAbout()
        else
            print("|cFFFF6060[LootPro]|r UI not initialized yet.")
        end
        return
    elseif msg == "help" or msg == "?" then
        print("|cFFAAAAFF[LootPro]|r Commands: /lp (toggle GUI), /lp recap (session recap), /lp recap reset, /lp whatsnew, /lp about, /lp test, /lp help")
        return
    end
    if ns.UI and ns.UI.toggleGUI then
        ns.UI.toggleGUI()
    else
        print("|cFFFF6060[LootPro]|r UI not initialized yet.")
    end
end