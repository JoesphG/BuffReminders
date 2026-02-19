# JG Fork Customizations (Explicit Inventory)

This document is the authoritative reapply checklist for this fork's custom behavior.

## Scope

The fork includes:

- Additive extension module logic under `Extensions/JG/`
- Small integration points outside `Extensions/JG/` (TOC + options hook + docs)
- Display hardening in `Display/BuffReminders.lua` to prevent dynamic icon overlap

## Customization Inventory By File

1. `Extensions/JG/Bootstrap.lua`
- Injects additive self-buff anchors into `BR.BUFF_TABLES.self`:
  - `jg_soulwell`
  - `jg_repair`
  - `jg_eating_timer`

2. `Extensions/JG/PostRefresh.lua`
- Wraps `BR.BuffState.Refresh` and applies parity post-processing in one pass:
  - healthstone
  - soulstone
  - soulwell
  - repair
  - eating timer
- Rebuilds `BR.BuffState.visibleByCategory` after post-refresh mutations.
- Adds event-driven refresh triggers for parity rows.
- Uses secure-value-safe guards (`issecretvalue`) for aura/cooldown reads.

3. `Extensions/JG/ClickActions.lua`
- Ensures self category remains clickable for parity rows.
- Adds/maintains secure click overlays for JG rows.
- Supports:
  - optional repair macro click action from settings
- Reapplies parity item actions after display/secure refresh to prevent action loss.

4. `Extensions/JG/OptionsSection.lua`
- Adds JG settings section in `/br` Settings tab:
  - healthstone threshold
  - soulstone threshold
  - repair threshold
  - eating timer toggles
  - repair click macro enable toggle
- Owns defaults/initialization for `BuffRemindersDB.jgParity`.

5. `Extensions/JG/PetHover.lua`
- Adds pet hover UX for pet frames:
  - tooltip by spell
  - hunter family line
  - temporary icon swap on hover (spec/family hint)
- Wraps `BR.Display.Update` to refresh hover metadata after each render.

6. `BuffReminders.toc`
- Adds JG extension load entries and keeps required order:
  - `Extensions\JG\Bootstrap.lua`
  - `Extensions\JG\PostRefresh.lua`
  - `Extensions\JG\ClickActions.lua`
  - `Extensions\JG\PetHover.lua`
  - `Extensions\JG\OptionsSection.lua`
- Fork version suffix: `3.7.4-JG.5`.

7. `Options/Options.lua`
- Integrates extension settings by calling `BR.JG.BuildSettingsSection(...)`.

8. `README.md`
- Adds "Fork Customizations" section pointing to this file.

9. `Display/BuffReminders.lua` (fork hardening outside extension)
- Dynamic layout hardening for no-overlap behavior when icons are added/removed.
- Main and split containers always relayout each display pass.
- Expanded extra frames are force-hidden each cycle before selective re-show.
- Prevents orphan/leftover extra icons from colliding with base icons.

10. Custom buff click/data extensions (outside `Extensions/JG/`)
- `Options/Options.lua`:
  - Custom modal includes `Cast ID` and `Item ID` fields (saved to custom buff entries).
  - Footer/layout spacing adjusted to avoid Delete button collisions.
- `Display/SecureButtons.lua`:
  - Custom click actions can use `itemID` (secure macro use flow) when aura spell ID differs.
- `State.lua`:
  - Custom buffs with `itemID` only process/show when that item is in bags or equipped.

## Required TOC Order

Use this order (relative subset shown):

```toc
Core.lua
Data\Buffs.lua
Data\ConsumableItems.lua
Data\Pets.lua
Extensions\JG\Bootstrap.lua
State.lua
Extensions\JG\PostRefresh.lua
...
Display\SecureButtons.lua
Extensions\JG\ClickActions.lua
Extensions\JG\PetHover.lua
Extensions\JG\OptionsSection.lua
Options\Options.lua
```

Why: `Bootstrap` requires buff tables; `PostRefresh` wraps `State.Refresh`; click/hover/options layers require display/secure modules.

## SavedVariables Contract

`BuffRemindersDB.jgParity` keys:

- `healthstoneThreshold` (default `1`)
- `soulstoneThresholdMin` (default `5`)
- `durabilityThreshold` (default `30`)
- `enableEatingTimer` (default `true`)
- `suppressFoodWhileEating` (default `true`)
- `enableRepairMacro` (default `false`)
- `repairClickMacro` (default secure repair macro text)

## Reapply Procedure After Upstream Sync

1. Restore all files under `Extensions/JG/`.
2. Reapply TOC entries and order from this document.
3. Reapply `Options/Options.lua` hook to call `BR.JG.BuildSettingsSection(...)`.
4. Reapply display hardening in `Display/BuffReminders.lua` (dynamic no-overlap logic).
5. Reload UI and run validation checklist.

## Validation Checklist

- Warlock and non-warlock characters.
- Solo, party, and raid contexts.
- Instance vs open-world gating behavior.
- Soulwell/healthstone de-duplication behavior.
- Pet hover tooltip/icon behavior in generic and expanded pet modes.
- Eating timer visibility and food suppression toggle behavior.
- Repeated dynamic icon add/remove cycles do not overlap.
