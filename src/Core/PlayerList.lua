local addonName, PRY = ...

-- Initialize module
PRY.PlayerListUI = PRY.PlayerListUI or {}
local PLUI = PRY.PlayerListUI

-- Local variables
local listFrame
local scrollFrame
local playerButtons = {}
local MAX_BUTTONS = 20
local BUTTON_HEIGHT = 20
local currentSort = "lastSeen" -- Default sort
local sortDir = -1 -- -1 = descending, 1 = ascending

-- Initialize function
-- Initialize function
function PLUI:Initialize()
    if listFrame then return end

    -- Create main frame
    listFrame = CreateFrame("Frame", "PRY_PlayerListFrame", UIParent, "BasicFrameTemplateWithInset")
    listFrame:SetSize(650, 450)
    listFrame:SetPoint("CENTER")
    listFrame:SetFrameStrata("HIGH")
    listFrame:Hide()

    -- Make it movable
    listFrame:SetMovable(true)
    listFrame:SetClampedToScreen(true)
    listFrame:RegisterForDrag("LeftButton")
    listFrame:SetScript("OnDragStart", listFrame.StartMoving)
    listFrame:SetScript("OnDragStop", listFrame.StopMovingOrSizing)

    -- Set title
    listFrame.TitleText:SetText("Players Remembered")

    -- Create scroll frame with a proper setup
    scrollFrame = CreateFrame("ScrollFrame", "PRY_PlayerListScrollFrame", listFrame, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 5, -50) -- Adjusted position
    scrollFrame:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -27, 30) -- Adjusted position

    -- Create column headers
    self:CreateColumnHeaders()

    -- Create buttons
    for i = 1, MAX_BUTTONS do
        local button = CreateFrame("Button", "PRY_PlayerListButton" .. i, listFrame)
        button:SetSize(scrollFrame:GetWidth() - 30, BUTTON_HEIGHT)
        button:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 8, -((i-1) * BUTTON_HEIGHT) - 3)

        -- Player name
        button.name = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        button.name:SetPoint("LEFT", 5, 0)
        button.name:SetWidth(120)
        button.name:SetJustifyH("LEFT")

        -- Server name
        button.server = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        button.server:SetPoint("LEFT", 130, 0)
        button.server:SetWidth(100)
        button.server:SetJustifyH("LEFT")

        -- First seen
        button.firstSeen = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        button.firstSeen:SetPoint("LEFT", 235, 0)
        button.firstSeen:SetWidth(100)
        button.firstSeen:SetJustifyH("LEFT")

        -- Last seen
        button.lastSeen = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        button.lastSeen:SetPoint("LEFT", 340, 0)
        button.lastSeen:SetWidth(100)
        button.lastSeen:SetJustifyH("LEFT")

        -- Group type
        button.groupType = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        button.groupType:SetPoint("LEFT", 445, 0)
        button.groupType:SetWidth(100)
        button.groupType:SetJustifyH("LEFT")

        -- Current status
        button.status = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        button.status:SetPoint("LEFT", 550, 0)
        button.status:SetWidth(70)
        button.status:SetJustifyH("LEFT")

        -- Highlight on hover
        button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

        -- Store in table
        playerButtons[i] = button
    end

    -- Set up scroll frame
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, BUTTON_HEIGHT, function()
            PLUI:Debug("Scroll event triggered refresh")
            PLUI:RefreshList()
        end)
    end)

    -- Add OnShow handler to make sure list updates when frame becomes visible
    listFrame:SetScript("OnShow", function()
        PLUI:Debug("Frame OnShow triggered")
        -- Set default sort when opening
        currentSort = "lastSeen"
        sortDir = -1  -- Descending (most recent first)

        -- Update sort arrows to match initial sort
        PLUI:UpdateSortArrows()

        -- Force update of the scroll frame
        FauxScrollFrame_Update(scrollFrame, 9999, MAX_BUTTONS, BUTTON_HEIGHT)
        FauxScrollFrame_SetOffset(scrollFrame, 0)

        -- Refresh the list
        PLUI:RefreshList()
    end)

    -- Set up slash command
    SLASH_PRYLIST1 = "/prylist"
    SlashCmdList["PRYLIST"] = function(msg) self:ToggleUI() end

    -- Register with ESC key
    tinsert(UISpecialFrames, "PRY_PlayerListFrame")

    print("|cff33ff99PeaversRemembersYou|r: Player list initialized. Type /prylist to open.")
end

