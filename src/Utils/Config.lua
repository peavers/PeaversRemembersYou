local addonName, PRY = ...
local Config = {}
PRY.Config = Config

-- Default settings
local defaults = {
    enabled = true,
    ttl = 30, -- Time to live in days
    excludeGuild = true,
    chatFrame = 1,
    notificationThreshold = 300, -- Minimum time in seconds
    DEBUG_ENABLED = false
}

-- Initialize configuration
function Config:Initialize()
    -- Load saved variables
    PeaversRemembersYouDB = PeaversRemembersYouDB or {}
    
    if not PeaversRemembersYouDB.settings then
        PeaversRemembersYouDB.settings = {}
    end
    
    if not PeaversRemembersYouDB.players then
        PeaversRemembersYouDB.players = {}
    end
    
    -- Merge with defaults
    for k, v in pairs(defaults) do
        if PeaversRemembersYouDB.settings[k] == nil then
            PeaversRemembersYouDB.settings[k] = v
        end
    end
    
    -- Copy to the current config
    for k, v in pairs(PeaversRemembersYouDB.settings) do
        self[k] = v
    end
    
    return self
end

-- Save configuration
function Config:Save()
    for k, _ in pairs(defaults) do
        if self[k] ~= nil then
            PeaversRemembersYouDB.settings[k] = self[k]
        end
    end
end

return Config