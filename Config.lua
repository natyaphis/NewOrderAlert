local _, addon = ...
local L = addon.L
local ADDON_TITLE = L["ADDON_TITLE"]

local db
local isElvUISkinned
local optionsPanel

local PANEL_WIDTH = 620
local CONTENT_WIDTH = 588
local PANEL_HEIGHT = 680
local ROW_SPACING = 5
local SECTION_SPACING = 10
local SECTION_CONTENT_OFFSET = 10
local LABEL_WIDTH = 180
local CONTROL_X_OFFSET = 190
local CONTROL_WIDTH = 220
local SLIDER_WIDTH_OFFSET = 45
local DEFAULT_EDITBOX_HEIGHT = 20
local BUTTON_HEIGHT = 24
local INLINE_BUTTON_WIDTH = 96
local DROPDOWN_PREVIEW_SIZE = 12

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

local function CreateCheckbox(parent, label)
    local check = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    check.Text:SetText(label)
    ApplySettingLabelStyle(check.Text)
    check:SetEnabled(true)
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

local function CreateDropdown(parent, width)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown.noResize = true
    dropdown.width = width

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

local function CreateSection(parent, anchor)
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
    widget:SetWidth(width + SLIDER_WIDTH_OFFSET)
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

local function GetDropdownText(dropdown)
    return dropdown.Text or _G[dropdown:GetName() and (dropdown:GetName() .. "Text") or ""]
end

local function ApplyDropdownPreviewFont(dropdown, fontPath)
    local text = GetDropdownText(dropdown)
    if not text then
        return
    end

    local fallbackPath, _, fallbackFlags = GameFontHighlightSmall:GetFont()
    text:SetFont(fontPath or fallbackPath, DROPDOWN_PREVIEW_SIZE, fallbackFlags)
end

local function SetDropdownSelection(dropdown, value, text, fontPath)
    UIDropDownMenu_SetSelectedValue(dropdown, value)
    UIDropDownMenu_SetText(dropdown, text or "")
    ApplyDropdownPreviewFont(dropdown, fontPath)
end

local function BindDropdown(dropdown, items, getValue, setValue)
    dropdown.itemsProvider = items
    dropdown.getValue = getValue
    dropdown.setValue = setValue

    if not dropdown.isInitialized then
        UIDropDownMenu_Initialize(dropdown, function(_, level)
            for _, item in ipairs(dropdown.itemsProvider()) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = item.text
                info.value = item.value
                info.notCheckable = true
                info.func = function()
                    dropdown.setValue(item.value, item.text, item)
                    SetDropdownSelection(dropdown, item.value, item.text, item.fontPath)
                end
                UIDropDownMenu_AddButton(info)

                local menuLevel = level or UIDROPDOWNMENU_MENU_LEVEL or 1
                local listFrame = _G["DropDownList" .. menuLevel]
                local button = listFrame and _G[listFrame:GetName() .. "Button" .. listFrame.numButtons]
                local buttonText = button and button.NormalText
                if buttonText then
                    local fallbackPath, _, fallbackFlags = GameFontHighlightSmall:GetFont()
                    buttonText:SetFont(item.fontPath or fallbackPath, DROPDOWN_PREVIEW_SIZE, fallbackFlags)
                end
            end
        end)

        SetDropdownWidth(dropdown, dropdown.width)
        dropdown.isInitialized = true
    end

    local value, text, fontPath = dropdown.getValue()
    SetDropdownSelection(dropdown, value, text, fontPath)
end

local function CreateInlineButton(parent, text)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(INLINE_BUTTON_WIDTH, BUTTON_HEIGHT)
    button:SetText(text)
    button:SetEnabled(true)
    return button
end

local function CreateCheckboxRow(section, widgets, options)
    local row = section:AddRow(28)
    local checkbox = CreateCheckbox(row, options.label)
    AnchorCheckbox(checkbox, row)
    checkbox:SetScript("OnClick", options.onClick)
    table.insert(widgets.checkboxes, checkbox)

    local button
    if options.buttonText then
        button = CreateInlineButton(row, options.buttonText)
        button:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        if options.buttonOnClick then
            button:SetScript("OnClick", options.buttonOnClick)
        end
        table.insert(widgets.buttons, button)
    end

    return {
        row = row,
        checkbox = checkbox,
        button = button,
    }
end

local function CreateDropdownRow(section, widgets, label, width)
    local row = section:AddRow(32)
    CreateRowLabel(row, row, label)
    local dropdown = CreateDropdown(row, width)
    AnchorDropdown(dropdown, row)
    table.insert(widgets.dropdowns, dropdown)

    return {
        row = row,
        dropdown = dropdown,
    }
end

