local addonName, ns = ...

ns.addon = CreateFrame("Frame", addonName .. "EventFrame")
ns.addon.VERSION = "2.14.2"
-- Bump on each new What's New popup; shown once per revision (LootProConfig.whatsNewSeen).
ns.addon.WHATS_NEW = 9
ns.addon.isTesting = false
ns.addon.IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
ns.addon.IS_BCC    = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

ns.U = {}

_G[addonName] = ns.addon

ns.addon.DISCORD_URL = "https://discord.gg/vm8K2WfQUE"

local function DiscordBox_OnEscape(box)
    box:GetParent():Hide()
end
local function DiscordBox_OnTextChanged(box)
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
    -- Use the per-dialog fields, not SetScript on the shared editbox, which would leak these handlers onto later popups.
    EditBoxOnEscapePressed = DiscordBox_OnEscape,
    EditBoxOnTextChanged = DiscordBox_OnTextChanged,
    OnShow = function(self)
        local eb = self.editBox or (self.EditBox)
        if eb then
            eb:SetText(ns.addon.DISCORD_URL)
            eb:HighlightText()
            eb:SetFocus()
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

ns.addon._urlToCopy = ""

local function URLBox_OnEscape(box)
    box:GetParent():Hide()
end
local function URLBox_OnTextChanged(box)
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
    EditBoxOnEscapePressed = URLBox_OnEscape,
    EditBoxOnTextChanged = URLBox_OnTextChanged,
    OnShow = function(self)
        local eb = self.editBox or (self.EditBox)
        if eb then
            eb:SetText(ns.addon._urlToCopy)
            eb:HighlightText()
            eb:SetFocus()
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

StaticPopupDialogs["LOOTPRO_RESET"] = {
    text = "Reset all Loot Pro settings to defaults?\n\nThis clears your watch list, block list, colors, window layout, and every toggle. It cannot be undone.",
    button1 = "Reset",
    button2 = "Cancel",
    OnAccept = function() ns.addon:ResetDefaults() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = true,
    preferredIndex = 3,
}

-- Registered at load time so /lp works during the loading screen, not only after PLAYER_LOGIN.
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