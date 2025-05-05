local addonName, PRY = ...

-- Access PeaversCommons utilities
local PeaversCommons = _G.PeaversCommons

-- Default settings
local defaults = {
    enabled = true,
    ttl = 30, -- Time to live in days
    excludeGuild = true,
    chatFrame = 1,
    notificationThreshold = 300, -- Minimum time in seconds
    DEBUG_ENABLED = false
}

-- Create configuration using PeaversCommons.ConfigManager
PRY.Config = PeaversCommons.ConfigManager:New(
    "PeaversRemembersYou", 
    defaults,  -- Default settings first
    {
        savedVariablesName = "PeaversRemembersYouDB",
        settingsKey = "settings" -- Use settings key for backward compatibility
    }
)

-- Initialize configuration is already handled by the ConfigManager

-- Make sure we have a players table for legacy compatibility
local function InitializePlayers()
    PeaversRemembersYouDB = PeaversRemembersYouDB or {}
    if not PeaversRemembersYouDB.players then
        PeaversRemembersYouDB.players = {}
    end
end

-- Add custom config methods for working with the players database
function PRY.Config:GetPlayerData(name)
    InitializePlayers()
    return PeaversRemembersYouDB.players[name]
end

function PRY.Config:SetPlayerData(name, data)
    InitializePlayers()
    PeaversRemembersYouDB.players[name] = data
end

function PRY.Config:ResetPlayerData()
    InitializePlayers()
    PeaversRemembersYouDB.players = {}
end

function PRY.Config:GetAllPlayerData()
    InitializePlayers()
    return PeaversRemembersYouDB.players
end

function PRY.Config:Initialize()
    -- For backward compatibility, ensure initialization of players table
    InitializePlayers()
end

return PRY.Config