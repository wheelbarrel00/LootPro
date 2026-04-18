local addonName, ns = ...

-- Create the master addon frame and shared namespace
ns.addon = CreateFrame("Frame", addonName .. "EventFrame")
ns.addon.VERSION = "2.1.0"
ns.addon.isTesting = false
ns.addon.IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
ns.addon.IS_BCC    = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

-- Create a table specifically for UI Widgets/Helpers
ns.U = {}

-- Expose to global environment
_G[addonName] = ns.addon