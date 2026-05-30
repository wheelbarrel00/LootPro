local addonName, ns = ...

-- Create the master addon frame and shared namespace
ns.addon = CreateFrame("Frame", addonName .. "EventFrame")
ns.addon.VERSION = "2.5.2"
-- Bump when there is a new "What's New" popup to show existing users. The
-- popup fires once per revision (tracked in LootProConfig.whatsNewSeen).
ns.addon.WHATS_NEW = 1
ns.addon.isTesting = false
ns.addon.IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
ns.addon.IS_BCC    = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

-- Create a table specifically for UI Widgets/Helpers
ns.U = {}

-- Expose to global environment
_G[addonName] = ns.addon

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
    elseif msg == "help" or msg == "?" then
        print("|cFFAAAAFF[LootPro]|r Commands: /lp (toggle GUI), /lp recap (session recap), /lp recap reset, /lp whatsnew, /lp test, /lp help")
        return
    end
    if ns.UI and ns.UI.toggleGUI then
        ns.UI.toggleGUI()
    else
        print("|cFFFF6060[LootPro]|r UI not initialized yet.")
    end
end