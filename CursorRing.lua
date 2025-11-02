-- Default ring size... because if I let it be decided by the image size, it's HUUUUUGE
local ringSize, ringColor, castColor, showOutOfCombat
local trailCheckbox, sparkleCheckbox, mouseTrail, sparkleTrail, sparkleOffsetRange, trailFadeTime, trailColor

-- Load saved settings or create default table
CursorRingDB = CursorRingDB or {}
ringSize = CursorRingDB.ringSize or 64
showOutOfCombat = CursorRingDB.showOutOfCombat or true

-- Get class color as default for main ring
local _, class = UnitClass("player")
local defaultClassColor = RAID_CLASS_COLORS[class]
local ringColor = CursorRingDB.ringColor or {r = defaultClassColor.r, g = defaultClassColor.g, b = defaultClassColor.b}
local castColor = CursorRingDB.castColor or {r = 1, g = 1, b = 1} -- Default to white
local showOutOfCombat = CursorRingDB.showOutOfCombat or CursorRingDB.showOutOfCombat == nil and true -- Default to true

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
local trailGroup = {}
local sparkleGroup = {}
local MAX_TRAIL_POINTS = 20
local NUM_CAST_SEGMENTS = 100
local hasCastSegments = false


-- Number of segments for the cast bar (240 segments for 1/240th textures)
local NUM_CAST_SEGMENTS = 240

-- Function to update ring size
local function UpdateRingSize(size)
    ringSize = size
    CursorRingDB.ringSize = size
    if ring and ring:GetParent() then
        ring:GetParent():SetSize(ringSize, ringSize)
    end
end

-- Function to update ring color
local function UpdateRingColor(r, g, b)
    ringColor.r, ringColor.g, ringColor.b = r, g, b
    CursorRingDB.ringColor = ringColor
    if ring then
        ring:SetVertexColor(r, g, b, 1)
    end
end

-- Function to update cast style
local function UpdateCastStyle(style)
    castStyle = style
    CursorRingDB.castStyle = style
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
    CursorRingDB.castColor = castColor
end

-- Function to check if ring should be visible
local function ShouldShowRing()
    -- Always show in combat
    if InCombatLockdown() then
        return true
    end
    
    -- Always show in instances (dungeons, raids, battlegrounds, arenas)
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "pvp" or instanceType == "arena") then
        return true
    end
    
    -- Otherwise, use the user setting
    return showOutOfCombat
end

-- Function to update ring visibility based on current conditions
local function UpdateRingVisibility()
    if not ring or not ring:GetParent() then return end
    
    local shouldShow = ShouldShowRing()
    if shouldShow then
        ring:GetParent():Show()
    else
        ring:GetParent():Hide()
    end
end

-- Function to update out of combat visibility setting
local function UpdateShowOutOfCombat(show)
    showOutOfCombat = show
    CursorRingDB.showOutOfCombat = show
    UpdateRingVisibility()
end

-- Function to create the cursor ring frame
local function CreateCursorRing()
    if ring then return end  -- prevent multiple frames
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(ringSize, ringSize)
    f:SetFrameStrata("HIGH")

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
        print("Creating cast segment", i, "with style", castStyle)
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
    leftHalf:SetVertexColor(1,1,1,0)

    rightHalf = f:CreateTexture(nil, "OVERLAY")
    rightHalf:SetTexture("Interface\\AddOns\\CursorRing\\innerring_right.tga", "CLAMP")
    rightHalf:SetAllPoints()
    rightHalf:SetVertexColor(1,1,1,0)

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

        -- Mouse trail
        if mouseTrail then
            local worldX, worldY = x / scale, y / scale
            local now = GetTime()

            table.insert(trailGroup, {x = worldX, y = worldY, created = now})

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
                local fade = 1 - (age / trailFadeTime)
                if fade <= 0 then
                    if point.tex then point.tex:Hide() end
                    if point.sparkle then point.sparkle:Hide() end
                    table.remove(trailGroup, i)
                else
                    if not point.tex then point.tex = CreateTrailTexture(self) end
                    point.tex:ClearAllPoints()
                    point.tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", point.x, point.y)
                    local rc = trailColor or {r=1,g=1,b=1}
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
                leftHalf:SetVertexColor(1,1,1,0)
                rightHalf:SetVertexColor(1,1,1,0)
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
                leftHalf:SetVertexColor(1,1,1,0)
                rightHalf:SetVertexColor(1,1,1,0)
            else
                -- Fallback to old spinning halves method
                local angle = progress * 360

                leftHalf:SetVertexColor(castColor.r, castColor.g, castColor.b, 1)
                rightHalf:SetVertexColor(castColor.r, castColor.g, castColor.b, 1)

                if angle <= 180 then
                    rightHalf:SetRotation(math.rad(angle))
                    leftHalf:SetRotation(0)
                    leftHalf:SetVertexColor(1,1,1,0)
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
            leftHalf:SetVertexColor(1,1,1,0)
            rightHalf:SetVertexColor(1,1,1,0)
        end
    end)
    
    -- Set initial visibility based on current conditions
    UpdateRingVisibility()
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

    -- Ring Size Slider
    local slider = CreateFrame("Slider", "CursorRingSizeSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -40)
    slider:SetMinMaxValues(32, 256)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(ringSize)
    _G[slider:GetName().."Text"]:SetText("Ring Size")

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
    ringColorButton:SetSize(40, 20)
    
    local ringColorTexture = ringColorButton:CreateTexture(nil, "BACKGROUND")
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
    castColorButton:SetSize(40, 20)
    
    local castColorTexture = castColorButton:CreateTexture(nil, "BACKGROUND")
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
    styleLabel:SetPoint("LEFT", castColorButton, "LEFT", 60, 0)
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

    -- Show Out of Combat Checkbox
    local outOfCombatCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    outOfCombatCheckbox:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -20)
    
    local outOfCombatLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    outOfCombatLabel:SetPoint("LEFT", outOfCombatCheckbox, "RIGHT", 5, 0)
    outOfCombatLabel:SetText("Show ring outside of combat/instances")
    
    outOfCombatCheckbox:SetChecked(showOutOfCombat)
    outOfCombatCheckbox:SetScript("OnClick", function(self)
        UpdateShowOutOfCombat(self:GetChecked())
    end)

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
    castColor = CursorRingDB.castColor or {r = 1, g = 1, b = 1}
    castStyle = CursorRingDB.castStyle or "ring"
        mouseTrail = CursorRingDB.mouseTrail or false
        sparkleTrail = CursorRingDB.sparkleTrail or false
        trailFadeTime = CursorRingDB.trailFadeTime or 0.6
        trailColor = CursorRingDB.trailColor or {r = 1, g = 1, b = 1}

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