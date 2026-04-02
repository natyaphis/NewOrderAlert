local addonName, addon = ...
local L = addon.L
local ADDON_TITLE = L["ADDON_TITLE"]
local VERSION = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version") or "unknown"

local db
local isElvUISkinned

local PANEL_WIDTH = 620
local CONTENT_WIDTH = 588
local PANEL_HEIGHT = 680
local ROW_SPACING = 5
local SECTION_SPACING = 10
local SECTION_CONTENT_OFFSET = 10
local LABEL_WIDTH = 180
local CONTROL_X_OFFSET = 190
local CONTROL_WIDTH = 220
local DEFAULT_EDITBOX_HEIGHT = 20
local BUTTON_HEIGHT = 24
local INLINE_BUTTON_WIDTH = 96

local function ApplySettingLabelStyle(fontString)
    if not fontString then
        return
    end

    fontString:SetFontObject("GameFontHighlight")
    fontString:SetTextColor(1, 0.82, 0)
    fontString:SetJustifyH("LEFT")
end

local function GetElvUISkinsModule()
    local E = _G.ElvUI and unpack(_G.ElvUI)
    local blizzardSkins = E and E.private and E.private.skins and E.private.skins.blizzard
    if not blizzardSkins or not blizzardSkins.enable or blizzardSkins.blizzardOptions == false then
        return
    end

    return E.GetModule and E:GetModule("Skins", true) or nil
end

local function CreateCheckbox(parent, label, tooltip)
    local check = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    check.Text:SetText(label)
    ApplySettingLabelStyle(check.Text)
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
    dropdown.noResize = true
    dropdown.width = width
    dropdown.labelText = label

    return dropdown
end

local function CreateEditBox(parent, width)
    local editbox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editbox:SetSize(width or 300, DEFAULT_EDITBOX_HEIGHT)
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
    button.border = border

    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("TOPLEFT", 2, -2)
    texture:SetPoint("BOTTOMRIGHT", -2, 2)
    texture:SetColorTexture(1, 1, 0)
    button.texture = texture

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetColorTexture(1, 1, 1, 0.3)

    local labelText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("RIGHT", button, "LEFT", -8, 0)
    labelText:SetWidth(LABEL_WIDTH - 8)
    labelText:SetText(label)
    ApplySettingLabelStyle(labelText)
    button.label = labelText

    return button
end

local function CreateSection(parent, title, anchor)
    local section = CreateFrame("Frame", nil, parent)
    section:SetWidth(PANEL_WIDTH)
    if anchor then
        section:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -SECTION_SPACING)
    else
        section:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    end

    local dividerLeft = section:CreateTexture(nil, "ARTWORK")
    dividerLeft:SetColorTexture(1, 1, 1, 1)
    dividerLeft:SetGradient("HORIZONTAL",
        CreateColor(1, 1, 1, 0.08),
        CreateColor(1, 1, 1, 0.32)
    )
    dividerLeft:SetPoint("TOPLEFT", 10, 0)
    dividerLeft:SetPoint("TOPRIGHT", section, "TOP", 0, 0)
    dividerLeft:SetHeight(1)

    local dividerRight = section:CreateTexture(nil, "ARTWORK")
    dividerRight:SetColorTexture(1, 1, 1, 1)
    dividerRight:SetGradient("HORIZONTAL",
        CreateColor(1, 1, 1, 0.32),
        CreateColor(1, 1, 1, 0.08)
    )
    dividerRight:SetPoint("TOPLEFT", section, "TOP", 0, 0)
    dividerRight:SetPoint("TOPRIGHT", -22, 0)
    dividerRight:SetHeight(1)

    section.rowOffset = 0

    function section:AddRow(rowHeight)
        local row = CreateFrame("Frame", nil, self)
        row:SetSize(CONTENT_WIDTH, rowHeight)
        row:SetPoint("TOPLEFT", 16, -(SECTION_CONTENT_OFFSET + self.rowOffset))

        self.rowOffset = self.rowOffset + rowHeight + ROW_SPACING
        return row
    end

    function section:Finalize()
        local contentHeight = math.max(0, self.rowOffset - ROW_SPACING)
        self:SetHeight(SECTION_CONTENT_OFFSET + contentHeight)
    end

    return section
end

local function AnchorCheckbox(widget, anchor)
    widget:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
end

local function AnchorDropdown(widget, anchor)
    widget:SetPoint("LEFT", anchor, "LEFT", CONTROL_X_OFFSET, 0)
end

local function CreateRowLabel(parent, anchor, text)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", anchor, "LEFT", 0, 0)
    label:SetWidth(LABEL_WIDTH - 8)
    label:SetText(text)
    ApplySettingLabelStyle(label)
    return label
