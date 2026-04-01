local addonName, addon = ...
local L = addon.L
local ADDON_TITLE = L["ADDON_TITLE"]
local VERSION = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version") or "unknown"

local db

local function CreateCheckbox(parent, label, tooltip)
    local check = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    check.Text:SetText(label)
    check:SetEnabled(true)
    if tooltip then
        check.tooltipText = tooltip
    end
    return check
end

local function CreateSlider(parent, label, minVal, maxVal, step)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetEnabled(true)
    slider.Text:SetText(label)
    slider.Low:SetText(minVal)
    slider.High:SetText(maxVal)
    slider:SetValue((minVal + maxVal) / 2)
    return slider
end

local function CreateDropdown(parent, label, width)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")

    local labelText = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 20, 3)
    labelText:SetText(label)
    dropdown.label = labelText

    return dropdown
end

local function CreateEditBox(parent, width)
    local editbox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editbox:SetSize(width or 300, 20)
    editbox:SetAutoFocus(false)
    editbox:SetEnabled(true)
    editbox:SetFontObject("GameFontHighlight")
    editbox:SetJustifyH("LEFT")
    return editbox
end

local function CreateColorPicker(parent, label)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(24, 24)
    button:SetEnabled(true)

    local border = button:CreateTexture(nil, "BORDER")
    border:SetAllPoints(button)
    border:SetColorTexture(0.3, 0.3, 0.3, 1)

    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("TOPLEFT", 2, -2)
    texture:SetPoint("BOTTOMRIGHT", -2, 2)
    texture:SetColorTexture(1, 1, 0)
    button.texture = texture

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetColorTexture(1, 1, 1, 0.3)

    local labelText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("LEFT", button, "RIGHT", 8, 0)
    labelText:SetText(label)
    button.label = labelText

    return button
end

