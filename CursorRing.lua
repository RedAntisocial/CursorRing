-- CursorRing.lua
-- Local variables
local showOutOfCombat, cursorRingOptionsPanel
local ring, ringEnabled, ringSize, ringColor, ringTexture, ringColorTexture, ringColorButton
local casting, castColor, castStyle, castSegments, castFill, currentCastStyle, castColorTexture, castColorButton
local mouseTrail, mouseTrailActive, trailFadeTime, trailColor, trailColorButton, sparkleColor, sparkleTrail, sparkleColorButton, sparkleColorTexture, sparkleMultiplier
local panelLoaded = false
local panelFrame = nil
local trailGroup = {}
local MAX_TRAIL_POINTS = 20
local NUM_CAST_SEGMENTS = 240


-- Outer Ring Options
local outerRingOptions = {
    { name = "Ring", file = "ring.tga", style = "ring" },
    { name = "Thin Ring",   file = "thin_ring.tga", style = "ring" },
    { name = "Star",    file = "star.tga", style = "ring" },
    -- { name = "Heart",   file = "heart.tga", style = "ring" },
}

-- SavedVariables DB
CursorRingDB = CursorRingDB or {}

-- CLAMP!!! I SAID CLAMP!!!!
local function Clamp(val, min, max)
    if val < min then return min elseif val > max then return max end
    return val
end

-- Build the fill texture for the given donut... er ring...
local function GetFillTextureForRing(ringFile)
    local baseName = ringFile:gsub("%.tga$", "")
    return baseName .. "_fill.tga"
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

    -- Ring Texture
    ringTexture = specDB.ringTexture or "ring.tga"

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
    specDB.ringTexture = ringTexture
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
    specDB.ringTexture = ringTexture
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

-- Update Cast Style (fill or ring. Ring is better, but some people want fill)
local function UpdateCastStyle(style)
    castStyle = style
    GetSpecDB().castStyle = castStyle
    SaveSpecSettings()

    if not ring or not ring:GetParent() then return end

    local f = ring:GetParent()
    -- Clear existing segments (fix for segments not sodding off when changing styles)
    if castSegments then
        for i=1,NUM_CAST_SEGMENTS do
            if castSegments[i] then
                castSegments[i]:Hide()
                castSegments[i] = nil
            end
        end
    end
    castSegments = {}

    -- Create segments
    for i=1,NUM_CAST_SEGMENTS do
        local segment = f:CreateTexture(nil, "BACKGROUND")
        local texturePath
        if castStyle == "fill" then
            texturePath = "Interface\\AddOns\\CursorRing\\" .. GetFillTextureForRing(ringTexture)
        else
            texturePath = "Interface\\AddOns\\CursorRing\\cast_segment.tga"
        end
        segment:SetTexture(texturePath, "CLAMP")
        segment:SetAllPoints()
        segment:SetRotation(math.rad((i-1)*(360/NUM_CAST_SEGMENTS)))
        segment:SetVertexColor(1, 1, 1, 0)
        castSegments[i] = segment
    end
    if castStyle == "fill" and castFill then
        castFill:Show()
        local specDB = GetSpecDB()
        local fillColor = specDB.castColor or { r = 1, g = 1, b = 1 }
        castFill:SetVertexColor(fillColor.r, fillColor.g, fillColor.b, 1)
    end

end

-- Update Ring Texture/Shape
local function UpdateRingTexture(textureFile)
    if ring then
        ring:SetTexture("Interface\\AddOns\\CursorRing\\"..textureFile)
    end
    if castFill then
        castFill:SetTexture("Interface\\AddOns\\CursorRing\\" .. GetFillTextureForRing(textureFile))
    end
    GetSpecDB().ringTexture = textureFile
    SaveSpecSettings()

    -- Refresh cast segments if using fill style
    if castStyle == "fill" then
        UpdateCastStyle(castStyle)
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

