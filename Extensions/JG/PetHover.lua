local _, BR = ...

if not BR or not BR.Display or not BR.BuffState then
    return
end

BR.JG = BR.JG or {}

if BR.JG._petHoverWrapped then
    return
end
BR.JG._petHoverWrapped = true

local CALL_PET_SLOT_BY_SPELL = {
    [883] = 1,
    [83242] = 2,
    [83243] = 3,
    [83244] = 4,
    [83245] = 5,
}

local function AbilityIconForSpec(specID)
    if specID == 79 then
        return 348567 -- Cunning
    end
    if specID == 74 then
        return 136224 -- Ferocity
    end
    if specID == 81 then
        return 571585 -- Tenacity
    end
    return nil
end

local function FirstNonEmptyString(info, keys)
    if not info then
        return nil
    end
    for _, key in ipairs(keys) do
        local v = info[key]
        if type(v) == "string" and v ~= "" then
            return v
        end
    end
    return nil
end

local function GetStableSpecID(info)
    if not info then
        return nil
    end
    return info.specID or info.specialization or info.petSpecID
end

local function GetHunterHoverMeta(spellID)
    local slot = spellID and CALL_PET_SLOT_BY_SPELL[spellID]
    if not slot or not C_StableInfo or not C_StableInfo.GetStablePetInfo then
        return nil, nil
    end
    local info = C_StableInfo.GetStablePetInfo(slot)
    if not info then
        return nil, nil
    end
    local family = FirstNonEmptyString(info, {
        "familyName",
        "family",
        "petFamilyName",
        "creatureFamily",
        "speciesName",
        "petTypeName",
    })
    local hoverIcon = AbilityIconForSpec(GetStableSpecID(info))
    return hoverIcon, family
end

local function EnsureHoverScripts(frame)
    if not frame or frame._jg_pet_hover_init then
        return
    end
    frame._jg_pet_hover_init = true

    frame:HookScript("OnEnter", function(self)
        if not self._jg_pet_spell_id then
            return
        end

        -- Stable info can populate late; refresh hunter family/icon on hover.
        if self._jg_pet_is_hunter and (not self._jg_pet_family or self._jg_pet_family == "") then
            local hoverIcon, family = GetHunterHoverMeta(self._jg_pet_spell_id)
            if hoverIcon then
                self._jg_pet_hover_icon = hoverIcon
            end
            if family and family ~= "" then
                self._jg_pet_family = family
            end
        end

        if self._jg_pet_hover_icon and self.icon and self.icon.GetTexture then
            self._jg_pet_icon_restore = self.icon:GetTexture()
            self.icon:SetTexture(self._jg_pet_hover_icon)
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if GameTooltip.SetSpellByID then
            GameTooltip:SetSpellByID(self._jg_pet_spell_id)
        else
            GameTooltip:SetText(self._jg_pet_label or self.displayName or "Pet", 1, 1, 1)
        end
        if self._jg_pet_family and self._jg_pet_family ~= "" then
            GameTooltip:AddLine(self._jg_pet_family, 0.7, 0.7, 0.7, true)
        end
        GameTooltip:Show()
    end)

    frame:HookScript("OnLeave", function(self)
        if GameTooltip and GameTooltip:IsOwned(self) then
            GameTooltip:Hide()
        end
        if self.icon and self._jg_pet_icon_restore then
            self.icon:SetTexture(self._jg_pet_icon_restore)
            self._jg_pet_icon_restore = nil
        end
    end)
end

local function ClearHover(frame)
    if not frame then
        return
    end
    frame._jg_pet_spell_id = nil
    frame._jg_pet_label = nil
    frame._jg_pet_family = nil
    frame._jg_pet_hover_icon = nil
    frame._jg_pet_is_hunter = nil
    frame:EnableMouse(false)
    if GameTooltip and GameTooltip:IsOwned(frame) then
        GameTooltip:Hide()
    end
end

local function ApplyHover(frame, action, class)
    if not frame or not action or not action.spellID then
        ClearHover(frame)
        return
    end

    EnsureHoverScripts(frame)
    frame._jg_pet_spell_id = action.spellID
    frame._jg_pet_label = action.label

    if class == "HUNTER" then
        frame._jg_pet_is_hunter = true
        frame._jg_pet_hover_icon, frame._jg_pet_family = GetHunterHoverMeta(action.spellID)
    else
        frame._jg_pet_is_hunter = nil
        frame._jg_pet_hover_icon = nil
        frame._jg_pet_family = nil
    end

    frame:EnableMouse(true)
end

local function RefreshPetHover()
    local visible = BR.BuffState.visibleByCategory and BR.BuffState.visibleByCategory.pet
    local frames = BR.Display.frames
    if type(frames) ~= "table" then
        return
    end

    local class = select(2, UnitClass("player"))
    local mode = (BuffRemindersDB and BuffRemindersDB.defaults and BuffRemindersDB.defaults.petDisplayMode) or "generic"
    local byKey = {}

    if type(visible) == "table" then
        for _, entry in ipairs(visible) do
            if entry and entry.key then
                byKey[entry.key] = entry
            end
        end
    end

    for key, frame in pairs(frames) do
        if frame and frame.buffCategory == "pet" then
            local entry = byKey[key]
            if not (entry and frame:IsShown() and entry.petActions and #entry.petActions > 0) then
                ClearHover(frame)
                if frame.extraFrames then
                    for _, extra in ipairs(frame.extraFrames) do
                        ClearHover(extra)
                    end
                end
            else
                if mode == "expanded" then
                    ApplyHover(frame, entry.petActions[1], class)
                    if frame.extraFrames then
                        for i, extra in ipairs(frame.extraFrames) do
                            if extra and extra:IsShown() then
                                ApplyHover(extra, entry.petActions[i + 1], class)
                            else
                                ClearHover(extra)
                            end
                        end
                    end
                else
                    local idx = entry.petActions.genericIndex or 1
                    ApplyHover(frame, entry.petActions[idx], class)
                    if frame.extraFrames then
                        for _, extra in ipairs(frame.extraFrames) do
                            ClearHover(extra)
                        end
                    end
                end
            end
        end
    end
end

local origUpdate = BR.Display.Update
BR.Display.Update = function(...)
    local r = origUpdate(...)
    RefreshPetHover()
    return r
end
