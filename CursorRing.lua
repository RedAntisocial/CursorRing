-- CursorRing.lua
-- Local variables
local ring, ringEnabled, ringSize, ringColor, castColor, showOutOfCombat
local casting, castStyle, mouseTrail, mouseTrailActive, sparkleTrail, trailFadeTime, trailColor, sparkleColor
local castSegments, leftHalf, rightHalf
local panelLoaded = false
local panelFrame = nil
local trailGroup = {}
local MAX_TRAIL_POINTS = 20
local NUM_CAST_SEGMENTS = 240

-- SavedVariables DB
CursorRingDB = CursorRingDB or {}

-- CLAMP!!! I SAID CLAMP!!!!
local function Clamp(val, min, max)
    if val < min then return min elseif val > max then return max end
    return val
end

-- Get current spec key
local function GetCurrentSpecKey()
    local specIndex = GetSpecialization()
    if not specIndex then return "NoSpec" end
    local _, specName = GetSpecializationInfo(specIndex)
    return specName or ("Spec"..specIndex)
end

-- Load per-spec settings
local function LoadSpecSettings()
    local specKey = GetCurrentSpecKey()
    CursorRingDB[specKey] = CursorRingDB[specKey] or {}
    local specDB = CursorRingDB[specKey]

    ringEnabled = specDB.ringEnabled
    if ringEnabled == nil then ringEnabled = true end

    ringSize = specDB.ringSize or 64
    showOutOfCombat = specDB.showOutOfCombat
    if showOutOfCombat == nil then showOutOfCombat = true end

    local _, class = UnitClass("player")
    local defaultClassColor = RAID_CLASS_COLORS[class]

    ringColor = specDB.ringColor or { r = defaultClassColor.r, g = defaultClassColor.g, b = defaultClassColor.b }
    castColor = specDB.castColor or { r = 1, g = 1, b = 1 }

    castStyle = specDB.castStyle or "ring"
    mouseTrail = specDB.mouseTrail or false
    sparkleTrail = specDB.sparkleTrail or false
    trailFadeTime = specDB.trailFadeTime or 0.6
    trailColor = specDB.trailColor or { r = 1, g = 1, b = 1 }
    sparkleColor = specDB.sparkleColor or { r = 1, g = 1, b = 1 }

    -- Save back to DB so it's not an empty meaningless void
    specDB.ringEnabled = ringEnabled
    specDB.ringSize = ringSize
    specDB.ringColor = ringColor
    specDB.castColor = castColor
    specDB.showOutOfCombat = showOutOfCombat
    specDB.castStyle = castStyle
    specDB.mouseTrail = mouseTrail
    specDB.sparkleTrail = sparkleTrail
    specDB.trailFadeTime = trailFadeTime
    specDB.trailColor = trailColor
    specDB.sparkleColor = sparkleColor

    return specDB
end

-- It puts the spec specific values in the CursorRingDB or it gets the hose again...
local function SaveSpecSettings()
    local specKey = GetCurrentSpecKey()
    CursorRingDB[specKey] = CursorRingDB[specKey] or {}
    local specDB = CursorRingDB[specKey]

    specDB.ringEnabled = ringEnabled
    specDB.ringSize = ringSize
    specDB.ringColor = ringColor
    specDB.castColor = castColor
    specDB.showOutOfCombat = showOutOfCombat
    specDB.castStyle = castStyle
    specDB.mouseTrail = mouseTrail
    specDB.sparkleTrail = sparkleTrail
    specDB.trailFadeTime = trailFadeTime
    specDB.trailColor = trailColor
    specDB.sparkleColor = sparkleColor
end

-- You want spec specific settings? This is where we get them.
local function GetSpecDB()
    CursorRingDB = CursorRingDB or {}
    local key = GetCurrentSpecKey()
    CursorRingDB[key] = CursorRingDB[key] or {}
    return CursorRingDB[key]
end

