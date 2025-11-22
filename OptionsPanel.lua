-- OptionsPanel.lua
-- Reusable options panel builder for WoW addons

local OptionsPanel = {}

-- Helper function to style color picker buttons with inset appearance
local function StyleColorButtonInset(button)
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.3)
    local border = button:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0, 0, 0, 1)
    local highlight = button:CreateTexture(nil, "OVERLAY")
    highlight:SetPoint("TOPLEFT", -1, 1)
    highlight:SetPoint("BOTTOMRIGHT", 0, 0)
    highlight:SetColorTexture(1, 1, 1, 0.1)
    if button:GetNormalTexture() then 
        button:GetNormalTexture():SetDrawLayer("OVERLAY", 1) 
    end
end

-- Create a new options panel
function OptionsPanel:NewPanel(config)
    local panel = CreateFrame("Frame", config.name .. "OptionsPanel", UIParent)
    panel.name = config.displayName or config.name
    panel.elements = {}
    
    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(config.title or panel.name)
    
    panel.title = title
    
    return panel
end

-- Add a checkbox to the panel
function OptionsPanel:AddCheckbox(panel, config)
    local checkbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint(config.point or "TOPLEFT", config.anchor, config.relativePoint or "BOTTOMLEFT", config.xOffset or 0, config.yOffset or 0)
    checkbox:SetChecked(config.default or false)
    
    if config.onClick then
        checkbox:SetScript("OnClick", function(self)
            config.onClick(self:GetChecked())
        end)
    end
    
    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    label:SetText(config.label or "")
    
    panel.elements[config.key] = checkbox
    return checkbox
end

-- Add a slider to the panel
function OptionsPanel:AddSlider(panel, config)
    local slider = CreateFrame("Slider", config.name or nil, panel, "OptionsSliderTemplate")
    slider:SetPoint(config.point or "TOPLEFT", config.anchor, config.relativePoint or "BOTTOMLEFT", config.xOffset or 0, config.yOffset or 0)
    slider:SetMinMaxValues(config.min or 0, config.max or 100)
    slider:SetValueStep(config.step or 1)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(config.default or config.min or 0)
    slider.Low:SetText(config.lowText or "")
    slider.High:SetText(config.highText or "")
    
    if config.name then
        _G[config.name .. "Text"]:SetText(config.label or "")
    end
    
    if config.onValueChanged then
        slider:SetScript("OnValueChanged", function(self, value)
            config.onValueChanged(value)
        end)
    end
    
    panel.elements[config.key] = slider
    return slider
end

-- Add a color picker to the panel
function OptionsPanel:AddColorPicker(panel, config)
    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint(config.point or "TOPLEFT", config.anchor, config.relativePoint or "BOTTOMLEFT", config.xOffset or 0, config.yOffset or 0)
    label:SetText(config.label or "Color:")
    
    local button = CreateFrame("Button", nil, panel)
    button:SetPoint("LEFT", label, "LEFT", config.labelOffset or 110, 0)
    button:SetSize(16, 16)
    StyleColorButtonInset(button)
    
    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetColorTexture(config.r or 1, config.g or 1, config.b or 1, 1)
    
    button:SetScript("OnClick", function()
        local info = {}
        info.r, info.g, info.b = config.r or 1, config.g or 1, config.b or 1
        info.hasOpacity = false
        info.swatchFunc = function()
            local r, g, b
            if ColorPickerFrame and ColorPickerFrame.GetColorRGB then
                r, g, b = ColorPickerFrame:GetColorRGB()
            else
                r, g, b = info.r, info.g, info.b
            end
            texture:SetColorTexture(r, g, b, 1)
            if config.onColorChanged then
                config.onColorChanged(r, g, b)
            end
        end
        info.cancelFunc = function(previous)
            texture:SetColorTexture(previous.r, previous.g, previous.b, 1)
            if config.onColorChanged then
                config.onColorChanged(previous.r, previous.g, previous.b)
            end
        end
        
        local colorPickerFrame = _G["ColorPickerFrame"]
        if colorPickerFrame then
            if colorPickerFrame.SetupColorPickerAndShow then
                colorPickerFrame:SetupColorPickerAndShow(info)
            else
                colorPickerFrame.func = info.swatchFunc
                colorPickerFrame.cancelFunc = info.cancelFunc
                if colorPickerFrame.SetColorRGB then
                    colorPickerFrame:SetColorRGB(info.r, info.g, info.b)
                end
                colorPickerFrame:Show()
            end
        end
    end)
    
    panel.elements[config.key] = {button = button, texture = texture, label = label}
    return button, texture, label
end

-- Add a dropdown to the panel
function OptionsPanel:AddDropdown(panel, config)
    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint(config.point or "TOPLEFT", config.anchor, config.relativePoint or "BOTTOMLEFT", config.xOffset or 0, config.yOffset or 0)
    label:SetText(config.label or "")
    
    local dropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", label, "LEFT", config.labelOffset or 100, 0)
    dropdown:SetSize(config.width or 150, 25)
    
    local currentValue = config.default
    
    local function OnItemSelected(self, value)
        currentValue = value
        UIDropDownMenu_SetSelectedValue(dropdown, value)
        
        for _, opt in ipairs(config.options) do
            if opt.value == value then
                UIDropDownMenu_SetText(dropdown, opt.text)
                break
            end
        end
        
        if config.onSelect then
            config.onSelect(value)
        end
    end
    
    UIDropDownMenu_Initialize(dropdown, function(self)
        for _, opt in ipairs(config.options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.text
            info.arg1 = opt.value
            info.func = OnItemSelected
            info.checked = (currentValue == opt.value)
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    UIDropDownMenu_SetSelectedValue(dropdown, currentValue)
    for _, opt in ipairs(config.options) do
        if opt.value == currentValue then
            UIDropDownMenu_SetText(dropdown, opt.text)
            break
        end
    end
    
    panel.elements[config.key] = {dropdown = dropdown, label = label}
    return dropdown, label
end

-- Add a button to the panel
function OptionsPanel:AddButton(panel, config)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetPoint(config.point or "TOPLEFT", config.anchor, config.relativePoint or "BOTTOMLEFT", config.xOffset or 0, config.yOffset or 0)
    button:SetSize(config.width or 180, config.height or 25)
    button:SetText(config.text or "Button")
    
    if config.onClick then
        button:SetScript("OnClick", function()
            config.onClick()
        end)
    end
    
    panel.elements[config.key] = button
    return button
end

-- Register the panel with WoW's settings system
function OptionsPanel:Register(panel)
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
end

-- Update element values (for refreshing UI from saved data)
function OptionsPanel:UpdateCheckbox(panel, key, value)
    if panel.elements[key] then
        panel.elements[key]:SetChecked(value)
    end
end

function OptionsPanel:UpdateSlider(panel, key, value)
    if panel.elements[key] then
        panel.elements[key]:SetValue(value)
    end
end

function OptionsPanel:UpdateColorPicker(panel, key, r, g, b)
    if panel.elements[key] and panel.elements[key].texture then
        panel.elements[key].texture:SetColorTexture(r, g, b, 1)
    end
end

function OptionsPanel:UpdateDropdown(panel, key, value, displayText)
    if panel.elements[key] and panel.elements[key].dropdown then
        UIDropDownMenu_SetSelectedValue(panel.elements[key].dropdown, value)
        if displayText then
            UIDropDownMenu_SetText(panel.elements[key].dropdown, displayText)
        end
    end
end

_G.OptionsPanel = OptionsPanel