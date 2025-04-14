local _, PRY = ...

local ADDON_NAME = "PeaversRemembersYou"
local ADDON_ID = "PeaversRemembersYou"
local ICON_PATH = "Interface\\Icons\\INV_Misc_Note_01"

-- Initialize SupportUI namespace
local SupportUI = {}
PRY.Utils.SupportUI = SupportUI

-- Constants
local ICON_ALPHA = 0.1

-- Creates and initializes the support options panel
function SupportUI:InitializeOptions()
	local panel = CreateFrame("Frame")
	panel.name = "Support"

	-- Add background image
	local largeIcon = panel:CreateTexture(nil, "BACKGROUND")
	largeIcon:SetTexture(ICON_PATH)
	largeIcon:SetPoint("CENTER", panel, "CENTER", 0, 0)
	largeIcon:SetSize(256, 256)
	largeIcon:SetAlpha(ICON_ALPHA)

	-- Create header and description
	local titleText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	titleText:SetPoint("TOPLEFT", 16, -16)
	titleText:SetText("Support " .. ADDON_NAME)

	-- Set addon version
	local version = PRY.version or "1.0.0"
	local versionText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	versionText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -8)
	versionText:SetText("Version: " .. version)

	-- Support information
	local supportInfo = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	supportInfo:SetPoint("TOPLEFT", 16, -70)
	supportInfo:SetPoint("TOPRIGHT", -16, -70)
	supportInfo:SetJustifyH("LEFT")
	supportInfo:SetText("If you enjoy " .. ADDON_NAME .. " and would like to support its development, or if you need help or want to request new features, stop by the website.")
	supportInfo:SetSpacing(2)

	-- Website URL as text
	local websiteLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	websiteLabel:SetPoint("TOPLEFT", 16, -120)
	websiteLabel:SetText("Website:")

	local websiteURL = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	websiteURL:SetPoint("TOPLEFT", websiteLabel, "TOPLEFT", 70, 0)
	websiteURL:SetText("https://peavers.io")
	websiteURL:SetTextColor(0.3, 0.6, 1.0)

	-- Additional info at bottom
	local additionalInfo = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	additionalInfo:SetPoint("BOTTOMRIGHT", -16, 16)
	additionalInfo:SetJustifyH("RIGHT")
	additionalInfo:SetText("Thank you for using Peavers Addons!")

	-- Required callbacks
	panel.OnRefresh = function() end
	panel.OnCommit = function() end
	panel.OnDefault = function() end

	return panel
end

-- Initialize and register the support panel
function SupportUI:Initialize()
	-- Only initialize if the main category exists
	if not PRY.mainCategory then
		print("|cff33ff99PeaversRemembersYou|r: Error initializing support UI - main category not found")
		return
	end

	local panel = self:InitializeOptions()

	-- Register as subcategory of the main category
	PRY.supportCategory = Settings.RegisterCanvasLayoutSubcategory(PRY.mainCategory, panel, panel.name)
	PRY.supportCategory.ID = panel.name
end
