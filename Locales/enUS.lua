local addonName, addon = ...
local L = addon.L

L["ADDON_TITLE"] = "NewOrderAlert"
L["ADDON_NOTES"] = "Notifies crafters when they receive Personal Crafting Orders with customizable sound and visual alerts."
L["LOADED_MESSAGE"] = "|cff00ff00%s|r v%s loaded. Type |cff00ff00/noa|r for options."
L["PANEL_SUBTITLE"] = "|cffaaaaaaby %s  •  v%s|r"
L["CHAT_PREFIX"] = "|cff00ff00%s:|r %s"
L["MSG_SAVED"] = "Message saved."
L["MSG_TESTING"] = "Testing order notification"
L["DEFAULT_ORDER_MESSAGE"] = "<New Order!>"

L["ENABLE_SOUND"] = "Enable Sound Notifications"
L["PLAY_IN_BACKGROUND"] = "Play in Background"
L["SOUND"] = "Sound"
L["CHANNEL"] = "Channel"
L["TEST_NOTIFICATION"] = "Test Notification"
L["ENABLE_TEXT"] = "Enable On-Screen Text"
L["TEST_TEXT"] = "Test Text"
L["SCALE"] = "Font Size"
L["DISPLAY_DURATION"] = "Display Duration (sec)"
L["X_POSITION"] = "X Position"
L["Y_POSITION"] = "Y Position"
L["FONT_COLOR"] = "Font Color"
L["FONT_FACE"] = "Font"
L["NOTIFICATION_MESSAGE"] = "Notification Message"
L["SAVE"] = "Save"
L["SUPPRESS_COMBAT"] = "Suppress notifications in combat"
L["SUPPRESS_INSTANCE"] = "Suppress notifications in instances/raids"

L["SCALE_FORMAT"] = "Font Size: %d"
L["DISPLAY_DURATION_FORMAT"] = "Display Duration: %d sec"
L["POSITION_FORMAT"] = "%s: %d"

L["PERSONAL_ORDER_PATTERNS"] = { "Crafting Order", "received", "Personal" }