local function CreateSliderRow(section, widgets, label, minValue, maxValue, step)
    local row = section:AddRow(32)
    local slider = CreateSlider(row, label, minValue, maxValue, step)
    AnchorSlider(slider, row, CONTROL_WIDTH)
    table.insert(widgets.sliders, slider)

    return {
        row = row,
        slider = slider,
    }
end

local function CreateColorPickerRow(section, widgets, label)
    local row = section:AddRow(28)
    local colorPicker = CreateColorPicker(row, label)
    colorPicker:SetPoint("LEFT", row, "LEFT", CONTROL_X_OFFSET, 0)
    colorPicker.label:ClearAllPoints()
    colorPicker.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    widgets.colorPicker = colorPicker

    return {
        row = row,
        colorPicker = colorPicker,
    }
end

local function CreateMessageRow(section, widgets)
    local row = section:AddRow(48)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetWidth(LABEL_WIDTH - 8)
    label:SetText(L["NOTIFICATION_MESSAGE"])
    ApplySettingLabelStyle(label)

    local editBox = CreateEditBox(row, 360)
    editBox:SetPoint("LEFT", row, "LEFT", CONTROL_X_OFFSET, 0)
    editBox:SetSize(CONTENT_WIDTH - CONTROL_X_OFFSET - INLINE_BUTTON_WIDTH - 8, DEFAULT_EDITBOX_HEIGHT)
    table.insert(widgets.editBoxes, editBox)

    local button = CreateInlineButton(row, L["SAVE"])
    button:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    table.insert(widgets.buttons, button)

    return {
        row = row,
        label = label,
        editBox = editBox,
        button = button,
    }
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
    if optionsPanel and optionsPanel.category then
        return optionsPanel, optionsPanel.category
    end

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

    local controls = {}
    local sections = {}

    sections.sound = CreateSection(scrollChild)
    controls.enableSound = CreateCheckboxRow(sections.sound, widgets, {
        label = L["ENABLE_SOUND"],
        onClick = function(self)
            db.soundEnabled = self:GetChecked()
        end,
        buttonText = L["TEST_NOTIFICATION"],
        buttonOnClick = function()
            addon.PlayNotificationSound()
            addon.ShowNotification(db.orderMessage)
        end,
    })
    controls.playInBackground = CreateCheckboxRow(sections.sound, widgets, {
        label = L["PLAY_IN_BACKGROUND"],
        onClick = function(self)
            db.playInBackground = self:GetChecked()
            addon.ApplyBackgroundSoundSetting()
        end,
    })
    controls.soundDropdown = CreateDropdownRow(sections.sound, widgets, L["SOUND"], CONTROL_WIDTH)
    controls.channelDropdown = CreateDropdownRow(sections.sound, widgets, L["CHANNEL"], CONTROL_WIDTH)
    sections.sound:Finalize()

    sections.display = CreateSection(scrollChild, sections.sound)
    controls.enableText = CreateCheckboxRow(sections.display, widgets, {
        label = L["ENABLE_TEXT"],
        onClick = function(self)
            db.textEnabled = self:GetChecked()
            if not db.textEnabled then
                addon.HideNotification()
            end
        end,
        buttonText = L["TEST_TEXT"],
        buttonOnClick = function()
            addon.ToggleTestNotification()
        end,
    })
    controls.colorPicker = CreateColorPickerRow(sections.display, widgets, L["FONT_COLOR"])
    controls.fontDropdown = CreateDropdownRow(sections.display, widgets, L["FONT_FACE"], CONTROL_WIDTH)
    controls.fontOutlineDropdown = CreateDropdownRow(sections.display, widgets, L["FONT_OUTLINE_STYLE"], CONTROL_WIDTH)
    controls.fontSize = CreateSliderRow(sections.display, widgets, L["SCALE"], 5, 100, 1)
    controls.duration = CreateSliderRow(sections.display, widgets, L["DISPLAY_DURATION"], 2, 10, 1)
    controls.xOffset = CreateSliderRow(sections.display, widgets, L["X_POSITION"], -1000, 1000, 5)
    controls.yOffset = CreateSliderRow(sections.display, widgets, L["Y_POSITION"], -500, 500, 5)
    controls.message = CreateMessageRow(sections.display, widgets)
    sections.display:Finalize()

    sections.suppression = CreateSection(scrollChild, sections.display)
    controls.suppressCombat = CreateCheckboxRow(sections.suppression, widgets, {
        label = L["SUPPRESS_COMBAT"],
        onClick = function(self)
            db.suppressInCombat = self:GetChecked()
        end,
    })
    controls.suppressMythicPlus = CreateCheckboxRow(sections.suppression, widgets, {
        label = L["SUPPRESS_MYTHIC_PLUS"],
        onClick = function(self)
            db.suppressInMythicPlus = self:GetChecked()
        end,
    })
    controls.suppressRaid = CreateCheckboxRow(sections.suppression, widgets, {
        label = L["SUPPRESS_RAID"],
        onClick = function(self)
            db.suppressInRaid = self:GetChecked()
        end,
    })
    controls.suppressArena = CreateCheckboxRow(sections.suppression, widgets, {
        label = L["SUPPRESS_ARENA"],
        onClick = function(self)
            db.suppressInArena = self:GetChecked()
        end,
    })
    controls.suppressBattleground = CreateCheckboxRow(sections.suppression, widgets, {
        label = L["SUPPRESS_BATTLEGROUND"],
        onClick = function(self)
            db.suppressInBattleground = self:GetChecked()
        end,
    })
    controls.restAreaOnly = CreateCheckboxRow(sections.suppression, widgets, {
        label = L["REST_AREA_ONLY"],
        onClick = function(self)
            db.restAreaOnly = self:GetChecked()
        end,
    })
    sections.suppression:Finalize()

    local contentHeight = sections.sound:GetHeight()
        + sections.display:GetHeight()
        + sections.suppression:GetHeight()
        + (SECTION_SPACING * 2)
        + 24
    scrollChild:SetHeight(contentHeight)

    panel:HookScript("OnShow", function()
        ApplyElvUISkin(widgets)
    end)
    panel:HookScript("OnHide", function()
        addon.HideNotification()
    end)

    local function GetSoundItems()
        local items = {}
        for i, soundData in ipairs(addon.SOUND_LIST or {}) do
            items[#items + 1] = {
                value = i,
                text = soundData.label,
            }
        end
        return items
    end

    local function GetChannelItems()
        return {
            { value = "Master", text = "Master" },
            { value = "SFX", text = "SFX" },
            { value = "Music", text = "Music" },
            { value = "Ambience", text = "Ambience" },
            { value = "Dialog", text = "Dialog" },
        }
    end

    local function GetFontItems()
        local items = {}
        for _, fontOption in ipairs(addon.FONT_OPTIONS or {}) do
            items[#items + 1] = {
                value = fontOption.key,
                text = fontOption.label,
                fontPath = fontOption.path,
            }
        end
        return items
    end

    local function GetFontOutlineItems()
        local items = {}
        for _, outlineOption in ipairs(addon.FONT_OUTLINE_OPTIONS or {}) do
            items[#items + 1] = {
                value = outlineOption.value,
                text = outlineOption.label,
            }
        end
        return items
    end

    local function BindAllDropdowns()
        BindDropdown(
            controls.soundDropdown.dropdown,
            GetSoundItems,
            function()
                local selected = addon.SOUND_LIST and addon.SOUND_LIST[db.soundIndex]
                return db.soundIndex, selected and selected.label or ""
            end,
            function(value)
                db.soundIndex = value
            end
        )

        BindDropdown(
            controls.channelDropdown.dropdown,
            GetChannelItems,
            function()
                return db.soundChannel, db.soundChannel
            end,
            function(value)
                db.soundChannel = value
            end
        )

        BindDropdown(
            controls.fontDropdown.dropdown,
            GetFontItems,
            function()
                local selected = addon.FONT_LOOKUP and addon.FONT_LOOKUP[db.fontKey]
                return db.fontKey, selected and selected.label or db.fontKey, selected and selected.path or nil
            end,
            function(value)
                db.fontKey = value
                addon.UpdateNotificationFrameFont()
            end
        )

        BindDropdown(
            controls.fontOutlineDropdown.dropdown,
            GetFontOutlineItems,
            function()
                local selectedValue = db.fontOutline or ""
                for _, item in ipairs(addon.FONT_OUTLINE_OPTIONS or {}) do
                    if item.value == selectedValue then
                        return selectedValue, item.label
                    end
                end
                return selectedValue, L["FONT_OUTLINE_NONE"]
            end,
            function(value)
                db.fontOutline = value
                addon.UpdateNotificationFrameFont()
            end
        )
    end

    BindAllDropdowns()

    controls.fontSize.slider:SetScript("OnValueChanged", function(self, value)
        db.fontSize = value
        self.Text:SetText(string.format(L["SCALE_FORMAT"], value))
        addon.UpdateNotificationFrameFont()
    end)

    controls.duration.slider:SetScript("OnValueChanged", function(self, value)
        db.displayDuration = value
        self.Text:SetText(string.format(L["DISPLAY_DURATION_FORMAT"], value))
    end)

    controls.xOffset.slider:SetScript("OnValueChanged", function(self, value)
        db.textOffsetX = value
        self.Text:SetText(string.format(L["POSITION_FORMAT"], L["X_POSITION"], value))
        addon.UpdateNotificationFramePosition()
    end)

    controls.yOffset.slider:SetScript("OnValueChanged", function(self, value)
        db.textOffsetY = value
        self.Text:SetText(string.format(L["POSITION_FORMAT"], L["Y_POSITION"], value))
        addon.UpdateNotificationFramePosition()
    end)

    controls.colorPicker.colorPicker:SetScript("OnClick", function()
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
                controls.colorPicker.colorPicker.texture:SetColorTexture(r, g, b)
                addon.UpdateNotificationFrameColor()
            end,
            cancelFunc = function()
                local r, g, b = ColorPickerFrame:GetPreviousValues()
                db.textColor.r = r
                db.textColor.g = g
                db.textColor.b = b
                controls.colorPicker.colorPicker.texture:SetColorTexture(r, g, b)
                addon.UpdateNotificationFrameColor()
            end,
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)

    controls.message.button:SetScript("OnClick", function()
        db.orderMessage = controls.message.editBox:GetText()
        print(string.format(L["CHAT_PREFIX"], ADDON_TITLE, L["MSG_SAVED"]))
    end)
    controls.message.editBox:SetScript("OnEnterPressed", function(self)
        db.orderMessage = self:GetText()
        self:ClearFocus()
        print(string.format(L["CHAT_PREFIX"], ADDON_TITLE, L["MSG_SAVED"]))
    end)
    controls.message.editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(db.orderMessage)
        self:ClearFocus()
    end)

    local function RefreshPanel()
        if not db then
            db = addon.db
        end
        if not db then
            return
        end

        controls.enableSound.checkbox:SetChecked(db.soundEnabled)
        controls.playInBackground.checkbox:SetChecked(db.playInBackground)
        controls.enableText.checkbox:SetChecked(db.textEnabled)
        controls.suppressCombat.checkbox:SetChecked(db.suppressInCombat)
        controls.suppressMythicPlus.checkbox:SetChecked(db.suppressInMythicPlus)
        controls.suppressRaid.checkbox:SetChecked(db.suppressInRaid)
        controls.suppressArena.checkbox:SetChecked(db.suppressInArena)
        controls.suppressBattleground.checkbox:SetChecked(db.suppressInBattleground)
        controls.restAreaOnly.checkbox:SetChecked(db.restAreaOnly)

        BindAllDropdowns()

        controls.fontSize.slider:SetValue(db.fontSize)
        controls.fontSize.slider.Text:SetText(string.format(L["SCALE_FORMAT"], db.fontSize))
        controls.duration.slider:SetValue(db.displayDuration)
        controls.duration.slider.Text:SetText(string.format(L["DISPLAY_DURATION_FORMAT"], db.displayDuration))
        controls.xOffset.slider:SetValue(db.textOffsetX)
        controls.xOffset.slider.Text:SetText(string.format(L["POSITION_FORMAT"], L["X_POSITION"], db.textOffsetX))
        controls.yOffset.slider:SetValue(db.textOffsetY)
        controls.yOffset.slider.Text:SetText(string.format(L["POSITION_FORMAT"], L["Y_POSITION"], db.textOffsetY))

        controls.colorPicker.colorPicker.texture:SetColorTexture(db.textColor.r, db.textColor.g, db.textColor.b)
        controls.message.editBox:SetText(db.orderMessage or "")
        controls.message.editBox:SetCursorPosition(0)
    end

    panel.refresh = RefreshPanel
    panel:SetScript("OnShow", RefreshPanel)

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    panel.category = category
    optionsPanel = panel

    ApplyElvUISkin(widgets)
    RefreshPanel()
    return panel, category
end

local function EnsureSettingsCategory()
    if addon.settingsCategory and optionsPanel then
        if optionsPanel.refresh then
            optionsPanel.refresh()
        end
        return addon.settingsCategory
    end

    if not db then
        db = addon.db
    end
    if not db then
        return nil
    end

    local panel, category = CreateOptionsPanel()
    addon.settingsCategory = category
    if panel and panel.refresh then
        panel.refresh()
    end
    return category
end

local function SlashCommandHandler(msg)
    if not db then
        db = addon.db
    end

    msg = strtrim((msg or ""):lower())

    if msg == "test" then
        addon.PlayNotificationSound()
        addon.ShowNotification(db.orderMessage)
        print(string.format(L["CHAT_PREFIX"], ADDON_TITLE, L["MSG_TESTING"]))
    else
        local category = EnsureSettingsCategory()
        if category then
            Settings.OpenToCategory(category:GetID())
            Settings.OpenToCategory(category:GetID())
        end
    end
end

SLASH_NEWORDERALERT1 = "/noa"
SLASH_NEWORDERALERT2 = "/neworderalert"
SlashCmdList["NEWORDERALERT"] = SlashCommandHandler

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    db = addon.db
end)
