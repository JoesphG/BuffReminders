# CRB Parity Extension (Standalone)

This folder adds feature parity behavior inspired by `ClickableRaidBuffs` while keeping changes mostly additive, so upstream resync is low-friction.

## Goals

- Keep parity logic in standalone files.
- Avoid large edits to core addon files.
- Allow reimplementation after upstream resync by re-adding this folder and TOC entries.

## Included Features

1. Soulstone parity behavior
- Tracks warlock Soulstone responsibility in grouped/instance contexts.
- Uses expiration threshold logic.

2. Healthstone parity behavior
- Uses charge threshold logic (not only ready-check visibility).
- Handles warlock/non-warlock contexts.
- Includes Soulwell availability reminder entry.

3. Repair / durability reminder
- Shows reminder when lowest equipped durability drops below threshold.

4. Eating timer
- Shows active timer-style entry while eating.
- Suppresses default food reminder entry during active eating timer display.

5. Trinket reminders
- Tracks selected equipped trinkets and their aura coverage.

## Files

- `Extensions/CRBParity/Bootstrap.lua`
- `Extensions/CRBParity/PostRefresh.lua`
- `Extensions/CRBParity/ClickActions.lua`

## TOC Wiring

Ensure these entries exist in `BuffReminders.toc` in this order:

```toc
Core.lua
Data\Buffs.lua
Data\ConsumableItems.lua
Data\Pets.lua
Extensions\CRBParity\Bootstrap.lua
State.lua
Extensions\CRBParity\PostRefresh.lua
Display\SecureButtons.lua
Extensions\CRBParity\ClickActions.lua
```

The extension depends on `BR.BUFF_TABLES` and `BR.BuffState`, so it must load after `Data\Buffs.lua` and after `State.lua` for refresh wrapping.

## SavedVariables Keys

Stored under `BuffRemindersDB.crbParity`:

- `healthstoneThreshold` (default: `1`)
- `soulstoneThresholdMin` (default: `5`)
- `durabilityThreshold` (default: `25`)

## Reapply After Upstream Resync

1. Re-add `Extensions/CRBParity/` folder.
2. Re-add TOC lines shown above.
3. Reload UI and validate behavior.

## Validation Checklist

- Warlock and non-warlock characters.
- Solo, party, and raid contexts.
- In-instance vs open world behavior.
- Eating timer display during food channel.
- Durability reminder threshold trigger.
- Trinket reminder visibility only when tracked trinket is equipped.

## Maintenance Notes

- Current trinket rows are defined in `Bootstrap.lua` (`BR.CRBParity.TRINKETS`).
- To add/remove tracked trinkets, edit that table only.
- Click binding for item-based parity rows is handled in `ClickActions.lua`.
- Post-refresh logic lives in one place: `PostRefresh.lua`.