local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "NewOrderAlertOptionsPanel", UIParent)
    panel.name = ADDON_TITLE

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(ADDON_TITLE)

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    subtitle:SetText(string.format(L["PANEL_SUBTITLE"], "Nathan", VERSION))

    local yOffset = -52

    local divider1 = panel:CreateTexture(nil, "ARTWORK")
    divider1:SetColorTexture(0.4, 0.4, 0.4, 0.6)
    divider1:SetSize(570, 1)
    divider1:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 8

    local soundHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    soundHeader:SetPoint("TOPLEFT", 16, yOffset)
    soundHeader:SetText(L["SECTION_SOUND"])
    soundHeader:SetTextScale(1.15)
    yOffset = yOffset - 22

    local enableSound = CreateCheckbox(panel, L["ENABLE_SOUND"])
    enableSound:SetPoint("TOPLEFT", 16, yOffset)

    local playInBackground = CreateCheckbox(panel, L["PLAY_IN_BACKGROUND"])
    playInBackground:SetPoint("TOPLEFT", 250, yOffset)
    yOffset = yOffset - 40

    local soundDropdown = CreateDropdown(panel, L["SOUND"], 150)
    soundDropdown:SetPoint("TOPLEFT", 16, yOffset)

    local channelDropdown = CreateDropdown(panel, L["CHANNEL"], 100)
    channelDropdown:SetPoint("TOPLEFT", 250, yOffset)
    yOffset = yOffset - 35

    local testButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testButton:SetSize(140, 24)
    testButton:SetPoint("TOPLEFT", 16, yOffset)
    testButton:SetText(L["TEST_NOTIFICATION"])
    testButton:SetEnabled(true)
    yOffset = yOffset - 32

    local divider2 = panel:CreateTexture(nil, "ARTWORK")
    divider2:SetColorTexture(0.4, 0.4, 0.4, 0.6)
    divider2:SetSize(570, 1)
    divider2:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 8

    local displayHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    displayHeader:SetPoint("TOPLEFT", 16, yOffset)
    displayHeader:SetText(L["SECTION_DISPLAY"])
    displayHeader:SetTextScale(1.15)
    yOffset = yOffset - 22

    local enableText = CreateCheckbox(panel, L["ENABLE_TEXT"])
    enableText:SetPoint("TOPLEFT", 16, yOffset)

    local enableChat = CreateCheckbox(panel, L["ENABLE_CHAT"])
    enableChat:SetPoint("TOPLEFT", 250, yOffset)
    yOffset = yOffset - 40

    local scaleSlider = CreateSlider(panel, L["SCALE"], 0.5, 2.0, 0.1)
    scaleSlider:SetPoint("TOPLEFT", 16, yOffset)
    scaleSlider:SetWidth(180)

    local durationSlider = CreateSlider(panel, L["DISPLAY_DURATION"], 2, 10, 1)
    durationSlider:SetPoint("TOPLEFT", 250, yOffset)
    durationSlider:SetWidth(180)
    yOffset = yOffset - 35

    local xOffsetSlider = CreateSlider(panel, L["X_POSITION"], -960, 960, 5)
    xOffsetSlider:SetPoint("TOPLEFT", 16, yOffset)
    xOffsetSlider:SetWidth(130)

    local xOffsetBox = CreateEditBox(panel, 45)
    xOffsetBox:SetPoint("LEFT", xOffsetSlider, "RIGHT", 8, 0)
    xOffsetBox:SetMaxLetters(5)

    local yOffsetSlider = CreateSlider(panel, L["Y_POSITION"], -500, 500, 5)
    yOffsetSlider:SetPoint("TOPLEFT", 250, yOffset)
    yOffsetSlider:SetWidth(130)

    local yOffsetBox = CreateEditBox(panel, 45)
    yOffsetBox:SetPoint("LEFT", yOffsetSlider, "RIGHT", 8, 0)
    yOffsetBox:SetMaxLetters(5)

    yOffset = yOffset - 35

    local colorPicker = CreateColorPicker(panel, L["FONT_COLOR"])
    colorPicker:SetPoint("TOPLEFT", 16, yOffset)
    yOffset = yOffset - 30

    local orderLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    orderLabel:SetPoint("TOPLEFT", 16, yOffset)
    orderLabel:SetText(L["NOTIFICATION_MESSAGE"])
    yOffset = yOffset - 20

    local orderMessage = CreateEditBox(panel, 360)
    orderMessage:SetPoint("TOPLEFT", 16, yOffset)

    local orderSaveButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    orderSaveButton:SetSize(55, 22)
    orderSaveButton:SetPoint("LEFT", orderMessage, "RIGHT", 6, 0)
    orderSaveButton:SetText(L["SAVE"])
    orderSaveButton:SetEnabled(true)

    yOffset = yOffset - 30

    local divider3 = panel:CreateTexture(nil, "ARTWORK")
    divider3:SetColorTexture(0.4, 0.4, 0.4, 0.6)
    divider3:SetSize(570, 1)
    divider3:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 8

    local suppressHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    suppressHeader:SetPoint("TOPLEFT", 16, yOffset)
    suppressHeader:SetText(L["SECTION_SUPPRESSION"])
    suppressHeader:SetTextScale(1.15)
    yOffset = yOffset - 22

    local suppressCombat = CreateCheckbox(panel, L["SUPPRESS_COMBAT"])
    suppressCombat:SetPoint("TOPLEFT", 16, yOffset)
    yOffset = yOffset - 24

    local suppressInstance = CreateCheckbox(panel, L["SUPPRESS_INSTANCE"])
    suppressInstance:SetPoint("TOPLEFT", 16, yOffset)

    local function RefreshPanel()
        if not db then
            db = addon.db
        end
        if not db then
            return
        end

        enableSound:SetChecked(db.soundEnabled)
        playInBackground:SetChecked(db.playInBackground)

        if addon.SOUND_LIST and addon.SOUND_LIST[db.soundIndex] then
            UIDropDownMenu_SetSelectedValue(soundDropdown, db.soundIndex)
            UIDropDownMenu_SetText(soundDropdown, addon.SOUND_LIST[db.soundIndex].label)
        end
        UIDropDownMenu_SetSelectedValue(channelDropdown, db.soundChannel)
        UIDropDownMenu_SetText(channelDropdown, db.soundChannel)

        enableText:SetChecked(db.textEnabled)
        enableChat:SetChecked(db.chatEnabled)
        scaleSlider:SetValue(db.textScale)
        scaleSlider.Text:SetText(string.format(L["SCALE_FORMAT"], db.textScale))
        xOffsetSlider:SetValue(db.textOffsetX)
        xOffsetSlider.Text:SetText(string.format(L["POSITION_FORMAT"], L["X_POSITION"], db.textOffsetX))
        xOffsetBox:SetText(tostring(db.textOffsetX))
        yOffsetSlider:SetValue(db.textOffsetY)
        yOffsetSlider.Text:SetText(string.format(L["POSITION_FORMAT"], L["Y_POSITION"], db.textOffsetY))
        yOffsetBox:SetText(tostring(db.textOffsetY))
        durationSlider:SetValue(db.displayDuration)
        durationSlider.Text:SetText(string.format(L["DISPLAY_DURATION_FORMAT"], db.displayDuration))

        if db.orderMessage then
            orderMessage:SetText(db.orderMessage)
            orderMessage:SetCursorPosition(0)
        end

        suppressCombat:SetChecked(db.suppressInCombat)
        suppressInstance:SetChecked(db.suppressInInstance)
        colorPicker.texture:SetColorTexture(db.textColor.r, db.textColor.g, db.textColor.b)
    end

    panel.refresh = RefreshPanel
    panel:SetScript("OnShow", RefreshPanel)

    enableSound:SetScript("OnClick", function(self)
        db.soundEnabled = self:GetChecked()
    end)

    UIDropDownMenu_Initialize(soundDropdown, function(self, level)
        for i, soundData in ipairs(addon.SOUND_LIST) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = soundData.label
            info.value = i
            info.func = function()
                db.soundIndex = i
                UIDropDownMenu_SetSelectedValue(soundDropdown, i)
                UIDropDownMenu_SetText(soundDropdown, soundData.label)
            end
            info.checked = (db.soundIndex == i)
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetWidth(soundDropdown, 150)
    UIDropDownMenu_SetButtonWidth(soundDropdown, 124)
    UIDropDownMenu_JustifyText(soundDropdown, "LEFT")

    UIDropDownMenu_Initialize(channelDropdown, function(self, level)
        local channels = { "Master", "SFX" }
        for _, channel in ipairs(channels) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = channel
            info.value = channel
            info.func = function()
                db.soundChannel = channel
                UIDropDownMenu_SetSelectedValue(channelDropdown, channel)
                UIDropDownMenu_SetText(channelDropdown, channel)
            end
            info.checked = (db.soundChannel == channel)
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetWidth(channelDropdown, 100)
    UIDropDownMenu_SetButtonWidth(channelDropdown, 74)
    UIDropDownMenu_JustifyText(channelDropdown, "LEFT")

    playInBackground:SetScript("OnClick", function(self)
        db.playInBackground = self:GetChecked()
        addon.ApplyBackgroundSoundSetting()
    end)

    testButton:SetScript("OnClick", function()
        addon.PlayNotificationSound()
        addon.ShowNotification(db.orderMessage)
        addon.ShowChatNotification(db.orderMessage)
    end)

    enableText:SetScript("OnClick", function(self)
        db.textEnabled = self:GetChecked()
    end)

    enableChat:SetScript("OnClick", function(self)
        db.chatEnabled = self:GetChecked()
    end)

    scaleSlider:SetScript("OnValueChanged", function(self, value)
        db.textScale = value
        self.Text:SetText(string.format(L["SCALE_FORMAT"], value))
        addon.UpdateNotificationFrameScale()
    end)

    xOffsetSlider:SetScript("OnValueChanged", function(self, value)
        db.textOffsetX = value
        self.Text:SetText(string.format(L["POSITION_FORMAT"], L["X_POSITION"], value))
        xOffsetBox:SetText(tostring(math.floor(value)))
        addon.UpdateNotificationFramePosition()
    end)

    xOffsetBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or 0
        value = math.max(-960, math.min(960, value))
        db.textOffsetX = value
        xOffsetSlider:SetValue(value)
        self:ClearFocus()
        addon.UpdateNotificationFramePosition()
    end)
    xOffsetBox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(db.textOffsetX))
        self:ClearFocus()
    end)

    yOffsetSlider:SetScript("OnValueChanged", function(self, value)
        db.textOffsetY = value
        self.Text:SetText(string.format(L["POSITION_FORMAT"], L["Y_POSITION"], value))
        yOffsetBox:SetText(tostring(math.floor(value)))
        addon.UpdateNotificationFramePosition()
    end)

    yOffsetBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or 0
        value = math.max(-500, math.min(500, value))
        db.textOffsetY = value
        yOffsetSlider:SetValue(value)
        self:ClearFocus()
        addon.UpdateNotificationFramePosition()
    end)
    yOffsetBox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(db.textOffsetY))
        self:ClearFocus()
    end)

    durationSlider:SetScript("OnValueChanged", function(self, value)
        db.displayDuration = value
        self.Text:SetText(string.format(L["DISPLAY_DURATION_FORMAT"], value))
    end)

    colorPicker:SetScript("OnClick", function(self)
        local info = {
            r = db.textColor.r,
            g = db.textColor.g,
            b = db.textColor.b,
            hasOpacity = false,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                db.textColor.r = r
                db.textColor.g = g
                db.textColor.b = b
                colorPicker.texture:SetColorTexture(r, g, b)
                addon.UpdateNotificationFrameColor()
            end,
            cancelFunc = function()
                local r, g, b = ColorPickerFrame:GetPreviousValues()
                db.textColor.r = r
                db.textColor.g = g
                db.textColor.b = b
                colorPicker.texture:SetColorTexture(r, g, b)
                addon.UpdateNotificationFrameColor()
            end,
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)

    orderSaveButton:SetScript("OnClick", function()
        db.orderMessage = orderMessage:GetText()
        print(string.format(L["CHAT_PREFIX"], ADDON_TITLE, L["MSG_SAVED"]))
    end)
    orderMessage:SetScript("OnEnterPressed", function(self)
        db.orderMessage = self:GetText()
        self:ClearFocus()
        print(string.format(L["CHAT_PREFIX"], ADDON_TITLE, L["MSG_SAVED"]))
    end)
    orderMessage:SetScript("OnEscapePressed", function(self)
        self:SetText(db.orderMessage)
        self:ClearFocus()
    end)

    suppressCombat:SetScript("OnClick", function(self)
        db.suppressInCombat = self:GetChecked()
    end)

    suppressInstance:SetScript("OnClick", function(self)
        db.suppressInInstance = self:GetChecked()
    end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    panel.category = category

    RefreshPanel()
    return panel, category
end

local function SlashCommandHandler(msg)
    if not db then
        db = addon.db
    end

    msg = strtrim(msg:lower())

    if msg == "test" then
        addon.PlayNotificationSound()
        addon.ShowNotification(db.orderMessage)
        addon.ShowChatNotification(db.orderMessage)
        print(string.format(L["CHAT_PREFIX"], ADDON_TITLE, L["MSG_TESTING"]))
    elseif addon.settingsCategory then
        Settings.OpenToCategory(addon.settingsCategory:GetID())
    end
end

SLASH_NEWORDERALERT1 = "/noa"
SLASH_NEWORDERALERT2 = "/neworderalert"
SlashCmdList["NEWORDERALERT"] = SlashCommandHandler

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    db = addon.db
    local panel, category = CreateOptionsPanel()
    addon.settingsCategory = category
end)
