-- CursorRing.lua

-- SavedVariables DB
CursorRingDB = CursorRingDB or {}

-- Local variables
local OptionsPanel = _G.OptionsPanel or {}

local showOutOfCombat, cursorRingOptionsPanel, combatAlpha, outOfCombatAlpha
local ring, ringEnabled, ringSize, ringColor, ringTexture, ringColorTexture, ringColorButton
local casting, castColor, castStyle, castSegments, castFill, currentCastStyle, castColorTexture, castColorButton
local mouseTrail, mouseTrailActive, trailFadeTime, trailColor, trailColorButton, sparkleColor, sparkleTrail, sparkleColorButton, sparkleColorTexture, sparkleMultiplier
local panelLoaded = false
local panelFrame = nil
local trailGroup = {}
local MAX_TRAIL_POINTS = 20
local NUM_CAST_SEGMENTS = 180


-- Outer Ring Options
local outerRingOptions = {
    { name = "Ring", file = "ring.tga", style = "ring", supportedStyles = {"ring", "fill", "wedge"} },
    { name = "Thin Ring",   file = "thin_ring.tga", style = "ring", supportedStyles = {"ring", "fill", "wedge"} },
    { name = "Star",    file = "star.tga", style = "ring", supportedStyles = {"fill"} },
    { name = "Hex",   file = "hex.tga", style = "ring", supportedStyles = {"fill"} },
    { name = "Hex 90",   file = "hex90.tga", style = "ring", supportedStyles = {"fill"} },
    -- { name = "Heart",   file = "heart.tga", style = "ring", supportedStyles = {"ring", "fill"} },
}

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

    ringSize = specDB.ringSize or 48
    showOutOfCombat = specDB.showOutOfCombat
    if showOutOfCombat == nil then showOutOfCombat = true end

    local _, class = UnitClass("player")
    local defaultClassColor = RAID_CLASS_COLORS[class]

    -- In/Out of Combat Alpha settings
	combatAlpha = specDB.combatAlpha or 1.0
    outOfCombatAlpha = specDB.outOfCombatAlpha or 1.0
	
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
	specDB.combatAlpha = combatAlpha
    specDB.outOfCombatAlpha = outOfCombatAlpha
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
	specDB.combatAlpha = combatAlpha
    specDB.outOfCombatAlpha = outOfCombatAlpha
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
        elseif castStyle == "wedge" then
            texturePath = "Interface\\AddOns\\CursorRing\\cast_wedge.tga"
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
    -- if InCombatLockdown() then return true end
	if InCombatLockdown() or UnitAffectingCombat("player") then return true end
    local inInst, t = IsInInstance()
    if inInst and (t=="party" or t=="raid" or t=="pvp" or t=="arena" or t=="scenario") then
        return true
    end
    return showOutOfCombat
end

-- Compute active alpha for any cursor element
local function GetCursorAlpha()
    local inCombat = InCombatLockdown()
    local inInst, t = IsInInstance()
    local inInstance = inInst and (t=="party" or t=="raid" or t=="pvp" or t=="arena" or t=="scenario")
    return (inCombat or inInstance) and (combatAlpha or 1.0) or (outOfCombatAlpha or 1.0)
end

local function UpdateRingVisibility()
    if ring then
        local shouldShow = ringEnabled and ShouldShowAllowedByCombatRules()
        ring:SetShown(shouldShow)
        if shouldShow then
            local inCombat = InCombatLockdown()
            local inInst, t = IsInInstance()
            local inInstance = inInst and (t=="party" or t=="raid" or t=="pvp" or t=="arena" or t=="scenario")
            
            -- Use combat alpha if in actual combat or instance
            local alpha = (inCombat or inInstance) and (combatAlpha or 1.0) or (outOfCombatAlpha or 1.0)
            ring:SetAlpha(alpha)
        end
    end
end

