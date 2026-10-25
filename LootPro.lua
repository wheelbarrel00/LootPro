local addonName, ns = ...

ns.addon = CreateFrame("Frame", addonName .. "EventFrame")
ns.addon.VERSION = "3.1.1"
ns.addon.isTesting = false
-- Forever reports WOW_PROJECT_CAMELOT (18) since build 70170 but runs the retail engine.
ns.addon.IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE or WOW_PROJECT_ID == WOW_PROJECT_CAMELOT

_G[addonName] = ns.addon

ns.addon.DISCORD_URL = "https://discord.gg/vm8K2WfQUE"

-- Registered at load time so /lp works during the loading screen, not only after PLAYER_LOGIN.
SLASH_LOOTPRO1 = "/lp"
SlashCmdList["LOOTPRO"] = function(msg)
    msg = ((msg or ""):lower():gsub("%s+", " ")):match("^%s*(.-)%s*$")
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
    elseif msg == "pause" then
        if ns.addon.RecapPauseToggle then
            local paused = ns.addon:RecapPauseToggle()
            print(paused and "|cFFFFA000[LootPro]|r Session timer paused." or "|cFF00FF00[LootPro]|r Session timer resumed.")
            if ns.Settings then ns.Settings.Redraw() end
        end
        return
    elseif msg == "whatsnew" then
        if ns.WhatsNew and ns.addon:IsReady() then
            ns.WhatsNew.Show()
        else
            print("|cFFFF6060[LootPro]|r What's New popup not available yet.")
        end
        return
    elseif msg == "whatsnew reset" then
        if LootProConfig and ns.WhatsNew then
            ns.WhatsNew.ResetSeen()
            print("|cFF00FF00[LootPro]|r What's New reset. The newest release counts as unread at the next login.")
        end
        return
    elseif msg == "about" then
        if ns.Settings and ns.addon:IsReady() then
            ns.Settings.Open("about")
        else
            print("|cFFFF6060[LootPro]|r UI not initialized yet.")
        end
        return
    elseif msg == "help" or msg == "?" then
        print("|cFFAAAAFF[LootPro]|r Commands: /lp (toggle GUI), /lp recap (session recap), /lp recap reset, /lp pause (pause/resume timer), /lp whatsnew, /lp whatsnew reset, /lp about, /lp test, /lp help")
        return
    -- Words other addons use to open their settings still open Loot Pro's, since any text used to.
    elseif msg ~= "" and msg ~= "config" and msg ~= "options" and msg ~= "settings" then
        print("|cFFFF6060[LootPro]|r Unknown command '" .. (msg:gsub("|", "||")) .. "'. Type /lp help for the list.")
        return
    end
    if ns.Settings and ns.addon:IsReady() then
        ns.Settings.Toggle()
    else
        print("|cFFFF6060[LootPro]|r UI not initialized yet.")
    end
end