-- Create column headers with sort functionality
function PLUI:CreateColumnHeaders()
    local headers = {
        {text = "Player", width = 120, field = "name"},
        {text = "Server", width = 100, field = "server"},
        {text = "First Seen", width = 100, field = "firstSeen"},
        {text = "Last Seen", width = 100, field = "lastSeen"},
        {text = "Group Type", width = 100, field = "groupType"},
        {text = "Current", width = 70, field = "current"}
    }

    local xOffset = 5
    for i, header in ipairs(headers) do
        local headerButton = CreateFrame("Button", nil, listFrame)
        headerButton:SetSize(header.width, 20)
        headerButton:SetPoint("TOPLEFT", listFrame, "TOPLEFT", xOffset, -25)

        -- Create background
        local bg = headerButton:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)

        -- Create text
        local text = headerButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", 5, 0)
        text:SetText(header.text)

        -- Create sort arrow
        local arrow = headerButton:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(16, 16)
        arrow:SetPoint("RIGHT", -2, 0)
        arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
        arrow:Hide()

        -- Store sort field
        headerButton.field = header.field
        headerButton.arrow = arrow

        -- Set click handler
        headerButton:SetScript("OnClick", function()
            if currentSort == header.field then
                -- Toggle direction
                sortDir = sortDir * -1
            else
                -- New sort field
                currentSort = header.field
                sortDir = -1
            end

            -- Update arrows
            self:UpdateSortArrows()

            -- Refresh list with new sort
            self:RefreshList()
        end)

        -- Store for later
        headerButton.field = header.field

        xOffset = xOffset + header.width + 5
    end
end

-- Update sort arrows
function PLUI:UpdateSortArrows()
    -- Find and update all header buttons
    for i = 1, listFrame:GetNumChildren() do
        local child = select(i, listFrame:GetChildren())
        if child.field and child.arrow then
            if child.field == currentSort then
                child.arrow:Show()
                if sortDir == 1 then
                    child.arrow:SetTexCoord(0, 0.5, 0, 1) -- Up arrow
                else
                    child.arrow:SetTexCoord(0.5, 1, 0, 1) -- Down arrow
                end
            else
                child.arrow:Hide()
            end
        end
    end
end

-- Toggle UI visibility
function PLUI:ToggleUI()
    if listFrame:IsShown() then
        listFrame:Hide()
    else
        -- Set default sort when opening
        currentSort = "lastSeen"
        sortDir = -1  -- Descending (most recent first)

        -- Update sort arrows to match initial sort
        self:UpdateSortArrows()

        -- Refresh and show the list
        self:RefreshList()
        listFrame:Show()
    end
end

-- Format time for display
function PLUI:FormatTime(timestamp)
    if not timestamp then return "N/A" end

    local currentTime = time()
    local diff = currentTime - timestamp

    if diff < 60 then
        return "Just now"
    elseif diff < 3600 then
        local minutes = math.floor(diff / 60)
        return minutes .. (minutes == 1 and " min ago" or " mins ago")
    elseif diff < 86400 then
        local hours = math.floor(diff / 3600)
        return hours .. (hours == 1 and " hour ago" or " hours ago")
    else
        local days = math.floor(diff / 86400)
        if days < 30 then
            return days .. (days == 1 and " day ago" or " days ago")
        else
            return date("%m/%d/%y %H:%M", timestamp)
        end
    end
end

-- Format group type in Title Case
function PLUI:FormatGroupType(groupType)
    if not groupType then return "Unknown" end

    if groupType == "group" then
        return "Group"
    elseif groupType == "raid" then
        return "Raid"
    elseif groupType == "dungeon" then
        return "Dungeon"
    else
        return groupType:gsub("^%l", string.upper)
    end
end

-- Split player name and server
function PLUI:SplitNameServer(fullName)
    if not fullName then return "Unknown", "" end

    local dashPosition = string.find(fullName, "-")
    if dashPosition then
        local name = string.sub(fullName, 1, dashPosition - 1)
        local server = string.sub(fullName, dashPosition + 1)
        return name, server
    else
        return fullName, ""
    end
end

-- Safer comparing function that handles nil values
function PLUI:SafeCompare(a, b, field, direction)
    -- Handle nil values
    if a[field] == nil and b[field] == nil then
        return false -- They're equal
    elseif a[field] == nil then
        return direction == 1 -- nil comes first in ascending, last in descending
    elseif b[field] == nil then
        return direction ~= 1 -- nil comes last in ascending, first in descending
    end

    -- Both values exist, compare normally
    if direction == 1 then
        return a[field] < b[field]
    else
        return a[field] > b[field]
    end
end

-- Debug function
function PLUI:Debug(message)
    print("|cffff9900PRY Debug:|r " .. message)
