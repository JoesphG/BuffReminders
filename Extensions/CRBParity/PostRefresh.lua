local _, BR = ...

if not BR or not BR.BuffState or not BR.StateHelpers then
    return
end

BR.CRBParity = BR.CRBParity or {}

local function EnsureParityDB()
    BuffRemindersDB = BuffRemindersDB or {}
    BuffRemindersDB.crbParity = BuffRemindersDB.crbParity or {}
    local db = BuffRemindersDB.crbParity
    if db.healthstoneThreshold == nil then
        db.healthstoneThreshold = 1
    end
    if db.soulstoneThresholdMin == nil then
        db.soulstoneThresholdMin = 5
    end
    if db.durabilityThreshold == nil then
        db.durabilityThreshold = 25
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

local function CountItem(itemID)
    local ok, count = pcall(C_Item.GetItemCount, itemID, false, true)
    if ok and type(count) == "number" then
        return count
    end
    return C_Item.GetItemCount(itemID, false) or 0
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

local function HasWarlockInGroup()
    if IsWarlockPlayer() then
        return true
    end
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local _, class = UnitClass("raid" .. i)
            if class == "WARLOCK" then
                return true
            end
        end
        return false
    end
    if IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            local _, class = UnitClass("party" .. i)
            if class == "WARLOCK" then
                return true
            end
        end
    end
    return false
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

local function GetAuraRemaining(unit, spellIDs)
    local ids = type(spellIDs) == "table" and spellIDs or { spellIDs }
    for _, spellID in ipairs(ids) do
        local aura = C_UnitAuras.GetUnitAuraBySpellID(unit, spellID)
        if aura then
            local remaining = nil
            if aura.expirationTime and aura.expirationTime > 0 then
                remaining = math.max(0, aura.expirationTime - GetTime())
            end
            return true, remaining, aura
        end
    end
    return false, nil, nil
end

local function BuildAuraNameSet(spellIDs)
    local out = {}
    local ids = type(spellIDs) == "table" and spellIDs or { spellIDs }
    for _, spellID in ipairs(ids) do
        if spellID then
            local info = C_Spell.GetSpellInfo(spellID)
            local name = info and info.name
            if type(name) == "string" and name ~= "" then
                out[name] = true
            end
        end
    end
    return out
end

local function UnitHasAuraByName(unit, nameSet)
    if not nameSet or next(nameSet) == nil then
        return false
    end
    local i = 1
    while true do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
        if not aura then
            break
        end
        if aura.name and nameSet[aura.name] then
            return true
        end
        i = i + 1
    end
    return false
end

local function ScanEatingRemaining()
    local iconID = BR.EATING_AURA_ICON or 133950
    local i = 1
    while true do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura then
            break
        end
        if aura.icon == iconID then
            if aura.expirationTime and aura.expirationTime > 0 then
                return math.max(0, aura.expirationTime - GetTime())
            end
            if aura.duration and aura.duration > 0 then
                return aura.duration
            end
            return 0
        end
        i = i + 1
    end
    return nil
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

local function ProcessHealthstone(db)
    local entry = BR.BuffState.GetEntry("healthstone")
    if not entry then
        return
    end
    if BR.StateHelpers.IsBuffEnabled and not BR.StateHelpers.IsBuffEnabled("healthstone") then
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

    local threshold = tonumber(db.healthstoneThreshold) or 1
    local isWarlock = IsWarlockPlayer()

    local charges = 0
    if isWarlock and IsPlayerSpell(386689) then
        charges = CountItem(224464) -- Demonic Healthstone
    else
        charges = CountItem(5512) -- Healthstone
    end

    if not isWarlock and not HasWarlockInGroup() and charges == 0 then
        HideEntry(entry)
        return
    end

    if charges <= threshold then
        SetCount(entry, tostring(charges), charges == 0)
        return
    end

    HideEntry(entry)
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
    local total = 0
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
            total = total + 1
            local aura = C_UnitAuras.GetUnitAuraBySpellID(unit, 20707)
            if aura and aura.sourceUnit and UnitIsUnit(aura.sourceUnit, "player") then
                have = have + 1
                if aura.expirationTime and aura.expirationTime > 0 then
                    local remaining = aura.expirationTime - GetTime()
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

local function ProcessSoulwell()
    local entry = BR.BuffState.GetEntry("crbp_soulwell")
    if not entry then
        return
    end
    if BR.StateHelpers.IsBuffEnabled and not BR.StateHelpers.IsBuffEnabled("crbp_soulwell") then
        HideEntry(entry)
        return
    end
    if not IsWarlockPlayer() then
        HideEntry(entry)
        return
    end
    if UnitIsDeadOrGhost("player") or IsResting() or InCombatLockdown() then
        HideEntry(entry)
        return
    end
    if not (GetNumGroupMembers() > 0 and select(1, IsInInstance())) then
        HideEntry(entry)
        return
    end
    if not IsPlayerSpell(29893) then
        HideEntry(entry)
        return
    end

    local cd = C_Spell.GetSpellCooldown(29893)
    local start = cd and cd.startTime or 0
    local dur = cd and cd.duration or 0
    local enabled = cd and cd.isEnabled
    local onCD = enabled and start and dur and start > 0 and dur > 1.5 and ((start + dur) > GetTime())
    if onCD then
        HideEntry(entry)
        return
    end

    local hsCount = CountItem(IsPlayerSpell(386689) and 224464 or 5512)
    if hsCount > ((tonumber(EnsureParityDB().healthstoneThreshold) or 1)) then
        HideEntry(entry)
        return
    end

    SetMissing(entry, "SOUL\nWELL", true)
