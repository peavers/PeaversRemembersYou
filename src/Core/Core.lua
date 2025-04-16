local addonName, PRY = ...

-- Default settings
local defaults = {
	enabled = true,
	ttl = 30, -- Time to live in days
	excludeGuild = true,
	chatFrame = 1,
	notificationThreshold = 300 -- Minimum time in seconds
}

-- Local variables
local icon = "|TInterface\\Icons\\INV_Misc_Note_01:16:16:0:0|t"
local eventHandlers = {}
local isInitialized = false
local currentGroupMembers = {} -- Track current group members

-- Initialize the addon
function PRY:Initialize()
	-- Set up database if it doesn't exist
	if not PeaversRemembersYouDB then
		PeaversRemembersYouDB = {
			settings = CopyTable(defaults),
			players = {}
		}
	end

	-- Ensure all settings exist
	for k, v in pairs(defaults) do
		if PeaversRemembersYouDB.settings[k] == nil then
			PeaversRemembersYouDB.settings[k] = v
		end
	end

	-- Create the static popups
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

	if not StaticPopupDialogs["PRY_CONFIRM_RELOAD"] then
		StaticPopupDialogs["PRY_CONFIRM_RELOAD"] = {
			text = "Database has been cleared. It's recommended to reload your UI to ensure all settings are properly updated. Reload now?",
			button1 = "Yes",
			button2 = "No",
			OnAccept = function() ReloadUI() end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	end

	-- Register events
	self:RegisterEvents()

	isInitialized = true
end

-- Register our event handlers
function PRY:RegisterEvents()
	local eventFrame = CreateFrame("Frame")
	self.eventFrame = eventFrame

	eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
	eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- Added to initialize group state

	eventFrame:SetScript("OnEvent", function(self, event, ...)
		if isInitialized and eventHandlers[event] then
			eventHandlers[event](...)
		end
	end)
end

-- Event Handlers
eventHandlers.PLAYER_ENTERING_WORLD = function()
	if not PeaversRemembersYouDB.settings.enabled then return end
	wipe(currentGroupMembers) -- Clear current group members on login/reload

	if IsInGroup() or IsInRaid() then
		PRY:UpdateCurrentGroupMembers()
	end
end

eventHandlers.GROUP_ROSTER_UPDATE = function()
	if not PeaversRemembersYouDB.settings.enabled then return end
	if not IsInGroup() and not IsInRaid() then
		wipe(currentGroupMembers) -- Clear current group members when leaving group
		return
	end

	PRY:ProcessGroupMembers()
end

eventHandlers.RAID_ROSTER_UPDATE = eventHandlers.GROUP_ROSTER_UPDATE

-- Update current group members
function PRY:UpdateCurrentGroupMembers()
	wipe(currentGroupMembers)

	-- Get current group members
	local numGroupMembers = IsInRaid() and GetNumGroupMembers() or GetNumSubgroupMembers()

	if numGroupMembers > 0 then
		local prefix = IsInRaid() and "raid" or "party"

		for i = 1, numGroupMembers do
			local unit = prefix..i

			if UnitExists(unit) then
				local name = GetUnitName(unit, true)

				if name and name ~= UnitName("player") then
					currentGroupMembers[name] = true
				end
			end
		end
	end
end

-- Process group members
function PRY:ProcessGroupMembers()
	-- Get current group type
	local groupType = "group"
	if IsInRaid() then
		groupType = "raid"
	end

	-- Check if we're in an instance
	local inInstance, instanceType = IsInInstance()
	if inInstance and instanceType == "party" then
		groupType = "dungeon"
	end

	-- Get current group members
	local numGroupMembers = IsInRaid() and GetNumGroupMembers() or GetNumSubgroupMembers()
	local newGroupMembers = {}

	-- Check if we're in a group
	if numGroupMembers > 0 then
		-- If in raid, use raid1-N, otherwise for party use party1-N
		local prefix = IsInRaid() and "raid" or "party"

		-- Loop through members
		for i = 1, numGroupMembers do
			local unit = prefix..i

			if UnitExists(unit) then
				local name = GetUnitName(unit, true)

				if name and name ~= UnitName("player") then
					local isGuildMember = UnitIsInMyGuild(unit)
					newGroupMembers[name] = true

					-- Skip guild members if option is enabled
					if not (PeaversRemembersYouDB.settings.excludeGuild and isGuildMember) then
						-- Only process if they're not already in the current group
						if not currentGroupMembers[name] then
							self:ProcessPlayer(name, groupType)
						end
					end
				end
			end
		end
	end

	-- Update current group members
	currentGroupMembers = newGroupMembers

	-- Clean up old entries
	self:CleanupDatabase()
end

-- Process a player
function PRY:ProcessPlayer(name, groupType)
	local currentTime = time()

	if PeaversRemembersYouDB.players[name] then
		-- Player exists in database
		local timeSinceLastMet = currentTime - PeaversRemembersYouDB.players[name].lastSeen

		-- Fix: Always send notification if threshold is 0, otherwise use threshold
		if PeaversRemembersYouDB.settings.notificationThreshold == 0 or
		   timeSinceLastMet >= PeaversRemembersYouDB.settings.notificationThreshold then
			local oldGroupType = PeaversRemembersYouDB.players[name].groupType

			-- Use the fancy formatted message
			if timeSinceLastMet >= 86400 then -- More than 1 day
				local days = math.floor(timeSinceLastMet / 86400)
				self:SendNotification(name, days, oldGroupType, days == 1 and "day" or "days")
			elseif timeSinceLastMet >= 3600 then -- More than 1 hour
				local hours = math.floor(timeSinceLastMet / 3600)
				self:SendNotification(name, hours, oldGroupType, hours == 1 and "hour" or "hours")
			else -- Minutes
				local minutes = math.floor(timeSinceLastMet / 60)
				if minutes < 1 then minutes = 1 end -- Minimum 1 minute
				self:SendNotification(name, minutes, oldGroupType, minutes == 1 and "minute" or "minutes")
			end
		end

		-- Update last seen time and group type
		PeaversRemembersYouDB.players[name].lastSeen = currentTime
		PeaversRemembersYouDB.players[name].groupType = groupType

	else
		-- New player, add to database
		PeaversRemembersYouDB.players[name] = {
			firstSeen = currentTime,
			lastSeen = currentTime,
			groupType = groupType
		}
	end
end

-- Send a notification message
function PRY:SendNotification(name, timeValue, groupType, timeUnit)
	local message = string.format("%s You last grouped with |cff00ff00%s|r in a |cff00ccff%s|r %d %s ago!",
		icon, name, groupType, timeValue, timeUnit)

	-- Send to selected chat frame
	local chatFrame = _G["ChatFrame"..PeaversRemembersYouDB.settings.chatFrame]
	if chatFrame then
		chatFrame:AddMessage(message)
	else
		DEFAULT_CHAT_FRAME:AddMessage(message)
	end
end

-- Clean up old entries
function PRY:CleanupDatabase()
	local currentTime = time()
	local ttlSeconds = PeaversRemembersYouDB.settings.ttl * 86400

	for name, data in pairs(PeaversRemembersYouDB.players) do
		if (currentTime - data.lastSeen) > ttlSeconds then
			PeaversRemembersYouDB.players[name] = nil
		end
	end
end

-- Reset database
function PRY:ResetDatabase()
	wipe(PeaversRemembersYouDB.players)
	print("|cff33ff99PeaversRemembersYou|r: Player database has been cleared.")

	-- Show reload UI confirmation
	StaticPopup_Show("PRY_CONFIRM_RELOAD")
end

-- Handle slash commands - Kept minimal
function PRY:HandleSlashCommand(msg)
	-- Just open the settings panel directly
	Settings.OpenToCategory("PeaversRemembersYou")
end
