-- Declaring local variables.
local ringEnabled, ringSize, ringColor, castColor, showOutOfCombat
local trailCheckbox, sparkleCheckbox, mouseTrail, mouseTrailActive, sparkleTrail, sparkleOffsetRange, trailFadeTime, trailColor

-- Load in the SavedVariables DB
CursorRingDB = CursorRingDB or {}

-- Get the player's current spec key
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

    -- Save defaults back if missing
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

    return specDB
end

-- Save settings per-spec
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
end

-- Get the current spec settings on load
local specDB = LoadSpecSettings()

local addon = CreateFrame("Frame")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")
addon:RegisterEvent("UNIT_SPELLCAST_START")
addon:RegisterEvent("UNIT_SPELLCAST_STOP")
addon:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
addon:RegisterEvent("UNIT_SPELLCAST_FAILED")
addon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
addon:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
addon:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
addon:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat
addon:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Leaving combat
addon:RegisterEvent("ZONE_CHANGED_NEW_AREA") -- Zone changes (for instance detection)
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("ADDON_LOADED")

local ring, leftHalf, rightHalf, castSegments
local casting = false
local castStart, castEnd = 0, 0
local panelLoaded = false
local castStyle = "ring"

-- Mouse trail variables
local trailGroup = {}       -- TODO: on/off to menu
local sparkleGroup = {}     -- TODO: on/off to menu dependent on trail
local MAX_TRAIL_POINTS = 20 -- TODO: add this to menu as slider
local NUM_CAST_SEGMENTS = 100
local hasCastSegments = false


-- Number of segments for the cast bar (240 segments for 1/240th textures)
local NUM_CAST_SEGMENTS = 240

-- Function to update ring size
local function UpdateRingSize(size)
    ringSize = size
    specDB.ringSize = size
    SaveSpecSettings()
    if ring and ring:GetParent() then
        ring:GetParent():SetSize(ringSize, ringSize)
    end
end

-- Function to update ring color
local function UpdateRingColor(r, g, b)
    ringColor.r, ringColor.g, ringColor.b = r, g, b
    specDB.ringColor = ringColor
    SaveSpecSettings()
    if ring then
        ring:SetVertexColor(r, g, b, 1)
    end
end

-- Function to update cast style
local function UpdateCastStyle(style)
    castStyle = style
    specDB.castStyle = style
    SaveSpecSettings()
    print("Cast style updated to:", style)

    -- Recreate cast segments with new texture if they exist
    if castSegments and ring and ring:GetParent() then
        local f = ring:GetParent()

        -- Remove old segments
        for i = 1, NUM_CAST_SEGMENTS do
            if castSegments[i] then
                castSegments[i]:Hide()
                castSegments[i] = nil
            end
        end

        -- Create new segments with updated texture
        castSegments = {}
        for i = 1, NUM_CAST_SEGMENTS do
            local segment = f:CreateTexture(nil, "OVERLAY")
            local segmentTexturePath = "Interface\\AddOns\\CursorRing\\cast_segment.tga"
            if castStyle == "wedge" then
                segmentTexturePath = "Interface\\AddOns\\CursorRing\\cast_wedge.tga"
            end
            segment:SetTexture(segmentTexturePath, "CLAMP")
            segment:SetAllPoints()

            -- Calculate rotation for this segment
            local angle = (i - 1) * (360 / NUM_CAST_SEGMENTS)
            segment:SetRotation(math.rad(angle))

            -- Start hidden
            segment:SetVertexColor(1, 1, 1, 0)

            castSegments[i] = segment
        end
    end
end

-- Function to update cast color
local function UpdateCastColor(r, g, b)
    castColor.r, castColor.g, castColor.b = r, g, b
    specDB.castColor = castColor
    SaveSpecSettings()
end

-- Function to check if ring/trail should be visible outside of combat/instances
local function ShouldShowAllowedByCombatRules()
    if InCombatLockdown() then return true end
    local inInst, t = IsInInstance()
    if inInst and (t=="party" or t=="raid" or t=="pvp" or t=="arena" or t=="scenario") then
        return true
    end
    return showOutOfCombat
end

