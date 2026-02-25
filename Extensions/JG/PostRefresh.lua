local _, BR = ...

if not BR or not BR.BuffState or not BR.StateHelpers then
    return
end

BR.JG = BR.JG or {}

local function EnsureParityDB()
    BuffRemindersDB = BuffRemindersDB or {}
    BuffRemindersDB.jgParity = BuffRemindersDB.jgParity or {}
    local db = BuffRemindersDB.jgParity

    if db.durabilityThreshold == nil then
        db.durabilityThreshold = 30
    end
    return db
end

local function HideEntry(entry)
    if not entry then
        return
    end
    entry.visible = false
    entry.shouldGlow = false
    entry.countText = nil
    entry.missingText = nil
    entry.expiringTime = nil
    entry.isEating = nil
end

local function SetCount(entry, countText, shouldGlow)
    entry.visible = true
    entry.displayType = "count"
    entry.countText = countText
    entry.shouldGlow = shouldGlow == true
    entry.expiringTime = nil
    entry.missingText = nil
    entry.isEating = nil
end

local function LowestEquippedDurabilityPercent()
    local minPct = nil
    for slot = 1, 19 do
        if slot ~= 4 and slot ~= 18 then
            local cur, max = GetInventoryItemDurability(slot)
            if cur and max and max > 0 then
                local pct = (cur / max) * 100
                if not minPct or pct < minPct then
                    minPct = pct
                end
            end
        end
    end
    if not minPct then
        return 100
    end
    return math.floor(minPct + 0.5)
end

local function RebuildVisibleByCategory()
    local entries = BR.BuffState.entries or {}
    BR.BuffState.visibleByCategory = {}
    for _, entry in pairs(entries) do
        if entry.visible then
            local cat = entry.category
            if not BR.BuffState.visibleByCategory[cat] then
                BR.BuffState.visibleByCategory[cat] = {}
            end
            BR.BuffState.visibleByCategory[cat][#BR.BuffState.visibleByCategory[cat] + 1] = entry
        end
    end
end

local function ProcessRepair(db)
    local entry = BR.BuffState.GetEntry("jg_repair")
    if not entry then
        return
    end
    if BR.StateHelpers.IsBuffEnabled and not BR.StateHelpers.IsBuffEnabled("jg_repair") then
        HideEntry(entry)
        return
    end
    if UnitIsDeadOrGhost("player") or InCombatLockdown() then
        HideEntry(entry)
        return
    end

    local threshold = tonumber(db.durabilityThreshold) or 30
    threshold = math.max(0, math.min(100, threshold))
    local pct = LowestEquippedDurabilityPercent()
    if pct <= threshold then
        SetCount(entry, tostring(pct) .. "%", true)
        return
    end
    HideEntry(entry)
end

local function PostRefreshPatch()
    if not BuffRemindersDB then
        return
    end
    local db = EnsureParityDB()

    ProcessRepair(db)

    RebuildVisibleByCategory()
end

if BR.JG._refreshWrapped then
    return
end
BR.JG._refreshWrapped = true

local origRefresh = BR.BuffState.Refresh
BR.BuffState.Refresh = function(...)
    local r = origRefresh(...)
    PostRefreshPatch()
    return r
end

-- Keep parity reminders fresh on relevant events.
if not BR.JG._eventFrame then
    local f = CreateFrame("Frame")
    f:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    f:RegisterEvent("UNIT_INVENTORY_CHANGED")
    f:RegisterEvent("MERCHANT_SHOW")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(_, event, arg1)
        if event == "UNIT_INVENTORY_CHANGED" and arg1 ~= "player" then
            return
        end
        if event == "PLAYER_REGEN_ENABLED" or not InCombatLockdown() then
            if BR.Display and BR.Display.Update then
                BR.Display.Update()
            elseif BR.BuffState and BR.BuffState.Refresh then
                BR.BuffState.Refresh()
            end
        end
    end)
    BR.JG._eventFrame = f
end
