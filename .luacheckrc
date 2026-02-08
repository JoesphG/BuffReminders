---@diagnostic disable: lowercase-global
std = "lua51"
max_line_length = false
codes = true
exclude_files = { "Libs/" }

ignore = {
	"21./_",
	"212/self",
	"212/profileKey",
	"311/currentValue", -- Closure state in dropdown components
}

globals = {
	"_",
	"BuffRemindersV2",
	"BuffRemindersV2DB",
	"SLASH_BUFFREMINDERSV2_1",
	"SLASH_BUFFREMINDERSV2_2",
	"SlashCmdList",
	"StaticPopupDialogs",
}

read_globals = {
	-- WoW API
	"C_ActionBar",
	"C_AddOns",
	"C_ChallengeMode",
	"C_Housing",
	"C_EncodingUtil",
	"C_Container",
	"C_Item",
	"C_Spell",
	"C_SpellActivationOverlay",
	"C_Timer",
	"C_UnitAuras",
	"CreateFrame",
	"GetActionInfo",
	"GetPetActionInfo",
	"GetCursorPosition",
	"GetCVarBool",
	"GetItemIcon",
	"GetItemCount",
	"GetItemSpell",
	"GetNumGroupMembers",
	"GetSpellTexture",
	"GetSpecialization",
	"GetSpecializationInfo",
	"GetSpecializationInfoForClassID",
	"GetSpecializationRole",
	"GetTime",
	"GetWeaponEnchantInfo",
	"InCombatLockdown",
	"IsInInstance",
	"IsInRaid",
	"IsMounted",
	"IsMouseButtonDown",
	"IsShiftKeyDown",
	"ReloadUI",
	"Settings",
	"SettingsPanel",
	"StaticPopup_Show",
	"time",
	"UIParent",
	"IsPlayerSpell",
	"NUM_PET_ACTION_SLOTS",
	"NUM_BAG_SLOTS",
	"UnitCanAssist",
	"UnitClass",
	"UnitExists",
	"UnitGroupRolesAssigned",
	"UnitIsConnected",
	"UnitIsDeadOrGhost",
	"UnitIsPlayer",
	"UnitIsUnit",
	"UnitIsVisible",
	"UnitLevel",

	"tinsert",

	-- WoW Mixins
	"Mixin",
	"CreateFromMixins",
	"CallbackRegistryMixin",

	-- WoW UI globals
	"ColorPickerFrame",
	"DynamicResizeButton_Resize",
	"GameTooltip",
	"HideUIPanel",
	"STANDARD_TEXT_FONT",
	"UISpecialFrames",

	-- Libraries
	"LibStub",
}
