local _, BR = ...

-- PET ACTIONS (ClickableRaidBuffs-inspired)

local HUNTER_CALL_PET_SPELLS = { 883, 83242, 83243, 83244, 83245 }
local HUNTER_REVIVE_PET_SPELL = 982
local HUNTER_DISABLE_PETS_SPELL = 1223323 -- Unbreakable Bond (MM pet enable)
local WARLOCK_SUMMON_SPELLS = { 688, 697, 691, 366222, 30146 }
local WARLOCK_SACRIFICE_SPELL = 108503
local WARLOCK_SACRIFICE_BUFF = 196099

local function KnowSpell(id)
    if not id then
        return false
    end
    if IsPlayerSpell then
        return IsPlayerSpell(id)
    end
    if IsSpellKnown then
        return IsSpellKnown(id)
    end
    return false
end

local function HasUsablePet()
    if not UnitExists("pet") then
        return false
    end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("pet") then
        return false
    end
    if not UnitIsVisible("pet") then
        return false
    end
    return true
end

local function HasSacrificeBuff()
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        return C_UnitAuras.GetPlayerAuraBySpellID(WARLOCK_SACRIFICE_BUFF) ~= nil
    end
    local i = 1
    while true do
        local a = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not a then
            break
        end
        if a.spellId == WARLOCK_SACRIFICE_BUFF then
            return true
        end
        i = i + 1
    end
    return false
end

local function IsMMWithoutUnbreakableBond()
    if not GetSpecialization or not GetSpecializationInfo then
        return false
    end
    local specIndex = GetSpecialization()
    if not specIndex then
        return false
    end
    local specID = GetSpecializationInfo(specIndex)
    if specID ~= 254 then
        return false
    end
    return not KnowSpell(HUNTER_DISABLE_PETS_SPELL)
end

local function HunterSlotHasPet(slotIndex)
    if not slotIndex then
        return false
    end
    local info = C_StableInfo and C_StableInfo.GetStablePetInfo and C_StableInfo.GetStablePetInfo(slotIndex)
    if not info then
        return false
    end
    if info.isEmpty == true then
        return false
    end
    local name = info.name or info.petName or info.customName
    local cid = info.creatureID or info.displayID or info.speciesID
    return (name and name ~= "") or (cid and cid ~= 0)
end

local function HunterSpecAtlas(specID)
    if specID == 79 then
        return "cunning-icon-small"
    end
    if specID == 74 then
        return "ferocity-icon-small"
    end
    if specID == 81 then
        return "tenacity-icon-small"
    end
    return nil
end

local function HunterAbilityIconForSpec(specID)
    if specID == 79 then
        return 348567
    end
    if specID == 74 then
        return 136224
    end
    if specID == 81 then
        return 571585
    end
    return nil
end

local function HunterSpecName(specID)
    if specID == 79 then
        return "Cunning"
    end
    if specID == 74 then
        return "Ferocity"
    end
    if specID == 81 then
        return "Tenacity"
    end
    return nil
end

local function GetSpellIcon(spellID)
    local texture = GetSpellTexture and GetSpellTexture(spellID)
    if not texture and C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            texture = info.iconID or info.icon
        end
    end
    return texture
end

local PetHelpers = {
    actionDefs = {},
}

local function RegisterAction(action)
    if action and action.key then
        PetHelpers.actionDefs[action.key] = action
    end
end

local function ActionKey(prefix, id)
    return prefix .. "_" .. tostring(id)
end

function PetHelpers.GetActionDef(key)
    return PetHelpers.actionDefs[key]
end

