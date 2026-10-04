# Architecture

GreyVendorTrash uses separate runtime implementations where Blizzard's bag APIs and behavior materially differ.

## Files

- `Compat.lua` — client detection and API adapters used by the Forever implementation.
- `Implementation.lua` — selects the implementation at load time.
- `GreyVendorTrash_Classic.lua` — proven pre-Forever implementation for Classic-family clients, including TBC Anniversary.
- `GreyVendorTrash_Forever.lua` — Forever-only bag presentation, native junk coin, darkness, and refresh behavior.
- `Options.lua` — Forever settings and SavedVariables UI only.
- `Diagnostics.lua` — development-only Forever diagnostics; excluded from release packages.
- `GreyVendorTrash.toc` — metadata and load order.

## Compatibility rule

Classic/TBC behavior is intentionally isolated from Forever behavior. Changes needed for Forever must not alter the proven Classic/TBC rendering path. Forever reports `WOW_PROJECT_MAINLINE`, so the 16000-series interface generation is used where explicit Forever identification is required.

## Scope

Forever styling is restricted to player inventory bags. Merchant, buyback, bank, guild-bank, and other non-bag item buttons are left to Blizzard. Classic/TBC retains the original implementation unchanged.
