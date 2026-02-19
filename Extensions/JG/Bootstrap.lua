local _, BR = ...

BR.JG = BR.JG or {}

local function EnsureInjectedSelfBuff(def)
    local selfBuffs = BR.BUFF_TABLES and BR.BUFF_TABLES.self
    if type(selfBuffs) ~= "table" then
        return
    end
    for _, row in ipairs(selfBuffs) do
        if row and row.key == def.key then
            return
        end
    end
    selfBuffs[#selfBuffs + 1] = def
end

-- Soulwell reminder anchor (visibility logic handled in PostRefresh).
EnsureInjectedSelfBuff({
    spellID = 29893, -- Ritual of Souls
    key = "jg_soulwell",
    name = "Soulwell",
    class = "WARLOCK",
    displayIcon = 136194,
    missingText = "SOUL\nWELL",
    infoTooltip = "JG|Shows when Soulwell is available and your healthstones are low.",
})

-- Durability/repair reminder anchor (state handled in PostRefresh).
EnsureInjectedSelfBuff({
    spellID = 0,
    key = "jg_repair",
    name = "Repair",
    displayIcon = 136241,
    missingText = "REPAIR",
    infoTooltip = "JG|Shows when your equipped durability drops below threshold.",
})

-- Eating timer anchor (state handled in PostRefresh).
EnsureInjectedSelfBuff({
    spellID = 0,
    key = "jg_eating_timer",
    name = "Eating Timer",
    displayIcon = 133950,
    missingText = "EATING",
    infoTooltip = "JG|Shows an active countdown while eating.",
})
