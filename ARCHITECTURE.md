# Architecture

GreyVendorTrash is maintained by StormtrooperTK421 as part of a multi-client World of Warcraft addon family.

## Design goals

- Preserve the addon's simple purpose while supporting WoW Forever cleanly.
- Prefer capability detection over project/version checks.
- Keep client/API compatibility in `Compat.lua`.
- Keep saved preferences and Blizzard Settings UI in `Options.lua`.
- Keep beta probes in `Diagnostics.lua`, separate from normal feature behavior.
- Preserve one addon version across supported WoW clients.

## File responsibilities

- `GreyVendorTrash.lua` — core bag-item presentation and refresh behavior.
- `Compat.lua` — Blizzard API adapters and Forever detection.
- `Options.lua` — SavedVariables and AddOns settings panel.
- `Diagnostics.lua` — development-only diagnostics; excluded from release packages.
- `GreyVendorTrash.toc` — metadata and load order.

## Forever behavior

WoW Forever reports `WOW_PROJECT_MAINLINE`, so project ID alone must not be used to identify Retail behavior. The 16000-series interface generation is used only where explicit Forever identification is required.

Forever already displays a Blizzard junk/coin marker while a merchant is open. GreyVendorTrash does not replace or duplicate that marker. The optional coin setting keeps Blizzard's native `JunkIcon` visible on player bags away from merchants. GreyVendorTrash never styles merchant, buyback, bank, guild-bank, or other non-bag item buttons.

## Development

`main` is the known-good/release branch. Forever work is developed on a branch and merged only after in-game testing.
