local addonName, PRY = ...

-- Initialize addon namespace and modules
PRY = PRY or {}

-- Module namespaces
PRY.Utils = {}
PRY.Config = {}

-- Version information
PRY.version = "1.0.0"
PRY.addonName = addonName

-- Initialize addon when ADDON_LOADED event fires
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")

initFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize core functionality first
        PRY:Initialize()

        -- Initialize configuration UI if available with a small delay
        C_Timer.After(0.2, function()
            if PRY.ConfigUI and PRY.ConfigUI.Initialize then
                PRY.ConfigUI:Initialize()
            end

            -- Initialize support UI if available with a small delay
            C_Timer.After(0.1, function()
                if PRY.SupportUI and PRY.SupportUI.Initialize then
                    PRY.SupportUI:Initialize()
                end
            end)
        end)

        -- Unregister the event
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Print a loading message once PLAYER_ENTERING_WORLD fires
local loadingFrame = CreateFrame("Frame")
loadingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loadingFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        print("|cff33ff99PeaversRemembersYou|r: Addon loaded - remembering your party members")
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)
