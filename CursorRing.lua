-- Default ring size... because if I let it be decided by the image size, it's HUUUUUGE
local ringSize = 64

-- Load saved settings or create default table
CursorRingDB = CursorRingDB or {}
ringSize = CursorRingDB.ringSize or 64

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

local ring, leftHalf, rightHalf
local casting = false
local castStart, castEnd = 0, 0
local pcol = {r=1,g=1,b=1}
local panelLoaded = false

-- Function to update ring size
local function UpdateRingSize(size)
    ringSize = size
    CursorRingDB.ringSize = size
    if ring and ring:GetParent() then
        ring:GetParent():SetSize(ringSize, ringSize)
    end
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
    local _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class]
    ringTex:SetVertexColor(color.r, color.g, color.b, 1)
    ring = ringTex

    -- Left semicircle for the very bad castbar "animation"
    leftHalf = f:CreateTexture(nil, "OVERLAY")
    leftHalf:SetTexture("Interface\\AddOns\\CursorRing\\innerring_left.tga", "CLAMP")
    leftHalf:SetAllPoints()
    leftHalf:SetVertexColor(1,1,1,0)

    -- Right semicircle for the very bad castbar "animation"
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
                leftHalf:SetVertexColor(1,1,1,0)
                rightHalf:SetVertexColor(1,1,1,0)
                return
            end
            
            progress = math.min(math.max(progress, 0), 1)
            local angle = progress * 360

            leftHalf:SetVertexColor(pcol.r, pcol.g, pcol.b, 1)
            rightHalf:SetVertexColor(pcol.r, pcol.g, pcol.b, 1)

            if angle <= 180 then
                rightHalf:SetRotation(math.rad(angle))
                leftHalf:SetRotation(0)
                leftHalf:SetVertexColor(1,1,1,0)
            else
                rightHalf:SetRotation(math.rad(180))
                leftHalf:SetRotation(math.rad(angle - 180))
            end
        else
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
                local powerType = UnitPowerType("player")
                pcol = PowerBarColor[powerType] or {r=1,g=1,b=1}
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
                local powerType = UnitPowerType("player")
                pcol = PowerBarColor[powerType] or {r=1,g=1,b=1}
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
