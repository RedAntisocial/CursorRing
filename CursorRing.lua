-- Default ring size... because if I let it be decided by the image size, it's HUUUUUGE
local ringSize = 64

-- Load saved settings or create default table
CursorRingDB = CursorRingDB or {}
ringSize = CursorRingDB.ringSize or 64

-- Get class color as default for main ring
local _, class = UnitClass("player")
local defaultClassColor = RAID_CLASS_COLORS[class]
local ringColor = CursorRingDB.ringColor or {r = defaultClassColor.r, g = defaultClassColor.g, b = defaultClassColor.b}
local castColor = CursorRingDB.castColor or {r = 1, g = 1, b = 1} -- Default to white

local addon = CreateFrame("Frame")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")
addon:RegisterEvent("UNIT_SPELLCAST_START")
addon:RegisterEvent("UNIT_SPELLCAST_STOP")
addon:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
addon:RegisterEvent("UNIT_SPELLCAST_FAILED")
addon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
addon:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
addon:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("ADDON_LOADED")

local ring, leftHalf, rightHalf, castSegments
local casting = false
local castStart, castEnd = 0, 0
local panelLoaded = false

-- Number of segments for the cast bar (100 segments for 1/100th textures)
local NUM_CAST_SEGMENTS = 100

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

-- Function to update cast color
local function UpdateCastColor(r, g, b)
    castColor.r, castColor.g, castColor.b = r, g, b
    CursorRingDB.castColor = castColor
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

    -- Create cast progress segments (assuming you'll provide a cast_segment.tga texture)
    castSegments = {}
    for i = 1, NUM_CAST_SEGMENTS do
        local segment = f:CreateTexture(nil, "OVERLAY")
        segment:SetTexture("Interface\\AddOns\\CursorRing\\cast_segment.tga", "CLAMP")
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

    -- OnUpdate: move to cursor and fill while casting
    f:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)

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
            
            -- Use segmented progress if cast_segment.tga exists, otherwise fall back to old method
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
    slider:SetMinMaxValues(64, 256)
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
    ringColorButton:SetPoint("LEFT", ringColorLabel, "RIGHT", 10, 0)
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

    -- Reset to Class Color Button
    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", castColorLabel, "BOTTOMLEFT", 0, -40)
    resetButton:SetSize(170, 25)
    resetButton:SetText("Reset Ring to Class Color")
    resetButton:SetScript("OnClick", function()
        local _, class = UnitClass("player")
        local classColor = RAID_CLASS_COLORS[class]
        ringColorTexture:SetColorTexture(classColor.r, classColor.g, classColor.b, 1)
        UpdateRingColor(classColor.r, classColor.g, classColor.b)
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

    elseif event == "PLAYER_LOGIN" or (event == "ADDON_LOADED" and arg1 == "CursorRing") then
        CreateOptionsPanel()
    end
end)
