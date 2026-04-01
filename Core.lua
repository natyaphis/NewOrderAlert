-- NewOrderAlert - Core
-- Main event handling, detection, and notification logic

local addonName, addon = ...
local ADDON_TITLE = "NewOrderAlert"
local SAVED_VARIABLES_NAME = "NewOrderAlertDB"

-- ============================================================================
-- Constants and Defaults
-- ============================================================================

local THROTTLE_SECONDS = 3
local LOCALE = GetLocale and GetLocale() or "enUS"
local ORDER_MESSAGE_PATTERNS = {
    enUS = {
        personal = { "Crafting Order", "received", "Personal" },
        guild = { "Crafting Order", "received", "Guild" },
    },
    zhCN = {
        personal = { "制作订单", "个人" },
        guild = { "制作订单", "公会" },
    },
    zhTW = {
        personal = { "製作訂單", "個人" },
        guild = { "製作訂單", "公會" },
    },
}

local DEFAULTS = {
    soundEnabled = true,
    soundIndex = 1,
    soundChannel = "Master",
    playInBackground = true,

    textEnabled = true,
    textScale = 1.0,
    textColor = { r = 1, g = 1, b = 0 },
    textOffsetX = 0,
    textOffsetY = 200,
    displayDuration = 3,
    orderMessage = "New Personal Crafting Order!",
    chatEnabled = false,

    suppressInCombat = true,
    suppressInInstance = true,
}

-- ============================================================================
-- Local Variables
-- ============================================================================

local db
local lastNotificationTime = 0
local notificationFrame

-- ============================================================================
-- Helper Functions
-- ============================================================================

local function MessageContainsAll(message, parts)
    if type(message) ~= "string" or type(parts) ~= "table" then
        return false
    end

    for _, part in ipairs(parts) do
        if not message:find(part, 1, true) then
            return false
        end
    end

    return true
end

local function GetOrderMessageType(message)
    local patterns = ORDER_MESSAGE_PATTERNS[LOCALE] or ORDER_MESSAGE_PATTERNS.enUS

    if patterns and MessageContainsAll(message, patterns.personal) then
        return "personal"
    end

    if patterns and MessageContainsAll(message, patterns.guild) then
        return "guild"
    end

    if LOCALE ~= "enUS" then
        if MessageContainsAll(message, ORDER_MESSAGE_PATTERNS.enUS.personal) then
            return "personal"
        end
        if MessageContainsAll(message, ORDER_MESSAGE_PATTERNS.enUS.guild) then
            return "guild"
        end
    end

    return nil
end

local function CanNotify()
    local now = GetTime()
    if now - lastNotificationTime < THROTTLE_SECONDS then
        return false
    end
    lastNotificationTime = now
    return true
end

local function IsSuppressed()
    if db.suppressInCombat and UnitAffectingCombat("player") then
        return true
    end

    if db.suppressInInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType ~= "none" then
            return true
        end
    end

    return false
end

local function PlayNotificationSound()
    if not db.soundEnabled then return end

    local soundData = addon.SOUND_LIST[db.soundIndex]
    if soundData then
        if soundData.soundKitID then
            -- Use PlaySound for SoundKitIDs
            PlaySound(soundData.soundKitID, db.soundChannel)
        elseif soundData.fileDataID then
            -- Use PlaySoundFile for FileDataIDs
            PlaySoundFile(soundData.fileDataID, db.soundChannel)
        end
    end
end

local function ShowNotification(message)
    if not db.textEnabled then return end

    local frame = notificationFrame
    if not frame then return end

    -- Update text content
    frame.text:SetText(message)

    -- Cancel any existing fade animations
    UIFrameFadeRemoveFrame(frame)

    -- Fade in
    frame:Show()
    UIFrameFadeIn(frame, 0.5, 0, 1)

    -- Schedule fade out
    local holdTime = math.max(db.displayDuration - 1.0, 1.0)
    C_Timer.After(0.5 + holdTime, function()
        UIFrameFadeOut(frame, 0.5, 1, 0)
        C_Timer.After(0.5, function()
            frame:Hide()
        end)
    end)
end

local function ShowChatNotification(message)
    if not db.chatEnabled then return end

    print("|cff00ff00" .. ADDON_TITLE .. ":|r " .. message)
end