-- Function to update ring visibility based on current conditions
local function UpdateRingVisibility()
    if ring then
        ring:SetShown(ringEnabled and ShouldShowAllowedByCombatRules())
    end
end

-- Function to update mouse trail visibility
local function UpdateMouseTrailVisibility()
    mouseTrailActive = mouseTrail and ShouldShowAllowedByCombatRules()
    if mouseTrailActive then
        for i, point in ipairs(trailGroup) do
            if point.tex then
                point.tex:SetAlpha(1)
            end
            if point.sparkle then
                point.sparkle:SetAlpha(1)
            end
        end
    else
        for i, point in ipairs(trailGroup) do
            if point.tex then
                point.tex:SetAlpha(0)
            end
            if point.sparkle then
                point.sparkle:SetAlpha(0)
            end
        end
    end
end

-- Function to update mouse trail setting
local function UpdateMouseTrail(enabled)
    mouseTrail = enabled
    specDB.mouseTrail = enabled
    SaveSpecSettings()
    UpdateMouseTrailVisibility()
end

-- Function to update out of combat visibility setting
local function UpdateShowOutOfCombat(show)
    showOutOfCombat = show
    specDB.showOutOfCombat = show
    SaveSpecSettings()
    UpdateRingVisibility()
    UpdateMouseTrailVisibility()
end