end

-- Refresh player list
-- Refresh player list
function PLUI:RefreshList()
    if not listFrame:IsShown() then return end

    -- Debug the database content
    self:Debug("Refreshing player list, found " .. (PeaversRemembersYouDB and PeaversRemembersYouDB.players and self:TableCount(PeaversRemembersYouDB.players) or 0) .. " players")
    self:Debug("Current sort: " .. currentSort .. ", direction: " .. sortDir)

    -- Build player list
    local players = {}

    -- Make sure the database exists
    if PeaversRemembersYouDB and PeaversRemembersYouDB.players then
        for fullName, data in pairs(PeaversRemembersYouDB.players) do
            local name, server = self:SplitNameServer(fullName)
            local isCurrentlyInGroup = false

            -- Check if player is in current group
            if PRY.currentGroupMembers then
                isCurrentlyInGroup = PRY.currentGroupMembers[fullName] == true
            end

            table.insert(players, {
                fullName = fullName,
                name = name,
                server = server,
                firstSeen = data.firstSeen,
                lastSeen = data.lastSeen,
                groupType = data.groupType or "unknown",
                current = isCurrentlyInGroup
            })
        end
    end

    -- Update title with player count
    local totalPlayers = #players
    listFrame.TitleText:SetText("Players Remembered (Total: " .. totalPlayers .. ")")

    -- Debug the raw player list
    self:Debug("Built raw player list with " .. #players .. " entries")

    -- Debug first few entries for inspection
    if #players > 0 then
        self:Debug("First player: " .. players[1].fullName .. ", last seen: " .. (players[1].lastSeen or "nil"))
    end

    -- Sort list with nil-safe comparisons
    table.sort(players, function(a, b)
        if not a or not b then
            self:Debug("Nil entry in sort!")
            return false -- Handle nil entries
        end

        if currentSort == "name" then
            return self:SafeCompare(a, b, "name", sortDir)
        elseif currentSort == "server" then
            return self:SafeCompare(a, b, "server", sortDir)
        elseif currentSort == "firstSeen" then
            return self:SafeCompare(a, b, "firstSeen", sortDir)
        elseif currentSort == "lastSeen" then
            return self:SafeCompare(a, b, "lastSeen", sortDir)
        elseif currentSort == "groupType" then
            return self:SafeCompare(a, b, "groupType", sortDir)
        elseif currentSort == "current" then
            -- Sort by current status (true comes first if descending)
            if (a.current or false) ~= (b.current or false) then
                if sortDir == -1 then
                    return a.current or false
                else
                    return b.current or false
                end
            end
            -- Secondary sort by name
            return (a.name or "") < (b.name or "")
        end

        -- Default fallback
        self:Debug("Hit default fallback in sort!")
        return false
    end)

    -- Debug the player list after sorting
    self:Debug("Sorted player list with " .. #players .. " entries")
    if #players > 0 then
        self:Debug("First sorted player: " .. players[1].fullName)
    end

    -- Update FauxScrollFrame
    local numPlayers = #players
    FauxScrollFrame_Update(scrollFrame, numPlayers, MAX_BUTTONS, BUTTON_HEIGHT)

    -- Get offset
    local offset = FauxScrollFrame_GetOffset(scrollFrame)
    self:Debug("FauxScrollFrame offset: " .. offset)

    -- Debug visibility info
    self:Debug("Will display " .. math.min(MAX_BUTTONS, numPlayers) .. " players (offset " .. offset .. ")")

    -- Update visible buttons
    for i = 1, MAX_BUTTONS do
        local button = playerButtons[i]
        local index = i + offset

        if index <= numPlayers then
            local player = players[index]

            button.name:SetText(player.name or "Unknown")
            button.server:SetText(player.server or "")
            button.firstSeen:SetText(self:FormatTime(player.firstSeen))
            button.lastSeen:SetText(self:FormatTime(player.lastSeen))
            button.groupType:SetText(self:FormatGroupType(player.groupType))

            if player.current then
                button.status:SetText("In Group")
                button.status:SetTextColor(0, 1, 0)
            else
                button.status:SetText("Offline")
                button.status:SetTextColor(0.7, 0.7, 0.7)
            end

            self:Debug("Button " .. i .. " showing player: " .. player.fullName)
            button:Show()
        else
            button:Hide()
        end
    end
end

-- Count entries in a table
function PLUI:TableCount(t)
    local count = 0
    if t then
        for _ in pairs(t) do
            count = count + 1
        end
    end
    return count
end

-- Expose core table for external access
PRY.PlayerListUI = PLUI
