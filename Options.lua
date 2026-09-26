-- GreyVendorTrash options and saved preferences.

GreyVendorTrash = GreyVendorTrash or {}
local GVT = GreyVendorTrash

local DEFAULTS = {
    desaturate = true,
    alwaysShowCoin = false,
    darkness = 0,
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
    if self.RefreshAll then self:RefreshAll() end
end

function GVT:SetDarkness(value)
    self:EnsureSettingsDefaults()
    value = tonumber(value) or 0
    GreyVendorTrashDB.darkness = math.max(0, math.min(0.75, value))
    if self.RefreshAll then self:RefreshAll() end
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

local function CreateDarknessSlider(parent, y)
    local heading = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    heading:SetPoint("TOPLEFT", 16, y)
    heading:SetText("Greyscale darkness")

    local valueText = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    valueText:SetPoint("LEFT", heading, "RIGHT", 8, 0)

    local slider = CreateFrame("Slider", "GreyVendorTrashDarknessSlider", parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 4, -16)
    slider:SetWidth(260)
    slider:SetMinMaxValues(0, 75)
    slider:SetValueStep(5)
    slider:SetObeyStepOnDrag(true)

    _G[slider:GetName() .. "Low"]:SetText("Original")
    _G[slider:GetName() .. "High"]:SetText("Darker")
    _G[slider:GetName() .. "Text"]:SetText("")

    local function UpdateValueText(percent)
        valueText:SetText(string.format("%d%%", percent))
    end

    local initial = math.floor((tonumber(GVT:GetSetting("darkness")) or 0) * 100 + 0.5)
    slider:SetValue(initial)
    UpdateValueText(initial)

    slider:SetScript("OnValueChanged", function(_, value)
        local rounded = math.floor(value / 5 + 0.5) * 5
        UpdateValueText(rounded)
        GVT:SetDarkness(rounded / 100)
    end)

    local note = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", -4, -18)
    note:SetWidth(520)
    note:SetJustifyH("LEFT")
    note:SetText("Adds neutral shading over desaturated vendor-trash icons. 0% matches the normal greyscale appearance.")

    return slider
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

    CreateDarknessSlider(self, -145)

    CreateCheck(
        self, -260,
        "Show the vendor coin outside merchants",
        "Keeps Blizzard's native junk coin visible on vendor trash even when you are away from a vendor.",
        "alwaysShowCoin"
    )

    local hint = self:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 16, -338)
    hint:SetWidth(540)
    hint:SetJustifyH("LEFT")
    hint:SetText("Desaturation, darkness and the coin marker can be combined to your preference. /gvt opens this panel; /gvt diag prints Forever diagnostics.")
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