-- Function to create the cursor ring frame
local function CreateCursorRing()
    if ring then return end -- prevent multiple frames
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(ringSize, ringSize)
    f:SetFrameStrata("TOOLTIP")

    -- Outer class-colored ring
    local ringTex = f:CreateTexture(nil, "ARTWORK")
    ringTex:SetTexture("Interface\\AddOns\\CursorRing\\ring.tga", "CLAMP")
    ringTex:SetAllPoints()
    ringTex:SetVertexColor(ringColor.r, ringColor.g, ringColor.b, 1)
    ring = ringTex

    -- Create cast progress segments
    castSegments = {}
    for i = 1, NUM_CAST_SEGMENTS do
        local segment = f:CreateTexture(nil, "OVERLAY")
        local segmentTexturePath = "Interface\\AddOns\\CursorRing\\cast_segment.tga" -- Ensure a default is set
        -- print("Creating cast segment", i, "with style", castStyle)
        if castStyle == "wedge" then
            segmentTexturePath = "Interface\\AddOns\\CursorRing\\cast_wedge.tga"
        end
        segment:SetTexture(segmentTexturePath, "CLAMP")
        segment:SetAllPoints()

        -- Calculate rotation for this segment (18 degrees per segment for 20 segments)
        local angle = (i - 1) * (360 / NUM_CAST_SEGMENTS)
        segment:SetRotation(math.rad(angle))

        -- Start hidden
        segment:SetVertexColor(1, 1, 1, 0)

        castSegments[i] = segment
    end

    -- Keep the old textures hidden for backwards compatibility (in case cast_segment.tga doesn't exist)
    leftHalf = f:CreateTexture(nil, "OVERLAY")
    leftHalf:SetTexture("Interface\\AddOns\\CursorRing\\innerring_left.tga", "CLAMP")
    leftHalf:SetAllPoints()
    leftHalf:SetVertexColor(1, 1, 1, 0)

    rightHalf = f:CreateTexture(nil, "OVERLAY")
    rightHalf:SetTexture("Interface\\AddOns\\CursorRing\\innerring_right.tga", "CLAMP")
    rightHalf:SetAllPoints()
    rightHalf:SetVertexColor(1, 1, 1, 0)

    -- Create Mouse Trail  textures
    local function CreateTrailTexture(parent)
        local tex = parent:CreateTexture(nil, "BACKGROUND")
        tex:SetTexture("Interface\\AddOns\\CursorRing\\trail_glow.tga")
        tex:SetBlendMode("ADD")
        tex:SetAlpha(0)
        tex:SetSize((ringSize or 64) * 0.5, (ringSize or 64) * 0.5)
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

    -- OnUpdate: move to cursor and fill while casting
    f:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
        -- print("MouseTrail: ", mouseTrail)
        -- Mouse trail
        if mouseTrailActive == true then
            local worldX, worldY = x / scale, y / scale
            local now = GetTime()

            table.insert(trailGroup, { x = worldX, y = worldY, created = now })

            -- Trim oldest points if over limit
            while #trailGroup > MAX_TRAIL_POINTS do
                local old = table.remove(trailGroup, 1)
                if old and old.tex then old.tex:Hide() end
                if old and old.sparkle then old.sparkle:Hide() end
            end

            -- Iterate backwards to safely remove expired points
            for i = #trailGroup, 1, -1 do
                local point = trailGroup[i]
                local age = now - point.created
                local trailFadeTime = CursorRingDB.fadeTime or 1.0
                local fade = 1 - (age / trailFadeTime)
                if fade <= 0 then
                    if point.tex then point.tex:Hide() end
                    if point.sparkle then point.sparkle:Hide() end
                    table.remove(trailGroup, i)
                else
                    if not point.tex then point.tex = CreateTrailTexture(self) end
                    point.tex:ClearAllPoints()
                    point.tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", point.x, point.y)
                    local rc = trailColor or { r = 1, g = 1, b = 1 }
                    point.tex:SetVertexColor(rc.r, rc.g, rc.b, Clamp(fade * 0.8, 0, 1))
                    point.tex:SetAlpha(fade)
                    local size = (ringSize or 64) * 0.4 * fade
                    point.tex:SetSize(size, size)
                    point.tex:Show()

                    -- Add Sparkles!!!!
                    if sparkleTrail then
                        if not point.sparkle then
                            point.sparkle = CreateSparkleTexture(self)
                        end

                        -- Random offset around the mouseTrail
                        local sparkleOffsetRange = sparkleOffsetRange or 12 -- pixels
                        local dx = (math.random() - 0.5) * 2 * sparkleOffsetRange
                        local dy = (math.random() - 0.5) * 2 * sparkleOffsetRange

                        point.sparkle:ClearAllPoints()
                        point.sparkle:SetPoint("CENTER", UIParent, "BOTTOMLEFT", point.x + dx, point.y + dy)
                        local sc = CursorRingDB.sparkleColor or { r = 1, g = 1, b = 1 }
                        point.sparkle:SetVertexColor(sc.r, sc.g, sc.b, 1)

                        local flicker = 1.7 + math.random() * 1.3
                        point.sparkle:SetAlpha(Clamp(fade * flicker, 0, 1))

                        point.sparkle:Show()
                    end
                end
            end
        end

        if casting then
            local now = GetTime()
            local progress = 0

            -- Check if we're currently casting or channeling
            local castName, _, _, castStartTime, castEndTime = UnitCastingInfo("player")
            local channelName, _, _, channelStartTime, channelEndTime = UnitChannelInfo("player")

            if castName then
                -- Regular cast
                progress = (now - (castStartTime / 1000)) / ((castEndTime - castStartTime) / 1000)
            elseif channelName then
                -- Channeled spell (progress goes from 1 to 0)
                progress = 1 - ((now - (channelStartTime / 1000)) / ((channelEndTime - channelStartTime) / 1000))
            else
                -- No cast detected, stop casting state
                casting = false
                -- Hide all segments
                if castSegments then
                    for i = 1, NUM_CAST_SEGMENTS do
                        castSegments[i]:SetVertexColor(1, 1, 1, 0)
                    end
                end
                -- Hide old halves too
                leftHalf:SetVertexColor(1, 1, 1, 0)
                rightHalf:SetVertexColor(1, 1, 1, 0)
                return
            end

            progress = math.min(math.max(progress, 0), 1)

            -- Use segmented progress if relevant textures exist, otherwise fall back to old method
            if castSegments and castSegments[1]:GetTexture() then
                -- Calculate how many segments to show
                local segmentsToShow = math.floor(progress * NUM_CAST_SEGMENTS)

                for i = 1, NUM_CAST_SEGMENTS do
                    if i <= segmentsToShow then
                        castSegments[i]:SetVertexColor(castColor.r, castColor.g, castColor.b, 1)
                    else
                        castSegments[i]:SetVertexColor(1, 1, 1, 0)
                    end
                end

                -- Hide old halves when using segments
                leftHalf:SetVertexColor(1, 1, 1, 0)
                rightHalf:SetVertexColor(1, 1, 1, 0)
            else
                -- Fallback to old spinning halves method
                local angle = progress * 360

                leftHalf:SetVertexColor(castColor.r, castColor.g, castColor.b, 1)
                rightHalf:SetVertexColor(castColor.r, castColor.g, castColor.b, 1)

                if angle <= 180 then
                    rightHalf:SetRotation(math.rad(angle))
                    leftHalf:SetRotation(0)
                    leftHalf:SetVertexColor(1, 1, 1, 0)
                else
                    rightHalf:SetRotation(math.rad(180))
                    leftHalf:SetRotation(math.rad(angle - 180))
                end

                -- Hide segments when using old method
                if castSegments then
                    for i = 1, NUM_CAST_SEGMENTS do
                        castSegments[i]:SetVertexColor(1, 1, 1, 0)
                    end
                end
            end
        else
            -- Hide everything when not casting
            if castSegments then
                for i = 1, NUM_CAST_SEGMENTS do
                    castSegments[i]:SetVertexColor(1, 1, 1, 0)
                end
            end
            leftHalf:SetVertexColor(1, 1, 1, 0)
            rightHalf:SetVertexColor(1, 1, 1, 0)
        end
    end)

    -- Set initial visibility based on current conditions
    UpdateRingVisibility()
