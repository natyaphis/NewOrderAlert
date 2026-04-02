local addonName, addon = ...
local L = addon.L
local ADDON_TITLE = L["ADDON_TITLE"]
local SAVED_VARIABLES_NAME = "NewOrderAlertDB"
local VERSION = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version") or "unknown"

local THROTTLE_SECONDS = 3

local DEFAULTS = {
    soundEnabled = true,
    soundIndex = 1,
    soundChannel = "Master",
    playInBackground = true,
    textEnabled = true,
    fontSize = 32,
    fontKey = "Friz Quadrata",
    textColor = { r = 1, g = 1, b = 0 },
    textOffsetX = 0,
    textOffsetY = 200,
    displayDuration = 3,
    orderMessage = L["DEFAULT_ORDER_MESSAGE"],
    suppressInCombat = true,
    suppressInInstance = true,
}

local db
local lastNotificationTime = 0
local notificationFrame
local notificationController = {
    mode = "hidden",
}

local function CreateFontRegistry()
    local options = {}
    local lookup = {}

    local function AddFont(label, path)
        if type(label) ~= "string" or label == "" or type(path) ~= "string" or path == "" or lookup[label] then
            return
        end

        local option = {
            key = label,
            label = label,
            path = path,
        }
        table.insert(options, option)
        lookup[label] = option
    end

    return options, lookup, AddFont
end

local function CollectBuiltinFonts(addFont)
    addFont("Friz Quadrata", "Fonts\\FRIZQT__.TTF")
    addFont("Arial Narrow", "Fonts\\ARIALN.TTF")
    addFont("Morpheus", "Fonts\\MORPHEUS.TTF")
    addFont("Skurri", "Fonts\\skurri.ttf")
end

local function CollectSharedMediaFonts(addFont)
    local LSM = _G.LibStub and _G.LibStub("LibSharedMedia-3.0", true)
    if not (LSM and LSM.HashTable) then
        return
    end

    local fonts = LSM:HashTable("font")
    for name, path in pairs(fonts or {}) do
        addFont(name, path)
    end
end

local function CollectElvUIFonts(addFont)
    local E = _G.ElvUI and unpack(_G.ElvUI)
    if E and E.media then
        addFont("ElvUI Normal", E.media.normFont)
        addFont("ElvUI Combat", E.media.combatFont)
    end
end

local function BuildFontOptions()
    local options, lookup, addFont = CreateFontRegistry()

    CollectBuiltinFonts(addFont)
    CollectSharedMediaFonts(addFont)
    CollectElvUIFonts(addFont)

    table.sort(options, function(a, b)
        return a.label < b.label
    end)

    addon.FONT_OPTIONS = options
    addon.FONT_LOOKUP = lookup
end

local function GetNotificationFont()
    local _, _, fontFlags = GameFontNormalLarge:GetFont()
    local selectedPath = addon.FONT_LOOKUP and addon.FONT_LOOKUP[db.fontKey] and addon.FONT_LOOKUP[db.fontKey].path

    return selectedPath or "Fonts\\FRIZQT__.TTF", fontFlags
end

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

local function IsPersonalOrderMessage(message)
    return MessageContainsAll(message, L["PERSONAL_ORDER_PATTERNS"])
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
    if not db.soundEnabled then
        return
    end

    local soundData = addon.SOUND_LIST[db.soundIndex]
    if not soundData then
        return
    end

    if soundData.soundKitID then
        PlaySound(soundData.soundKitID, db.soundChannel)
    elseif soundData.fileDataID then
        PlaySoundFile(soundData.fileDataID, db.soundChannel)
    end
end

local function ShowNotification(message)
    if not db.textEnabled then
        return
    end

    local frame = notificationFrame
    if not frame then
        return
    end

    notificationController.mode = "transient"
    frame.text:SetText(message)
    UIFrameFadeRemoveFrame(frame)
    frame:Show()
    UIFrameFadeIn(frame, 0.5, 0, 1)

    local holdTime = math.max(db.displayDuration - 1.0, 1.0)
    C_Timer.After(0.5 + holdTime, function()
        if notificationController.mode ~= "transient" then
            return
        end

        UIFrameFadeOut(frame, 0.5, 1, 0)
        C_Timer.After(0.5, function()
            if notificationController.mode ~= "transient" then
                return
            end
            notificationController.mode = "hidden"
            frame:Hide()
        end)
    end)