end

local function AnchorSlider(widget, anchor, width)
    widget:ClearAllPoints()
    widget:SetPoint("LEFT", anchor, "LEFT", CONTROL_X_OFFSET, 0)
    widget:SetWidth(width)
    if widget.Text then
        widget.Text:ClearAllPoints()
        widget.Text:SetPoint("LEFT", anchor, "LEFT", 0, 0)
        widget.Text:SetWidth(LABEL_WIDTH - 8)
        ApplySettingLabelStyle(widget.Text)
    end
end

local function SetDropdownWidth(dropdown, width)
    UIDropDownMenu_SetWidth(dropdown, width)
    UIDropDownMenu_SetButtonWidth(dropdown, math.max(width - 24, 1))
    UIDropDownMenu_JustifyText(dropdown, "LEFT")

    local text = dropdown.Text or _G[dropdown:GetName() and (dropdown:GetName() .. "Text") or ""]
    if text then
        text:ClearAllPoints()
        text:SetPoint("LEFT", dropdown, "LEFT", 16, 0)
        text:SetPoint("RIGHT", dropdown, "RIGHT", -32, 0)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("MIDDLE")
    end
end

local function ApplyElvUISkin(widgets)
    if isElvUISkinned then
        return
    end

    local S = GetElvUISkinsModule()
    if not S then
        return
    end

    if widgets.checkboxes and S.HandleCheckBox then
        for _, checkbox in ipairs(widgets.checkboxes) do
            S:HandleCheckBox(checkbox)
        end
    end

    if widgets.sliders then
        for _, slider in ipairs(widgets.sliders) do
            if S.HandleSliderFrame then
                S:HandleSliderFrame(slider)
            elseif S.HandleSlider then
                S:HandleSlider(slider)
            end
        end
    end

    if widgets.dropdowns and S.HandleDropDownBox then
        for _, dropdown in ipairs(widgets.dropdowns) do
            S:HandleDropDownBox(dropdown, dropdown.width)
        end
    end

    if widgets.scrollBar and S.HandleScrollBar then
        S:HandleScrollBar(widgets.scrollBar)
    end

    if widgets.editBoxes and S.HandleEditBox then
        for _, editBox in ipairs(widgets.editBoxes) do
            S:HandleEditBox(editBox)
        end
    end

    if widgets.buttons and S.HandleButton then
        for _, button in ipairs(widgets.buttons) do
            S:HandleButton(button)
        end
    end

    if widgets.colorPicker and S.HandleButton then
        S:HandleButton(widgets.colorPicker)
        widgets.colorPicker:SetSize(24, 24)
        if widgets.colorPicker.border then
            widgets.colorPicker.border:Hide()
        end
    end

    isElvUISkinned = true
end