-- Update Cast Segments for the selected shape
local function UpdateCastSegmentsForShape(shape)
    castStyle = shape  -- "ring" or "fill"
    UpdateCastStyle(castStyle)
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
    f:SetIgnoreParentScale(true)
    f:EnableMouse(false)
    f:SetClampedToScreen(true)
    f:SetClampRectInsets(0,0,0,0)

    -- Outer ring
    ring = f:CreateTexture(nil, "BORDER")
    ring:SetTexture("Interface\\AddOns\\CursorRing\\"..(GetSpecDB().ringTexture or "ring.tga"), "CLAMP")
    ring:SetAllPoints()
    ring:SetVertexColor(ringColor.r, ringColor.g, ringColor.b, 1)

    -- Cast segments
    castSegments = {}
    for i = 1, NUM_CAST_SEGMENTS do
        local segment = f:CreateTexture(nil, "ARTWORK")
        local texturePath
        if castStyle == "fill" then
            texturePath = "Interface\\AddOns\\CursorRing\\" .. GetFillTextureForRing(ringTexture)
        else
            texturePath = "Interface\\AddOns\\CursorRing\\cast_segment.tga"
        end
        segment:SetTexture(texturePath, "CLAMP")
        segment:SetAllPoints()
        segment:SetRotation(math.rad((i-1)*(360/NUM_CAST_SEGMENTS)))
        segment:SetVertexColor(1, 1, 1, 0)
        castSegments[i] = segment
    end

    -- Cast Fill (for scaling animation)
    castFill = f:CreateTexture(nil, "OVERLAY")
    castFill:SetTexture("Interface\\AddOns\\CursorRing\\" .. GetFillTextureForRing(ringTexture)) -- ensure *_fill.tga
    local specDB = GetSpecDB()
    local fillColor = specDB.castColor or { r = 1, g = 1, b = 1 }
    castFill:SetVertexColor(fillColor.r, fillColor.g, fillColor.b, 1)
    castFill:SetAlpha(0)
    castFill:SetSize(ringSize*0.01, ringSize*0.01)
    castFill:SetPoint("CENTER", f, "CENTER")

    UpdateCastStyle(castStyle)

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

    -- OnUpdate - cursor position only
    f:SetScript("OnUpdate", function(self, elapsed)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        x = x
        y = y
		
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)

        -- Mouse Trail
        if mouseTrailActive then
            local now = GetTime()
            table.insert(trailGroup, { x=x, y=y, created=now })
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
                    point.tex:ClearAllPoints()
                    point.tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", point.x, point.y)
                    local rc = trailColor or { r=1, g=1, b=1 }
                    point.tex:SetVertexColor(rc.r, rc.g, rc.b, Clamp(fade*0.8,0,1))
                    point.tex:SetAlpha(fade)
                    point.tex:SetSize(ringSize*0.4*fade, ringSize*0.4*fade)
                    point.tex:Show()
                    if sparkleTrail then
                        if not point.sparkle then 
                            point.sparkle = CreateSparkleTexture(self) 
                            point.sparkle:SetBlendMode("ADD")  -- ensures smooth additive glow
                        end

                        -- Circular distribution
                        local radius = specDB.ringSize * 0.3
                        local angle = math.random() * 2 * math.pi
                        local distance = (math.random() ^ 1.4) * radius -- Adjust center bias ( > 1 = more center bias)
                        local dx = math.cos(angle) * distance
                        local dy = math.sin(angle) * distance

                        point.sparkle:ClearAllPoints()
                        point.sparkle:SetPoint("CENTER", UIParent, "BOTTOMLEFT", point.x + dx, point.y + dy)

                        local sc = sparkleColor or { r = 1, g = 1, b = 1 }
                        point.sparkle:SetVertexColor(sc.r, sc.g, sc.b, 1)

                        -- Fade slowly and smoothly
                        local fadeSpeed = 0.1 -- lower = slower fade
                        local fadeAdj = Clamp(fade / fadeSpeed, 0, 1) -- keeps alpha reaching 1
                        point.sparkle:SetAlpha(fadeAdj)

                        -- Randomized size for softness / natural variance
                        local baseSize = radius * fade * 0.5 * (specDB.sparkleMultiplier or 1.0)
                        local variance = math.random() * baseSize * 0.5
                        point.sparkle:SetSize(baseSize + variance, baseSize + variance)
                        point.sparkle:Show()
                    end
                end
            end
        end
    end)

    -- Separate ticker for cast progress updates (lower frequency)
    local castTicker = C_Timer.NewTicker(0.016, function()
        if not casting then return end
        
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
            -- Hide all segments when done
            if castFill then
                castFill:SetAlpha(0)
                castFill:SetSize(ringSize*0.01, ringSize*0.01)
            end
            if castSegments then
                for i=1,NUM_CAST_SEGMENTS do
                    if castSegments[i] then
                        castSegments[i]:SetVertexColor(1,1,1,0)
                    end
                end
            end
            return
        end

        progress = Clamp(progress, 0, 1)

        -- Fill style
        if castStyle == "fill" and castFill then
            castFill:SetAlpha(progress > 0 and 1 or 0)
            local size = ringSize * math.max(progress, 0.01)
            castFill:SetSize(size, size)
        end

        -- Ring style (segment reveal)
        if castStyle == "ring" and castSegments then
            local numLit = math.floor(progress * NUM_CAST_SEGMENTS + 0.5)
            for i=1,NUM_CAST_SEGMENTS do
                if castSegments[i] then
                    castSegments[i]:SetVertexColor(castColor.r, castColor.g, castColor.b, i <= numLit and 1 or 0)
                end
            end
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

    local panel = CreateFrame("Frame", "cursorRingOptionsPanel", UIParent)
    panel.name = "CursorRing"

    cursorRingOptionsPanel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("CursorRing Settings")

    -- Show Out of Combat Checkbox
    showOutOfCombat = specDB.showOutOfCombat or false
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
    ringEnabled = specDB.ringEnabled
    if ringEnabled == nil then ringEnabled = true end
    local ringToggle = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    ringToggle:SetPoint("TOPLEFT", outOfCombatCheckbox, "BOTTOMLEFT", 0, -8)
    ringToggle:SetChecked(ringEnabled)
    ringToggle:SetScript("OnClick", function(self)
        ringEnabled = self:GetChecked()
        _G.ringEnabled = ringEnabled
        specDB.ringEnabled = ringEnabled
        SaveSpecSettings()
        UpdateRingVisibility()
    end)

    local ringToggleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ringToggleLabel:SetPoint("LEFT", ringToggle, "RIGHT", 5, 0)
    ringToggleLabel:SetText("Enable Cursor Ring")

    -- Ring Size Slider   
    ringSize = specDB.ringSize or 64
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
    ringColor = specDB.ringColor or { r = 1, g = 1, b = 1 }
    local ringColorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ringColorLabel:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -40)
    ringColorLabel:SetText("Ring Color:")

    ringColorButton = CreateFrame("Button", nil, panel)
    ringColorButton:SetPoint("LEFT", ringColorLabel, "LEFT", 110, 0)
    ringColorButton:SetSize(16, 16)

    -- Apply inset style to color button
    StyleColorButtonInset(ringColorButton)

    ringColorTexture = ringColorButton:CreateTexture(nil, "ARTWORK")
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

 -- Cursor Ring Shape / Texture Dropdown
    local ringTextureDropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    ringTextureDropdown:SetPoint("LEFT", ringColorLabel, "LEFT", 380, 0)
    ringTextureDropdown:SetSize(150, 25)
 
    local ringTextureLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ringTextureLabel:SetPoint("LEFT", ringColorLabel, "LEFT", 280, 0)
    ringTextureLabel:SetText("Ring Shape:")

    local currentTexture = GetSpecDB().ringTexture or "ring.tga" -- tracks the current selection

    local function OnRingTextureSelected(self, opt)
        currentTexture = opt.file                    -- update currentTexture
        ringTexture = opt.file                       -- update global ringTexture
        GetSpecDB().ringTexture = opt.file
        SaveSpecSettings()
        UpdateRingTexture(opt.file)

        UIDropDownMenu_SetSelectedValue(ringTextureDropdown, opt.file)
        UIDropDownMenu_SetText(ringTextureDropdown, opt.name)
        -- print("CursorRing: Dropdown updated ring texture to " .. ringTexture)
    end

    UIDropDownMenu_Initialize(ringTextureDropdown, function(self, level, menuList)
        for _, opt in ipairs(outerRingOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.name
            info.arg1 = opt
            info.func = OnRingTextureSelected
            info.checked = (currentTexture == opt.file)  -- now references the updated currentTexture
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- Set initial display after initialization
    UIDropDownMenu_SetSelectedValue(ringTextureDropdown, currentTexture)
    for _, opt in ipairs(outerRingOptions) do
        if opt.file == currentTexture then
            UIDropDownMenu_SetText(ringTextureDropdown, opt.name)
            break
        end
    end

    -- Cast Color Picker
    castColor = specDB.castColor or { r = 1, g = 1, b = 1 }
    local castColorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    castColorLabel:SetPoint("TOPLEFT", ringColorLabel, "BOTTOMLEFT", 0, -40)
    castColorLabel:SetText("Cast Effect Color:")

    castColorButton = CreateFrame("Button", nil, panel)
    castColorButton:SetPoint("LEFT", castColorLabel, "LEFT", 110, 0)
    castColorButton:SetSize(16, 16)

    -- Apply inset style to color button
    StyleColorButtonInset(castColorButton)

    castColorTexture = castColorButton:CreateTexture(nil, "ARTWORK")
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

    -- Cast Style Dropdown
    local styleDropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    styleDropdown:SetPoint("LEFT", castColorLabel, "LEFT", 380, 0)
    styleDropdown:SetSize(150, 25)
    
    local styleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    styleLabel:SetPoint("LEFT", castColorLabel, "LEFT", 280, 0)
    styleLabel:SetText("Cast Ring Style:")
    
    local castStyleOptions = {
        { text = "Ring", value = "ring" },
        { text = "Fill", value = "fill" },
    }

    currentCastStyle = GetSpecDB().castStyle or "ring"

    local function OnCastStyleSelected(self, styleValue)
        currentCastStyle = styleValue
        GetSpecDB().castStyle = styleValue
        SaveSpecSettings()
        UpdateCastStyle(styleValue)

        UIDropDownMenu_SetSelectedValue(styleDropdown, styleValue)
        UIDropDownMenu_SetText(styleDropdown, (styleValue == "ring" and "Ring" or "Fill"))
    end

    UIDropDownMenu_Initialize(styleDropdown, function(self)
        for _, opt in ipairs(castStyleOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.text
            info.arg1 = opt.value
            info.func = OnCastStyleSelected
            info.checked = (currentCastStyle == opt.value)
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetSelectedValue(styleDropdown, currentCastStyle)
    for _, opt in ipairs(castStyleOptions) do
        if opt.value == currentCastStyle then
            UIDropDownMenu_SetText(styleDropdown, opt.text)
            break
        end
    end

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
    mouseTrail = specDB.mouseTrail or false
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
    sparkleCheckbox:SetPoint("LEFT", mouseTrailCheckbox, "LEFT", 280, 0)
    sparkleCheckbox:SetChecked(sparkleTrail)
    sparkleCheckbox:SetScript("OnClick", function(self)
        sparkleTrail = self:GetChecked()
        specDB.sparkleTrail = sparkleTrail
        SaveSpecSettings()
    end)

    local sparkleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sparkleLabel:SetPoint("LEFT", sparkleCheckbox, "RIGHT", 5, 0)
    sparkleLabel:SetText("Enable Sparkle Effect on Mouse Trail")

    -- Mouse Trail Color Picker
    trailColor = specDB.trailColor or { r = 1, g = 1, b = 1 }
    local trailColorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    trailColorLabel:SetPoint("TOPLEFT", mouseTrailCheckbox, "BOTTOMLEFT", 0, -40)
    trailColorLabel:SetText("Mouse Trail Color:")

    trailColorButton = CreateFrame("Button", nil, panel)
    trailColorButton:SetPoint("LEFT", trailColorLabel, "RIGHT", 10, 0)
    trailColorButton:SetSize(16, 16)

    -- Apply inset style to color button
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

    -- Sparkle Color Picker
    sparkleColor = specDB.sparkleColor or { r = 1, g = 1, b = 1 }
    local sparkleColorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sparkleColorLabel:SetPoint("LEFT", trailColorLabel, "LEFT", 280, 0)
    sparkleColorLabel:SetText("Sparkle Color:")

    sparkleColorButton = CreateFrame("Button", nil, panel)
    sparkleColorButton:SetPoint("LEFT", sparkleColorLabel, "RIGHT", 10, 0)
    sparkleColorButton:SetSize(16, 16)

    -- Apply inset style to color button
    StyleColorButtonInset(sparkleColorButton)

    sparkleColorTexture = sparkleColorButton:CreateTexture(nil, "ARTWORK")
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

    -- Mouse Trail Fade Slider
    trailFadeTime = specDB.trailFadeTime or 1.0
    local fadeTimeSlider = CreateFrame("Slider", "CursorRingTrailFadeTimeSlider", panel, "OptionsSliderTemplate")
    fadeTimeSlider:SetPoint("TOPLEFT", trailColorLabel, "BOTTOMLEFT", 0, -40)
    fadeTimeSlider:SetMinMaxValues(0.1, 6.0)
    fadeTimeSlider:SetValueStep(0.1)
    fadeTimeSlider:SetValue(trailFadeTime)
    fadeTimeSlider.Low:SetText("Short")
    fadeTimeSlider.High:SetText("Long")
    _G[fadeTimeSlider:GetName() .. "Text"]:SetText("Mouse Trail Length")
    fadeTimeSlider:SetScript("OnValueChanged", function(self, value)
        trailFadeTime = value
        specDB.trailFadeTime = trailFadeTime
        SaveSpecSettings()
    end)

    -- Sparkle Trail Size Slider
    sparkleMultiplier = specDB.sparkleMultiplier or 1.0  -- default 1x
    local sparkleSlider = CreateFrame("Slider", "CursorRingSparkleSizeSlider", panel, "OptionsSliderTemplate")
    sparkleSlider:SetPoint("TOPLEFT", fadeTimeSlider, "BOTTOMLEFT", 0, -30)
    sparkleSlider:SetMinMaxValues(0.3, 10.0)
    sparkleSlider:SetValueStep(0.1)
    sparkleSlider:SetValue(sparkleMultiplier)
    sparkleSlider.Low:SetText("Small")
    sparkleSlider.High:SetText("Huge")
    _G[sparkleSlider:GetName() .. "Text"]:SetText("Sparkle Size Multiplier")

    sparkleSlider:SetScript("OnValueChanged", function(self, value)
        sparkleMultiplier = value
        specDB.sparkleMultiplier = sparkleMultiplier
        SaveSpecSettings()
    end)

    -- store panel controls globally for refresh so it updates correctly on spec change
    cursorRingOptionsPanel.outOfCombatCheckbox = outOfCombatCheckbox
    cursorRingOptionsPanel.ringToggle = ringToggle
    cursorRingOptionsPanel.slider = slider
    cursorRingOptionsPanel.ringColorTexture = ringColorTexture
    cursorRingOptionsPanel.castColorTexture = castColorTexture
    cursorRingOptionsPanel.ringTextureDropdown = ringTextureDropdown
    cursorRingOptionsPanel.styleDropdown = styleDropdown
    cursorRingOptionsPanel.trailColorTexture = trailColorTexture
    cursorRingOptionsPanel.sparkleColorTexture = sparkleColorTexture

    -- Register Panel
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
end

-- Refresh the options panel UI to reflect current spec's settings
local function UpdateOptionsPanel()
    if not panelLoaded or not cursorRingOptionsPanel then return end
    local specDB = GetSpecDB()

    -- Checkboxes
    if cursorRingOptionsPanel.outOfCombatCheckbox then
        cursorRingOptionsPanel.outOfCombatCheckbox:SetChecked(specDB.showOutOfCombat or false)
    end
    if cursorRingOptionsPanel.ringToggle then
        cursorRingOptionsPanel.ringToggle:SetChecked(specDB.ringEnabled ~= false)
    end

    -- Sliders
    if cursorRingOptionsPanel.slider then
        cursorRingOptionsPanel.slider:SetValue(specDB.ringSize or 64)
    end
    if cursorRingOptionsPanel.trailFadeTimeSlider then
        cursorRingOptionsPanel.trailFadeTimeSlider:SetValue(specDB.trailFadeTime or 1.0)
    end
    if cursorRingOptionsPanel.sparkleSizeSlider then
        cursorRingOptionsPanel.sparkleSizeSlider:SetValue(specDB.sparkleMultiplier or 1.0)
    end

    -- Color buttons
    if cursorRingOptionsPanel.ringColorTexture then
        local c = specDB.ringColor or { r = 1, g = 1, b = 1 }
        cursorRingOptionsPanel.ringColorTexture:SetColorTexture(c.r, c.g, c.b, 1)
    end
    if cursorRingOptionsPanel.castColorTexture then
        local c = specDB.castColor or { r = 1, g = 1, b = 1 }
        cursorRingOptionsPanel.castColorTexture:SetColorTexture(c.r, c.g, c.b, 1)
    end
    if cursorRingOptionsPanel.trailColorTexture then
        local c = specDB.trailColor or { r = 1, g = 1, b = 1 }
        cursorRingOptionsPanel.trailColorTexture:SetColorTexture(c.r, c.g, c.b, 1)
    end
    if cursorRingOptionsPanel.sparkleColorTexture then
        local c = specDB.sparkleColor or { r = 1, g = 1, b = 1 }
        cursorRingOptionsPanel.sparkleColorTexture:SetColorTexture(c.r, c.g, c.b, 1)
    end

    -- Dropdowns
    if cursorRingOptionsPanel.ringTextureDropdown then
        local tex = specDB.ringTexture or "ring.tga"
        UIDropDownMenu_SetSelectedValue(cursorRingOptionsPanel.ringTextureDropdown, tex)
        for _, opt in ipairs(outerRingOptions) do
            if opt.file == tex then
                UIDropDownMenu_SetText(cursorRingOptionsPanel.ringTextureDropdown, opt.name)
                break
            end
        end
    end
    if cursorRingOptionsPanel.styleDropdown then
        local style = specDB.castStyle or "ring"
        UIDropDownMenu_SetSelectedValue(cursorRingOptionsPanel.styleDropdown, style)
        UIDropDownMenu_SetText(cursorRingOptionsPanel.styleDropdown, (style == "fill" and "Fill" or "Ring"))
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
addon:RegisterEvent("PLAYER_LOGIN")

addon:SetScript("OnEvent", function(self,event,...)
    if event=="PLAYER_ENTERING_WORLD" or event=="PLAYER_SPECIALIZATION_CHANGED" then
        LoadSpecSettings()
        CreateCursorRing()
        UpdateCastStyle(castStyle)
        CreateOptionsPanel()
        UpdateOptionsPanel()
        UpdateRingVisibility()
        UpdateMouseTrailVisibility()
        if ring then
            ring:SetTexture("Interface\\AddOns\\CursorRing\\"..ringTexture)
            -- print("CursorRing: Updated ring texture to " .. ringTexture)
        end
        if castFill then
            castFill:SetTexture("Interface\\AddOns\\CursorRing\\" .. GetFillTextureForRing(ringTexture))
        end        
    elseif event=="UNIT_SPELLCAST_START" or event=="UNIT_SPELLCAST_CHANNEL_START" then
        local unit = ...
        if unit=="player" then casting = true end
    elseif event=="UNIT_SPELLCAST_STOP" or event=="UNIT_SPELLCAST_CHANNEL_STOP" then
        local unit = ...
        if unit=="player" then
            casting = false
            if castSegments then
                for i = 1, NUM_CAST_SEGMENTS do
                    if castSegments[i] then
                        castSegments[i]:SetVertexColor(1,1,1,0)
                    end
                end
            end
        end
    elseif event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "CursorRing" then
            LoadSpecSettings()
            CreateCursorRing()
            UpdateCastStyle(castStyle)
            CreateOptionsPanel()
            CreateOptionsPanel()
            UpdateOptionsPanel()
            UpdateRingVisibility()
            UpdateMouseTrailVisibility()
        end
        CreateOptionsPanel()
        UpdateOptionsPanel()
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