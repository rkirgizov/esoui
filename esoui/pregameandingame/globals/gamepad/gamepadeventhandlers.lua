EVENT_MANAGER:RegisterForEvent("SharedDialogs", EVENT_CONTROLLER_DISCONNECTED, function() ZO_ControllerDisconnect_ShowPopup() end)
EVENT_MANAGER:RegisterForEvent("SharedDialogs", EVENT_CONTROLLER_CONNECTED, function() ZO_ControllerDisconnect_DismissPopup() end)