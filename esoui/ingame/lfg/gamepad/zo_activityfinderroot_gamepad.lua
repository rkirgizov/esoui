ZO_GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE_NAME = "gamepad_activity_finder_root"

--------------
--Initialize--
--------------

local ActivityFinderRoot_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ActivityFinderRoot_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ActivityFinderRoot_Gamepad:Initialize(control)
    local ACTIVATE_LIST_ON_SHOW = true
    GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE = ZO_Scene:New(ZO_GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE_NAME, SCENE_MANAGER)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_LIST_ON_SHOW, GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE)
    self:SetListsUseTriggerKeybinds(true)
    self:AddRolesMenuEntry()

    local function RefreshCategories()
        self:RefreshCategories()
    end

    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnLevelUpdate", RefreshCategories)
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, RefreshCategories)
end

function ActivityFinderRoot_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                    local targetData = self:GetMainList():GetTargetData()
                    if targetData then
                        local entryData = targetData.data
                        if entryData.isRoleSelector then
                            GAMEPAD_GROUP_ROLES_BAR:ToggleSelected()
                        else
                            SCENE_MANAGER:Push(entryData.sceneName)
                        end
                    end
                end,
            enabled = function()
                local targetData = self:GetMainList():GetTargetData()
                return targetData and targetData.enabled
            end
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ActivityFinderRoot_Gamepad:OnDeferredInitialize()
    self.headerData =
    {
        titleText = "Activity Finder",
    }

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ActivityFinderRoot_Gamepad:SetupList(list)
    local function CategoryEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        local isLevelLocked = false
        local lowestLevelLimit, lowestRankLimit
        if data.data.activityFinderObject then
            isLevelLocked, lowestLevelLimit, lowestRankLimit = data.data.activityFinderObject:GetLevelLockInfo()
        end
        enabled = enabled and not isLevelLocked and IsUnitSoloOrGroupLeader("player")
        data.enabled = enabled
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end

    list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplate", CategoryEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

    local function OnSelectedMenuEntry(_, selectedData)
        if selectedData.data.isRoleSelector then
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
            GAMEPAD_GROUP_ROLES_BAR:Activate()
        else
            GAMEPAD_GROUP_ROLES_BAR:Deactivate()
            self:RefreshTooltip(selectedData.data)
        end

        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end

    list:SetOnSelectedDataChangedCallback(OnSelectedMenuEntry)
    list:SetDefaultSelectedIndex(2) --Don't select roles by default
end

----------
--Update--
----------

function ActivityFinderRoot_Gamepad:PerformUpdate()
    --We must override this
end

function ActivityFinderRoot_Gamepad:OnShowing()
    local list = self:GetMainList()
    --Make sure we aren't interacting with the roles bar when we get there
    local targetData = list:GetTargetData()
    if targetData and targetData.data.isRoleSelector then
        local DONT_ANIMATE = false
        local ALLOW_EVEN_IF_DISABLED = true
        list:SetDefaultIndexSelected(DONT_ANIMATE, ALLOW_EVEN_IF_DISABLED)
        targetData = list:GetTargetData()
    else
        GAMEPAD_GROUP_ROLES_BAR:Deactivate()
    end
    list:RefreshVisible()
    self:RefreshTooltip(targetData.data)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

do
    local LOCK_TEXTURE = zo_iconFormat("EsoUI/Art/Miscellaneous/Gamepad/gp_icon_locked32.dds", "100%", "100%")
    local RANK_ICON = zo_iconFormat(GetGamepadVeteranRankIcon(), "100%", "100%")
    local NOT_LEADER_TEXT = zo_strformat(SI_FORMAT_ICON_TEXT, LOCK_TEXTURE, GetString(SI_ACTIVITY_FINDER_LOCKED_NOT_LEADER_TEXT))

    function ActivityFinderRoot_Gamepad:RefreshTooltip(data)
        if self.scene:IsShowing() and not data.isRoleSelector then
            local isLevelLocked, lowestLevelLimit, lowestRankLimit = data.activityFinderObject:GetLevelLockInfo()
            local lockedText
            if isLevelLocked then
                if lowestLevelLimit then
                    lockedText = zo_strformat(SI_ACTIVITY_FINDER_TOOLTIP_LEVEL_LOCK, LOCK_TEXTURE, lowestLevelLimit)
                elseif lowestRankLimit then
                    lockedText = zo_strformat(SI_ACTIVITY_FINDER_TOOLTIP_RANK_LOCK, LOCK_TEXTURE, RANK_ICON, lowestRankLimit)
                end
            else
                if not IsUnitSoloOrGroupLeader("player") then
                    lockedText = NOT_LEADER_TEXT
                end
            end

            GAMEPAD_TOOLTIPS:LayoutTitleAndMultiSectionDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, data.name, data.tooltipDescription, lockedText)
        end
    end
end

--Add an ethereal entry to interact with the roles
function ActivityFinderRoot_Gamepad:AddRolesMenuEntry()
    local entryData = ZO_GamepadEntryData:New("")
    entryData.data =
    {
        isRoleSelector = true,
    }

    local list = self:GetMainList()
    list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
end

function ActivityFinderRoot_Gamepad:AddCategory(categoryData)
    local entryData = ZO_GamepadEntryData:New(categoryData.name, categoryData.menuIcon)
    entryData.data = categoryData
    entryData:SetIconTintOnSelection(true)

    local list = self:GetMainList()
    list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    list:Commit()
end

function ActivityFinderRoot_Gamepad:RefreshCategories()
    local list = self:GetMainList()
    list:RefreshVisible()
    list:Commit()
end

function ZO_ActivityFinderRoot_Gamepad_OnInitialize(control)
    ZO_ACTIVITY_FINDER_ROOT_GAMEPAD = ActivityFinderRoot_Gamepad:New(control)
end