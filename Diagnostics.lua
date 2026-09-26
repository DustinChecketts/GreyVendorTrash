-- GreyVendorTrash Forever diagnostics.
-- Kept separate from feature code so beta probes are easy to remove or extend.

GreyVendorTrash = GreyVendorTrash or {}
local GVT = GreyVendorTrash
local Compat = GVT.Compat

local function Print(...)
    print("|cff33ff99GreyVendorTrash:|r", ...)
end

local function Safe(value)
    local ok, text = pcall(tostring, value)
    return ok and text or "<protected>"
end

local function FindVisibleTrashButton()
    local function Scan(frame)
        if not frame then return nil end

        local buttons = {}
        if frame.EnumerateValidItems then
            for _, button in frame:EnumerateValidItems() do
                buttons[#buttons + 1] = button
            end
        elseif frame.Items then
            for _, button in ipairs(frame.Items) do
                buttons[#buttons + 1] = button
            end
        else
            local name = frame.GetName and frame:GetName()
            if name then
                local i = 1
                while _G[name .. "Item" .. i] do
                    buttons[#buttons + 1] = _G[name .. "Item" .. i]
                    i = i + 1
                end
            end
        end

        for _, button in ipairs(buttons) do
            local bag, slot = Compat.GetBagAndSlot(button)
            local info = bag ~= nil and slot ~= nil and Compat.GetContainerItemInfo(bag, slot)
            if info and info.hyperlink then
                local quality = info.quality
                if quality == nil then quality = Compat.GetItemQuality(info.hyperlink) end
                if quality == 0 then
                    return button, bag, slot, info
                end
            end
        end
    end

    if ContainerFrameCombinedBags and ContainerFrameCombinedBags:IsShown() then
        local button, bag, slot, info = Scan(ContainerFrameCombinedBags)
        if button then return button, bag, slot, info end
    end

    local i = 1
    while _G["ContainerFrame" .. i] do
        local frame = _G["ContainerFrame" .. i]
        if frame:IsShown() then
            local button, bag, slot, info = Scan(frame)
            if button then return button, bag, slot, info end
        end
        i = i + 1
    end
end

local function DumpRegions(button)
    if not button or not button.GetRegions then return end
    local regions = { button:GetRegions() }
    Print("button regions:", #regions)

    for index, region in ipairs(regions) do
        if region and region.GetObjectType then
            local kind = region:GetObjectType()
            if kind == "Texture" then
                local texture = region.GetTexture and region:GetTexture()
                local shown = region.IsShown and region:IsShown()
                local point, relativeTo, relativePoint, x, y
                if region.GetPoint then
                    point, relativeTo, relativePoint, x, y = region:GetPoint(1)
                end
                Print(
                    index,
                    "Texture",
                    "shown=" .. Safe(shown),
                    "texture=" .. Safe(texture),
                    "point=" .. Safe(point),
                    "x=" .. Safe(x),
                    "y=" .. Safe(y)
                )
            end
        end
    end
end

function GVT:RunDiagnostics()
    local _, build, _, interfaceVersion = GetBuildInfo()
    Print("build=" .. Safe(build),
        "interface=" .. Safe(interfaceVersion),
        "project=" .. Safe(WOW_PROJECT_ID),
        "Forever=" .. Safe(Compat.IsForever()))
    Print("merchantOpen=" .. Safe(Compat.IsMerchantOpen()),
        "C_Container=" .. Safe(C_Container ~= nil),
        "ContainerFrame_Update=" .. Safe(ContainerFrame_Update ~= nil),
        "combinedBags=" .. Safe(ContainerFrameCombinedBags ~= nil))

    local button, bag, slot, info = FindVisibleTrashButton()
    if not button then
        Print("No visible poor-quality bag item found. Open your bags with at least one grey item and run /gvt diag again.")
        return
    end

    Print("trash button=" .. Safe(button:GetName()),
        "bag=" .. Safe(bag),
        "slot=" .. Safe(slot),
        "item=" .. Safe(info.hyperlink))
    Print("known fields:",
        "JunkIcon=" .. Safe(button.JunkIcon),
        "junkIcon=" .. Safe(button.junkIcon),
        "IconOverlay=" .. Safe(button.IconOverlay),
        "IconBorder=" .. Safe(button.IconBorder))
    DumpRegions(button)
    Print("Run this once away from a vendor and once with the merchant window open; paste both outputs back to me.")
end

SLASH_GREYVENDORTRASH1 = "/gvt"
SlashCmdList.GREYVENDORTRASH = function(message)
    message = (message or ""):lower():match("^%s*(.-)%s*$")
    if message == "diag" or message == "diagnostics" then
        GVT:RunDiagnostics()
    elseif message == "refresh" then
        GVT:RefreshAll()
        Print("bags refreshed")
    else
        GVT:OpenOptions()
    end
end
