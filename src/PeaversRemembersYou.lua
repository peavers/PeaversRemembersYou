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

	-- Set up slash commands
	SLASH_PEAVERSREMEMBERSYOU1 = "/pry"
	SLASH_PEAVERSREMEMBERSYOU2 = "/peaversremembersyou"
	SlashCmdList["PEAVERSREMEMBERSYOU"] = function(msg)
		PRY:HandleSlashCommand(msg)
	end

	-- Register events
	self:RegisterEvents()

	-- We need to delay UI initialization until the Settings API is fully loaded
	-- This is crucial for proper Settings integration
	C_Timer.After(1, function()
		-- Initialize UI components AFTER core is ready
		if PRY.Utils.ConfigUI then
			PRY.Utils.ConfigUI:Initialize()
		end
	end)

	isInitialized = true
end

-- Register our event handlers
function PRY:RegisterEvents()
	local eventFrame = CreateFrame("Frame")
	self.eventFrame = eventFrame

	eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")

	eventFrame:SetScript("OnEvent", function(self, event, ...)
		if isInitialized and eventHandlers[event] then
			eventHandlers[event](...)
		end
	end)
end

-- Event Handlers
eventHandlers.GROUP_ROSTER_UPDATE = function()
	if not PeaversRemembersYouDB.settings.enabled then return end
	if not IsInGroup() and not IsInRaid() then return end

	PRY:ProcessGroupMembers()
end

eventHandlers.RAID_ROSTER_UPDATE = eventHandlers.GROUP_ROSTER_UPDATE

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

					-- Skip guild members if option is enabled
					if not (PeaversRemembersYouDB.settings.excludeGuild and isGuildMember) then
						self:ProcessPlayer(name, groupType)
					end
				end
			end
		end
	end

	-- Clean up old entries
	self:CleanupDatabase()
end

-- Process a player
function PRY:ProcessPlayer(name, groupType)
	local currentTime = time()

	if PeaversRemembersYouDB.players[name] then
		-- Player exists in database
		local timeSinceLastMet = currentTime - PeaversRemembersYouDB.players[name].lastSeen

		-- Only announce if it's been at least the configured threshold time since we last saw them
		if timeSinceLastMet >= PeaversRemembersYouDB.settings.notificationThreshold then
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
end

-- Handle slash commands
function PRY:HandleSlashCommand(msg)
	msg = msg:lower():trim()

	if msg == "reset" then
		self:ResetDatabase()
	elseif msg == "toggle" then
		PeaversRemembersYouDB.settings.enabled = not PeaversRemembersYouDB.settings.enabled
		print("|cff33ff99PeaversRemembersYou|r: " .. (PeaversRemembersYouDB.settings.enabled and "Enabled" or "Disabled"))
	else
		-- Make sure we use the correct Settings API call
		Settings.OpenToCategory("PeaversRemembersYou")
	end
end