end

-- Setting the styles for the Options Panel
-- Start with the color picker buttons

local function StyleColorButtonInset(button)
    local w, h = button:GetSize()

    -- Background
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(button)
    bg:SetColorTexture(0, 0, 0, 0.3) -- semi-transparent dark

    -- Outer border (black)
    local border = button:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0, 0, 0, 1)

    -- Inner highlight (top-left inset)
    local highlight = button:CreateTexture(nil, "OVERLAY")
    highlight:SetPoint("TOPLEFT", -1, 1)
    highlight:SetPoint("BOTTOMRIGHT", 0, 0)
    highlight:SetColorTexture(1, 1, 1, 0.1)

    -- Keep original swatch texture on top
    if button:GetNormalTexture() then
        button:GetNormalTexture():SetDrawLayer("OVERLAY", 1)
    end
end

-- Function to create the options panel (this was a pain in the ass. Make sure you rip code off of newer addons next time dumbass)
local function CreateOptionsPanel()
    if panelLoaded then return end
    panelLoaded = true

    local panel = CreateFrame("Frame", "CursorRingOptionsPanel", UIParent)
    panel.name = "CursorRing"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("CursorRing Settings")

    -- Show Out of Combat Checkbox
    local outOfCombatCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    outOfCombatCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)

    local outOfCombatLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    outOfCombatLabel:SetPoint("LEFT", outOfCombatCheckbox, "RIGHT", 5, 0)
    outOfCombatLabel:SetText("Show Ring and Mouse Trail outside of combat/instances")

    outOfCombatCheckbox:SetChecked(showOutOfCombat)
    outOfCombatCheckbox:SetScript("OnClick", function(self)
        UpdateShowOutOfCombat(self:GetChecked())
    end)

    -- Enable Ring Checkbox
    local ringToggle = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    ringToggle:SetPoint("TOPLEFT", outOfCombatCheckbox, "BOTTOMLEFT", 0, -8) -- anchor as you wish
    ringToggle:SetChecked(ringEnabled)
    ringToggle:SetScript("OnClick", function(self)
        ringEnabled = self:GetChecked()
        CursorRingDB.ringEnabled = ringEnabled
        UpdateRingVisibility()
    end)

    local lbl = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lbl:SetPoint("LEFT", ringToggle, "RIGHT", 5, 0)
    lbl:SetText("Enable Cursor Ring")

    -- Ring Size Slider
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
        UpdateRingSize(value)
    end)

    -- Ring Color Label
    local ringColorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ringColorLabel:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -40)
    ringColorLabel:SetText("Ring Color:")
 
    -- Ring Color Picker Button
    local ringColorButton = CreateFrame("Button", nil, panel)
    ringColorButton:SetPoint("LEFT", ringColorLabel, "RIGHT", 40, 0)
    ringColorButton:SetSize(16, 16)

    -- Apply inset style 
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
            UpdateRingColor(r, g, b)
        end
        info.cancelFunc = function(previous)
            ringColorTexture:SetColorTexture(previous.r, previous.g, previous.b, 1)
            UpdateRingColor(previous.r, previous.g, previous.b)
        end

        -- Use available color picker API
        local colorPickerFrame = _G["ColorPickerFrame"]
        if colorPickerFrame then
            if colorPickerFrame.SetupColorPickerAndShow then
                colorPickerFrame:SetupColorPickerAndShow(info)
            else
                -- Fallback for older versions
                colorPickerFrame.func = info.swatchFunc
                colorPickerFrame.cancelFunc = info.cancelFunc
                if colorPickerFrame.SetColorRGB then
                    colorPickerFrame:SetColorRGB(info.r, info.g, info.b)
                end
                colorPickerFrame:Show()
            end
        end
    end)

    -- Cast Color Label
    local castColorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    castColorLabel:SetPoint("TOPLEFT", ringColorLabel, "BOTTOMLEFT", 0, -40)
    castColorLabel:SetText("Cast Ring Color:")

    -- Cast Color Picker Button
    local castColorButton = CreateFrame("Button", nil, panel)
    castColorButton:SetPoint("LEFT", castColorLabel, "RIGHT", 10, 0)
    castColorButton:SetSize(16, 16)

    -- Apply inset style 
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
            UpdateCastColor(r, g, b)
        end
        info.cancelFunc = function(previous)
            castColorTexture:SetColorTexture(previous.r, previous.g, previous.b, 1)
            UpdateCastColor(previous.r, previous.g, previous.b)
        end

        -- Use available color picker API
        local colorPickerFrame = _G["ColorPickerFrame"]
        if colorPickerFrame then
            if colorPickerFrame.SetupColorPickerAndShow then
                colorPickerFrame:SetupColorPickerAndShow(info)
            else
                -- Fallback for older versions
                colorPickerFrame.func = info.swatchFunc
                colorPickerFrame.cancelFunc = info.cancelFunc
                if colorPickerFrame.SetColorRGB then
                    colorPickerFrame:SetColorRGB(info.r, info.g, info.b)
                end
                colorPickerFrame:Show()
            end
        end
    end)

    -- Ring or Wedge Cast Style Dropdown
    local styleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    styleLabel:SetPoint("LEFT", castColorButton, "RIGHT", 100, 0)
    styleLabel:SetText("Cast Ring Style:")

    local styleDropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    styleDropdown:SetPoint("LEFT", styleLabel, "RIGHT", 5, 0)
    styleDropdown:SetSize(150, 25)

    local function OnStyleSelected(self, arg1, arg2, checked)
        UpdateCastStyle(arg1)
        UIDropDownMenu_SetText(styleDropdown, arg1 == "ring" and "Ring" or "Wedge")
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

    -- Set the initial display text based on current castStyle
    UIDropDownMenu_SetText(styleDropdown, castStyle == "ring" and "Ring" or "Wedge")
    -- Reset to Class Color Button
    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", castColorLabel, "BOTTOMLEFT", 0, -40)
    resetButton:SetSize(180, 25)
    resetButton:SetText("Reset Ring to Class Color")
    resetButton:SetScript("OnClick", function()
        local _, class = UnitClass("player")
        local classColor = RAID_CLASS_COLORS[class]
        ringColorTexture:SetColorTexture(classColor.r, classColor.g, classColor.b, 1)
        UpdateRingColor(classColor.r, classColor.g, classColor.b)
    end)

    -- Enable/Disable Mouse Trail Checkbox
    mouseTrail = CursorRingDB.mouseTrail or false
    local mouseTrailCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    mouseTrailCheckbox:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -20)
    mouseTrailCheckbox:SetChecked(mouseTrail)
    mouseTrailCheckbox:SetScript("OnClick", function(self)
        mouseTrail = self:GetChecked()
        -- print("Mouse Trail set to:", mouseTrail)
        UpdateMouseTrail(mouseTrail)
    end)
    -- Mouse Trail Checkbox
    local mouseTrailLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    mouseTrailLabel:SetPoint("LEFT", mouseTrailCheckbox, "RIGHT", 5, 0)
    mouseTrailLabel:SetText("Enable Mouse Trail")

    -- Mouse Trail Sparkles Checkbox
    sparkleTrail = CursorRingDB.sparkleTrail or false
    sparkleCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    sparkleCheckbox:SetPoint("LEFT", mouseTrailLabel, "RIGHT", 100, 0)
    sparkleCheckbox:SetChecked(sparkleTrail)
    sparkleCheckbox:SetScript("OnClick", function(self)
        sparkleTrail = self:GetChecked()
        CursorRingDB.sparkleTrail = sparkleTrail
        -- print("Sparkle Trail set to:", sparkleTrail)
    end)
    local sparkleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sparkleLabel:SetPoint("LEFT", sparkleCheckbox, "RIGHT", 5, 0)
    sparkleLabel:SetText("Enable Sparkle Effect on Mouse Trail")


    -- Mouse Trail Colour Label
    local trailColorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    trailColorLabel:SetPoint("TOPLEFT", mouseTrailCheckbox, "BOTTOMLEFT", 0, -40)
    trailColorLabel:SetText("Mouse Trail Color:")

    -- Mouse Trail Color Picker Button
    local trailColorButton = CreateFrame("Button", nil, panel)
    trailColorButton:SetPoint("LEFT", trailColorLabel, "RIGHT", 10, 0)
    trailColorButton:SetSize(16, 16)

    -- Apply inset style
    StyleColorButtonInset(trailColorButton)

    local trailColorTexture = trailColorButton:CreateTexture(nil, "ARTWORK")
    trailColorTexture:SetAllPoints()
    local trailColor = CursorRingDB.trailColor or { r = 1, g = 1, b = 1 }
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
            CursorRingDB.trailColor = trailColor
        end
        info.cancelFunc = function(previous)
            trailColorTexture:SetColorTexture(previous.r, previous.g, previous.b, 1)
            trailColor.r, trailColor.g, trailColor.b = previous.r, previous.g, previous.b
            CursorRingDB.trailColor = trailColor
        end

        -- Use available color picker API
        local colorPickerFrame = _G["ColorPickerFrame"]
        if colorPickerFrame then
            if colorPickerFrame.SetupColorPickerAndShow then
                colorPickerFrame:SetupColorPickerAndShow(info)
            else
                -- Fallback for older versions
                colorPickerFrame.func = info.swatchFunc
                colorPickerFrame.cancelFunc = info.cancelFunc
                if colorPickerFrame.SetColorRGB then
                    colorPickerFrame:SetColorRGB(info.r, info.g, info.b)
                end
                colorPickerFrame:Show()
            end
        end
    end)


    -- Sparkle Trail Colour Label
    local sparkleColorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sparkleColorLabel:SetPoint("TOPLEFT", sparkleCheckbox, "BOTTOMLEFT", 0, -40)
    sparkleColorLabel:SetText("Sparkle Color:")

    -- Sparkle Trail Color Picker ButtonBindingToIndex
    local sparkleColorButton = CreateFrame("Button", nil, panel)
    sparkleColorButton:SetPoint("LEFT", sparkleColorLabel, "RIGHT", 10, 0)
    sparkleColorButton:SetSize(16, 16)

    -- Apply inset style
    StyleColorButtonInset(sparkleColorButton)

    local sparkleColorTexture = sparkleColorButton:CreateTexture(nil, "ARTWORK")
    sparkleColorTexture:SetAllPoints()
    local sparkleColor = CursorRingDB.sparkleColor or { r = 1, g = 1, b = 1 }
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
            CursorRingDB.sparkleColor = sparkleColor
        end
        info.cancelFunc = function(previous)
            sparkleColorTexture:SetColorTexture(previous.r, previous.g, previous.b, 1)
            sparkleColor.r, sparkleColor.g, sparkleColor.b = previous.r, previous.g, previous.b
            CursorRingDB.sparkleColor = sparkleColor
        end

        -- Use available color picker API
        local colorPickerFrame = _G["ColorPickerFrame"]
        if colorPickerFrame then
            if colorPickerFrame.SetupColorPickerAndShow then
                colorPickerFrame:SetupColorPickerAndShow(info)
            else
                -- Fallback for older versions
                colorPickerFrame.func = info.swatchFunc
                colorPickerFrame.cancelFunc = info.cancelFunc
                if colorPickerFrame.SetColorRGB then
                    colorPickerFrame:SetColorRGB(info.r, info.g, info.b)
                end
                colorPickerFrame:Show()
            end
        end
    end)

    -- MouseTrail Fade Time Slider
    local fadeTimeSlider = CreateFrame("Slider", "CursorRingTrailFadeTimeSlider", panel, "OptionsSliderTemplate")
    fadeTimeSlider:SetPoint("TOPLEFT", trailColorLabel, "BOTTOMLEFT", 0, -40)
    fadeTimeSlider:SetMinMaxValues(0.1, 6.0)
    fadeTimeSlider:SetValue(CursorRingDB.fadeTime or 1.0)
    fadeTimeSlider:SetValueStep(0.1)
    fadeTimeSlider:SetScript("OnValueChanged", function(self, value)
        CursorRingDB.fadeTime = value
    end)
    fadeTimeSlider.Low:SetText("Short")
    fadeTimeSlider.High:SetText("Long")
    _G[fadeTimeSlider:GetName() .. "Text"]:SetText("Mouse Trail Length")


    -- This is the part you mucked up by using an old API
    if Settings and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    else
        -- Fallback for older clients - try to use the old interface if it exists
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