local function CreateNotificationFrame()
    local frame = CreateFrame("Frame", "NewOrderAlertFrame", UIParent)
    frame:SetSize(400, 50)
    frame:SetPoint("CENTER", UIParent, "CENTER", db.textOffsetX, db.textOffsetY)
    frame:SetFrameStrata("HIGH")
    frame:Hide()

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    text:SetTextColor(db.textColor.r, db.textColor.g, db.textColor.b)
    frame.text = text

    return frame
end

local function UpdateNotificationFramePosition()
    if notificationFrame then
        notificationFrame:ClearAllPoints()
        notificationFrame:SetPoint("CENTER", UIParent, "CENTER", db.textOffsetX, db.textOffsetY)
    end
end

local function UpdateNotificationFrameScale()
    if notificationFrame and notificationFrame.text then
        notificationFrame.text:SetScale(db.textScale)
    end
end

local function UpdateNotificationFrameColor()
    if notificationFrame and notificationFrame.text then
        notificationFrame.text:SetTextColor(db.textColor.r, db.textColor.g, db.textColor.b)
    end
end

local function ApplyBackgroundSoundSetting()
    if db.playInBackground then
        SetCVar("Sound_EnableSoundWhenGameIsInBG", "1")
    else
        -- Restore original value
        if db.originalBGSoundCVar then
            SetCVar("Sound_EnableSoundWhenGameIsInBG", db.originalBGSoundCVar)
        else
            SetCVar("Sound_EnableSoundWhenGameIsInBG", "0")
        end
    end
end

-- ============================================================================
-- Event Handlers
-- ============================================================================

local function OnSystemMessage(self, event, message, ...)
    local orderType = GetOrderMessageType(message)
    if not orderType then return end

    if IsSuppressed() then return end
    if not CanNotify() then return end

    PlayNotificationSound()
    ShowNotification(db.orderMessage)
    ShowChatNotification(db.orderMessage)
end

local function OnLogin()
    -- Initialize SavedVariables
    local saved = _G[SAVED_VARIABLES_NAME]
    if not saved then
        saved = {}
    end

    _G[SAVED_VARIABLES_NAME] = saved
    db = saved

    -- Migrate old personalMessage to orderMessage
    if db.personalMessage and not db.orderMessage then
        db.orderMessage = db.personalMessage
    end
    -- Clean up old guild message
    db.personalMessage = nil
    db.guildMessage = nil

    -- Apply defaults for missing values
    for key, value in pairs(DEFAULTS) do
        if db[key] == nil then
            if type(value) == "table" then
                db[key] = {}
                for k, v in pairs(value) do
                    db[key][k] = v
                end
            else
                db[key] = value
            end
        end
    end

    -- Ensure textColor table is complete
    if db.textColor then
        if db.textColor.r == nil then db.textColor.r = 1 end
        if db.textColor.g == nil then db.textColor.g = 1 end
        if db.textColor.b == nil then db.textColor.b = 0 end
    end

    -- Store original background sound CVar if not already stored
    if db.originalBGSoundCVar == nil then
        db.originalBGSoundCVar = GetCVar("Sound_EnableSoundWhenGameIsInBG")
    end

    -- Apply background sound setting
    ApplyBackgroundSoundSetting()

    -- Create notification frame
    notificationFrame = CreateNotificationFrame()

    -- Make functions available to other modules
    addon.db = db
    addon.PlayNotificationSound = PlayNotificationSound
    addon.ShowNotification = ShowNotification
    addon.ShowChatNotification = ShowChatNotification
    addon.UpdateNotificationFramePosition = UpdateNotificationFramePosition
    addon.UpdateNotificationFrameScale = UpdateNotificationFrameScale
    addon.UpdateNotificationFrameColor = UpdateNotificationFrameColor
    addon.ApplyBackgroundSoundSetting = ApplyBackgroundSoundSetting
    addon.GetOrderMessageType = GetOrderMessageType

    print("|cff00ff00" .. ADDON_TITLE .. "|r v1.0.0 loaded. Type |cff00ff00/noa|r for options.")
end

local function OnLogout()
    -- Optionally restore CVar on logout (commented out for now)
    -- This allows the setting to persist across sessions
    -- Uncomment if you want to restore the original value
    -- if db.originalBGSoundCVar then
    --     SetCVar("Sound_EnableSoundWhenGameIsInBG", db.originalBGSoundCVar)
    -- end
end

-- ============================================================================
-- Initialization
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        OnLogin()
    elseif event == "CHAT_MSG_SYSTEM" then
        OnSystemMessage(self, event, ...)
    end
end)
