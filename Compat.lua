-- GreyVendorTrash client/API compatibility layer.
-- Prefer capability detection. WoW Forever currently reports MAINLINE even
-- though its API surface differs from Retail.

GreyVendorTrash = GreyVendorTrash or {}
local GVT = GreyVendorTrash

GVT.Compat = GVT.Compat or {}
local Compat = GVT.Compat

function Compat.IsForever()
    local interfaceVersion = select(4, GetBuildInfo())
    return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
        and type(interfaceVersion) == "number"
        and interfaceVersion >= 16000
        and interfaceVersion < 17000
end

function Compat.GetContainerItemInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        return C_Container.GetContainerItemInfo(bag, slot)
    end

    if GetContainerItemInfo then
        local texture, stackCount, locked, quality, readable, lootable, itemLink,
              isFiltered, noValue, itemID, isBound = GetContainerItemInfo(bag, slot)

        if texture then
            return {
                iconFileID = texture,
                stackCount = stackCount,
                isLocked = locked,
                quality = quality,
                isReadable = readable,
                hasLoot = lootable,
                hyperlink = itemLink,
                isFiltered = isFiltered,
                hasNoValue = noValue,
                itemID = itemID,
                isBound = isBound,
            }
        end
    end
end

function Compat.GetItemQuality(item)
    if not item then return nil end

    if C_Item and C_Item.GetItemInfo then
        local _, _, quality = C_Item.GetItemInfo(item)
        if quality ~= nil then return quality end
    end

    if GetItemInfo then
        return select(3, GetItemInfo(item))
    end
end

function Compat.GetItemButtonIcon(button)
    if not button then return nil end
    return button.Icon
        or button.icon
        or (button.GetName and button:GetName() and _G[button:GetName() .. "IconTexture"])
end

function Compat.GetBagAndSlot(button)
    if not button then return nil, nil end

    local bag
    if button.GetBagID then
        bag = button:GetBagID()
    end
    if bag == nil and button.GetParent and button:GetParent() and button:GetParent().GetID then
        bag = button:GetParent():GetID()
    end

    local slot = button.GetID and button:GetID()
    return bag, slot
end

function Compat.IsMerchantOpen()
    return MerchantFrame and MerchantFrame:IsShown()
end
