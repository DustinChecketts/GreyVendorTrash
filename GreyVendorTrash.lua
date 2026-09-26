-- GreyVendorTrash core bag behavior.
-- Client/API differences belong in Compat.lua; settings UI belongs in Options.lua.

GreyVendorTrash = GreyVendorTrash or {}
local GVT = GreyVendorTrash
local Compat = GVT.Compat

local Cache = setmetatable({}, { __mode = "k" })
local COIN_TEXTURE = "Interface\\MoneyFrame\\UI-GoldIcon"

local function GetState(button)
    local state = Cache[button]
    if state then return state end

    state = {}
    Cache[button] = state
    return state
end

local function EnsureCoin(button)
    local state = GetState(button)
    if state.coin then return state.coin end

    local icon = Compat.GetItemButtonIcon(button)
    if not icon then return nil end

    local coin = button:CreateTexture(nil, "OVERLAY", nil, 7)
    coin:SetTexture(COIN_TEXTURE)
    coin:SetSize(12, 12)
    coin:SetPoint("TOPLEFT", icon, "TOPLEFT", 1, -1)
    coin:Hide()

    state.coin = coin
    return coin
end

local function ClearButton(button)
    local state = Cache[button]
    local icon = Compat.GetItemButtonIcon(button)

    if state and state.coin then
        state.coin:Hide()
    end

    if icon and GVT:GetSetting("desaturate") then
        -- Only undo the state this addon intentionally applies. Blizzard may
        -- desaturate locked items itself, so preserve that below when possible.
        icon:SetDesaturated(false)
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

    if GVT:GetSetting("desaturate") then
        icon:SetDesaturated(isTrash or locked)
    else
        -- Do not fight Blizzard's normal locked-item treatment.
        icon:SetDesaturated(locked)
    end

    local coin = EnsureCoin(button)
    if coin then
        -- Forever already supplies its own junk coin while the merchant is open.
        -- Our marker exists to extend that visual language away from merchants,
        -- not to draw a second coin over Blizzard's.
        local showOurCoin = isTrash
            and GVT:GetSetting("alwaysShowCoin")
            and not Compat.IsMerchantOpen()
        coin:SetShown(showOurCoin)
    end
end

local function UpdateContainer(frame)
    if not frame then return end

    -- Modern/Forever combined or individual bags.
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

    -- Classic bag frames.
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
        -- Hook whichever bag update paths this client exposes.
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

-- Blizzard can change icon desaturation after a bag update (notably for locks).
-- Re-apply our poor-quality state after its helper runs.
if SetItemButtonDesaturated then
    hooksecurefunc("SetItemButtonDesaturated", function(button)
        local bag, slot = Compat.GetBagAndSlot(button)
        if bag ~= nil and slot ~= nil then
            UpdateButton(button, bag, slot)
        end
    end)
end

GVT.UpdateButton = UpdateButton
GVT.UpdateContainer = UpdateContainer
