-- GreyVendorTrash client implementation loader.
-- Classic-family clients keep the proven pre-Forever implementation intact.
-- WoW Forever uses the new options/native-coin implementation.

if GreyVendorTrash and GreyVendorTrash.Compat and GreyVendorTrash.Compat.IsForever() then
    -- Forever implementation is loaded directly by the TOC after this selector.
    GreyVendorTrash.UseForeverImplementation = true
else
    GreyVendorTrash = GreyVendorTrash or {}
    GreyVendorTrash.UseForeverImplementation = false
end
