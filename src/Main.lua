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

	-- DIRECT REGISTRATION APPROACH
	-- This ensures the addon appears in Options > Addons regardless of PeaversCommons logic
	C_Timer.After(0.5, function()
		-- Create the main panel (Support UI as landing page)
		local mainPanel = CreateFrame("Frame")
		mainPanel.name = "PeaversRemembersYou"

		-- Required callbacks
		mainPanel.OnRefresh = function() end
		mainPanel.OnCommit = function() end
		mainPanel.OnDefault = function() end

		-- Get addon version
		local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

		-- Add background image
		local ICON_ALPHA = 0.1
		local iconPath = "Interface\\AddOns\\PeaversCommons\\src\\Media\\Icon"
		local largeIcon = mainPanel:CreateTexture(nil, "BACKGROUND")
		largeIcon:SetTexture(iconPath)
		largeIcon:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 0, 0)
		largeIcon:SetPoint("BOTTOMRIGHT", mainPanel, "BOTTOMRIGHT", 0, 0)
		largeIcon:SetAlpha(ICON_ALPHA)

		-- Create header and description
		local titleText = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		titleText:SetPoint("TOPLEFT", 16, -16)
		titleText:SetText("Peavers Remembers You")
		titleText:SetTextColor(1, 0.84, 0)  -- Gold color for title

		-- Version information
		local versionText = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		versionText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -8)
		versionText:SetText("Version: " .. version)

		-- Support information
		local supportInfo = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		supportInfo:SetPoint("TOPLEFT", 16, -70)
		supportInfo:SetPoint("TOPRIGHT", -16, -70)
		supportInfo:SetJustifyH("LEFT")
		supportInfo:SetText("Records players you group with and notifies you when you meet them again. If you enjoy this addon and would like to support its development, or if you need help, stop by the website.")
		supportInfo:SetSpacing(2)

		-- Website URL
		local websiteLabel = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		websiteLabel:SetPoint("TOPLEFT", 16, -120)
		websiteLabel:SetText("Website:")

		local websiteURL = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		websiteURL:SetPoint("TOPLEFT", websiteLabel, "TOPLEFT", 70, 0)
		websiteURL:SetText("https://peavers.io")
		websiteURL:SetTextColor(0.3, 0.6, 1.0)

		-- Additional info
		local additionalInfo = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		additionalInfo:SetPoint("BOTTOMRIGHT", -16, 16)
		additionalInfo:SetJustifyH("RIGHT")
		additionalInfo:SetText("Thank you for using Peavers Addons!")

		-- Now create/prepare the settings panel
		local settingsPanel

		if PRY.ConfigUI and PRY.ConfigUI.panel then
			-- Use existing ConfigUI panel
			settingsPanel = PRY.ConfigUI.panel
		else
			-- Create a simple settings panel with commands
			settingsPanel = CreateFrame("Frame")
			settingsPanel.name = "Settings"

			-- Required callbacks
			settingsPanel.OnRefresh = function() end
			settingsPanel.OnCommit = function() end
			settingsPanel.OnDefault = function() end

			-- Add content
			local settingsTitle = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			settingsTitle:SetPoint("TOPLEFT", 16, -16)
			settingsTitle:SetText("Settings")

			local commandsTitle = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			commandsTitle:SetPoint("TOPLEFT", settingsTitle, "BOTTOMLEFT", 0, -16)
			commandsTitle:SetText("Available Commands:")

			local commandsList = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
			commandsList:SetPoint("TOPLEFT", commandsTitle, "BOTTOMLEFT", 10, -8)
			commandsList:SetJustifyH("LEFT")
			commandsList:SetText(
				"/pry - Open settings\n" ..
				"/pry reset - Reset player database\n" ..
				"/pry help - Show available commands"
			)
		end

		-- Register with the Settings API
		if Settings then
			-- Register main category
			local category = Settings.RegisterCanvasLayoutCategory(mainPanel, mainPanel.name)

			-- This is the CRITICAL line to make it appear in Options > Addons
			Settings.RegisterAddOnCategory(category)

			-- Store the category
			PRY.directCategory = category
			PRY.directPanel = mainPanel

			-- Register settings panel as subcategory
			local settingsCategory = Settings.RegisterCanvasLayoutSubcategory(category, settingsPanel, settingsPanel.name)
			PRY.directSettingsCategory = settingsCategory

			Utils.Debug(PRY, "Direct registration complete")
		end
	end)

end, {
	announceMessage = "Use |cff3abdf7/pry config|r to get started"
})