end

local function HideNotification()
    if not notificationFrame then
        return
    end

    notificationController.mode = "hidden"
    UIFrameFadeRemoveFrame(notificationFrame)
    notificationFrame:Hide()
end

local function ShowTestNotification()
    if not db.textEnabled or not notificationFrame then
        return
    end

    notificationController.mode = "test"
    notificationFrame.text:SetText(db.orderMessage)
    UIFrameFadeRemoveFrame(notificationFrame)
    notificationFrame:SetAlpha(1)
    notificationFrame:Show()
end

local function ToggleTestNotification()
    if notificationController.mode == "test" then
        HideNotification()
        return false
    end

    ShowTestNotification()
    return true
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
    if not notificationFrame then
        return
    end

    notificationFrame:ClearAllPoints()
    notificationFrame:SetPoint("CENTER", UIParent, "CENTER", db.textOffsetX, db.textOffsetY)
end

local function UpdateNotificationFrameFont()
    if notificationFrame and notificationFrame.text then
        local fontName, fontFlags = GetNotificationFont()
        notificationFrame.text:SetFont(fontName, db.fontSize, fontFlags)
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
        return
    end

    if db.originalBGSoundCVar then
        SetCVar("Sound_EnableSoundWhenGameIsInBG", db.originalBGSoundCVar)
    else
        SetCVar("Sound_EnableSoundWhenGameIsInBG", "0")
    end
end

local function OnSystemMessage(self, event, message, ...)
    if not IsPersonalOrderMessage(message) then
        return
    end

    if IsSuppressed() or not CanNotify() then
        return
    end

    PlayNotificationSound()
    ShowNotification(db.orderMessage)
end

local function OnLogin()
    local saved = _G[SAVED_VARIABLES_NAME]
    if not saved then
        saved = {}
    end

    _G[SAVED_VARIABLES_NAME] = saved
    db = saved

    if db.personalMessage and not db.orderMessage then
        db.orderMessage = db.personalMessage
    end
    db.personalMessage = nil

    if db.fontSize == nil and db.textScale ~= nil then
        db.fontSize = math.max(5, math.min(100, math.floor((db.textScale * 32) + 0.5)))
    end
    db.textScale = nil
    db.chatEnabled = nil
    if db.fontKey == "Frizqt" then db.fontKey = "Friz Quadrata" end
    if db.fontKey == "Arial" then db.fontKey = "Arial Narrow" end
    if db.fontKey == "Morpheus" then db.fontKey = "Morpheus" end
    if db.fontKey == "Skurri" then db.fontKey = "Skurri" end

    for key, value in pairs(DEFAULTS) do
        if db[key] == nil then
            if type(value) == "table" then
                db[key] = {}
                for childKey, childValue in pairs(value) do
                    db[key][childKey] = childValue
                end
            else
                db[key] = value
            end
        end
    end

    if db.textColor then
        if db.textColor.r == nil then db.textColor.r = 1 end
        if db.textColor.g == nil then db.textColor.g = 1 end
        if db.textColor.b == nil then db.textColor.b = 0 end
    end

    if db.originalBGSoundCVar == nil then
        db.originalBGSoundCVar = GetCVar("Sound_EnableSoundWhenGameIsInBG")
    end

    BuildFontOptions()
    if not (addon.FONT_LOOKUP and addon.FONT_LOOKUP[db.fontKey]) then
        db.fontKey = DEFAULTS.fontKey
    end

    ApplyBackgroundSoundSetting()
    notificationFrame = CreateNotificationFrame()
    UpdateNotificationFrameFont()

    addon.db = db
    addon.HideNotification = HideNotification
    addon.PlayNotificationSound = PlayNotificationSound
    addon.ShowNotification = ShowNotification
    addon.ShowTestNotification = ShowTestNotification
    addon.ToggleTestNotification = ToggleTestNotification
    addon.UpdateNotificationFramePosition = UpdateNotificationFramePosition
    addon.UpdateNotificationFrameFont = UpdateNotificationFrameFont
    addon.UpdateNotificationFrameColor = UpdateNotificationFrameColor
    addon.ApplyBackgroundSoundSetting = ApplyBackgroundSoundSetting
    addon.IsPersonalOrderMessage = IsPersonalOrderMessage

    print(string.format(L["LOADED_MESSAGE"], ADDON_TITLE, VERSION))
end

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
