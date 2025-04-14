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
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN") -- Add PLAYER_LOGIN for safer initialization

frame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == addonName then
		-- Mark the addon as loaded but don't initialize yet
		PRY.loaded = true

		-- Unregister the ADDON_LOADED event
		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "PLAYER_LOGIN" and PRY.loaded then
		-- Initialize after PLAYER_LOGIN and only if our addon is loaded
		-- This ensures the Settings API is fully ready
		C_Timer.After(0.5, function() -- Delay initialization to ensure Settings API is ready
			PRY:Initialize()
		end)

		-- Unregister the event
		self:UnregisterEvent("PLAYER_LOGIN")
	end
end)

-- Print a loading message once PLAYER_ENTERING_WORLD fires
local loadingFrame = CreateFrame("Frame")
loadingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loadingFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_ENTERING_WORLD" then
		print("|cff33ff99PeaversRemembersYou|r: Type /pry to open settings")
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end)
