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
	"BuffReminders",
	"BuffRemindersV2",
	"BuffRemindersDB",
	"BuffRemindersV2DB",
	"SLASH_BUFFREMINDERS1",
	"SLASH_BUFFREMINDERS2",
	"SLASH_BUFFREMINDERS3",
	"SLASH_BUFFREMINDERS4",
	"SlashCmdList",
	"StaticPopupDialogs",
}

read_globals = {
	-- WoW API
	"C_ActionBar",
	"C_AddOns",
	"C_Container",
	"C_ChallengeMode",
	"C_Housing",
	"C_EncodingUtil",
	"C_Item",
	"C_Spell",
	"C_SpellBook",
	"C_StableInfo",
	"C_SpellActivationOverlay",
	"C_Timer",
	"C_UnitAuras",
	"CreateFrame",
	"GetActionInfo",
	"GetInstanceInfo",
	"GetPetActionInfo",
	"GetCursorPosition",
	"GetNumGroupMembers",
	"GetSpecialization",
	"GetSpecializationInfo",
	"GetSpecializationInfoForClassID",
	"GetSpecializationRole",
	"GetSpellTexture",
	"GetTime",
	"GetWeaponEnchantInfo",
	"InCombatLockdown",
	"IsInInstance",
	"IsInRaid",
	"IsMounted",
	"IsResting",
	"IsMouseButtonDown",
	"IsShiftKeyDown",
	"IsSpellKnownOrOverridesKnown",
	"IsSpellKnown",
	"NUM_BAG_SLOTS",
	"REAGENTBAG_CONTAINER",
	"ReloadUI",
	"Settings",
	"SettingsPanel",
	"StaticPopup_Show",
	"time",
	"UIParent",
	"IsPlayerSpell",
	"IsResting",
	"NUM_PET_ACTION_SLOTS",
	"UnitAffectingCombat",
	"UnitCanAssist",
	"UnitClass",
	"UnitExists",
	"UnitGroupRolesAssigned",
	"UnitIsConnected",
	"UnitIsDeadOrGhost",
	"UnitIsPlayer",
	"UnitGUID",
	"UnitIsUnit",
	"UnitIsVisible",
	"UnitLevel",
	"UnitInRange",

	"strsplit",
	"strtrim",
	"tinsert",
	"wipe",

	-- WoW Mixins
	"Mixin",
	"CreateFromMixins",
	"CallbackRegistryMixin",

	-- WoW UI globals
	"ColorPickerFrame",
	"DynamicResizeButton_Resize",
	"GameTooltip",
	"GameTooltip_Hide",
	"HideUIPanel",
	"C_PetJournal",
	"RegisterStateDriver",
	"STANDARD_TEXT_FONT",
	"UISpecialFrames",
	"UnregisterStateDriver",

	-- Libraries
	"LibStub",
}
