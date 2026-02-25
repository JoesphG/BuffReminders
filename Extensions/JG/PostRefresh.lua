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

    if db.durabilityThreshold == nil then
        db.durabilityThreshold = 30
    end
    if db.trinketExpiringThresholdMin == nil then
        db.trinketExpiringThresholdMin = 15
    end
    if db.excludedTrinkets == nil then
        db.excludedTrinkets = {}
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

local function IsEquippedItem(itemID)
    if not itemID then
        return false
    end
    local s13 = GetInventoryItemID("player", 13)
    local s14 = GetInventoryItemID("player", 14)
    if s13 == itemID or s14 == itemID then
        return true
    end
    if C_Item and C_Item.IsEquippedItem then
        return C_Item.IsEquippedItem(itemID) and true or false
    end
    if _G.IsEquippedItem then
        return _G.IsEquippedItem(itemID) and true or false
    end
    return false
end

local function BuildAuraNameSet(spellIDs)
    local out = {}
    local ids = type(spellIDs) == "table" and spellIDs or { spellIDs }
    for _, spellID in ipairs(ids) do
        if spellID then
            local info = C_Spell.GetSpellInfo(spellID)
            local name = info and SafeString(info.name, nil)
            if name then
                out[name] = true
            end
        end
    end
    return out
end

local function UnitHasAuraByName(unit, nameSet)
    if not nameSet or next(nameSet) == nil then
        return false, nil
    end

    local bestRemaining = nil
    local i = 1
    while true do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
        if not aura then
            break
        end
        local auraName = aura and SafeString(aura.name, nil)
        if auraName and nameSet[auraName] then
            local remaining = math.huge
            local exp = SafeNumber(aura.expirationTime, nil)
            if exp and exp > 0 then
                remaining = math.max(0, exp - GetTime())
            end
            if bestRemaining == nil or remaining < bestRemaining then
                bestRemaining = remaining
            end
        end
        i = i + 1
    end

    if bestRemaining ~= nil then
        return true, bestRemaining
    end
    return false, nil
end

local function UnitHasAuraBySpellIDs(unit, spellIDs, mineOnly)
    local ids = type(spellIDs) == "table" and spellIDs or { spellIDs }
    local bestRemaining = nil

    for _, spellID in ipairs(ids) do
        local aura = C_UnitAuras.GetUnitAuraBySpellID(unit, spellID)
        if aura then
            local sourceOk = true
            if mineOnly then
                local src = SafeString(aura.sourceUnit, nil)
                sourceOk = src and UnitIsUnit(src, "player")
            end
            if sourceOk then
                local remaining = math.huge
                local exp = SafeNumber(aura.expirationTime, nil)
                if exp and exp > 0 then
                    remaining = math.max(0, exp - GetTime())
                end
                if bestRemaining == nil or remaining < bestRemaining then
                    bestRemaining = remaining
                end
            end
        end
    end

    if bestRemaining ~= nil then
        return true, bestRemaining
    end
    return false, nil
end

