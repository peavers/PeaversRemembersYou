local addonName, PRY = ...

-- Access the PeaversCommons library
local PeaversCommons = _G.PeaversCommons
local Utils = PeaversCommons.Utils

-- Local variables
local icon = "|TInterface\\Icons\\INV_Misc_Note_01:16:16:0:0|t"
local currentGroupMembers = {} -- Track current group members
local pendingGuidPlayers = {} -- Track players with missing GUIDs for retry

-- Initialize the addon
function PRY:Initialize()
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

    -- Handle group/raid roster changes (shared handler for both events)
    local function HandleGroupChange()
        if not PRY.Config.enabled then return end
        if not IsInGroup() and not IsInRaid() then
            wipe(currentGroupMembers) -- Clear current group members when leaving group
            wipe(pendingGuidPlayers) -- Clear pending players when leaving group
            return
        end

        PRY:ProcessGroupMembers()
    end

    -- Register events with the shared handler
    PeaversCommons.Events:RegisterEvent("GROUP_ROSTER_UPDATE", HandleGroupChange)
    PeaversCommons.Events:RegisterEvent("RAID_ROSTER_UPDATE", HandleGroupChange)

    PeaversCommons.Events:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        if not PRY.Config.enabled then return end
        wipe(currentGroupMembers) -- Clear current group members on login/reload
        wipe(pendingGuidPlayers) -- Clear pending players on login/reload

        if IsInGroup() or IsInRaid() then
            PRY:UpdateCurrentGroupMembers()
        end
    end)
end

-- Helper function to check if a player is valid for tracking
function PRY:IsValidPlayer(name, unit, guid)
    return name and
           name ~= "Unknown" and
           name ~= UnitName("player") and
           UnitIsPlayer(unit) and
           guid and
           guid ~= ""
end

-- Helper function to get current group information
function PRY:GetGroupInfo()
    local info = {
        isInGroup = IsInGroup() or IsInRaid(),
        numMembers = IsInRaid() and GetNumGroupMembers() or GetNumSubgroupMembers(),
        prefix = IsInRaid() and "raid" or "party",
        groupType = "group"
    }

    -- Determine group type
    if IsInRaid() then
        info.groupType = "raid"
    end

    -- Check if we're in an instance
    local inInstance, instanceType = IsInInstance()
    if inInstance and instanceType == "party" then
        info.groupType = "dungeon"
    end

    return info
end

-- Process an individual group member
function PRY:ProcessGroupMember(name, unit, guid, groupType, isNewGroup)
    local isGuildMember = UnitIsInMyGuild(unit)

    if self:IsValidPlayer(name, unit, guid) then
        -- Valid player with GUID
        if isNewGroup then
            currentGroupMembers[name] = true
        end

        -- Skip guild members if option is enabled
        if not (PRY.Config.excludeGuild and isGuildMember) then
            -- Only process if they're not already in the current group
            if not currentGroupMembers[name] or isNewGroup then
                self:ProcessPlayer(name, groupType)
            end
        end

        return true
    elseif name and name ~= "Unknown" and name ~= UnitName("player") and UnitIsPlayer(unit) then
        -- Player without valid GUID, add to pending list for retry
        if not pendingGuidPlayers[name] then
            pendingGuidPlayers[name] = {
                unit = unit,
                groupType = groupType,
                added = time()
            }

            -- Start checking pending players if this is the first one
            local pendingCount = 0
            for _ in pairs(pendingGuidPlayers) do pendingCount = pendingCount + 1 end
            if pendingCount == 1 then
                C_Timer.After(20, function() self:CheckPendingPlayers() end)
            end
        end
    end

    return false
end

-- Update current group members
function PRY:UpdateCurrentGroupMembers()
    wipe(currentGroupMembers)

    local groupInfo = self:GetGroupInfo()

    if groupInfo.numMembers > 0 then
        for i = 1, groupInfo.numMembers do
            local unit = groupInfo.prefix..i

            if UnitExists(unit) then
                local name = GetUnitName(unit, true)
                local guid = UnitGUID(unit)

                if self:IsValidPlayer(name, unit, guid) then
                    currentGroupMembers[name] = true
                end
            end
        end
    end
