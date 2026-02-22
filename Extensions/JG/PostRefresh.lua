local _, BR = ...

if not BR or not BR.BuffState or not BR.StateHelpers then
    return
end

BR.JG = BR.JG or {}

local function IsSecretValue(v)
    if type(issecretvalue) == "function" then
        return issecretvalue(v) == true
    end
    return false
end

local function SafeNumber(v, fallback)
    if type(v) == "number" and not IsSecretValue(v) then
        return v
    end
    return fallback
end

local function SafeString(v, fallback)
    if type(v) == "string" and v ~= "" and not IsSecretValue(v) then
        return v
    end
    return fallback
end

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

local function SetMissing(entry, missingText, shouldGlow)
    entry.visible = true
    entry.displayType = "missing"
    entry.missingText = missingText
    entry.shouldGlow = shouldGlow == true
    entry.countText = nil
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

local function SetExpiring(entry, countText, remaining, shouldGlow)
    entry.visible = true
    entry.displayType = "expiring"
    entry.countText = countText
    entry.expiringTime = remaining
    entry.shouldGlow = shouldGlow == true
    entry.missingText = nil
    entry.isEating = nil
end

local function IsWarlockPlayer()
    local _, class = UnitClass("player")
    return class == "WARLOCK"
end

local function FormatSeconds(seconds)
    if BR.StateHelpers and BR.StateHelpers.FormatRemainingTime then
        return BR.StateHelpers.FormatRemainingTime(seconds)
    end
    local mins = math.floor(seconds / 60)
    if mins > 0 then
        return mins .. "m"
    end
    return math.floor(seconds) .. "s"
end

local function ScanEatingRemaining()
    local iconID = BR.EATING_AURA_ICON or 133950
    local i = 1
    while true do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura then
            break
        end
        local auraIcon = SafeNumber(aura.icon, nil)
        if auraIcon == iconID then
            local exp = SafeNumber(aura.expirationTime, nil)
            if exp and exp > 0 then
                return math.max(0, exp - GetTime())
            end
            local dur = SafeNumber(aura.duration, nil)
            if dur and dur > 0 then
                return dur
            end
            return 0
        end
        i = i + 1
    end
    return nil
end

local function HasFoodBuffAura()
    local iconID = 136000 -- Shared Well Fed/food buff icon
    local i = 1
    while true do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura then
            break
        end
        if SafeNumber(aura.icon, nil) == iconID then
            return true
        end
        i = i + 1
    end
    return false
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

local function ProcessSoulstone(db)
    local entry = BR.BuffState.GetEntry("soulstone")
    if not entry then
        return
    end
    if BR.StateHelpers.IsBuffEnabled and not BR.StateHelpers.IsBuffEnabled("soulstone") then
        HideEntry(entry)
        return
    end
    if not IsWarlockPlayer() then
        HideEntry(entry)
        return
    end

    local inGroup = GetNumGroupMembers() > 0
    local inInstance = select(1, IsInInstance())
    local resting = IsResting()
    local dead = UnitIsDeadOrGhost("player")
    if dead or resting or not inGroup or not inInstance then
        HideEntry(entry)
        return
    end

    local have = 0
    local minRemaining = nil
    local units = {}

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            units[#units + 1] = "raid" .. i
        end
    else
        units[#units + 1] = "player"
        for i = 1, GetNumSubgroupMembers() do
            units[#units + 1] = "party" .. i
        end
    end

    for _, unit in ipairs(units) do
        if BR.StateHelpers.IsValidGroupMember and BR.StateHelpers.IsValidGroupMember(unit) then
            local aura = C_UnitAuras.GetUnitAuraBySpellID(unit, 20707)
            local src = aura and SafeString(aura.sourceUnit, nil)
            if aura and src and UnitIsUnit(src, "player") then
                have = have + 1
                local exp = SafeNumber(aura.expirationTime, nil)
                if exp and exp > 0 then
                    local remaining = exp - GetTime()
                    if not minRemaining or remaining < minRemaining then
                        minRemaining = remaining
                    end
                end
            end
        end
    end

    if have < 1 then
        SetMissing(entry, "NO\nSTONE", true)
        return
    end

    local thresholdSec = (tonumber(db.soulstoneThresholdMin) or 5) * 60
    if minRemaining and minRemaining < thresholdSec then
        SetExpiring(entry, FormatSeconds(minRemaining), minRemaining, true)
        return
    end

    HideEntry(entry)
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

local function ProcessEatingTimer(db)
    local entry = BR.BuffState.GetEntry("jg_eating_timer")
    if not entry then
        return
    end
    if BR.StateHelpers.IsBuffEnabled and not BR.StateHelpers.IsBuffEnabled("jg_eating_timer") then
        HideEntry(entry)
        return
    end
    if db.enableEatingTimer == false or UnitIsDeadOrGhost("player") then
        HideEntry(entry)
        return
    end

    -- As soon as a food buff is active, stop showing the eating timer icon.
    -- This avoids overlap/flicker when the channel aura lingers briefly.
    if HasFoodBuffAura() then
        HideEntry(entry)
        return
    end

    local remaining = ScanEatingRemaining()
    if remaining and remaining >= 0 then
        if db.suppressFoodWhileEating ~= false then
            local food = BR.BuffState.GetEntry("food")
            if food then
                HideEntry(food)
            end
        end
        SetExpiring(entry, FormatSeconds(remaining), remaining, false)
        return
    end
    HideEntry(entry)
end

local function PostRefreshPatch()
    if not BuffRemindersDB then
        return
    end
    local db = EnsureParityDB()

    ProcessSoulstone(db)
    ProcessRepair(db)
    ProcessEatingTimer(db)

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
    f:RegisterEvent("UNIT_AURA")
    f:SetScript("OnEvent", function(_, event, arg1)
        if event == "UNIT_AURA" and arg1 ~= "player" and not (arg1 and (arg1:match("^party%d") or arg1:match("^raid%d"))) then
            return
        end
        if event == "UNIT_INVENTORY_CHANGED" and arg1 ~= "player" then
            return
        end
        if event == "PLAYER_REGEN_ENABLED" or not InCombatLockdown() then
            if BR.Display and BR.Display.Update then
                BR.Display.Update()
            end
        end
    end)
    BR.JG._eventFrame = f
end
