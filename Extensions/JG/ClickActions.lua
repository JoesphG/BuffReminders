local _, BR = ...

if not BR or not BR.SecureButtons or not BR.Display then
    return
end

BR.JG = BR.JG or {}

if BR.JG._clickWrapped then
    return
end
BR.JG._clickWrapped = true

local function EnsureSelfClickableCategory()
    BuffRemindersDB = BuffRemindersDB or {}
    BuffRemindersDB.categorySettings = BuffRemindersDB.categorySettings or {}
    BuffRemindersDB.categorySettings.self = BuffRemindersDB.categorySettings.self or {}
    local cs = BuffRemindersDB.categorySettings.self
    if cs.clickable ~= true then
        cs.clickable = true
    end
end

local function EnsureClickOverlay(frame)
    if frame.clickOverlay then
        return frame.clickOverlay
    end

    local overlay = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    overlay:RegisterForClicks("AnyDown", "AnyUp")
    overlay:EnableMouse(false)
    overlay:Hide()
    RegisterStateDriver(overlay, "visibility", "[combat] hide; show")
    overlay:SetScript("OnShow", function(self)
        if not frame:IsVisible() then
            self:Hide()
        end
    end)
    overlay:SetScript("PostClick", function()
        C_Timer.After(0.3, function()
            if not InCombatLockdown() and BR.Display and BR.Display.Update then
                BR.Display.Update()
            end
        end)
    end)
    overlay.highlight = overlay:CreateTexture(nil, "HIGHLIGHT")
    overlay.highlight:SetAllPoints()
    overlay.highlight:SetTexCoord(BR.TEXCOORD_INSET, 1 - BR.TEXCOORD_INSET, BR.TEXCOORD_INSET, 1 - BR.TEXCOORD_INSET)
    overlay.highlight:SetColorTexture(1, 1, 1, 0.2)
    frame.clickOverlay = overlay
    return overlay
end

local function GetRepairMacroText()
    local db = BuffRemindersDB and BuffRemindersDB.jgParity
    if not db or db.enableRepairMacro ~= true then
        return nil
    end
    local text = db.repairClickMacro
    if type(text) ~= "string" or text == "" then
        return nil
    end
    return text
end

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

    EnsureSelfClickableCategory()

    local repairMacro = GetRepairMacroText()

    for _, frame in pairs(BR.Display.frames or {}) do
        if frame and frame.buffCategory == "self" and frame.key == "jg_repair" and frame:IsShown() then
            local overlay = EnsureClickOverlay(frame)
            if repairMacro then
                overlay:SetAttribute("type", "macro")
                overlay:SetAttribute("macrotext", repairMacro)
                overlay:SetAttribute("spell", nil)
                overlay:SetAttribute("item", nil)
                overlay.itemID = nil
                overlay._br_has_action = true
                overlay:EnableMouse(true)
            elseif frame.clickOverlay then
                frame.clickOverlay._br_has_action = false
                frame.clickOverlay:EnableMouse(false)
                frame.clickOverlay:Hide()
                frame.clickOverlay._br_left = nil
            end
        end
    end

    if BR.SecureButtons and BR.SecureButtons.ScheduleSecureSync then
        BR.SecureButtons.ScheduleSecureSync()
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

-- Core refresh paths can rebuild overlays and clear non-spell actions.
-- Re-apply parity actions after each display update to keep trinket icons clickable.
if not BR.JG._displayUpdateWrapped and BR.Display and BR.Display.Update then
    BR.JG._displayUpdateWrapped = true
    local origDisplayUpdate = BR.Display.Update
    BR.Display.Update = function(...)
        local r = origDisplayUpdate(...)
        if not InCombatLockdown() then
            ApplyParityItemActions("self")
        end
        return r
    end
end

-- Re-apply on state changes that often rebuild secure overlays.
if not BR.JG._clickEventFrame then
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" or not InCombatLockdown() then
            ApplyParityItemActions("self")
        end
    end)
    BR.JG._clickEventFrame = f
end
