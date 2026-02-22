# JG Fork Customizations

This document tracks the JG-specific code that remains after upstream resync.

## Scope

- Additive extension modules under `Extensions/JG/`
- Small integration points outside `Extensions/JG/` (TOC + options hook + docs)

## Active Customizations

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

3. `Extensions/JG/OptionsSection.lua`
- Adds JG settings section in `/br` Settings tab:
  - healthstone threshold
  - soulstone threshold
  - repair threshold
  - eating timer toggles
- Owns defaults/initialization for `BuffRemindersDB.jgParity`.

4. `Extensions/JG/PetHover.lua`
- Adds pet hover UX for pet frames:
  - tooltip by spell
  - hunter family line
  - temporary icon swap on hover (spec/family hint)
- Wraps `BR.Display.Update` to refresh hover metadata after each render.

5. `BuffReminders.toc`
- Adds JG extension load entries and keeps required order:
  - `Extensions\\JG\\Bootstrap.lua`
  - `Extensions\\JG\\PostRefresh.lua`
  - `Extensions\\JG\\PetHover.lua`
  - `Extensions\\JG\\OptionsSection.lua`
- Fork version suffix: `3.8.0-JG.5`.

6. `Options/Options.lua`
- Integrates extension settings by calling `BR.JG.BuildSettingsSection(...)`.

7. `README.md`
- Documents fork customizations and points to this file.

## Required TOC Order

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
Extensions\JG\PetHover.lua
Extensions\JG\OptionsSection.lua
Options\Options.lua
```

Why: `Bootstrap` requires buff tables; `PostRefresh` wraps `State.Refresh`; hover/options layers require display modules.

## SavedVariables Contract

`BuffRemindersDB.jgParity` keys:

- `healthstoneThreshold` (default `1`)
- `soulstoneThresholdMin` (default `5`)
- `durabilityThreshold` (default `30`)
- `enableEatingTimer` (default `true`)
- `suppressFoodWhileEating` (default `true`)

## Reapply Procedure After Upstream Sync

1. Restore all files under `Extensions/JG/`.
2. Reapply TOC entries and order from this document.
3. Reapply `Options/Options.lua` hook to call `BR.JG.BuildSettingsSection(...)`.
4. Reload UI and run validation checklist.

## Validation Checklist

- Warlock and non-warlock characters.
- Solo, party, and raid contexts.
- Instance vs open-world gating behavior.
- Soulwell/healthstone de-duplication behavior.
- Pet hover tooltip/icon behavior in generic and expanded pet modes.
- Eating timer visibility and food suppression toggle behavior.