local function MergeSpellIDs(first, second)
    local out, seen = {}, {}

    local function add(v)
        if type(v) == "table" then
            for _, id in ipairs(v) do
                if id and not seen[id] then
                    seen[id] = true
                    out[#out + 1] = id
                end
            end
        elseif type(v) == "number" then
            if not seen[v] then
                seen[v] = true
                out[#out + 1] = v
            end
        end
    end

    add(first)
    add(second)
    return out
end

local function PassesTrinketGates(row)
    local gates = row.gates
    if type(gates) ~= "table" then
        return true
    end

    for _, gate in ipairs(gates) do
        if gate == "group" and GetNumGroupMembers() <= 0 then
            return false
        end
        if gate == "rested" and IsResting() then
            return false
        end
        if gate == "instance" and not select(1, IsInInstance()) then
            return false
        end
    end

    return true
end

local function IsExcludedTrinket(db, row)
    local ex = db.excludedTrinkets
    if type(ex) ~= "table" then
        return false
    end
    local itemID = row.itemID
    if itemID and (ex[itemID] or ex[tostring(itemID)]) then
        return true
    end
    if row.key and ex[row.key] then
        return true
    end
    return false
end

local function BuildGroupUnitsForRow(row)
    local units = {}

    if row.check == "player" then
        units[1] = "player"
        return units
    end

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            units[#units + 1] = "raid" .. i
        end
    elseif IsInGroup() then
        units[#units + 1] = "player"
        for i = 1, GetNumSubgroupMembers() do
            units[#units + 1] = "party" .. i
        end
    else
        units[#units + 1] = "player"
    end

    return units
end

local function GetTrinketThresholdSec(db, row)
    local minVal = tonumber(row.expiringThresholdMin)
    if not minVal then
        minVal = tonumber(db.trinketExpiringThresholdMin) or 15
    end
    return math.max(0, minVal) * 60
end

local function UnitHasAnyTrackedAura(unit, spellIDs, nameSet, mineOnly)
    local hasByID, remByID = UnitHasAuraBySpellIDs(unit, spellIDs, mineOnly)
    if hasByID then
        return true, remByID
    end

    if mineOnly then
        return false, nil
    end

    local hasByName, remByName = UnitHasAuraByName(unit, nameSet)
    if hasByName then
        return true, remByName
    end

    return false, nil
end

local function ProcessTrinkets(db)
    local rows = BR.JG and BR.JG.TRINKETS
    if type(rows) ~= "table" then
        return
    end

    for _, row in ipairs(rows) do
        local entry = BR.BuffState.GetEntry(row.key)
        if entry then
            if BR.StateHelpers.IsBuffEnabled and not BR.StateHelpers.IsBuffEnabled(row.key) then
                HideEntry(entry)
            elseif IsExcludedTrinket(db, row) then
                HideEntry(entry)
            elseif UnitIsDeadOrGhost("player") or InCombatLockdown() then
                HideEntry(entry)
            elseif not PassesTrinketGates(row) then
                HideEntry(entry)
            elseif not IsEquippedItem(row.itemID) then
                HideEntry(entry)
            else
                local skipFurtherChecks = false
                local playerHideIDs = MergeSpellIDs(row.buffIDs, row.targetBuffID)
                if row.hideWhenPlayerHasBuff then
                    local hideNameSet = BuildAuraNameSet(playerHideIDs)
                    local hasPlayerAura =
                        UnitHasAnyTrackedAura("player", playerHideIDs, hideNameSet, row.mineOnly == true)
                    if hasPlayerAura then
                        HideEntry(entry)
                        skipFurtherChecks = true
                    end
                end

                if not skipFurtherChecks then
                    local trackedIDs = row.targetBuffID and { row.targetBuffID } or row.buffIDs
                    trackedIDs = MergeSpellIDs(trackedIDs, nil)
                    local trackedNames = BuildAuraNameSet(trackedIDs)
                    local thresholdSec = GetTrinketThresholdSec(db, row)

                    if row.check == "player" then
                        local hasAura, remaining =
                            UnitHasAnyTrackedAura("player", trackedIDs, trackedNames, row.mineOnly == true)
                        if not hasAura then
                            SetMissing(entry, "TRINKET", true)
                        elseif remaining and remaining ~= math.huge and remaining <= thresholdSec then
                            SetExpiring(entry, FormatSeconds(remaining), remaining, true)
                        else
                            HideEntry(entry)
                        end
                    else
                        local units = BuildGroupUnitsForRow(row)
                        local have = 0
                        local total = 0
                        local soonest = nil

                        for _, unit in ipairs(units) do
                            local valid = true
                            if BR.StateHelpers.IsValidGroupMember then
                                valid = BR.StateHelpers.IsValidGroupMember(unit)
                            end
                            if valid then
                                total = total + 1
                                local hasAura, remaining =
                                    UnitHasAnyTrackedAura(unit, trackedIDs, trackedNames, row.mineOnly == true)
                                if hasAura then
                                    have = have + 1
                                    if remaining and remaining ~= math.huge then
                                        if not soonest or remaining < soonest then
                                            soonest = remaining
                                        end
                                    end
                                end
                            end
                        end

                        local required = tonumber(row.requiredCount) or 1
                        required = math.max(1, math.min(required, math.max(total, 1)))

                        if have < required then
                            SetCount(entry, tostring(have) .. "/" .. tostring(required), true)
                        elseif soonest and soonest <= thresholdSec then
                            SetExpiring(entry, FormatSeconds(soonest), soonest, true)
                        else
                            HideEntry(entry)
                        end
                    end
                end
            end
        end
    end
end

local function PostRefreshPatch()
    if not BuffRemindersDB then
        return
    end
    local db = EnsureParityDB()

    ProcessRepair(db)
    ProcessTrinkets(db)

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
        if
            event == "UNIT_AURA"
            and arg1 ~= "player"
            and not (arg1 and (arg1:match("^party%d") or arg1:match("^raid%d")))
        then
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
