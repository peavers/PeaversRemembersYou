local _, PRY = ...

local ConfigUI = {}
PRY.ConfigUI = ConfigUI

-- Access PeaversCommons utilities
local PeaversCommons = _G.PeaversCommons
local FrameUtils = PeaversCommons.FrameUtils
local ConfigUIUtils = PeaversCommons.ConfigUIUtils

-- Utility functions to reduce code duplication (using PeaversCommons.ConfigUIUtils)
local Utils = {}

-- Creates a slider with standardized formatting
function Utils:CreateSlider(parent, name, label, min, max, step, defaultVal, width, callback)
    return ConfigUIUtils.CreateSlider(parent, name, label, min, max, step, defaultVal, width, callback)
end

-- Creates a dropdown with standardized formatting
function Utils:CreateDropdown(parent, name, label, options, defaultOption, width, callback)
    return ConfigUIUtils.CreateDropdown(parent, name, label, options, defaultOption, width, callback)
end

-- Creates a checkbox with standardized formatting
function Utils:CreateCheckbox(parent, name, label, x, y, checked, callback)
    return ConfigUIUtils.CreateCheckbox(parent, name, label, x, y, checked, callback)
end

-- Creates a section header with standardized formatting
function Utils:CreateSectionHeader(parent, text, indent, yPos, fontSize)
    return ConfigUIUtils.CreateSectionHeader(parent, text, indent, yPos, fontSize)
end

-- Creates a subsection label with standardized formatting
function Utils:CreateSubsectionLabel(parent, text, indent, y)
    return ConfigUIUtils.CreateSubsectionLabel(parent, text, indent, y)
end

-- Creates a button with standardized formatting
function Utils:CreateButton(parent, name, text, x, y, width, height, onClick)
    return FrameUtils.CreateButton(parent, name, text, x, y, width, height, onClick)
end

-- Creates a separator with standardized formatting
function Utils:CreateSeparator(parent, x, y, width)
    return FrameUtils.CreateSeparator(parent, x, y, width)
end

function ConfigUI:InitializeOptions()
    -- Use the ConfigUIUtils to create a standard settings panel
    local panel = ConfigUIUtils.CreateSettingsPanel(
        "Settings",
        "Records players you group with and notifies you when you meet them again"
    )
    
    local content = panel.content
    local yPos = panel.yPos
    local baseSpacing = panel.baseSpacing
    local controlIndent = baseSpacing + 15
    local sliderWidth = 380

    -- SECTION 1: General Options
    local header, newY = Utils:CreateSectionHeader(content, "General Options", baseSpacing, yPos)
    yPos = newY - 10

    -- Enable checkbox
    local _, newY = Utils:CreateCheckbox(
        content,
        "PRYEnableCheckbox",
        "Enable Addon",
        controlIndent,
        yPos,
        PRY.Config.enabled,
        function(checked)
            PRY.Config.enabled = checked
            PRY.Config:Save()
        end
    )
    yPos = newY - 5

    -- Exclude guild members checkbox
    local _, newY = Utils:CreateCheckbox(
        content,
        "PRYExcludeGuildCheckbox",
        "Exclude Guild Members",
        controlIndent,
        yPos,
        PRY.Config.excludeGuild,
        function(checked)
            PRY.Config.excludeGuild = checked
            PRY.Config:Save()
        end
    )
    yPos = newY - 10

    -- Add separator
    local _, newY = Utils:CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - 15

    -- SECTION 2: Notification Settings
    local header, newY = Utils:CreateSectionHeader(content, "Notification Settings", baseSpacing, yPos)
    yPos = newY - 10

    -- TTL slider
    local ttlContainer, ttlSlider = Utils:CreateSlider(
        content,
        "PRYTTLSlider",
        "Days to Remember Players",
        1, 365, 1,
        PRY.Config.ttl,
        sliderWidth,
        function(value)
            PRY.Config.ttl = value
            PRY.Config:Save()
        end
    )
    ttlContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    yPos = yPos - 55

    -- Chat frame slider
    local chatFrameContainer, chatFrameSlider = Utils:CreateSlider(
        content,
        "PRYChatFrameSlider",
        "Notification Chat Frame",
        1, 10, 1,
        PRY.Config.chatFrame,
        sliderWidth,
        function(value)
            PRY.Config.chatFrame = value
            PRY.Config:Save()
        end
    )
    chatFrameContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    yPos = yPos - 55

    -- Notification threshold slider
    local thresholdContainer, thresholdSlider = Utils:CreateSlider(
        content,
        "PRYThresholdSlider",
        "Notification Threshold (minutes - 0 for always)",
        0, 60, 1,
        PRY.Config.notificationThreshold / 60,
        sliderWidth,
        function(value)
            PRY.Config.notificationThreshold = value * 60 -- Convert minutes to seconds
            PRY.Config:Save()
        end
    )
    thresholdContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    yPos = yPos - 65

    -- Add separator
    local _, newY = Utils:CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - 15

    -- SECTION 3: Database Management
    local header, newY = Utils:CreateSectionHeader(content, "Database Management", baseSpacing, yPos)
    yPos = newY - 15

    -- Reset button
    local resetBtn, btnY = Utils:CreateButton(
        content, 
        "PRYResetButton", 
        "Reset Database", 
        controlIndent, 
        yPos, 
        150, 
        25, 
        function()
            StaticPopup_Show("PRY_CONFIRM_RESET")
        end
    )
    yPos = btnY - 10

    -- Update content height
    panel:UpdateContentHeight(yPos)

    return panel
end

function ConfigUI:Initialize()
	self.panel = self:InitializeOptions()
end
