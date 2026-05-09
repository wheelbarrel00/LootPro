local addonName, ns = ...

-- Create the master addon frame and shared namespace
ns.addon = CreateFrame("Frame", addonName .. "EventFrame")
ns.addon.VERSION = "2.4.4"
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
    elseif msg == "help" or msg == "?" then
        print("|cFFAAAAFF[LootPro]|r Commands: /lp (toggle GUI), /lp test (run regression), /lp help")
        return
    end
    if ns.UI and ns.UI.toggleGUI then
        ns.UI.toggleGUI()
    else
        print("|cFFFF6060[LootPro]|r UI not initialized yet.")
    end
end