-- Update Mouse Trail Visibility
local function UpdateMouseTrailVisibility()
    mouseTrailActive = mouseTrail and ShouldShowAllowedByCombatRules()
    local alpha = GetCursorAlpha()

    for _, point in ipairs(trailGroup) do
        if point.tex then point.tex:SetAlpha(mouseTrailActive and alpha or 0) end
        if point.sparkle then point.sparkle:SetAlpha(mouseTrailActive and alpha or 0) end
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
    f:SetIgnoreParentScale(false)
    f:EnableMouse(false)
    f:SetClampedToScreen(false)

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
        elseif castStyle == "wedge" then
            texturePath = "Interface\\AddOns\\CursorRing\\cast_wedge.tga"
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
	local lastAlphaCheck = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        x = x / scale
        y = y / scale
		
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)

		-- Check alpha state periodically (every 0.5 seconds)
        lastAlphaCheck = lastAlphaCheck + elapsed
        if lastAlphaCheck >= 0.5 then
            lastAlphaCheck = 0
            if ring and ringEnabled and ShouldShowAllowedByCombatRules() then
                local inCombat = InCombatLockdown()
                local inInst, t = IsInInstance()
                local inInstance = inInst and (t=="party" or t=="raid" or t=="pvp" or t=="arena" or t=="scenario")
                local alpha = (inCombat or inInstance) and (combatAlpha or 1.0) or (outOfCombatAlpha or 1.0)
                ring:SetAlpha(alpha)
				-- Apply same alpha logic to cast fill
				if castFill then
					castFill:SetAlpha((castFill:GetAlpha() > 0) and alpha or 0)
				end

				-- Apply to cast segments
				if castSegments then
					for i = 1, NUM_CAST_SEGMENTS do
						local seg = castSegments[i]
						if seg then
							local r, g, b, a = seg:GetVertexColor()
							if a > 0 then
								seg:SetVertexColor(r, g, b, alpha)
							end
						end
					end
				end

				-- Apply to active trail points
				if mouseTrailActive then
					for _, point in ipairs(trailGroup) do
						if point.tex then
							local r, g, b = point.tex:GetVertexColor()
							point.tex:SetVertexColor(r, g, b, alpha)
						end
						if point.sparkle then
							local r, g, b = point.sparkle:GetVertexColor()
							point.sparkle:SetVertexColor(r, g, b, alpha)
						end
					end
				end
            end
        end

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
                    point.tex:SetAlpha(fade * GetCursorAlpha())
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
                        point.sparkle:SetAlpha(fadeAdj * GetCursorAlpha())

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
            -- Hide all segments and fill when done (not just cast rings)
            if castFill then
                castFill:SetAlpha(0)
                castFill:SetSize(ringSize*0.01, ringSize*0.01)
            end
            if castSegments then
                for i=1,NUM_CAST_SEGMENTS do
                    if castSegments[i] then
                        castSegments[i]:SetVertexColor(castColor.r, castColor.g, castColor.b,0)
                    end
                end
            end
            return
        end

        progress = Clamp(progress, 0, 1)

        local shouldShow = ringEnabled and ShouldShowAllowedByCombatRules()
        -- Fill style
        if castStyle == "fill" and castFill then
            castFill:SetAlpha(shouldShow and progress > 0 and 1 or 0)
            local size = ringSize * math.max(progress, 0.01)
            castFill:SetSize(size, size)
        end

        -- Ring/Wedge style (segment reveal)
        if (castStyle == "ring" or castStyle == "wedge") and castSegments then
            local numLit = math.floor(progress * NUM_CAST_SEGMENTS + 0.5)
            for i=1,NUM_CAST_SEGMENTS do
                if castSegments[i] then
                    castSegments[i]:SetVertexColor(castColor.r, castColor.g, castColor.b, shouldShow and i <= numLit and 1 or 0)
                end
            end
        end
    end)
    UpdateRingVisibility()
end