-- Spec specific Ring Size update
local function UpdateRingSize(size)
    ringSize = size
    GetSpecDB().ringSize = size
    SaveSpecSettings()
    if ring and ring:GetParent() then
        ring:GetParent():SetSize(ringSize, ringSize)
    end
end

-- Spec specific Ring Color update
local function UpdateRingColor(r, g, b)
    ringColor.r, ringColor.g, ringColor.b = r, g, b
    GetSpecDB().ringColor = ringColor
    SaveSpecSettings()
    if ring then
        ring:SetVertexColor(r, g, b, 1)
    end
end

-- Spec specific Cast Color update
local function UpdateCastColor(r, g, b)
    castColor.r, castColor.g, castColor.b = r, g, b
    GetSpecDB().castColor = castColor
    SaveSpecSettings()
end

-- Update Cast Style (wedge or ring. Ring is better, but some people want wedge)
local function UpdateCastStyle(style)
    castStyle = style
    GetSpecDB().castStyle = castStyle
    SaveSpecSettings()

    if castSegments and ring and ring:GetParent() then
        local f = ring:GetParent()
        for i = 1, NUM_CAST_SEGMENTS do
            if castSegments[i] then
                castSegments[i]:Hide()
                castSegments[i] = nil
            end
        end
        castSegments = {}
        for i = 1, NUM_CAST_SEGMENTS do
            local segment = f:CreateTexture(nil, "OVERLAY")
            local texturePath = castStyle == "wedge" and "Interface\\AddOns\\CursorRing\\cast_wedge.tga" or "Interface\\AddOns\\CursorRing\\cast_segment.tga"
            segment:SetTexture(texturePath, "CLAMP")
            segment:SetAllPoints()
            segment:SetRotation(math.rad((i-1)*(360/NUM_CAST_SEGMENTS)))
            segment:SetVertexColor(1, 1, 1, 0)
            castSegments[i] = segment
        end
    end
end

-- Determine if ring/trail should be shown based on combat/instance rules
local function ShouldShowAllowedByCombatRules()
    if InCombatLockdown() then return true end
    local inInst, t = IsInInstance()
    if inInst and (t=="party" or t=="raid" or t=="pvp" or t=="arena" or t=="scenario") then
        return true
    end
    return showOutOfCombat
end

-- Update Ring Visibility
local function UpdateRingVisibility()
    if ring then
        ring:SetShown(ringEnabled and ShouldShowAllowedByCombatRules())
    end
end

-- Update Mouse Trail Visibility
local function UpdateMouseTrailVisibility()
    mouseTrailActive = mouseTrail and ShouldShowAllowedByCombatRules()
    for _, point in ipairs(trailGroup) do
        if point.tex then point.tex:SetAlpha(mouseTrailActive and 1 or 0) end
        if point.sparkle then point.sparkle:SetAlpha(mouseTrailActive and 1 or 0) end
    end
end

-- Spec specific Ring Enabled setting update
local function UpdateMouseTrail(enabled)
    mouseTrail = enabled
    GetSpecDB().mouseTrail = enabled
    SaveSpecSettings()
    UpdateMouseTrailVisibility()
end

-- Spec specific Out of Combat setting update
local function UpdateShowOutOfCombat(show)
    showOutOfCombat = show
    GetSpecDB().showOutOfCombat = show
    SaveSpecSettings()
    UpdateRingVisibility()
    UpdateMouseTrailVisibility()
end

