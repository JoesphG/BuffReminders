local _, BR = ...

BR.JG = BR.JG or {}
BR.JG.ITEM_ACTIONS = BR.JG.ITEM_ACTIONS or {}

BR.JG.TRINKETS = {
    {
        key = "jg_trinket_190958",
        itemID = 190958, -- So'Leah's Secret Technique
        buffIDs = { 368512 },
        targetBuffID = 386510,
        check = "player",
        hideWhenPlayerHasBuff = true,
        requiredCount = 1,
        expiringThresholdMin = 15,
        gates = { "group", "rested" },
        mineOnly = true,
        fallbackIcon = 134400,
        name = "So'Leah",
    },
    {
        key = "jg_trinket_178742",
        itemID = 178742, -- Bottled Flayedwing Toxin
        buffIDs = { 345546 },
        check = "player",
        expiringThresholdMin = 15,
        gates = { "group", "rested" },
        mineOnly = true,
        fallbackIcon = 134400,
        name = "Bottled Toxin",
    },
}

local function GetItemIconSafe(itemID, fallback)
    local icon = nil
    if C_Item and C_Item.GetItemIconByID then
        icon = C_Item.GetItemIconByID(itemID)
    end
    if not icon then
        icon = select(5, GetItemInfoInstant(itemID))
    end
    return icon or fallback or 134400
end

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
    iconOverride = 136194,
    missingText = "SOUL\nWELL",
    infoTooltip = "JG|Shows when Soulwell is available and your healthstones are low.",
})

-- Durability/repair reminder anchor (state handled in PostRefresh).
EnsureInjectedSelfBuff({
    spellID = 0,
    key = "jg_repair",
    name = "Repair",
    iconOverride = 136241,
    missingText = "REPAIR",
    infoTooltip = "JG|Shows when your equipped durability drops below threshold.",
})

-- Eating timer anchor (state handled in PostRefresh).
EnsureInjectedSelfBuff({
    spellID = 0,
    key = "jg_eating_timer",
    name = "Eating Timer",
    iconOverride = 133950,
    missingText = "EATING",
    infoTooltip = "JG|Shows an active countdown while eating.",
})

for _, row in ipairs(BR.JG.TRINKETS) do
    BR.JG.ITEM_ACTIONS[row.key] = row.itemID
    EnsureInjectedSelfBuff({
        spellID = 0,
        key = row.key,
        name = row.name,
        iconOverride = GetItemIconSafe(row.itemID, row.fallbackIcon),
        missingText = "TRINKET",
        infoTooltip = "JG|Tracks equipped trinket buff coverage.",
    })
end