end

local function ProcessRepair(db)
    local entry = BR.BuffState.GetEntry("crbp_repair")
    if not entry then
        return
    end
    if BR.StateHelpers.IsBuffEnabled and not BR.StateHelpers.IsBuffEnabled("crbp_repair") then
        HideEntry(entry)
        return
    end
    if UnitIsDeadOrGhost("player") or InCombatLockdown() then
        HideEntry(entry)
        return
    end

    local threshold = tonumber(db.durabilityThreshold) or 25
    threshold = math.max(0, math.min(100, threshold))
    local pct = LowestEquippedDurabilityPercent()
    if pct <= threshold then
        SetCount(entry, tostring(pct) .. "%", true)
        return
    end
    HideEntry(entry)
end

local function ProcessEatingTimer()
    local entry = BR.BuffState.GetEntry("crbp_eating_timer")
    if not entry then
        return
    end
    if BR.StateHelpers.IsBuffEnabled and not BR.StateHelpers.IsBuffEnabled("crbp_eating_timer") then
        HideEntry(entry)
        return
    end
    if UnitIsDeadOrGhost("player") then
        HideEntry(entry)
        return
    end

    local remaining = ScanEatingRemaining()
    if remaining and remaining >= 0 then
        local food = BR.BuffState.GetEntry("food")
        if food then
            HideEntry(food)
        end
        SetExpiring(entry, FormatSeconds(remaining), remaining, false)
        return
    end
    HideEntry(entry)
end

local function ProcessTrinkets()
    local rows = BR.CRBParity and BR.CRBParity.TRINKETS
    if type(rows) ~= "table" then
        return
    end

    for _, row in ipairs(rows) do
        local entry = BR.BuffState.GetEntry(row.key)
        if entry then
            if BR.StateHelpers.IsBuffEnabled and not BR.StateHelpers.IsBuffEnabled(row.key) then
                HideEntry(entry)
            elseif not IsEquippedItem(row.itemID) then
                HideEntry(entry)
            elseif row.check == "player" then
                local hasAura = GetAuraRemaining("player", row.buffIDs)
                if not hasAura then
                    hasAura = UnitHasAuraByName("player", BuildAuraNameSet(row.buffIDs))
                end
                if hasAura then
                    HideEntry(entry)
                else
                    SetMissing(entry, "TRINKET", true)
                end
            else
                local hasAny = false
                local total = 0
                local auraNameSet = BuildAuraNameSet(row.buffIDs)
                if IsInRaid() then
                    for i = 1, GetNumGroupMembers() do
                        local unit = "raid" .. i
                        if BR.StateHelpers.IsValidGroupMember and BR.StateHelpers.IsValidGroupMember(unit) then
                            total = total + 1
                            local hasAura = GetAuraRemaining(unit, row.buffIDs)
                            if not hasAura then
                                hasAura = UnitHasAuraByName(unit, auraNameSet)
                            end
                            if hasAura then
                                hasAny = true
                                break
                            end
                        end
                    end
                else
                    local units = { "player" }
                    for i = 1, GetNumSubgroupMembers() do
                        units[#units + 1] = "party" .. i
                    end
                    for _, unit in ipairs(units) do
                        if BR.StateHelpers.IsValidGroupMember and BR.StateHelpers.IsValidGroupMember(unit) then
                            total = total + 1
                            local hasAura = GetAuraRemaining(unit, row.buffIDs)
                            if not hasAura then
                                hasAura = UnitHasAuraByName(unit, auraNameSet)
                            end
                            if hasAura then
                                hasAny = true
                                break
                            end
                        end
                    end
                end

                local required = tonumber(row.requiredCount) or 1
                if required <= 1 then
                    if hasAny then
                        HideEntry(entry)
                    else
                        SetCount(entry, "0/" .. tostring(math.max(total, 1)), true)
                    end
                elseif not hasAny then
                    SetCount(entry, "0/" .. tostring(math.max(total, 1)), true)
                else
                    HideEntry(entry)
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

    ProcessHealthstone(db)
    ProcessSoulstone(db)
    ProcessSoulwell()
    ProcessRepair(db)
    ProcessEatingTimer()
    ProcessTrinkets()

    RebuildVisibleByCategory()
end

if BR.CRBParity._refreshWrapped then
    return
end
BR.CRBParity._refreshWrapped = true

local origRefresh = BR.BuffState.Refresh
BR.BuffState.Refresh = function(...)
    local r = origRefresh(...)
    PostRefreshPatch()
    return r
end

-- Keep repair reminders fresh when durability changes.
if not BR.CRBParity._durabilityEventFrame then
    local f = CreateFrame("Frame")
    f:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" or not InCombatLockdown() then
            if BR.Display and BR.Display.Update then
                BR.Display.Update()
            end
        end
    end)
    BR.CRBParity._durabilityEventFrame = f
end
