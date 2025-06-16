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
	-- Configuration initialization is handled by ConfigManager
	-- However we need to call Initialize to ensure player data is set up
	PRY.Config:Initialize()

	-- Initialize core functionality
	PRY:Initialize()

	-- Initialize configuration UI
	if PRY.ConfigUI and PRY.ConfigUI.Initialize then
		PRY.ConfigUI:Initialize()
	end
	
	-- Initialize patrons support
	if PRY.Patrons and PRY.Patrons.Initialize then
		PRY.Patrons:Initialize()
	end

	-- Use the centralized SettingsUI system from PeaversCommons
	C_Timer.After(0.5, function()
		-- Create standardized settings pages
		PeaversCommons.SettingsUI:CreateSettingsPages(
			PRY,                       -- Addon reference
			"PeaversRemembersYou",     -- Addon name
			"Peavers Remembers You",   -- Display title
			"Records players you group with and notifies you when you meet them again.",  -- Description
			{   -- Slash commands
				"/pry - Open settings",
				"/pry reset - Reset player database",
				"/pry help - Show available commands"
			}
		)
	end)

end, {
	suppressAnnouncement = true
})