-- Cursor Ring Creation
local function CreateCursorRing()
    if ring then return end
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(ringSize, ringSize)
    f:SetFrameStrata("TOOLTIP")

    -- Outer ring
    ring = f:CreateTexture(nil, "ARTWORK")
    ring:SetTexture("Interface\\AddOns\\CursorRing\\ring.tga", "CLAMP")
    ring:SetAllPoints()
    ring:SetVertexColor(ringColor.r, ringColor.g, ringColor.b, 1)

    -- Inner halves for fallback
    leftHalf = f:CreateTexture(nil, "OVERLAY")
    leftHalf:SetTexture("Interface\\AddOns\\CursorRing\\innerring_left.tga", "CLAMP")
    leftHalf:SetAllPoints()
    leftHalf:SetVertexColor(1, 1, 1, 0)

    rightHalf = f:CreateTexture(nil, "OVERLAY")
    rightHalf:SetTexture("Interface\\AddOns\\CursorRing\\innerring_right.tga", "CLAMP")
    rightHalf:SetAllPoints()
    rightHalf:SetVertexColor(1, 1, 1, 0)

    -- Cast segments
    castSegments = {}
    for i = 1, NUM_CAST_SEGMENTS do
        local segment = f:CreateTexture(nil, "OVERLAY")
        local texturePath = castStyle == "wedge" and "Interface\\AddOns\\CursorRing\\cast_wedge.tga" or "Interface\\AddOns\\CursorRing\\cast_segment.tga"
        segment:SetTexture(texturePath, "CLAMP")
        segment:SetAllPoints()
        segment:SetRotation(math.rad((i-1)*(360/NUM_CAST_SEGMENTS)))
        segment:SetVertexColor(1, 1, 1, 0)
        castSegments[i] = segment
    end

    -- Mouse Trail
    local function CreateTrailTexture(parent)
        local tex = parent:CreateTexture(nil, "BACKGROUND")
        tex:SetTexture("Interface\\AddOns\\CursorRing\\trail_glow.tga")
        tex:SetBlendMode("ADD")
        tex:SetAlpha(0)
        tex:SetSize(ringSize*0.5, ringSize*0.5)
        return tex
    end

    local function CreateSparkleTexture(parent)
        local tex = parent:CreateTexture(nil, "ARTWORK")
        tex:SetTexture("Interface\\AddOns\\CursorRing\\sparkle.tga")
        tex:SetBlendMode("ADD")
        tex:SetAlpha(0)
        tex:SetSize(32, 32)
        return tex
    end

    -- OnUpdate
    f:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x/scale, y/scale)

        -- Mouse Trail
        if mouseTrailActive then
            local now = GetTime()
            table.insert(trailGroup, { x=x/scale, y=y/scale, created=now })
            while #trailGroup > MAX_TRAIL_POINTS do
                local old = table.remove(trailGroup, 1)
                if old and old.tex then old.tex:Hide() end
                if old and old.sparkle then old.sparkle:Hide() end
            end
            for i=#trailGroup,1,-1 do
                local point = trailGroup[i]
                local age = now - point.created
                local fade = 1 - (age / (trailFadeTime or 1))
                if fade <= 0 then
                    if point.tex then point.tex:Hide() end
                    if point.sparkle then point.sparkle:Hide() end
                    table.remove(trailGroup, i)
                else
                    if not point.tex then point.tex = CreateTrailTexture(self) end
                    point.tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", point.x, point.y)
                    local rc = trailColor or { r=1, g=1, b=1 }
                    point.tex:SetVertexColor(rc.r, rc.g, rc.b, Clamp(fade*0.8,0,1))
                    point.tex:SetAlpha(fade)
                    point.tex:SetSize(ringSize*0.4*fade, ringSize*0.4*fade)
                    point.tex:Show()
                    if sparkleTrail then
                        if not point.sparkle then point.sparkle = CreateSparkleTexture(self) end
                        local dx = (math.random()-0.5)*24
                        local dy = (math.random()-0.5)*24
                        point.sparkle:SetPoint("CENTER", UIParent, "BOTTOMLEFT", point.x+dx, point.y+dy)
                        local sc = sparkleColor or { r=1, g=1, b=1 }
                        point.sparkle:SetVertexColor(sc.r, sc.g, sc.b, 1)
                        point.sparkle:SetAlpha(Clamp(fade*1.7,0,1))
                        point.sparkle:Show()
                    end
                end
            end
        end

        -- Casting progress
        if casting then
            local now = GetTime()
            local progress = 0
            local castName, _, _, castStartTime, castEndTime = UnitCastingInfo("player")
            local channelName, _, _, channelStartTime, channelEndTime = UnitChannelInfo("player")
            if castName then
                progress = (now - (castStartTime/1000)) / ((castEndTime - castStartTime)/1000)
            elseif channelName then
                progress = 1 - ((now - (channelStartTime/1000)) / ((channelEndTime - channelStartTime)/1000))
            else
                casting = false
                for i=1,NUM_CAST_SEGMENTS do castSegments[i]:SetVertexColor(1,1,1,0) end
                leftHalf:SetVertexColor(1,1,1,0)
                rightHalf:SetVertexColor(1,1,1,0)
                return
            end
            progress = Clamp(progress,0,1)
            if castSegments and castSegments[1]:GetTexture() then
                local segmentsToShow = math.floor(progress*NUM_CAST_SEGMENTS)
                for i=1,NUM_CAST_SEGMENTS do
                    if i <= segmentsToShow then
                        castSegments[i]:SetVertexColor(castColor.r, castColor.g, castColor.b, 1)
                    else
                        castSegments[i]:SetVertexColor(1,1,1,0)
                    end
                end
                leftHalf:SetVertexColor(1,1,1,0)
                rightHalf:SetVertexColor(1,1,1,0)
            else
                local angle = progress*360
                leftHalf:SetVertexColor(castColor.r, castColor.g, castColor.b, 1)
                rightHalf:SetVertexColor(castColor.r, castColor.g, castColor.b, 1)
                if angle<=180 then
                    rightHalf:SetRotation(math.rad(angle))
                    leftHalf:SetRotation(0)
                    leftHalf:SetVertexColor(1,1,1,0)
                else
                    rightHalf:SetRotation(math.rad(180))
                    leftHalf:SetRotation(math.rad(angle-180))
                end
                for i=1,NUM_CAST_SEGMENTS do castSegments[i]:SetVertexColor(1,1,1,0) end
            end
        else
            for i=1,NUM_CAST_SEGMENTS do castSegments[i]:SetVertexColor(1,1,1,0) end
            leftHalf:SetVertexColor(1,1,1,0)
            rightHalf:SetVertexColor(1,1,1,0)
        end
    end)

    UpdateRingVisibility()