function PetHelpers.BuildPetActions()
    if IsMounted() then
        return nil
    end
    if HasUsablePet() then
        return nil
    end

    local actions = {}
    local _, class = UnitClass("player")

    if class == "HUNTER" then
        if IsMMWithoutUnbreakableBond() then
            return nil
        end
        for slotIndex, spellID in ipairs(HUNTER_CALL_PET_SPELLS) do
            if HunterSlotHasPet(slotIndex) and KnowSpell(spellID) then
                local info = C_StableInfo and C_StableInfo.GetStablePetInfo and C_StableInfo.GetStablePetInfo(slotIndex)
                local name = info and (info.name or info.petName or info.customName) or ("Pet " .. tostring(slotIndex))
                local icon = (info and (info.icon or info.iconFileID)) or GetSpellIcon(spellID) or 132161
                local familyName = info and (info.familyName or info.family)
                local familyIcon = info and (info.familyIcon or info.icon or info.iconFileID)
                local specID = info and info.specID
                local specAtlas = specID and HunterSpecAtlas(specID) or nil
                local hoverIcon = specID and HunterAbilityIconForSpec(specID) or nil
                if not familyName then
                    familyName = specID and HunterSpecName(specID) or nil
                end
                if not familyIcon and hoverIcon then
                    familyIcon = hoverIcon
                end
                local key = ActionKey("pet_hunter", spellID)
                local action = {
                    key = key,
                    spellID = spellID,
                    icon = icon,
                    label = name,
                    subLabel = "Pet " .. tostring(slotIndex),
                    familyName = familyName,
                    familyIcon = familyIcon,
                    specAtlas = specAtlas,
                    hoverIcon = hoverIcon,
                    sortOrder = slotIndex,
                    groupId = "pets",
                }
                RegisterAction(action)
                actions[#actions + 1] = action
            end
        end
        if KnowSpell(HUNTER_REVIVE_PET_SPELL) then
            local key = ActionKey("pet_revive", HUNTER_REVIVE_PET_SPELL)
            local action = {
                key = key,
                spellID = HUNTER_REVIVE_PET_SPELL,
                icon = GetSpellIcon(HUNTER_REVIVE_PET_SPELL),
                label = "Revive Pet",
                subLabel = "",
                sortOrder = 99,
                groupId = "pets",
            }
            RegisterAction(action)
            actions[#actions + 1] = action
        end
    elseif class == "WARLOCK" then
        if KnowSpell(WARLOCK_SACRIFICE_SPELL) and HasSacrificeBuff() then
            return nil
        end
        for _, spellID in ipairs(WARLOCK_SUMMON_SPELLS) do
            if KnowSpell(spellID) then
                local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID) or nil
                local name = info and info.name or nil
                local icon = GetSpellIcon(spellID)
                local key = ActionKey("pet_warlock", spellID)
                local action = {
                    key = key,
                    spellID = spellID,
                    icon = icon,
                    label = name,
                    subLabel = "",
                    familyName = name,
                    familyIcon = icon,
                    sortOrder = spellID,
                    groupId = "pets",
                }
                RegisterAction(action)
                actions[#actions + 1] = action
            end
        end
    elseif class == "DEATHKNIGHT" then
        if KnowSpell(46584) then
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(46584) or nil
            local name = info and info.name or "Raise Dead"
            local icon = GetSpellIcon(46584)
            local key = ActionKey("pet_dk", 46584)
            local action = {
                key = key,
                spellID = 46584,
                icon = icon,
                label = name,
                subLabel = "",
                familyName = "Ghoul",
                familyIcon = icon,
                sortOrder = 10,
                groupId = "pets",
            }
            RegisterAction(action)
            actions[#actions + 1] = action
        end
    elseif class == "MAGE" then
        if KnowSpell(31687) then
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(31687) or nil
            local name = info and info.name or "Water Elemental"
            local icon = GetSpellIcon(31687)
            local key = ActionKey("pet_mage", 31687)
            local action = {
                key = key,
                spellID = 31687,
                icon = icon,
                label = name,
                subLabel = "",
                familyName = "Elemental",
                familyIcon = icon,
                sortOrder = 10,
                groupId = "pets",
            }
            RegisterAction(action)
            actions[#actions + 1] = action
        end
    end

    if #actions == 0 then
        return nil
    end

    table.sort(actions, function(a, b)
        return (a.sortOrder or 0) < (b.sortOrder or 0)
    end)

    return actions
end

BR.PetHelpers = PetHelpers
