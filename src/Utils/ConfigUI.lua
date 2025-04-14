local _, PRY = ...
local ConfigUI = {}

-- Initialize ConfigUI namespace
PRY.Utils.ConfigUI = ConfigUI

-- Helper functions for UI creation
local function CreateSeparator(parent, xOffset, yPos, width)
	local separator = parent:CreateTexture(nil, "ARTWORK")
	separator:SetHeight(1)
	separator:SetPoint("TOPLEFT", xOffset, yPos)
	if width then
		separator:SetWidth(width)
	else
		separator:SetPoint("TOPRIGHT", -xOffset, yPos)
	end
	separator:SetColorTexture(0.3, 0.3, 0.3, 0.9)
	return separator, yPos - 15
end

local function CreateSectionHeader(parent, text, xOffset, yPos)
	local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	header:SetPoint("TOPLEFT", xOffset, yPos)
	header:SetText(text)
	header:SetTextColor(1, 0.82, 0)
	return header, yPos - 20
end

local function CreateLabel(parent, text, xOffset, yPos, fontStyle)
	local label = parent:CreateFontString(nil, "ARTWORK", fontStyle or "GameFontNormal")
	label:SetPoint("TOPLEFT", xOffset, yPos)
	label:SetText(text)
	return label, yPos - 15
end

local function CreateCheckbox(parent, name, text, xOffset, yPos, checked, color, onClick)
	local checkbox = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
	checkbox:SetPoint("TOPLEFT", xOffset, yPos)

	-- Set the text
	local checkboxText = _G[checkbox:GetName() .. "Text"]
	if checkboxText then
		checkboxText:SetText(text)
		if color then
			checkboxText:SetTextColor(color[1], color[2], color[3])
		end
	end

	-- Set the initial state
	checkbox:SetChecked(checked)

	-- Set the click handler
	checkbox:SetScript("OnClick", onClick)

	return checkbox, yPos - 25
end

local function CreateSlider(parent, name, label, min, max, step, defaultVal, xOffset, yPos, width, callback)
	local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", xOffset, yPos)
	slider:SetWidth(width or 400)
	slider:SetHeight(16)
	slider:SetMinMaxValues(min, max)
	slider:SetValueStep(step)
	slider:SetValue(defaultVal)

	-- Set up slider labels
	local sliderName = slider:GetName()
	_G[sliderName.."Low"]:SetText(min)
	_G[sliderName.."High"]:SetText(max)
	_G[sliderName.."Text"]:SetText(label .. ": " .. defaultVal)

	-- Set the change handler
	slider:SetScript("OnValueChanged", function(self, value)
		local roundedValue
		if step < 1 then
			roundedValue = math.floor(value * (1 / step) + 0.5) / (1 / step)
		else
			roundedValue = math.floor(value + 0.5)
		end

		_G[sliderName.."Text"]:SetText(label .. ": " .. roundedValue)

		if callback then
			callback(roundedValue)
		end
	end)

	return slider, yPos - 50
end