-- Single OnEvent handler, because as you learned, having multiple OnEvent handlers means only one gets used.
addon:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        CreateCursorRing()
    elseif event == "UNIT_SPELLCAST_START" then
        local unit = arg1
        if unit == "player" then
            local name, _, _, startTime, endTime = UnitCastingInfo("player")
            if name then
                casting = true
                castStart, castEnd = startTime / 1000, endTime / 1000
                -- Debug
                -- print("Regular cast started:", name)
            end
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unit = arg1
        if unit == "player" then
            local name, _, _, startTime, endTime = UnitChannelInfo("player")
            if name then
                casting = true
                castStart, castEnd = startTime / 1000, endTime / 1000
                -- Debug
                -- print("Channel started:", name)
            end
        end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" or
        event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_SUCCEEDED" or
        event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        local unit = arg1
        if unit == "player" then
            casting = false
            -- Debug
            -- print("Cast ended:", event)
        end
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" or
        event == "ZONE_CHANGED_NEW_AREA" then
        -- Combat or zone changed, update ring visibility
        UpdateRingVisibility()
        UpdateMouseTrailVisibility()
    elseif event == "ADDON_LOADED" and arg1 == "CursorRing" then
        CursorRingDB = CursorRingDB or {}

        -- Defaults
        local _, class = UnitClass("player")
        local defaultClassColor = RAID_CLASS_COLORS[class]

        ringSize = CursorRingDB.ringSize or 64
        showOutOfCombat = CursorRingDB.showOutOfCombat
        if showOutOfCombat == nil then showOutOfCombat = true end

        ringColor = CursorRingDB.ringColor or {
            r = defaultClassColor.r,
            g = defaultClassColor.g,
            b = defaultClassColor.b
        }
        castColor = CursorRingDB.castColor or { r = 1, g = 1, b = 1 }
        castStyle = CursorRingDB.castStyle or "ring"
        mouseTrail = CursorRingDB.mouseTrail or false
        sparkleTrail = CursorRingDB.sparkleTrail or false
        trailFadeTime = CursorRingDB.trailFadeTime or 0.6
        trailColor = CursorRingDB.trailColor or { r = 1, g = 1, b = 1 }

        -- Save defaults back if missing
        CursorRingDB.ringSize = ringSize
        CursorRingDB.ringColor = ringColor
        CursorRingDB.castColor = castColor
        CursorRingDB.showOutOfCombat = showOutOfCombat
        CursorRingDB.castStyle = castStyle
        CursorRingDB.mouseTrail = mouseTrail
        CursorRingDB.sparkleTrail = sparkleTrail
        CursorRingDB.trailFadeTime = trailFadeTime
        CursorRingDB.trailColor = trailColor

        CreateOptionsPanel()
    end
end)
