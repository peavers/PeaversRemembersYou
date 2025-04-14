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
frame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == addonName then
		-- Core initialization with delayed timer to ensure DB is ready
		C_Timer.After(0.1, function()
			PRY:Initialize()
		end)

		-- Unregister the ADDON_LOADED event
		self:UnregisterEvent("ADDON_LOADED")
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
