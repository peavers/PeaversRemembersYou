local addonName, PRY = ...

-- Access the PeaversCommons library
local PeaversCommons = _G.PeaversCommons
local Utils = PeaversCommons.Utils

-- Initialize addon namespace and modules
PRY = PRY or {}

-- Module namespaces
PRY.Utils = {}

-- Version information
PRY.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"
PRY.addonName = addonName
PRY.name = addonName

-- Register slash commands
PeaversCommons.SlashCommands:Register(addonName, "pry", {
	default = function()
		Settings.OpenToCategory("PeaversRemembersYou")
	end,
	reset = function()
		StaticPopup_Show("PRY_CONFIRM_RESET")
	end,
	help = function()
		Utils.Print(PRY, "Commands:")
		print("  /pry - Open settings")
		print("  /pry reset - Reset player database")
	end
})

-- Initialize addon using the PeaversCommons Events module
PeaversCommons.Events:Init(addonName, function()
	-- Initialize configuration
	PRY.Config:Initialize()

	-- Initialize core functionality
	PRY:Initialize()

	-- Initialize configuration UI
	if PRY.ConfigUI and PRY.ConfigUI.Initialize then
		PRY.ConfigUI:Initialize()
	end

	-- Initialize support UI
	if PRY.SupportUI and PRY.SupportUI.Initialize then
		PRY.SupportUI:Initialize()
	end

end, {
	announceMessage = "Type /pry config for options."
})
