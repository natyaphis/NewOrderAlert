local addonName, addon = ...
if GetLocale() ~= "zhCN" then
    return
end

local L = addon.L

L["ADDON_TITLE"] = "NewOrderAlert"
L["ADDON_NOTES"] = "在收到新的个人制造订单时提供可自定义声音和视觉提醒。"
L["LOADED_MESSAGE"] = "|cff00ff00%s|r v%s 已加载。输入 |cff00ff00/noa|r 打开设置。"
L["PANEL_SUBTITLE"] = "|cffaaaaaa作者 %s  •  v%s|r"
L["CHAT_PREFIX"] = "|cff00ff00%s:|r %s"
L["MSG_SAVED"] = "提醒文本已保存。"
L["MSG_TESTING"] = "正在测试订单提醒"
L["DEFAULT_ORDER_MESSAGE"] = "新的个人制造订单！"

L["SECTION_SOUND"] = "|cffffff00声音|r"
L["SECTION_DISPLAY"] = "|cffffff00显示|r"
L["SECTION_SUPPRESSION"] = "|cffffff00抑制|r"

L["ENABLE_SOUND"] = "启用声音提醒"
L["PLAY_IN_BACKGROUND"] = "游戏在后台时也播放声音"
L["SOUND"] = "声音"
L["CHANNEL"] = "频道"
L["TEST_NOTIFICATION"] = "测试提醒"
L["ENABLE_TEXT"] = "启用屏幕文字"
L["ENABLE_CHAT"] = "启用聊天消息"
L["SCALE"] = "缩放"
L["DISPLAY_DURATION"] = "显示时长（秒）"
L["X_POSITION"] = "X 位置"
L["Y_POSITION"] = "Y 位置"
L["FONT_COLOR"] = "字体颜色"
L["NOTIFICATION_MESSAGE"] = "提醒文本"
L["SAVE"] = "保存"
L["SUPPRESS_COMBAT"] = "战斗中不提醒"
L["SUPPRESS_INSTANCE"] = "副本/团队中不提醒"

L["SCALE_FORMAT"] = "缩放: %.1f"
L["DISPLAY_DURATION_FORMAT"] = "显示时长: %d 秒"
L["POSITION_FORMAT"] = "%s: %d"

L["PERSONAL_ORDER_PATTERNS"] = { "制造订单", "个人" }