--[[
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
]]
-- Create Options Panel
-- Create Options Panel
local function CreateOptionsPanel()
    if panelLoaded then return end
    panelLoaded = true

    local specDB = GetSpecDB()

    local panel = OptionsPanel:NewPanel({
        name = "CursorRing",
        displayName = "CursorRing",
        title = "CursorRing Settings"
    })

    cursorRingOptionsPanel = panel

    -- Show Out of Combat Checkbox
    local showOutOfCombatCheckbox = OptionsPanel:AddCheckbox(panel, {
        key = "showOutOfCombat",
        label = "Show Ring and Mouse Trail outside of combat/instances",
        default = specDB.showOutOfCombat or false,
        anchor = panel.title,
        point = "TOPLEFT",
        relativePoint = "BOTTOMLEFT",
        xOffset = 0,
        yOffset = -20,
        onClick = function(checked)
            showOutOfCombat = checked
            specDB.showOutOfCombat = showOutOfCombat
            SaveSpecSettings()
            UpdateShowOutOfCombat(showOutOfCombat)
        end
    })

    -- Enable Ring Checkbox
    local ringEnabledCheckbox = OptionsPanel:AddCheckbox(panel, {
        key = "ringEnabled",
        label = "Enable Cursor Ring",
        default = specDB.ringEnabled ~= false,
        anchor = showOutOfCombatCheckbox,
        point = "TOPLEFT",
        relativePoint = "BOTTOMLEFT",
        xOffset = 0,
        yOffset = -8,
        onClick = function(checked)
            ringEnabled = checked
            _G.ringEnabled = ringEnabled
            specDB.ringEnabled = ringEnabled
            SaveSpecSettings()
            UpdateRingVisibility()
        end
    })

    -- Ring Size Slider
    local ringSizeSlider = OptionsPanel:AddSlider(panel, {
        key = "ringSize",
        name = "CursorRingSizeSlider",
        label = "Ring Size",
        min = 32,
        max = 256,
        step = 1,
        default = specDB.ringSize or 64,
        lowText = "Small",
        highText = "Large",
        anchor = ringEnabledCheckbox,
        point = "TOPLEFT",
        relativePoint = "BOTTOMLEFT",
        xOffset = 0,
        yOffset = -30,
        onValueChanged = function(value)
            ringSize = value
            specDB.ringSize = ringSize
            SaveSpecSettings()
            UpdateRingSize(ringSize)
        end
    })

	-- Combat Alpha Slider
    local combatAlphaSlider = OptionsPanel:AddSlider(panel, {
        key = "combatAlpha",
        name = "CursorRingCombatAlphaSlider",
        label = "In Combat Opacity",
        min = 0,
        max = 1,
        step = 0.05,
        default = specDB.combatAlpha or 1.0,
        lowText = "0%",
        highText = "100%",
        anchor = ringSizeSlider,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        xOffset = 200,
        yOffset = 0,
        onValueChanged = function(value)
            combatAlpha = value
            specDB.combatAlpha = combatAlpha
            SaveSpecSettings()
            -- Update ring alpha if in combat
            if ring and InCombatLockdown() then
                ring:SetAlpha(combatAlpha)
            end
        end
    })

    -- Out of Combat Alpha Slider
    local outOfCombatAlphaSlider = OptionsPanel:AddSlider(panel, {
        key = "outOfCombatAlpha",
        name = "CursorRingOutOfCombatAlphaSlider",
        label = "Out of Combat Opacity",
        min = 0,
        max = 1,
        step = 0.05,
        default = specDB.outOfCombatAlpha or 1.0,
        lowText = "0%",
        highText = "100%",
        anchor = combatAlphaSlider,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        xOffset = 200,
        yOffset = 0,
        onValueChanged = function(value)
            outOfCombatAlpha = value
            specDB.outOfCombatAlpha = outOfCombatAlpha
            SaveSpecSettings()
            -- Update ring alpha if out of combat
            if ring and not InCombatLockdown() then
                ring:SetAlpha(outOfCombatAlpha)
            end
        end
    })
	
    -- Ring Color Picker
    local ringColorData = specDB.ringColor or { r = 1, g = 1, b = 1 }
    local ringColorButton, ringColorTexture, ringColorLabel = OptionsPanel:AddColorPicker(panel, {
        key = "ringColor",
        label = "Ring Color:",
        r = ringColorData.r,
        g = ringColorData.g,
        b = ringColorData.b,
        anchor = ringSizeSlider,
        point = "TOPLEFT",
        relativePoint = "BOTTOMLEFT",
        xOffset = 0,
        yOffset = -40,
        onColorChanged = function(r, g, b)
            ringColor.r, ringColor.g, ringColor.b = r, g, b
            specDB.ringColor = ringColor
            SaveSpecSettings()
            UpdateRingColor(r, g, b)
        end
    })

    -- Ring Texture Dropdown (positioned to the right of Ring Color)
    local currentTexture = specDB.ringTexture or "ring.tga"
    local ringTextureOptions = {}
    for _, opt in ipairs(outerRingOptions) do
        table.insert(ringTextureOptions, { text = opt.name, value = opt.file })
    end

    local ringTextureDropdown, ringTextureLabel = OptionsPanel:AddDropdown(panel, {
        key = "ringTexture",
        label = "Ring Shape:",
        labelOffset = 100,
        width = 150,
        default = currentTexture,
        options = ringTextureOptions,
        anchor = ringColorLabel,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        xOffset = 280,
        yOffset = 0,
        onSelect = function(value)
            currentTexture = value
            ringTexture = value
            specDB.ringTexture = value
            
            local selectedOpt
            for _, opt in ipairs(outerRingOptions) do
                if opt.file == value then
                    selectedOpt = opt
                    break
                end
            end
            
            if selectedOpt then
                local supportedStyles = selectedOpt.supportedStyles or {"ring"}
                local isSupported = false
                for _, style in ipairs(supportedStyles) do
                    if style == currentCastStyle then
                        isSupported = true
                        break
                    end
                end
                
                if not isSupported then
                    currentCastStyle = supportedStyles[1]
                    specDB.castStyle = currentCastStyle
                end
            end
            
            SaveSpecSettings()
            UpdateRingTexture(value)
            UpdateCastStyle(currentCastStyle)
            
            if cursorRingOptionsPanel.RefreshStyleDropdown then
                cursorRingOptionsPanel.RefreshStyleDropdown()
            end
        end
    })

    -- Cast Color Picker (continues vertical flow from Ring Color)
    local castColorData = specDB.castColor or { r = 1, g = 1, b = 1 }
    local castColorButton, castColorTexture, castColorLabel = OptionsPanel:AddColorPicker(panel, {
        key = "castColor",
        label = "Cast Effect Color:",
        r = castColorData.r,
        g = castColorData.g,
        b = castColorData.b,
        anchor = ringColorLabel,
        point = "TOPLEFT",
        relativePoint = "BOTTOMLEFT",
        xOffset = 0,
        yOffset = -40,
        onColorChanged = function(r, g, b)
            castColor.r, castColor.g, castColor.b = r, g, b
            specDB.castColor = castColor
            SaveSpecSettings()
            UpdateCastColor(r, g, b)
        end
    })

    -- Cast Style Dropdown (positioned to the right of Cast Color)
    currentCastStyle = specDB.castStyle or "ring"
    local castStyleOptions = {
        { text = "Ring", value = "ring" },
        { text = "Fill", value = "fill" },
        { text = "Wedge", value = "wedge" },
    }

    local styleDropdown, styleLabel = OptionsPanel:AddDropdown(panel, {
        key = "castStyle",
        label = "Cast Ring Style:",
        labelOffset = 100,
        width = 150,
        default = currentCastStyle,
        options = castStyleOptions,
        anchor = castColorLabel,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        xOffset = 280,
        yOffset = 0,
        onSelect = function(value)
            currentCastStyle = value
            specDB.castStyle = value
            SaveSpecSettings()
            UpdateCastStyle(value)
        end
    })

    -- Function to refresh style dropdown
    function cursorRingOptionsPanel.RefreshStyleDropdown()
        local supportedStyles = {"ring"}
        for _, opt in ipairs(outerRingOptions) do
            if opt.file == currentTexture then
                supportedStyles = opt.supportedStyles or {"ring"}
                break
            end
        end
        
        local filteredOptions = {}
        for _, opt in ipairs(castStyleOptions) do
            for _, supportedStyle in ipairs(supportedStyles) do
                if supportedStyle == opt.value then
                    table.insert(filteredOptions, opt)
                    break
                end
            end
        end
        
        local displayText = "Ring"
        for _, opt in ipairs(castStyleOptions) do
            if opt.value == currentCastStyle then
                displayText = opt.text
                break
            end
        end
        OptionsPanel:UpdateDropdown(panel, "castStyle", currentCastStyle, displayText)
    end

    -- Reset Button (continues vertical flow from Cast Color)
    local resetButton = OptionsPanel:AddButton(panel, {
        key = "resetColor",
        text = "Reset",
        width = 60,
        height = 25,
        anchor = ringColorLabel,
        point = "LEFT",
        relativePoint = "LEFT",
        xOffset = 140,
        yOffset = 0,
        onClick = function()
            local _, class = UnitClass("player")
            local classColor = RAID_CLASS_COLORS[class]
            ringColor = { r = classColor.r, g = classColor.g, b = classColor.b }
            specDB.ringColor = ringColor
            SaveSpecSettings()
            UpdateRingColor(classColor.r, classColor.g, classColor.b)
            OptionsPanel:UpdateColorPicker(panel, "ringColor", classColor.r, classColor.g, classColor.b)
        end
    })

    -- Mouse Trail Checkbox (continues vertical flow)
    local mouseTrailCheckbox = OptionsPanel:AddCheckbox(panel, {
        key = "mouseTrail",
        label = "Enable Mouse Trail",
        default = specDB.mouseTrail or false,
        anchor = castColorLabel,
        point = "TOPLEFT",
        relativePoint = "BOTTOMLEFT",
        xOffset = 0,
        yOffset = -20,
        onClick = function(checked)
            mouseTrail = checked
            specDB.mouseTrail = mouseTrail
            SaveSpecSettings()
            UpdateMouseTrail(mouseTrail)
        end
    })

    -- Sparkle Trail Checkbox (positioned to the right of Mouse Trail)
    local sparkleCheckbox = OptionsPanel:AddCheckbox(panel, {
        key = "sparkleTrail",
        label = "Enable Sparkle Effect on Mouse Trail",
        default = specDB.sparkleTrail or false,
        anchor = mouseTrailCheckbox,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        xOffset = 280,
        yOffset = 0,
        onClick = function(checked)
            sparkleTrail = checked
            specDB.sparkleTrail = sparkleTrail
            SaveSpecSettings()
        end
    })

    -- Mouse Trail Color Picker (continues vertical flow from Mouse Trail)
    local trailColorData = specDB.trailColor or { r = 1, g = 1, b = 1 }
    local trailColorButton, trailColorTexture, trailColorLabel = OptionsPanel:AddColorPicker(panel, {
        key = "trailColor",
        label = "Mouse Trail Color:",
        r = trailColorData.r,
        g = trailColorData.g,
        b = trailColorData.b,
        anchor = mouseTrailCheckbox,
        point = "TOPLEFT",
        relativePoint = "BOTTOMLEFT",
        xOffset = 0,
        yOffset = -40,
        onColorChanged = function(r, g, b)
            trailColor.r, trailColor.g, trailColor.b = r, g, b
            specDB.trailColor = trailColor
            SaveSpecSettings()
        end
    })

    -- Sparkle Color Picker (positioned to the right of Mouse Trail Color)
    local sparkleColorData = specDB.sparkleColor or { r = 1, g = 1, b = 1 }
    local sparkleColorButton, sparkleColorTexture, sparkleColorLabel = OptionsPanel:AddColorPicker(panel, {
        key = "sparkleColor",
        label = "Sparkle Color:",
        r = sparkleColorData.r,
        g = sparkleColorData.g,
        b = sparkleColorData.b,
        anchor = trailColorLabel,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        xOffset = 280,
        yOffset = 0,
        onColorChanged = function(r, g, b)
            sparkleColor.r, sparkleColor.g, sparkleColor.b = r, g, b
            specDB.sparkleColor = sparkleColor
            SaveSpecSettings()
        end
    })

    -- Mouse Trail Fade Slider (continues vertical flow from Mouse Trail Color)
    local trailFadeSlider = OptionsPanel:AddSlider(panel, {
        key = "trailFadeTime",
        name = "CursorRingTrailFadeTimeSlider",
        label = "Mouse Trail Length",
        min = 0.1,
        max = 6.0,
        step = 0.1,
        default = specDB.trailFadeTime or 1.0,
        lowText = "Short",
        highText = "Long",
        anchor = trailColorLabel,
        point = "TOPLEFT",
        relativePoint = "BOTTOMLEFT",
        xOffset = 0,
        yOffset = -40,
        onValueChanged = function(value)
            trailFadeTime = value
            specDB.trailFadeTime = trailFadeTime
            SaveSpecSettings()
        end
    })

    -- Sparkle Size Slider (continues vertical flow)
    local sparkleSlider = OptionsPanel:AddSlider(panel, {
        key = "sparkleMultiplier",
        name = "CursorRingSparkleSizeSlider",
        label = "Sparkle Size Multiplier",
        min = 0.3,
        max = 10.0,
        step = 0.1,
        default = specDB.sparkleMultiplier or 1.0,
        lowText = "Small",
        highText = "Huge",
        anchor = trailFadeSlider,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        xOffset = 280,
        yOffset = 0,
        onValueChanged = function(value)
            sparkleMultiplier = value
            specDB.sparkleMultiplier = sparkleMultiplier
            SaveSpecSettings()
        end
    })

    -- Store references for UpdateOptionsPanel
    cursorRingOptionsPanel.ringColorTexture = ringColorTexture
    cursorRingOptionsPanel.castColorTexture = castColorTexture
    cursorRingOptionsPanel.trailColorTexture = trailColorTexture
    cursorRingOptionsPanel.sparkleColorTexture = sparkleColorTexture

    -- Register Panel
    OptionsPanel:Register(panel)
