local SearchingForGroupManager = ZO_Object:Subclass()

function SearchingForGroupManager:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function SearchingForGroupManager:Initialize(control)
    self.control = control
    self.leaveQueueButton = control:GetNamedChild("LeaveQueueButton")
    
    self.statusLabel = control:GetNamedChild("Status")
    self.estimatedTimeLabel = control:GetNamedChild("EstimatedTime")
    self.actualTimeLabel = control:GetNamedChild("ActualTime")

    self.searching = IsCurrentlySearchingForGroup()
    self:Update()

    local function OnGroupingToolsStatusUpdate(searching)
        if self.searching ~= searching then
            self.searching = searching
            self:Update()

            if searching then
                PlaySound(SOUNDS.LFG_SEARCH_STARTED)
            else
                PlaySound(SOUNDS.LFG_SEARCH_FINISHED)
            end
        end
    end

    local function OnPlayerActivated()
        OnGroupingToolsStatusUpdate(IsCurrentlySearchingForGroup())
    end

    local lastUpdateS = 0
    local function OnUpdate(control, currentFrameTimeSeconds)
        if currentFrameTimeSeconds - lastUpdateS > 1 then
            self:Update()
            lastUpdateS = currentFrameTimeSeconds
        end
    end

    control:RegisterForEvent(EVENT_GROUPING_TOOLS_STATUS_UPDATE, function(event, ...) OnGroupingToolsStatusUpdate(...) end)
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function(event, ...) OnPlayerActivated(...) end)
    control:SetHandler("OnUpdate", OnUpdate)
end

do
    local STATUS_HEADER_TEXT = GetString(SI_LFG_QUEUE_STATUS)
    local ESTIMATED_HEADER_TEXT = GetString(SI_GAMEPAD_LFG_QUEUE_ESTIMATED)
    local ACTUAL_HEADER_TEXT = GetString(SI_GAMEPAD_LFG_QUEUE_ACTUAL)
    local NO_ICON = ""
    local LOADING_ICON = zo_iconFormat(ZO_TIMER_ICON_32, 24, 24)
    local STATUS_QUEUED_TEXT = zo_strformat(SI_ACTIVITY_QUEUE_STATUS_LABEL_FORMAT, STATUS_HEADER_TEXT, LOADING_ICON, GetString(SI_LFG_QUEUE_STATUS_QUEUED))
    local STATUS_NOT_QUEUED_TEXT = zo_strformat(SI_ACTIVITY_QUEUE_STATUS_LABEL_FORMAT, STATUS_HEADER_TEXT, NO_ICON, GetString(SI_LFG_QUEUE_STATUS_NOT_QUEUED))

    function SearchingForGroupManager:Update()
        self.leaveQueueButton:SetEnabled(self.searching)

        if self.searching then
            self.statusLabel:SetText(STATUS_QUEUED_TEXT)

            local searchStartTimeMs, searchEstimatedCompletionTimeMs = GetLFGSearchTimes()

            local timeSinceSearchStartMs = GetFrameTimeMilliseconds() - searchStartTimeMs
            local textStartTime = ZO_FormatTimeMilliseconds(timeSinceSearchStartMs, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            self.actualTimeLabel:SetText(zo_strformat(SI_ACTIVITY_QUEUE_STATUS_LABEL_FORMAT, ACTUAL_HEADER_TEXT, NO_ICON, textStartTime))

            if searchEstimatedCompletionTimeMs > 0 then
                local textEstimatedTime = ZO_GetSimplifiedTimeEstimateText(searchEstimatedCompletionTimeMs)
                self.estimatedTimeLabel:SetText(zo_strformat(SI_ACTIVITY_QUEUE_STATUS_LABEL_FORMAT, ESTIMATED_HEADER_TEXT, NO_ICON, textEstimatedTime))
            else
                self.estimatedTimeLabel:SetText("")
            end
        else
            self.statusLabel:SetText(STATUS_NOT_QUEUED_TEXT)
            self.actualTimeLabel:SetText("")
            self.estimatedTimeLabel:SetText("")
        end
    end
end

function ZO_SearchingForGroup_OnInitialized(self)
    SEARCHING_FOR_GROUP = SearchingForGroupManager:New(self)
end

function ZO_SearchingForGroupQueueButton_OnClicked(self, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        ZO_Dialogs_ShowDialog("LFG_LEAVE_QUEUE_CONFIRMATION")
    end
end