end

-- Process group members
function PRY:ProcessGroupMembers()
    local groupInfo = self:GetGroupInfo()
    local newGroupMembers = {}

    if groupInfo.numMembers > 0 then
        for i = 1, groupInfo.numMembers do
            local unit = groupInfo.prefix..i

            if UnitExists(unit) then
                local name = GetUnitName(unit, true)
                local guid = UnitGUID(unit)

                if self:ProcessGroupMember(name, unit, guid, groupInfo.groupType, true) then
                    newGroupMembers[name] = true
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
    -- Skip processing if the player name is "Unknown"
    if name == "Unknown" then return end

    local currentTime = time()
    local playerData = PRY.Config:GetPlayerData(name)

    if playerData then
        -- Player exists in database
        local timeSinceLastMet = currentTime - playerData.lastSeen

        -- Fix: Always send notification if threshold is 0, otherwise use threshold
        if PRY.Config.notificationThreshold == 0 or
           timeSinceLastMet >= PRY.Config.notificationThreshold then
            local oldGroupType = playerData.groupType

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
        playerData.lastSeen = currentTime
        playerData.groupType = groupType
        PRY.Config:SetPlayerData(name, playerData)
    else
        -- New player, add to database
        PRY.Config:SetPlayerData(name, {
            firstSeen = currentTime,
            lastSeen = currentTime,
            groupType = groupType
        })
    end
end

-- Send a notification message
function PRY:SendNotification(name, timeValue, groupType, timeUnit)
    -- Skip notification if player name is "Unknown"
    if name == "Unknown" then return end

    local message = string.format("%s You last grouped with |cff00ff00%s|r in a |cff00ccff%s|r %d %s ago!",
        icon, name, groupType, timeValue, timeUnit)

    -- Send to selected chat frame
    local chatFrame = _G["ChatFrame"..PRY.Config.chatFrame]
    if chatFrame then
        chatFrame:AddMessage(message)
    else
        DEFAULT_CHAT_FRAME:AddMessage(message)
    end
end

-- Clean up old entries
function PRY:CleanupDatabase()
    local currentTime = time()
    local ttlSeconds = PRY.Config.ttl * 86400
    local allPlayers = PRY.Config:GetAllPlayerData()

    for name, data in pairs(allPlayers) do
        -- Remove entries that are expired OR have "Unknown" as the name
        if (currentTime - data.lastSeen) > ttlSeconds or name == "Unknown" then
            PRY.Config:SetPlayerData(name, nil) -- Set to nil to remove
        end
    end
end

-- Check pending players with missing GUIDs
function PRY:CheckPendingPlayers()
    local playersToRemove = {}

    for name, info in pairs(pendingGuidPlayers) do
        -- Skip processing if the player name is "Unknown" and mark for removal
        if name == "Unknown" then
            table.insert(playersToRemove, name)
        else
            local unit = info.unit
            local groupType = info.groupType

            -- Check if the unit still exists and now has a GUID
            if UnitExists(unit) then
                local guid = UnitGUID(unit)
                if guid and guid ~= "" then
                    -- Player now has a valid GUID, process them
                    if not currentGroupMembers[name] then
                        self:ProcessPlayer(name, groupType)
                        currentGroupMembers[name] = true
                    end

                    -- Mark for removal from pending list
                    table.insert(playersToRemove, name)
                end
            else
                -- Unit no longer exists, remove from pending
                table.insert(playersToRemove, name)
            end
        end
    end

    -- Remove processed players from pending list
    for _, name in ipairs(playersToRemove) do
        pendingGuidPlayers[name] = nil
    end

    -- Schedule next check if we still have pending players
    if next(pendingGuidPlayers) then
        C_Timer.After(30, function() PRY:CheckPendingPlayers() end)
    end
end

-- Reset database
function PRY:ResetDatabase()
    PRY.Config:ResetPlayerData()
    Utils.Print(PRY, "Player database has been cleared.")

    -- Show reload UI confirmation
    StaticPopup_Show("PRY_CONFIRM_RELOAD")
end