-- Creates and initializes the options panel
function ConfigUI:InitializeOptions()
	local panel = CreateFrame("Frame")
	panel.name = "PeaversRemembersYou"
	panel:SetSize(600, 500) -- Explicit size can help

	-- Create a proper scroll frame with the new API pattern
	local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 10, -10)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

	local content = CreateFrame("Frame")
	content:SetSize(scrollFrame:GetWidth(), 800)  -- Initial height, give it plenty of room
	scrollFrame:SetScrollChild(content)

	local yPos = 0

	-- Create header and description
	local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 25, yPos)
	title:SetText("Peavers Remembers You")
	title:SetTextColor(1, 0.84, 0)  -- Gold color for main title
	title:SetFont(title:GetFont(), 24, "OUTLINE")
	yPos = yPos - 40

	local subtitle = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	subtitle:SetPoint("TOPLEFT", 25, yPos)
	subtitle:SetText("Records players you group with and notifies you when you meet them again")
	subtitle:SetFont(subtitle:GetFont(), 14)
	yPos = yPos - 30

	-- Add separator
	local _, newY = CreateSeparator(content, 25, yPos)
	yPos = newY

	-- SECTION 1: General Options
	local header, newY = CreateSectionHeader(content, "General Options", 25, yPos)
	yPos = newY - 5

	-- Enable checkbox
	local _, newY = CreateCheckbox(
		content,
		"PRYEnableCheckbox",
		"Enable Addon",
		40,
		yPos,
		PeaversRemembersYouDB.settings.enabled,
		{1, 1, 1},
		function(self)
			PeaversRemembersYouDB.settings.enabled = self:GetChecked()
		end
	)
	yPos = newY - 5

	-- Exclude guild members checkbox
	local _, newY = CreateCheckbox(
		content,
		"PRYExcludeGuildCheckbox",
		"Exclude Guild Members",
		40,
		yPos,
		PeaversRemembersYouDB.settings.excludeGuild,
		{1, 1, 1},
		function(self)
			PeaversRemembersYouDB.settings.excludeGuild = self:GetChecked()
		end
	)
	yPos = newY - 10

	-- Add separator
	local _, newY = CreateSeparator(content, 25, yPos)
	yPos = newY

	-- SECTION 2: Notification Settings
	local header, newY = CreateSectionHeader(content, "Notification Settings", 25, yPos)
	yPos = newY - 5

	-- TTL slider
	local label, newY = CreateLabel(content, "Days to Remember Players:", 40, yPos)
	yPos = newY - 5

	local _, newY = CreateSlider(
		content,
		"PRYTTLSlider",
		"Days to Remember",
		1, 365, 1,
		PeaversRemembersYouDB.settings.ttl,
		40, yPos, 400,
		function(value)
			PeaversRemembersYouDB.settings.ttl = value
		end
	)
	yPos = newY

	-- Chat frame slider
	local label, newY = CreateLabel(content, "Notification Chat Frame:", 40, yPos)
	yPos = newY - 5

	local _, newY = CreateSlider(
		content,
		"PRYChatFrameSlider",
		"Chat Frame",
		1, 10, 1,
		PeaversRemembersYouDB.settings.chatFrame,
		40, yPos, 400,
		function(value)
			PeaversRemembersYouDB.settings.chatFrame = value
		end
	)
	yPos = newY

	-- Notification threshold slider
	local label, newY = CreateLabel(content, "Notification Threshold (minutes):", 40, yPos)
	yPos = newY - 5

	local _, newY = CreateSlider(
		content,
		"PRYThresholdSlider",
		"Notification Threshold",
		0, 60, 1,
		PeaversRemembersYouDB.settings.notificationThreshold / 60,
		40, yPos, 400,
		function(value)
			PeaversRemembersYouDB.settings.notificationThreshold = value * 60 -- Convert minutes to seconds
		end
	)
	yPos = newY

	-- Add separator
	local _, newY = CreateSeparator(content, 25, yPos)
	yPos = newY

	-- SECTION 3: Database Management
	local header, newY = CreateSectionHeader(content, "Database Management", 25, yPos)
	yPos = newY - 15

	-- Reset button
	local resetBtn = CreateFrame("Button", "PRYResetButton", content, "UIPanelButtonTemplate")
	resetBtn:SetPoint("TOPLEFT", 40, yPos)
	resetBtn:SetWidth(150)
	resetBtn:SetHeight(25)
	resetBtn:SetText("Reset Database")
	resetBtn:SetScript("OnClick", function()
		StaticPopup_Show("PRY_CONFIRM_RESET")
	end)
	yPos = yPos - 40

	-- Create the static popup for reset confirmation if it doesn't exist
	if not StaticPopupDialogs["PRY_CONFIRM_RESET"] then
		StaticPopupDialogs["PRY_CONFIRM_RESET"] = {
			text = "Are you sure you want to reset your PeaversRemembersYou database?",
			button1 = "Yes",
			button2 = "No",
			OnAccept = function() PRY:ResetDatabase() end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	end

	-- Add separator
	local _, newY = CreateSeparator(content, 25, yPos)
	yPos = newY

	-- SECTION 4: How It Works
	local header, newY = CreateSectionHeader(content, "How It Works", 25, yPos)
	yPos = newY - 5

	-- List of usage information
	local usageInfo = {
		"This addon tracks all players you group with in dungeons, raids, and other groups.",
		"When you regroup with someone you've played with before, a notification appears.",
		"Guild members can be excluded from tracking (enabled by default).",
		"Old entries are automatically removed after the configured number of days.",
		"Use /pry or /peaversremembersyou to quickly open this settings panel."
	}

	for _, info in ipairs(usageInfo) do
		local infoText = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		infoText:SetPoint("TOPLEFT", 45, yPos)
		infoText:SetPoint("TOPRIGHT", -25, yPos)
		infoText:SetJustifyH("LEFT")
		infoText:SetText("• " .. info)
		yPos = yPos - 18
	end

	-- Update content height based on the last element position - VERY IMPORTANT
	content:SetHeight(math.abs(yPos) + 50)

	-- Required callbacks
	panel.refresh = function() end  -- Changed from OnRefresh to refresh

	return panel
end

-- Initialize the addon UI
function ConfigUI:Initialize()
	-- Make sure the database exists first
	if not PeaversRemembersYouDB then
		print("|cff33ff99PeaversRemembersYou|r: Error initializing configuration UI - database not found")
		return
	end

	local panel = self:InitializeOptions()

	-- IMPORTANT: Only register ONCE with the correct API
	PRY.mainCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
	PRY.mainCategory.ID = panel.name
	Settings.RegisterAddOnCategory(PRY.mainCategory)

	-- Initialize Support UI only after main category is created and properly registered
	if PRY.Utils.SupportUI then
		C_Timer.After(0.1, function()
			PRY.Utils.SupportUI:Initialize()
		end)
	end
end

-- Opens the configuration panel
function ConfigUI:Open()
	Settings.OpenToCategory(PRY.mainCategory.ID)  -- Use the ID directly
end