local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "NewOrderAlertOptionsPanel", UIParent)
    panel.name = ADDON_TITLE
    panel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(ADDON_TITLE)

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 12)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(PANEL_WIDTH, 1)
    scrollFrame:SetScrollChild(scrollChild)

    local widgets = {
        buttons = {},
        checkboxes = {},
        dropdowns = {},
        editBoxes = {},
        scrollBar = scrollFrame.ScrollBar,
        sliders = {},
    }

    local soundSection = CreateSection(scrollChild, L["SECTION_SOUND"])

    local soundRow1 = soundSection:AddRow(28)
    local enableSound = CreateCheckbox(scrollChild, L["ENABLE_SOUND"])
    AnchorCheckbox(enableSound, soundRow1)
    table.insert(widgets.checkboxes, enableSound)

    local testButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    testButton:SetSize(INLINE_BUTTON_WIDTH, BUTTON_HEIGHT)
    testButton:SetPoint("RIGHT", soundRow1, "RIGHT", 0, 0)
    testButton:SetText(L["TEST_NOTIFICATION"])
    testButton:SetEnabled(true)
    table.insert(widgets.buttons, testButton)

    local soundRow2 = soundSection:AddRow(28)
    local playInBackground = CreateCheckbox(scrollChild, L["PLAY_IN_BACKGROUND"])
    AnchorCheckbox(playInBackground, soundRow2)
    table.insert(widgets.checkboxes, playInBackground)

    local soundRow3 = soundSection:AddRow(32)
    CreateRowLabel(scrollChild, soundRow3, L["SOUND"])
    local soundDropdown = CreateDropdown(scrollChild, L["SOUND"], CONTROL_WIDTH)
    AnchorDropdown(soundDropdown, soundRow3)
    table.insert(widgets.dropdowns, soundDropdown)

    local soundRow4 = soundSection:AddRow(32)
    CreateRowLabel(scrollChild, soundRow4, L["CHANNEL"])
    local channelDropdown = CreateDropdown(scrollChild, L["CHANNEL"], CONTROL_WIDTH)
    AnchorDropdown(channelDropdown, soundRow4)
    table.insert(widgets.dropdowns, channelDropdown)
    soundSection:Finalize()

    local displaySection = CreateSection(scrollChild, L["SECTION_DISPLAY"], soundSection)

    local displayRow1 = displaySection:AddRow(28)
    local enableText = CreateCheckbox(scrollChild, L["ENABLE_TEXT"])
    AnchorCheckbox(enableText, displayRow1)
    table.insert(widgets.checkboxes, enableText)

    local testTextButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    testTextButton:SetSize(INLINE_BUTTON_WIDTH, BUTTON_HEIGHT)
    testTextButton:SetPoint("RIGHT", displayRow1, "RIGHT", 0, 0)
    testTextButton:SetText(L["TEST_TEXT"])
    testTextButton:SetEnabled(true)
    table.insert(widgets.buttons, testTextButton)

    local displayRow2 = displaySection:AddRow(28)
    local colorPicker = CreateColorPicker(scrollChild, L["FONT_COLOR"])
    colorPicker:SetPoint("LEFT", displayRow2, "LEFT", CONTROL_X_OFFSET, 0)
    colorPicker.label:ClearAllPoints()
    colorPicker.label:SetPoint("LEFT", displayRow2, "LEFT", 0, 0)
    widgets.colorPicker = colorPicker

    local displayRow3 = displaySection:AddRow(32)
    CreateRowLabel(scrollChild, displayRow3, L["FONT_FACE"])
    local fontDropdown = CreateDropdown(scrollChild, L["FONT_FACE"], CONTROL_WIDTH)
    AnchorDropdown(fontDropdown, displayRow3)
    table.insert(widgets.dropdowns, fontDropdown)

    local displayRow4 = displaySection:AddRow(32)
    local scaleSlider = CreateSlider(scrollChild, L["SCALE"], 5, 100, 1)
    AnchorSlider(scaleSlider, displayRow4, CONTROL_WIDTH)
    table.insert(widgets.sliders, scaleSlider)

    local displayRow5 = displaySection:AddRow(32)
    local durationSlider = CreateSlider(scrollChild, L["DISPLAY_DURATION"], 2, 10, 1)
    AnchorSlider(durationSlider, displayRow5, CONTROL_WIDTH)
    table.insert(widgets.sliders, durationSlider)

    local displayRow6 = displaySection:AddRow(32)
    local xOffsetSlider = CreateSlider(scrollChild, L["X_POSITION"], -1000, 1000, 5)
    AnchorSlider(xOffsetSlider, displayRow6, CONTROL_WIDTH)
    table.insert(widgets.sliders, xOffsetSlider)

    local displayRow7 = displaySection:AddRow(32)
    local yOffsetSlider = CreateSlider(scrollChild, L["Y_POSITION"], -500, 500, 5)
    AnchorSlider(yOffsetSlider, displayRow7, CONTROL_WIDTH)
    table.insert(widgets.sliders, yOffsetSlider)

    local displayRow8 = displaySection:AddRow(48)
    local orderLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    orderLabel:SetPoint("LEFT", displayRow8, "LEFT", 0, 0)
    orderLabel:SetWidth(LABEL_WIDTH - 8)
    orderLabel:SetText(L["NOTIFICATION_MESSAGE"])
    ApplySettingLabelStyle(orderLabel)

    local orderMessage = CreateEditBox(scrollChild, 360)
    orderMessage:SetPoint("LEFT", displayRow8, "LEFT", CONTROL_X_OFFSET, 0)
    orderMessage:SetSize(CONTENT_WIDTH - CONTROL_X_OFFSET - INLINE_BUTTON_WIDTH - 8, DEFAULT_EDITBOX_HEIGHT)
    table.insert(widgets.editBoxes, orderMessage)

    local orderSaveButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    orderSaveButton:SetSize(INLINE_BUTTON_WIDTH, BUTTON_HEIGHT)
    orderSaveButton:SetPoint("RIGHT", displayRow8, "RIGHT", 0, 0)
    orderSaveButton:SetText(L["SAVE"])
    orderSaveButton:SetEnabled(true)
    table.insert(widgets.buttons, orderSaveButton)
    displaySection:Finalize()

    local suppressSection = CreateSection(scrollChild, L["SECTION_SUPPRESSION"], displaySection)

    local suppressRow1 = suppressSection:AddRow(28)
    local suppressCombat = CreateCheckbox(scrollChild, L["SUPPRESS_COMBAT"])
    AnchorCheckbox(suppressCombat, suppressRow1)
    table.insert(widgets.checkboxes, suppressCombat)

    local suppressRow2 = suppressSection:AddRow(28)
    local suppressInstance = CreateCheckbox(scrollChild, L["SUPPRESS_INSTANCE"])
    AnchorCheckbox(suppressInstance, suppressRow2)
    table.insert(widgets.checkboxes, suppressInstance)
    suppressSection:Finalize()

    local contentHeight = soundSection:GetHeight()
        + displaySection:GetHeight()
        + suppressSection:GetHeight()
        + (SECTION_SPACING * 2)
        + 24
    scrollChild:SetHeight(contentHeight)

    panel:HookScript("OnShow", function()
        ApplyElvUISkin(widgets)
    end)

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
        if addon.FONT_OPTIONS then
            for _, fontOption in ipairs(addon.FONT_OPTIONS) do
                if fontOption.key == db.fontKey then
                    UIDropDownMenu_SetSelectedValue(fontDropdown, fontOption.key)
                    UIDropDownMenu_SetText(fontDropdown, fontOption.label)
                    break
                end
            end
        end

        enableText:SetChecked(db.textEnabled)
        scaleSlider:SetValue(db.fontSize)
        scaleSlider.Text:SetText(string.format(L["SCALE_FORMAT"], db.fontSize))
        xOffsetSlider:SetValue(db.textOffsetX)
        xOffsetSlider.Text:SetText(string.format(L["POSITION_FORMAT"], L["X_POSITION"], db.textOffsetX))
        yOffsetSlider:SetValue(db.textOffsetY)
        yOffsetSlider.Text:SetText(string.format(L["POSITION_FORMAT"], L["Y_POSITION"], db.textOffsetY))
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
    panel:HookScript("OnHide", function()
        addon.HideNotification()
    end)

    enableSound:SetScript("OnClick", function(self)
        db.soundEnabled = self:GetChecked()
    end)

    UIDropDownMenu_Initialize(soundDropdown, function(self, level)
        for i, soundData in ipairs(addon.SOUND_LIST) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = soundData.label
            info.value = i
            info.notCheckable = true
            info.func = function()
                db.soundIndex = i
                UIDropDownMenu_SetSelectedValue(soundDropdown, i)
                UIDropDownMenu_SetText(soundDropdown, soundData.label)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    SetDropdownWidth(soundDropdown, soundDropdown.width)

    UIDropDownMenu_Initialize(channelDropdown, function(self, level)
        local channels = { "Master", "SFX" }
        for _, channel in ipairs(channels) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = channel
            info.value = channel
            info.notCheckable = true
            info.func = function()
                db.soundChannel = channel
                UIDropDownMenu_SetSelectedValue(channelDropdown, channel)
                UIDropDownMenu_SetText(channelDropdown, channel)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    SetDropdownWidth(channelDropdown, channelDropdown.width)

    UIDropDownMenu_Initialize(fontDropdown, function(self, level)
        for _, fontOption in ipairs(addon.FONT_OPTIONS or {}) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = fontOption.label
            info.value = fontOption.key
            info.notCheckable = true
            info.func = function()
                db.fontKey = fontOption.key
                UIDropDownMenu_SetSelectedValue(fontDropdown, fontOption.key)
                UIDropDownMenu_SetText(fontDropdown, fontOption.label)
                addon.UpdateNotificationFrameFont()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    SetDropdownWidth(fontDropdown, fontDropdown.width)

    playInBackground:SetScript("OnClick", function(self)
        db.playInBackground = self:GetChecked()
        addon.ApplyBackgroundSoundSetting()
    end)

    testButton:SetScript("OnClick", function()
        addon.PlayNotificationSound()
        addon.ShowNotification(db.orderMessage)
    end)

    enableText:SetScript("OnClick", function(self)
        db.textEnabled = self:GetChecked()
        if not db.textEnabled then
            addon.HideNotification()
        end
    end)

    testTextButton:SetScript("OnClick", function()
        addon.ToggleTestNotification()
    end)

    scaleSlider:SetScript("OnValueChanged", function(self, value)
        db.fontSize = value
        self.Text:SetText(string.format(L["SCALE_FORMAT"], value))
        addon.UpdateNotificationFrameFont()
    end)

    xOffsetSlider:SetScript("OnValueChanged", function(self, value)
        db.textOffsetX = value
        self.Text:SetText(string.format(L["POSITION_FORMAT"], L["X_POSITION"], value))
        addon.UpdateNotificationFramePosition()
    end)

    yOffsetSlider:SetScript("OnValueChanged", function(self, value)
        db.textOffsetY = value
        self.Text:SetText(string.format(L["POSITION_FORMAT"], L["Y_POSITION"], value))
        addon.UpdateNotificationFramePosition()
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

    ApplyElvUISkin(widgets)
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