end

-- Refresh the options panel UI to reflect current spec's settings
local function UpdateOptionsPanel()
    if not panelLoaded or not cursorRingOptionsPanel then return end
    local specDB = GetSpecDB()

    -- Update all controls
    OptionsPanel:UpdateCheckbox(cursorRingOptionsPanel, "showOutOfCombat", specDB.showOutOfCombat or false)
    OptionsPanel:UpdateCheckbox(cursorRingOptionsPanel, "ringEnabled", specDB.ringEnabled ~= false)
    OptionsPanel:UpdateSlider(cursorRingOptionsPanel, "ringSize", specDB.ringSize or 64)
    OptionsPanel:UpdateSlider(cursorRingOptionsPanel, "trailFadeTime", specDB.trailFadeTime or 1.0)
    OptionsPanel:UpdateSlider(cursorRingOptionsPanel, "sparkleMultiplier", specDB.sparkleMultiplier or 1.0)

    -- Update color pickers
    local c = specDB.ringColor or { r = 1, g = 1, b = 1 }
    OptionsPanel:UpdateColorPicker(cursorRingOptionsPanel, "ringColor", c.r, c.g, c.b)
    
    c = specDB.castColor or { r = 1, g = 1, b = 1 }
    OptionsPanel:UpdateColorPicker(cursorRingOptionsPanel, "castColor", c.r, c.g, c.b)
    
    c = specDB.trailColor or { r = 1, g = 1, b = 1 }
    OptionsPanel:UpdateColorPicker(cursorRingOptionsPanel, "trailColor", c.r, c.g, c.b)
    
    c = specDB.sparkleColor or { r = 1, g = 1, b = 1 }
    OptionsPanel:UpdateColorPicker(cursorRingOptionsPanel, "sparkleColor", c.r, c.g, c.b)

    -- Update dropdowns
    local tex = specDB.ringTexture or "ring.tga"
    local texName = "Ring"
    for _, opt in ipairs(outerRingOptions) do
        if opt.file == tex then
            texName = opt.name
            break
        end
    end
    OptionsPanel:UpdateDropdown(cursorRingOptionsPanel, "ringTexture", tex, texName)

    local style = specDB.castStyle or "ring"
    local styleName = style == "fill" and "Fill" or (style == "wedge" and "Wedge" or "Ring")
    OptionsPanel:UpdateDropdown(cursorRingOptionsPanel, "castStyle", style, styleName)

    -- Refresh style dropdown
    if cursorRingOptionsPanel.RefreshStyleDropdown then
        cursorRingOptionsPanel.RefreshStyleDropdown()
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
addon:RegisterEvent("PLAYER_REGEN_DISABLED")
addon:RegisterEvent("PLAYER_REGEN_ENABLED")
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
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        UpdateRingVisibility()
        UpdateMouseTrailVisibility()
	elseif event=="UNIT_SPELLCAST_START" or event=="UNIT_SPELLCAST_CHANNEL_START" then
        local unit = ...
        if unit=="player" then casting = true end
    elseif event=="UNIT_SPELLCAST_STOP" or event=="UNIT_SPELLCAST_CHANNEL_STOP" then
        local unit = ...
        if unit=="player" then
            casting = false
            -- Clear cast visual effects immediately on interrupt
            if castFill then
                castFill:SetAlpha(0)
                castFill:SetSize(ringSize*0.01, ringSize*0.01)
            end
            if castSegments then
                for i = 1, NUM_CAST_SEGMENTS do
                    if castSegments[i] then
                        castSegments[i]:SetVertexColor(castColor.r, castColor.g, castColor.b,0)
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