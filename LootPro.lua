local addonName, ns = ...

-- Create the master addon frame and shared namespace
ns.addon = CreateFrame("Frame", addonName .. "EventFrame")
ns.addon.VERSION = "1.1"
ns.addon.isTesting = false

-- Create a table specifically for UI Widgets/Helpers
ns.U = {}

-- Expose to global environment
_G[addonName] = ns.addon