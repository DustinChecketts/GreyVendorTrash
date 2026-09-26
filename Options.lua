-- GreyVendorTrash options and saved preferences.

GreyVendorTrash = GreyVendorTrash or {}
local GVT = GreyVendorTrash

local DEFAULTS = {
    desaturate = true,
    alwaysShowCoin = false,
}

function GVT:EnsureSettingsDefaults()
    GreyVendorTrashDB = GreyVendorTrashDB or {}
    for key, value in pairs(DEFAULTS) do
        if GreyVendorTrashDB[key] == nil then
            GreyVendorTrashDB[key] = value
        end
    end
end

function GVT:GetSetting(key)
    self:EnsureSettingsDefaults()
    return GreyVendorTrashDB[key]
end

function GVT:SetSetting(key, value)
    self:EnsureSettingsDefaults()
    GreyVendorTrashDB[key] = value and true or false
    if self.RefreshAll then
        self:RefreshAll()
    end
end

GVT:EnsureSettingsDefaults()

local panel = CreateFrame("Frame", "GreyVendorTrashOptionsPanel")
panel.name = "GreyVendorTrash"

local function CreateCheck(parent, y, label, description, key)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", 12, y)
    check:SetChecked(GVT:GetSetting(key))

    local text = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("LEFT", check, "RIGHT", 2, 0)
    text:SetText(label)

    local note = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", check, "BOTTOMLEFT", 30, -2)
    note:SetWidth(520)
    note:SetJustifyH("LEFT")
    note:SetText(description)

    check:SetScript("OnClick", function(button)
        GVT:SetSetting(key, button:GetChecked())
    end)

    return check
end

local function InitializePanel(self)
    if self.initialized then return end
    self.initialized = true

    local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("GreyVendorTrash")

    local subtitle = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Choose how poor-quality vendor trash is identified in your bags.")

    CreateCheck(
        self, -76,
        "Desaturate vendor trash icons",
        "Greys out poor-quality item icons, matching GreyVendorTrash's classic behavior.",
        "desaturate"
    )

    CreateCheck(
        self, -142,
        "Show the vendor coin outside merchants",
        "Keeps a small coin marker on vendor trash while you are away from a vendor. At a merchant, Blizzard's native junk marker is left in control.",
        "alwaysShowCoin"
    )

    local hint = self:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 16, -218)
    hint:SetWidth(540)
    hint:SetJustifyH("LEFT")
    hint:SetText("The two options are independent: use desaturation, the coin marker, or both. /gvt opens this panel; /gvt diag prints Forever diagnostics.")
end

panel:SetScript("OnShow", InitializePanel)

if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, "GreyVendorTrash")
    Settings.RegisterAddOnCategory(category)
    GVT.OptionsCategory = category
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
end

function GVT:OpenOptions()
    if Settings and Settings.OpenToCategory and self.OptionsCategory then
        Settings.OpenToCategory(self.OptionsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
    else
        print("|cff33ff99GreyVendorTrash:|r options are available under AddOns settings.")
    end
end
