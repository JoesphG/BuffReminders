local _, BR = ...

if not BR then
    return
end

BR.JG = BR.JG or {}

local function EnsureParityDB()
    BuffRemindersDB = BuffRemindersDB or {}
    BuffRemindersDB.jgParity = BuffRemindersDB.jgParity or {}
    local db = BuffRemindersDB.jgParity

    if db.soulstoneThresholdMin == nil then
        db.soulstoneThresholdMin = 5
    end
    if db.durabilityThreshold == nil then
        db.durabilityThreshold = 30
    end
    if db.enableEatingTimer == nil then
        db.enableEatingTimer = true
    end
    if db.suppressFoodWhileEating == nil then
        db.suppressFoodWhileEating = true
    end
    return db
end

BR.JG.BuildSettingsSection = function(settingsContent, setLayout, opts)
    if not settingsContent or not setLayout or not opts then
        return
    end

    local Components = opts.Components
    local LayoutSectionHeader = opts.LayoutSectionHeader
    local UpdateDisplay = opts.UpdateDisplay
    local setX = opts.setX or 20
    local COMPONENT_GAP = opts.COMPONENT_GAP or 4

    EnsureParityDB()

    LayoutSectionHeader(setLayout, settingsContent, "JG")

    local ssHolder = Components.Slider(settingsContent, {
        label = "Soulstone",
        min = 1,
        max = 30,
        step = 1,
        suffix = " min",
        get = function()
            local db = EnsureParityDB()
            return tonumber(db.soulstoneThresholdMin) or 5
        end,
        tooltip = {
            title = "Soulstone expiring threshold",
            desc = "Show warning when your active Soulstone has less than this many minutes remaining.",
        },
        onChange = function(val)
            local db = EnsureParityDB()
            db.soulstoneThresholdMin = val
            UpdateDisplay()
        end,
    })
    setLayout:Add(ssHolder, nil, COMPONENT_GAP)

    local repairHolder = Components.Slider(settingsContent, {
        label = "Repair",
        min = 1,
        max = 100,
        step = 1,
        suffix = "%",
        get = function()
            local db = EnsureParityDB()
            return tonumber(db.durabilityThreshold) or 30
        end,
        tooltip = {
            title = "Durability warning threshold",
            desc = "Show repair reminder when your lowest equipped slot reaches this percent or lower.",
        },
        onChange = function(val)
            local db = EnsureParityDB()
            db.durabilityThreshold = val
            UpdateDisplay()
        end,
    })
    setLayout:Add(repairHolder, nil, COMPONENT_GAP)

    local eatingTimerHolder = Components.Checkbox(settingsContent, {
        label = "Show eating timer",
        get = function()
            local db = EnsureParityDB()
            return db.enableEatingTimer ~= false
        end,
        onChange = function(checked)
            local db = EnsureParityDB()
            db.enableEatingTimer = checked
            UpdateDisplay()
        end,
    })
    setLayout:Add(eatingTimerHolder, nil, COMPONENT_GAP)

    setLayout:SetX(setX + 20)
    local suppressFoodHolder = Components.Checkbox(settingsContent, {
        label = "Hide food icon while eating",
        get = function()
            local db = EnsureParityDB()
            return db.suppressFoodWhileEating ~= false
        end,
        enabled = function()
            local db = EnsureParityDB()
            return db.enableEatingTimer ~= false
        end,
        onChange = function(checked)
            local db = EnsureParityDB()
            db.suppressFoodWhileEating = checked
            UpdateDisplay()
        end,
    })
    setLayout:Add(suppressFoodHolder, nil, COMPONENT_GAP)
    setLayout:SetX(setX)

end
