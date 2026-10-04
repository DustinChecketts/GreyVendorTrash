-- GreyVendorTrash core bag behavior.
-- Client/API differences belong in Compat.lua; settings UI belongs in Options.lua.

GreyVendorTrash = GreyVendorTrash or {}
local GVT = GreyVendorTrash
local Compat = GVT.Compat

local Cache = setmetatable({}, { __mode = "k" })

local function GetState(button)
    local state = Cache[button]
    if state then return state end
    state = {}
    Cache[button] = state
    return state
end

local function EnsureDarkenOverlay(button)
    local state = GetState(button)
    if state.darken then return state.darken end

    local icon = Compat.GetItemButtonIcon(button)
    if not icon then return nil end

    local darken = button:CreateTexture(nil, "OVERLAY", nil, 4)
    darken:SetAllPoints(icon)
    darken:SetColorTexture(0, 0, 0, 1)
    darken:Hide()
    state.darken = darken
    return darken
end

local function SetNativeJunkIcon(button, shown)
    -- Forever's bag buttons already contain Blizzard's exact junk marker:
    -- JunkIcon uses the bags-junkcoin atlas, native atlas sizing, draw layer,
    -- placement and color treatment. Reusing it gives us a literal 1:1 match
    -- rather than approximating the appearance with a money-frame texture.
    if button and button.JunkIcon then
        button.JunkIcon:SetShown(shown)
        return true
    end
    return false
end

local function SetButtonDesaturated(button, icon, desaturated)
    -- Classic/TBC bag buttons can have Blizzard-managed icon regions where
    -- calling SetDesaturated directly on button.Icon is not the authoritative
    -- path. Use Blizzard's helper when available, matching the original addon.
    if SetItemButtonDesaturated then
        SetItemButtonDesaturated(button, desaturated)
    elseif icon and icon.SetDesaturated then
        icon:SetDesaturated(desaturated)
    end
end

local function ClearButton(button)
    local state = Cache[button]
    local icon = Compat.GetItemButtonIcon(button)

    if state and state.darken then
        state.darken:Hide()
    end

    if icon then
        SetButtonDesaturated(button, icon, false)
    end

    -- Never leave an addon-forced junk icon behind on a recycled bag button.
    -- Blizzard will independently show it at a merchant when appropriate.
    if not Compat.IsMerchantOpen() then
        SetNativeJunkIcon(button, false)
    end
end

local function UpdateButton(button, bag, slot)
    if not button or bag == nil or slot == nil then return end

    local info = Compat.GetContainerItemInfo(bag, slot)
    local icon = Compat.GetItemButtonIcon(button)
    if not info or not icon or not info.hyperlink then
        ClearButton(button)
        return
    end

    local quality = info.quality
    if quality == nil then
        quality = Compat.GetItemQuality(info.hyperlink)
    end

    local isTrash = quality == 0
    local locked = info.isLocked == true
    local desaturate = GVT:GetSetting("desaturate")

    if desaturate then
        SetButtonDesaturated(button, icon, isTrash or locked)
    else
        SetButtonDesaturated(button, icon, locked)
    end

    -- Optional darkness is applied as a neutral black overlay so the slider
    -- changes brightness without tinting the greyscale icon.
    local darken = EnsureDarkenOverlay(button)
    if darken then
        local darkness = tonumber(GVT:GetSetting("darkness")) or 0
        darkness = math.max(0, math.min(0.75, darkness))
        if isTrash and desaturate and darkness > 0 then
            darken:SetAlpha(darkness)
            darken:Show()
        else
            darken:Hide()
        end
    end

    -- At a merchant Blizzard owns this exact texture and its visibility.
    -- Away from a merchant, optionally keep that same native JunkIcon shown.
    if not Compat.IsMerchantOpen() then
        SetNativeJunkIcon(button, isTrash and GVT:GetSetting("alwaysShowCoin"))
    end
end

local function UpdateContainer(frame)
    if not frame then return end

    if frame.EnumerateValidItems then
        for _, button in frame:EnumerateValidItems() do
            local bag, slot = Compat.GetBagAndSlot(button)
            UpdateButton(button, bag, slot)
        end
        return
    end

    if frame.Items then
        for _, button in ipairs(frame.Items) do
            local bag, slot = Compat.GetBagAndSlot(button)
            UpdateButton(button, bag, slot)
        end
        return
    end

    local name = frame.GetName and frame:GetName()
    if not name then return end

    local id = 1
    local button = _G[name .. "Item" .. id]
    while button do
        local bag, slot = Compat.GetBagAndSlot(button)
        UpdateButton(button, bag, slot)
        id = id + 1
        button = _G[name .. "Item" .. id]
    end
end

function GVT:RefreshAll()
    if ContainerFrameCombinedBags and ContainerFrameCombinedBags:IsShown() then
        UpdateContainer(ContainerFrameCombinedBags)
    end

    local i = 1
    while true do
        local frame = _G["ContainerFrame" .. i]
        if not frame then break end
        if frame:IsShown() then
            UpdateContainer(frame)
        end
        i = i + 1
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:RegisterEvent("ITEM_LOCK_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if ContainerFrame_Update then
            hooksecurefunc("ContainerFrame_Update", UpdateContainer)
        end

        local i = 1
        while true do
            local frame = _G["ContainerFrame" .. i]
            if not frame then break end
            if frame.Update and not frame.__GreyVendorTrashHooked then
                hooksecurefunc(frame, "Update", UpdateContainer)
                frame.__GreyVendorTrashHooked = true
            end
            i = i + 1
        end

        if ContainerFrameCombinedBags and ContainerFrameCombinedBags.Update
            and not ContainerFrameCombinedBags.__GreyVendorTrashHooked then
            hooksecurefunc(ContainerFrameCombinedBags, "Update", UpdateContainer)
            ContainerFrameCombinedBags.__GreyVendorTrashHooked = true
        end
    end

    GVT:RefreshAll()
end)

-- Classic/TBC can call SetItemButtonDesaturated after ContainerFrame_Update,
-- overwriting our greyscale. Reapply only to buttons already cached from a
-- verified player bag, so other item UIs can never enter this path.
if SetItemButtonDesaturated then
    hooksecurefunc("SetItemButtonDesaturated", function(button)
        if not Cache[button] then return end
        local bag, slot = Compat.GetBagAndSlot(button)
        if IsPlayerBag(bag) and slot ~= nil then
            UpdateButton(button, bag, slot)
        end
    end)
end

GVT.UpdateButton = UpdateButton
GVT.UpdateContainer = UpdateContainer
