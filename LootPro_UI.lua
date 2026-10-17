local _, ns = ...
local addon = ns.addon

ns.UI = {}

local PANEL_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
}

local function StyledButton_OnEnter(self) self:SetBackdropColor(0.541, 0.024, 0.004, 1.0) end
local function StyledButton_OnLeave(self) self:SetBackdropColor(0.427, 0.020, 0.004, 1.0) end

local function CreateStyledButton(parent, width, height, label)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop(PANEL_BACKDROP)
    btn:SetBackdropColor(0.427, 0.020, 0.004, 1.0)
    btn:SetBackdropBorderColor(0.10, 0.00, 0.00, 1.0)

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetFont(text:GetFont(), 11)
    text:SetText(label or "")
    text:SetTextColor(0.922, 0.718, 0.024, 1.0)
    btn.label = text

    btn:SetScript("OnEnter", StyledButton_OnEnter)
    btn:SetScript("OnLeave", StyledButton_OnLeave)
    return btn
end

function ns.UI.Initialize()
    local panel = CreateFrame("Frame")
    panel.name = "Loot Pro"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cFFFF2222Loot Pro|r")

    local ver = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ver:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    ver:SetText("Version " .. addon.VERSION)

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", ver, "BOTTOMLEFT", 0, -16)
    desc:SetWidth(540)
    desc:SetJustifyH("LEFT")
    desc:SetText("Loot Pro opens its full options in a dedicated window. Click the button below, or type |cFFEBB706/lp|r in chat.")

    local openBtn = CreateStyledButton(panel, 220, 26, "Open Loot Pro Options")
    openBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -18)
    openBtn:SetScript("OnClick", function()
        -- Close the options panel first, so it is not left open with the Loot Pro window
        if SettingsPanel and SettingsPanel:IsShown() and HideUIPanel then
            HideUIPanel(SettingsPanel)
        elseif InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() and HideUIPanel then
            HideUIPanel(InterfaceOptionsFrame)
        end
        if ns.Settings then ns.Settings.Open() end
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "Loot Pro")
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end