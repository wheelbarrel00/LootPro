local addonName, ns = ...

-- Create the master addon frame and shared namespace
-- Using "LootProEventFrame" explicitly for the global registry
ns.addon = CreateFrame("Frame", "LootProEventFrame")
ns.addon.VERSION = "1.0.0"
ns.addon.isTesting = false

-- Create a table specifically for UI Widgets/Helpers
ns.U = {}

-- Expose to global environment as LootPro
_G["LootPro"] = ns.addon