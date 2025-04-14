local _, PRY = ...

local ConfigUI = {}
PRY.ConfigUI = ConfigUI

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

local function CreateCheckbox(parent, name, text, xOffset, yPos, checked, onClick)
    local checkbox = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", xOffset, yPos)

    -- Set the text
    local checkboxText = _G[checkbox:GetName() .. "Text"]
    if checkboxText then
        checkboxText:SetText(text)
    end

    -- Set the initial state
    checkbox:SetChecked(checked)

    -- Set the click handler
    checkbox:SetScript("OnClick", onClick)

    return checkbox, yPos - 25
end

local function CreateSlider(parent, name, label, min, max, step, defaultVal, xOffset, yPos, width, callback)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width or 400, 50)
    container:SetPoint("TOPLEFT", xOffset, yPos)

    local labelText = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 0, 0)
    labelText:SetText(label .. ": " .. defaultVal)

    local slider = CreateFrame("Slider", name, container, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 0, -20)
    slider:SetWidth(width or 400)
    slider:SetHeight(16)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetValue(defaultVal)

    -- Hide default slider text
    local sliderName = slider:GetName()
    if sliderName then
        local lowText = _G[sliderName .. "Low"]
        local highText = _G[sliderName .. "High"]
        local valueText = _G[sliderName .. "Text"]

        if lowText then lowText:SetText("") end
        if highText then highText:SetText("") end
        if valueText then valueText:SetText("") end
    end

    -- Set the change handler
    slider:SetScript("OnValueChanged", function(self, value)
        local roundedValue
        if step < 1 then
            roundedValue = math.floor(value * (1 / step) + 0.5) / (1 / step)
        else
            roundedValue = math.floor(value + 0.5)
        end

        labelText:SetText(label .. ": " .. roundedValue)

        if callback then
            callback(roundedValue)
        end
    end)

    return slider, yPos - 50
end

function ConfigUI:InitializeOptions()
	local panel = CreateFrame("Frame")
	panel.name = "PeaversRemembersYou"

	panel.layoutIndex = 1
	panel.OnShow = function(self)
		return true
	end

	local yPos = -16

  	-- Create header and description
	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, yPos)
	title:SetText("Peavers Remembers You")
	title:SetTextColor(1, 0.84, 0)  -- Gold color for main title
	yPos = yPos - 25

	local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	subtitle:SetPoint("TOPLEFT", 16, yPos)
	subtitle:SetText("Records players you group with and notifies you when you meet them again")
	yPos = yPos - 25

	-- Add separator
	local _, newY = CreateSeparator(panel, 16, yPos)
	yPos = newY


  -- SECTION 1: General Options
    local header, newY = CreateSectionHeader(panel, "General Options", 16, yPos)
    yPos = newY - 5

    -- Enable checkbox
    local _, newY = CreateCheckbox(
        panel,
        "PRYEnableCheckbox",
        "Enable Addon",
        30,
        yPos,
        PeaversRemembersYouDB.settings.enabled,
        function(self)
            PeaversRemembersYouDB.settings.enabled = self:GetChecked()
        end
    )
    yPos = newY - 5

    -- Exclude guild members checkbox
    local _, newY = CreateCheckbox(
        panel,
        "PRYExcludeGuildCheckbox",
        "Exclude Guild Members",
        30,
        yPos,
        PeaversRemembersYouDB.settings.excludeGuild,
        function(self)
            PeaversRemembersYouDB.settings.excludeGuild = self:GetChecked()
        end
    )
    yPos = newY - 10

    -- Add separator
    local _, newY = CreateSeparator(panel, 16, yPos)
    yPos = newY

    -- SECTION 2: Notification Settings
    local header, newY = CreateSectionHeader(panel, "Notification Settings", 16, yPos)
    yPos = newY - 5

    -- TTL slider
    local _, newY = CreateSlider(
        panel,
        "PRYTTLSlider",
        "Days to Remember Players",
        1, 365, 1,
        PeaversRemembersYouDB.settings.ttl,
        30, yPos, 400,
        function(value)
            PeaversRemembersYouDB.settings.ttl = value
        end
    )
    yPos = newY

    -- Chat frame slider
    local _, newY = CreateSlider(
        panel,
        "PRYChatFrameSlider",
        "Notification Chat Frame",
        1, 10, 1,
        PeaversRemembersYouDB.settings.chatFrame,
        30, yPos, 400,
        function(value)
            PeaversRemembersYouDB.settings.chatFrame = value
        end
    )
    yPos = newY

    -- Notification threshold slider - Updated to allow 0 (always notify)
    local _, newY = CreateSlider(
        panel,
        "PRYThresholdSlider",
        "Notification Threshold (minutes - 0 for always)",
        0, 60, 1,
        PeaversRemembersYouDB.settings.notificationThreshold / 60,
        30, yPos, 400,
        function(value)
            PeaversRemembersYouDB.settings.notificationThreshold = value * 60 -- Convert minutes to seconds
        end
    )
    yPos = newY

    -- Add separator
    local _, newY = CreateSeparator(panel, 16, yPos)
    yPos = newY

    -- SECTION 3: Database Management
    local header, newY = CreateSectionHeader(panel, "Database Management", 16, yPos)
    yPos = newY - 15

    -- Reset button
    local resetBtn = CreateFrame("Button", "PRYResetButton", panel, "UIPanelButtonTemplate")
    resetBtn:SetPoint("TOPLEFT", 30, yPos)
    resetBtn:SetWidth(150)
    resetBtn:SetHeight(25)
    resetBtn:SetText("Reset Database")
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("PRY_CONFIRM_RESET")
    end)
    yPos = yPos - 40

	PRY.mainCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
	PRY.mainCategory.ID = panel.name
	Settings.RegisterAddOnCategory(PRY.mainCategory)

	panel.OnRefresh = function()
	end
	panel.OnCommit = function()
	end
	panel.OnDefault = function()
	end

	return panel
end

function ConfigUI:Initialize()
	self:InitializeOptions()
end