end

-- Options panel styling
local function StyleColorButtonInset(button)
    local bg = button:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0,0,0,0.3)
    local border = button:CreateTexture(nil,"BORDER")
    border:SetPoint("TOPLEFT",-1,1)
    border:SetPoint("BOTTOMRIGHT",1,-1)
    border:SetColorTexture(0,0,0,1)
    local highlight = button:CreateTexture(nil,"OVERLAY")
    highlight:SetPoint("TOPLEFT",-1,1)
    highlight:SetPoint("BOTTOMRIGHT",0,0)
    highlight:SetColorTexture(1,1,1,0.1)
    if button:GetNormalTexture() then button:GetNormalTexture():SetDrawLayer("OVERLAY",1) end
end

-- Create Options Panel
local function CreateOptionsPanel()
    if panelLoaded then return end
    panelLoaded = true

    local specDB = GetSpecDB()

    local panel = CreateFrame("Frame", "CursorRingOptionsPanel", UIParent)
    panel.name = "CursorRing"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("CursorRing Settings")

    -- Show Out of Combat Checkbox
    local showOutOfCombat = specDB.showOutOfCombat or false
    local outOfCombatCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    outOfCombatCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    outOfCombatCheckbox:SetChecked(showOutOfCombat)
    outOfCombatCheckbox:SetScript("OnClick", function(self)
        showOutOfCombat = self:GetChecked()
        specDB.showOutOfCombat = showOutOfCombat
        SaveSpecSettings()
        UpdateShowOutOfCombat(showOutOfCombat)
    end)

    local outOfCombatLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    outOfCombatLabel:SetPoint("LEFT", outOfCombatCheckbox, "RIGHT", 5, 0)
    outOfCombatLabel:SetText("Show Ring and Mouse Trail outside of combat/instances")

    -- Enable Ring Checkbox
    local ringEnabled = specDB.ringEnabled
    if ringEnabled == nil then ringEnabled = true end
    local ringToggle = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    ringToggle:SetPoint("TOPLEFT", outOfCombatCheckbox, "BOTTOMLEFT", 0, -8)
    ringToggle:SetChecked(ringEnabled)
    ringToggle:SetScript("OnClick", function(self)
        ringEnabled = self:GetChecked()
        specDB.ringEnabled = ringEnabled
        SaveSpecSettings()
        UpdateRingVisibility()
    end)

    local ringToggleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ringToggleLabel:SetPoint("LEFT", ringToggle, "RIGHT", 5, 0)
    ringToggleLabel:SetText("Enable Cursor Ring")

    -- Ring Size Slider   
    local ringSize = specDB.ringSize or 64
    local slider = CreateFrame("Slider", "CursorRingSizeSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", ringToggle, "BOTTOMLEFT", 0, -30)
    slider:SetMinMaxValues(32, 256)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(ringSize)
    slider.Low:SetText("Small")
    slider.High:SetText("Large")
    _G[slider:GetName() .. "Text"]:SetText("Ring Size")
    slider:SetScript("OnValueChanged", function(self, value)
        ringSize = value
        specDB.ringSize = ringSize
        SaveSpecSettings()
        UpdateRingSize(ringSize)
    end)

    -- Ring Color Picker
    local ringColor = specDB.ringColor or { r = 1, g = 1, b = 1 }
    local ringColorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ringColorLabel:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -40)
    ringColorLabel:SetText("Ring Color:")

    local ringColorButton = CreateFrame("Button", nil, panel)
    ringColorButton:SetPoint("LEFT", ringColorLabel, "RIGHT", 40, 0)
    ringColorButton:SetSize(16, 16)
    StyleColorButtonInset(ringColorButton)

    local ringColorTexture = ringColorButton:CreateTexture(nil, "ARTWORK")
    ringColorTexture:SetAllPoints()
    ringColorTexture:SetColorTexture(ringColor.r, ringColor.g, ringColor.b, 1)

    ringColorButton:SetScript("OnClick", function()
        local info = {}
        info.r, info.g, info.b = ringColor.r, ringColor.g, ringColor.b
        info.hasOpacity = false
        info.swatchFunc = function()
            local r, g, b
            if ColorPickerFrame and ColorPickerFrame.GetColorRGB then
                r, g, b = ColorPickerFrame:GetColorRGB()
            else
                r, g, b = ringColor.r, ringColor.g, ringColor.b
            end
            ringColorTexture:SetColorTexture(r, g, b, 1)
            ringColor.r, ringColor.g, ringColor.b = r, g, b
            specDB.ringColor = ringColor
            SaveSpecSettings()
            UpdateRingColor(r, g, b)
        end
        info.cancelFunc = function(previous)
            ringColorTexture:SetColorTexture(previous.r, previous.g, previous.b, 1)
            ringColor = { r = previous.r, g = previous.g, b = previous.b }
            specDB.ringColor = ringColor
            SaveSpecSettings()
            UpdateRingColor(previous.r, previous.g, previous.b)
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

    -- Cast Color Picker
    local castColor = specDB.castColor or { r = 1, g = 1, b = 1 }
    local castColorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    castColorLabel:SetPoint("TOPLEFT", ringColorLabel, "BOTTOMLEFT", 0, -40)
    castColorLabel:SetText("Cast Ring Color:")

    local castColorButton = CreateFrame("Button", nil, panel)
    castColorButton:SetPoint("LEFT", castColorLabel, "RIGHT", 10, 0)
    castColorButton:SetSize(16, 16)
    StyleColorButtonInset(castColorButton)

    local castColorTexture = castColorButton:CreateTexture(nil, "ARTWORK")
    castColorTexture:SetAllPoints()
    castColorTexture:SetColorTexture(castColor.r, castColor.g, castColor.b, 1)

    castColorButton:SetScript("OnClick", function()
        local info = {}
        info.r, info.g, info.b = castColor.r, castColor.g, castColor.b
        info.hasOpacity = false
        info.swatchFunc = function()
            local r, g, b
            if ColorPickerFrame and ColorPickerFrame.GetColorRGB then
                r, g, b = ColorPickerFrame:GetColorRGB()
            else
                r, g, b = castColor.r, castColor.g, castColor.b
            end
            castColorTexture:SetColorTexture(r, g, b, 1)
            castColor.r, castColor.g, castColor.b = r, g, b
            specDB.castColor = castColor
            SaveSpecSettings()
            UpdateCastColor(r, g, b)
        end
        info.cancelFunc = function(previous)
            castColorTexture:SetColorTexture(previous.r, previous.g, previous.b, 1)
            castColor = { r = previous.r, g = previous.g, b = previous.b }
            specDB.castColor = castColor
            SaveSpecSettings()
            UpdateCastColor(previous.r, previous.g, previous.b)
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

    -- Cast Style Dropdown
    local castStyle = specDB.castStyle or "ring"
    local styleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    styleLabel:SetPoint("LEFT", castColorButton, "RIGHT", 100, 0)
    styleLabel:SetText("Cast Ring Style:")

    local styleDropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    styleDropdown:SetPoint("LEFT", styleLabel, "RIGHT", 5, 0)
    styleDropdown:SetSize(150, 25)

    local function OnStyleSelected(self, arg1, arg2, checked)
        castStyle = arg1
        specDB.castStyle = castStyle
        SaveSpecSettings()
        UpdateCastStyle(castStyle)
        UIDropDownMenu_SetText(styleDropdown, castStyle == "ring" and "Ring" or "Wedge")
    end

    UIDropDownMenu_SetInitializeFunction(styleDropdown, function(self)
        local info = UIDropDownMenu_CreateInfo()
        info.func = OnStyleSelected

        info.text = "Ring"
        info.arg1 = "ring"
        info.checked = (castStyle == "ring")
        UIDropDownMenu_AddButton(info)

        info.text = "Wedge"
        info.arg1 = "wedge"
        info.checked = (castStyle == "wedge")
        UIDropDownMenu_AddButton(info)
    end)
    UIDropDownMenu_SetText(styleDropdown, castStyle == "ring" and "Ring" or "Wedge")

    -- Reset Cursor Ring to Class Color Button
    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", castColorLabel, "BOTTOMLEFT", 0, -40)
    resetButton:SetSize(180, 25)
    resetButton:SetText("Reset Ring to Class Color")
    resetButton:SetScript("OnClick", function()
        local _, class = UnitClass("player")
        local classColor = RAID_CLASS_COLORS[class]
        ringColorTexture:SetColorTexture(classColor.r, classColor.g, classColor.b, 1)
        ringColor = { r = classColor.r, g = classColor.g, b = classColor.b }
        specDB.ringColor = ringColor
        SaveSpecSettings()
        UpdateRingColor(classColor.r, classColor.g, classColor.b)
    end)

    -- Mouse Trail Checkbox
    local mouseTrail = specDB.mouseTrail or false
    local mouseTrailCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    mouseTrailCheckbox:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -20)
    mouseTrailCheckbox:SetChecked(mouseTrail)
    mouseTrailCheckbox:SetScript("OnClick", function(self)
        mouseTrail = self:GetChecked()
        specDB.mouseTrail = mouseTrail
        SaveSpecSettings()
        UpdateMouseTrail(mouseTrail)
    end)

    local mouseTrailLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    mouseTrailLabel:SetPoint("LEFT", mouseTrailCheckbox, "RIGHT", 5, 0)
    mouseTrailLabel:SetText("Enable Mouse Trail")

    -- Sparkle Trail Checkbox
    sparkleTrail = specDB.sparkleTrail or false
    local sparkleCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    sparkleCheckbox:SetPoint("LEFT", mouseTrailLabel, "RIGHT", 100, 0)
    sparkleCheckbox:SetChecked(sparkleTrail)
    sparkleCheckbox:SetScript("OnClick", function(self)
        sparkleTrail = self:GetChecked()
        specDB.sparkleTrail = sparkleTrail
        SaveSpecSettings()
    end)

    local sparkleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sparkleLabel:SetPoint("LEFT", sparkleCheckbox, "RIGHT", 5, 0)
    sparkleLabel:SetText("Enable Sparkle Effect on Mouse Trail")

    -- Trail Color Picker
    trailColor = specDB.trailColor or { r = 1, g = 1, b = 1 }
    local trailColorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    trailColorLabel:SetPoint("TOPLEFT", mouseTrailCheckbox, "BOTTOMLEFT", 0, -40)
    trailColorLabel:SetText("Mouse Trail Color:")

    local trailColorButton = CreateFrame("Button", nil, panel)
    trailColorButton:SetPoint("LEFT", trailColorLabel, "RIGHT", 10, 0)
    trailColorButton:SetSize(16, 16)
    StyleColorButtonInset(trailColorButton)

    local trailColorTexture = trailColorButton:CreateTexture(nil, "ARTWORK")
    trailColorTexture:SetAllPoints()
    trailColorTexture:SetColorTexture(trailColor.r, trailColor.g, trailColor.b, 1)

    trailColorButton:SetScript("OnClick", function()
        local info = {}
        info.r, info.g, info.b = trailColor.r, trailColor.g, trailColor.b
        info.hasOpacity = false
        info.swatchFunc = function()
            local r, g, b
            if ColorPickerFrame and ColorPickerFrame.GetColorRGB then
                r, g, b = ColorPickerFrame:GetColorRGB()
            else
                r, g, b = trailColor.r, trailColor.g, trailColor.b
            end
            trailColorTexture:SetColorTexture(r, g, b, 1)
            trailColor.r, trailColor.g, trailColor.b = r, g, b
            specDB.trailColor = trailColor
            SaveSpecSettings()
        end
        info.cancelFunc = function(previous)
            trailColorTexture:SetColorTexture(previous.r, previous.g, previous.b, 1)
            trailColor = { r = previous.r, g = previous.g, b = previous.b }
            specDB.trailColor = trailColor
            SaveSpecSettings()
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

    -- Sparkle Color Picker
    sparkleColor = specDB.sparkleColor or { r = 1, g = 1, b = 1 }
    local sparkleColorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sparkleColorLabel:SetPoint("TOPLEFT", sparkleCheckbox, "BOTTOMLEFT", 0, -40)
    sparkleColorLabel:SetText("Sparkle Color:")

    local sparkleColorButton = CreateFrame("Button", nil, panel)
    sparkleColorButton:SetPoint("LEFT", sparkleColorLabel, "RIGHT", 10, 0)
    sparkleColorButton:SetSize(16, 16)
    StyleColorButtonInset(sparkleColorButton)

    local sparkleColorTexture = sparkleColorButton:CreateTexture(nil, "ARTWORK")
    sparkleColorTexture:SetAllPoints()
    sparkleColorTexture:SetColorTexture(sparkleColor.r, sparkleColor.g, sparkleColor.b, 1)

    sparkleColorButton:SetScript("OnClick", function()
        local info = {}
        info.r, info.g, info.b = sparkleColor.r, sparkleColor.g, sparkleColor.b
        info.hasOpacity = false
        info.swatchFunc = function()
            local r, g, b
            if ColorPickerFrame and ColorPickerFrame.GetColorRGB then
                r, g, b = ColorPickerFrame:GetColorRGB()
            else
                r, g, b = sparkleColor.r, sparkleColor.g, sparkleColor.b
            end
            sparkleColorTexture:SetColorTexture(r, g, b, 1)
            sparkleColor.r, sparkleColor.g, sparkleColor.b = r, g, b
            specDB.sparkleColor = sparkleColor
            SaveSpecSettings()
        end
        info.cancelFunc = function(previous)
            sparkleColorTexture:SetColorTexture(previous.r, previous.g, previous.b, 1)
            sparkleColor = { r = previous.r, g = previous.g, b = previous.b }
            specDB.sparkleColor = sparkleColor
            SaveSpecSettings()
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

    -- Mouse Trail Fade Slider
    local fadeTime = specDB.fadeTime or 1.0
    local fadeTimeSlider = CreateFrame("Slider", "CursorRingTrailFadeTimeSlider", panel, "OptionsSliderTemplate")
    fadeTimeSlider:SetPoint("TOPLEFT", trailColorLabel, "BOTTOMLEFT", 0, -40)
    fadeTimeSlider:SetMinMaxValues(0.1, 6.0)
    fadeTimeSlider:SetValueStep(0.1)
    fadeTimeSlider:SetValue(fadeTime)
    fadeTimeSlider.Low:SetText("Short")
    fadeTimeSlider.High:SetText("Long")
    _G[fadeTimeSlider:GetName() .. "Text"]:SetText("Mouse Trail Length")
    fadeTimeSlider:SetScript("OnValueChanged", function(self, value)
        fadeTime = value
        specDB.fadeTime = fadeTime
        SaveSpecSettings()
    end)

    -- Register Panel (Old & New API)
    if Settings and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    else
        local success = pcall(function()
            local oldAPI = _G["InterfaceOptions_AddCategory"]
            if oldAPI then
                oldAPI(panel)
            end
        end)
        if not success then
            print("CursorRing: Could not register options panel (unsupported client version).")
        end
    end
end

-- Event handling
local addon = CreateFrame("Frame")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")
addon:RegisterEvent("UNIT_SPELLCAST_START")
addon:RegisterEvent("UNIT_SPELLCAST_STOP")
addon:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
addon:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
addon:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_LOGIN") -- For modern settings panel registration

addon:SetScript("OnEvent", function(self,event,...)
    if event=="PLAYER_ENTERING_WORLD" or event=="PLAYER_SPECIALIZATION_CHANGED" then
        LoadSpecSettings()
        CreateCursorRing()
        CreateOptionsPanel()
        UpdateRingVisibility()
        UpdateMouseTrailVisibility()
    elseif event=="UNIT_SPELLCAST_START" or event=="UNIT_SPELLCAST_CHANNEL_START" then
        local unit = ...
        if unit=="player" then casting = true end
    elseif event=="UNIT_SPELLCAST_STOP" or event=="UNIT_SPELLCAST_CHANNEL_STOP" then
        local unit = ...
        if unit=="player" then casting = false end
    elseif event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "CursorRing" then
            LoadSpecSettings()
            CreateCursorRing()
            CreateOptionsPanel()
            UpdateRingVisibility()
            UpdateMouseTrailVisibility()
        end
   -- Only initialize panel frame, don't register it yet
    CreateOptionsPanel()
    elseif event == "PLAYER_LOGIN" then
        if panelFrame and Settings and Settings.RegisterAddOnCategory and Settings.RegisterCanvasLayoutCategory then
            local ok, err = pcall(function()
            local category = Settings.RegisterCanvasLayoutCategory(panelFrame, "CursorRing")
            Settings.RegisterAddOnCategory(category)
            end)
            if not ok then
                print("CursorRing: Could not register options panel:", err)
            end
        end
    end
end)
