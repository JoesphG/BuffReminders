local _, BR = ...

if not BR or not BR.SecureButtons or not BR.Display then
    return
end

BR.CRBParity = BR.CRBParity or {}

if BR.CRBParity._clickWrapped then
    return
end
BR.CRBParity._clickWrapped = true

local function ApplyParityItemActions(category)
    if category ~= "self" then
        return
    end
    if InCombatLockdown() then
        return
    end
    if BR.Display.IsTestMode and BR.Display.IsTestMode() then
        return
    end

    local db = BuffRemindersDB or {}
    local cs = db.categorySettings and db.categorySettings.self
    if not (cs and cs.clickable == true) then
        return
    end

    local actions = BR.CRBParity.ITEM_ACTIONS or {}
    for _, frame in pairs(BR.Display.frames or {}) do
        if frame and frame.buffCategory == "self" and frame.clickOverlay and frame.key then
            local itemID = actions[frame.key]
            if itemID and frame:IsShown() then
                frame.clickOverlay:SetAttribute("type", "item")
                frame.clickOverlay:SetAttribute("item", "item:" .. tostring(itemID))
                frame.clickOverlay:SetAttribute("spell", nil)
                frame.clickOverlay:SetAttribute("macrotext", nil)
                frame.clickOverlay:EnableMouse(true)
            end
        end
    end
end

local origUpdateActionButtons = BR.SecureButtons.UpdateActionButtons
BR.SecureButtons.UpdateActionButtons = function(category)
    local r = origUpdateActionButtons(category)
    ApplyParityItemActions(category)
    return r
end

local origRefreshOverlaySpells = BR.SecureButtons.RefreshOverlaySpells
BR.SecureButtons.RefreshOverlaySpells = function(...)
    local r = origRefreshOverlaySpells(...)
    ApplyParityItemActions("self")
    return r
end
