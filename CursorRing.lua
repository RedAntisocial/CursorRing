-- CursorRing.lua

-- SavedVariables DB
CursorRingGlobalDB = CursorRingGlobalDB or {}

-- Local variables
-- Debug flag
local debugMode = false

local OptionsPanel = _G.OptionsPanel or {}
local ProfileManager = _G.ProfileManager or {}

local showOutOfCombat, cursorRingOptionsPanel, combatAlpha, outOfCombatAlpha
local ring, ringEnabled, ringSize, ringTexture, ringColorTexture, ringColorButton
local ringColor = { r = 1, g = 1, b = 1 }
local casting, castStyle, castSegments, castFill, currentCastStyle, castColorTexture, castColorButton, castEnabled
local castColor = { r = 1, g = 1, b = 1 }
local mouseTrail, mouseTrailActive, trailFadeTime, trailColorButton, sparkleTrail, sparkleColorButton, sparkleColorTexture, sparkleMultiplier
local trailColor = { r = 1, g = 1, b = 1 }
local sparkleColor = { r = 1, g = 1, b = 1 }
local noDot
local profileManager
local panelLoaded = false
local trailGroup = {}
local MAX_TRAIL_POINTS = 20
local NUM_CAST_SEGMENTS = 180

-- Adding a single defaults table because I keep mismatching when I define them all over the place.
local DEFAULTS = {
    ringEnabled = true,
    castEnabled = true,
    ringSize = 48,
    ringTexture = "ring.tga",
    noDot = false,
    showOutOfCombat = true,
    combatAlpha = 1.0,
    outOfCombatAlpha = 1.0,
    castStyle = "ring",
    mouseTrail = false,
    trailFadeTime = 1.0,
    sparkleTrail = false,
    sparkleMultiplier = 1.0,
}

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

-- Initialize Profile Manager
local function InitializeProfileManager()
    if profileManager then return end
    
    profileManager = ProfileManager:Initialize({
        savedVariableTable = CursorRingGlobalDB,
        settingKeys = {
            "ringEnabled", "castEnabled", "ringSize", "ringColor", "ringTexture",
            "castColor", "castStyle", "showOutOfCombat", "combatAlpha", "outOfCombatAlpha",
            "mouseTrail", "sparkleTrail", "trailFadeTime", "trailColor", "sparkleColor",
            "sparkleMultiplier", "noDot"
        },
        onProfileChanged = function(profileName)
        end
    })
end

-- Get current settings as a table
local function GetCurrentSettings()
    local settings = {
        ringEnabled = ringEnabled,
        castEnabled = castEnabled,
        ringSize = ringSize,
        ringColor = { r = ringColor.r, g = ringColor.g, b = ringColor.b },
        ringTexture = ringTexture,
        castColor = { r = castColor.r, g = castColor.g, b = castColor.b },
        castStyle = currentCastStyle,
        showOutOfCombat = showOutOfCombat,
        combatAlpha = combatAlpha,
        outOfCombatAlpha = outOfCombatAlpha,
        mouseTrail = mouseTrail,
        sparkleTrail = sparkleTrail,
        trailFadeTime = trailFadeTime,
        trailColor = { r = trailColor.r, g = trailColor.g, b = trailColor.b },
        sparkleColor = { r = sparkleColor.r, g = sparkleColor.g, b = sparkleColor.b },
        sparkleMultiplier = sparkleMultiplier,
        noDot = noDot
    }
	
	if debugMode then
		-- Debug Block
		print("DEBUG GetCurrentSettings:")
		print("  ringEnabled = " .. tostring(ringEnabled))
		print("  castEnabled = " .. tostring(castEnabled))
		print("  ringSize = " .. tostring(ringSize))
		print("  ringColor = {r=" .. tostring(ringColor.r) .. ", g=" .. tostring(ringColor.g) .. ", b=" .. tostring(ringColor.b) .. "}")
		print("  ringTexture = " .. tostring(ringTexture))
		print("  castColor = {r=" .. tostring(castColor.r) .. ", g=" .. tostring(castColor.g) .. ", b=" .. tostring(castColor.b) .. "}")
		print("  castStyle = " .. tostring(currentCastStyle))
		print("  showOutOfCombat = " .. tostring(showOutOfCombat))
		print("  combatAlpha = " .. tostring(combatAlpha))
		print("  outOfCombatAlpha = " .. tostring(outOfCombatAlpha))
		print("  mouseTrail = " .. tostring(mouseTrail))
		print("  sparkleTrail = " .. tostring(sparkleTrail))
		print("  trailFadeTime = " .. tostring(trailFadeTime))
		print("  trailColor = {r=" .. tostring(trailColor.r) .. ", g=" .. tostring(trailColor.g) .. ", b=" .. tostring(trailColor.b) .. "}")
		print("  sparkleColor = {r=" .. tostring(sparkleColor.r) .. ", g=" .. tostring(sparkleColor.g) .. ", b=" .. tostring(sparkleColor.b) .. "}")
		print("  sparkleMultiplier = " .. tostring(sparkleMultiplier))
		print("  noDot = " .. tostring(noDot))
		-- End Debug
	end
	
	return settings
end

-- Apply settings table to current variables
local function ApplySettings(settings)
    if not settings then return end
    
	if debugMode then
		-- Debug Block
		print("DEBUG ApplySettings - INPUT:")
		print("  ringEnabled = " .. tostring(settings.ringEnabled))
		print("  castEnabled = " .. tostring(settings.castEnabled))
		print("  ringSize = " .. tostring(settings.ringSize))
		if settings.ringColor then
			print("  ringColor = " .. tostring(settings.ringColor.r) .. ", " .. tostring(settings.ringColor.g) .. ", " .. tostring(settings.ringColor.b))
		end
		print("  ringTexture = " .. tostring(settings.ringTexture))
		if settings.castColor then
			print("  castColor = " .. tostring(settings.castColor.r) .. ", " .. tostring(settings.castColor.g) .. ", " .. tostring(settings.castColor.b))
		end
		print("  castStyle = " .. tostring(settings.castStyle))
		print("  showOutOfCombat = " .. tostring(settings.showOutOfCombat))
		print("  combatAlpha = " .. tostring(settings.combatAlpha))
		print("  outOfCombatAlpha = " .. tostring(settings.outOfCombatAlpha))
		print("  mouseTrail = " .. tostring(settings.mouseTrail))
		print("  sparkleTrail = " .. tostring(settings.sparkleTrail))
		print("  trailFadeTime = " .. tostring(settings.trailFadeTime))
		if settings.trailColor then
			print("  trailColor = " .. tostring(settings.trailColor.r) .. ", " .. tostring(settings.trailColor.g) .. ", " .. tostring(settings.trailColor.b))
		end
		if settings.sparkleColor then
			print("  sparkleColor = " .. tostring(settings.sparkleColor.r) .. ", " .. tostring(settings.sparkleColor.g) .. ", " .. tostring(settings.sparkleColor.b))
		end
		print("  sparkleMultiplier = " .. tostring(settings.sparkleMultiplier))
		print("  noDot = " .. tostring(settings.noDot))
		-- End Debug
	end
	
    ringEnabled = settings.ringEnabled ~= false
    ringTexture = settings.ringTexture or DEFAULTS.ringTexture
    ringSize = settings.ringSize or DEFAULTS.ringSize
    if settings.ringColor then
        ringColor.r, ringColor.g, ringColor.b = settings.ringColor.r, settings.ringColor.g, settings.ringColor.b
    end
    noDot = settings.noDot or DEFAULTS.noDot

    showOutOfCombat = settings.showOutOfCombat ~= false
    combatAlpha = settings.combatAlpha or DEFAULTS.combatAlpha
    outOfCombatAlpha = settings.outOfCombatAlpha or DEFAULTS.outOfCombatAlpha

    castEnabled = settings.castEnabled ~= false
    if settings.castColor then
        castColor.r, castColor.g, castColor.b = settings.castColor.r, settings.castColor.g, settings.castColor.b
    end
    currentCastStyle = settings.castStyle or DEFAULTS.castStyle
    castStyle = currentCastStyle

    mouseTrail = settings.mouseTrail or DEFAULTS.mouseTrail
    if settings.trailColor then
        trailColor.r, trailColor.g, trailColor.b = settings.trailColor.r, settings.trailColor.g, settings.trailColor.b
    end
    trailFadeTime = settings.trailFadeTime or DEFAULTS.trailFadeTime  -- CHANGE from 0.6

    sparkleTrail = settings.sparkleTrail or DEFAULTS.sparkleTrail
    if settings.sparkleColor then
        sparkleColor.r, sparkleColor.g, sparkleColor.b = settings.sparkleColor.r, settings.sparkleColor.g, settings.sparkleColor.b
    end
    sparkleMultiplier = settings.sparkleMultiplier or DEFAULTS.sparkleMultiplier  -- Already 1.0 but now using DEFAULTS
	
	if debugMode then
		-- Debug Block
		print("DEBUG ApplySettings - FINAL VALUES:")
		print("  ringEnabled = " .. tostring(ringEnabled))
		print("  castEnabled = " .. tostring(castEnabled))
		print("  ringSize = " .. tostring(ringSize))
		print("  ringColor = " .. tostring(ringColor.r) .. ", " .. tostring(ringColor.g) .. ", " .. tostring(ringColor.b))
		print("  ringTexture = " .. tostring(ringTexture))
		print("  castColor = " .. tostring(castColor.r) .. ", " .. tostring(castColor.g) .. ", " .. tostring(castColor.b))
		print("  currentCastStyle = " .. tostring(currentCastStyle))
		print("  showOutOfCombat = " .. tostring(showOutOfCombat))
		print("  combatAlpha = " .. tostring(combatAlpha))
		print("  outOfCombatAlpha = " .. tostring(outOfCombatAlpha))
		print("  mouseTrail = " .. tostring(mouseTrail))
		print("  sparkleTrail = " .. tostring(sparkleTrail))
		print("  trailFadeTime = " .. tostring(trailFadeTime))
		print("  trailColor = " .. tostring(trailColor.r) .. ", " .. tostring(trailColor.g) .. ", " .. tostring(trailColor.b))
		print("  sparkleColor = " .. tostring(sparkleColor.r) .. ", " .. tostring(sparkleColor.g) .. ", " .. tostring(sparkleColor.b))
		print("  sparkleMultiplier = " .. tostring(sparkleMultiplier))
		print("  noDot = " .. tostring(noDot))
		-- End Debug
	end
end

-- Apply "_no_dot" suffix if enabled
local function ApplyNoDotSuffix(filename)
    if not noDot then return filename end
    local baseName = filename:gsub("%.tga$", "")
    return baseName .. "_no_dot.tga"
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
    InitializeProfileManager()

    -- Load debug mode from saved variables
    if CursorRingGlobalDB.debugMode ~= nil then
        debugMode = CursorRingGlobalDB.debugMode
    end

    local settings = profileManager:LoadSettings()
    
    if settings and next(settings) then
        ApplySettings(settings)

		-- Sanity check for legacy data to address a reported user issue.
		if castEnabled == nil then castEnabled = DEFAULTS.castEnabled end
		if not castColor or not castColor.r then castColor = { r = 1, g = 1, b = 1 } end
    
		-- Save corrected settings back
		profileManager:SaveSettings(GetCurrentSettings())

    else
        -- First time defaults
        local _, class = UnitClass("player")
        local defaultClassColor = RAID_CLASS_COLORS[class]
        
        ringEnabled = DEFAULTS.ringEnabled
        castEnabled = DEFAULTS.castEnabled
        ringSize = DEFAULTS.ringSize
        showOutOfCombat = DEFAULTS.showOutOfCombat
        combatAlpha = DEFAULTS.combatAlpha
        outOfCombatAlpha = DEFAULTS.outOfCombatAlpha
        ringTexture = DEFAULTS.ringTexture
        ringColor = { r = defaultClassColor.r, g = defaultClassColor.g, b = defaultClassColor.b }
        castColor = { r = 1, g = 1, b = 1 }
        castStyle = DEFAULTS.castStyle
        mouseTrail = DEFAULTS.mouseTrail
        sparkleTrail = DEFAULTS.sparkleTrail
        trailFadeTime = DEFAULTS.trailFadeTime
        trailColor = { r = 1, g = 1, b = 1 }
        sparkleColor = { r = 1, g = 1, b = 1 }
        sparkleMultiplier = DEFAULTS.sparkleMultiplier
        noDot = DEFAULTS.noDot
        
        -- Save defaults
        profileManager:SaveSettings(GetCurrentSettings())
        
        -- Create character-level auto-profile on first login (new toons don't have a spec, so this is cleaner all 'round)
        local charKey, _ = profileManager:GetCharacterSpecKey()
        local autoProfileName = charKey
        
        if not profileManager:ProfileExists(autoProfileName) then
            profileManager:SaveToProfile(autoProfileName, GetCurrentSettings())
            profileManager:SetActiveProfile(autoProfileName)
            print("CursorRing: Created default profile '" .. autoProfileName .. "'")
        end
    end
end

-- It puts the spec specific values in the CursorRingDB when they're updated/changed or it gets the hose again...
local function SaveSpecSettings()
    if not profileManager then return end
    profileManager:SaveSettings(GetCurrentSettings())
end

-- You want spec specific settings? This is where we get them.
local function GetSpecDB()
    if not profileManager then
        InitializeProfileManager()
    end
    return profileManager:GetCharacterSettings()
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
        castFill:SetVertexColor(castColor.r, castColor.g, castColor.b, 1)
    end

end

-- Update Ring Texture/Shape
local function UpdateRingTexture(textureFile)
    if ring then
        ring:SetTexture("Interface\\AddOns\\CursorRing\\"..ApplyNoDotSuffix(textureFile))
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
	GetSpecDB().ringColor = { r = r, g = g, b = b }
    SaveSpecSettings()
    if ring then
        ring:SetVertexColor(r, g, b, 1)
    end
end

-- Spec specific Cast Color update
local function UpdateCastColor(r, g, b)
    castColor.r, castColor.g, castColor.b = r, g, b
    GetSpecDB().castColor = { r = r, g = g, b = b }
    SaveSpecSettings()
	if castFill then
        castFill:SetVertexColor(r, g, b, 1)
    end
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
    ring:SetTexture("Interface\\AddOns\\CursorRing\\"..ApplyNoDotSuffix(GetSpecDB().ringTexture or "ring.tga"), "CLAMP")
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
        local left, bottom = UIParent:GetRect()
        local scale = UIParent:GetEffectiveScale()
        x = x / scale - left
        y = y / scale - bottom
		
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
                        local radius = ringSize * 0.3
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
                        local baseSize = radius * fade * 0.5 * (sparkleMultiplier or 1.0)
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
        if not casting or not castEnabled then return end
        
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
	
	-- Enable Cast Ring Checkbox
    local castEnabledCheckbox = OptionsPanel:AddCheckbox(panel, {
        key = "castEnabled",
        label = "Enable Cast Effect",
        default = specDB.castEnabled ~= false,
        anchor = ringEnabledCheckbox,
        point = "TOPLEFT",
        relativePoint = "TOPLEFT",
        xOffset = 280,
        yOffset = 0,
        onClick = function(checked)
            castEnabled = checked
            specDB.castEnabled = castEnabled
            SaveSpecSettings()
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
            GetSpecDB().combatAlpha = combatAlpha
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
            GetSpecDB().outOfCombatAlpha = outOfCombatAlpha
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
        yOffset = -24,
        onColorChanged = function(r, g, b)
            ringColor.r, ringColor.g, ringColor.b = r, g, b
            GetSpecDB().ringColor = { r = r, g = g, b = b }
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
            GetSpecDB().ringTexture = value
            
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

    -- Remove Centre Dot Checkbox (continues vertical flow from Ring Colour)
     local noDotCheckbox = OptionsPanel:AddCheckbox(panel, {
        key = "noDot",
        label = "Remove Center Dot",
		labelOffset = 100,
		width = 150,
        default = specDB.noDot or false,
        anchor = ringTextureLabel,
        point = "TOPLEFT",
        relativePoint = "BOTTOMLEFT",
        xOffset = 0,
        yOffset = -20,
        onClick = function(checked)
            noDot = checked
            GetSpecDB().noDot = noDot
            SaveSpecSettings()
            UpdateRingTexture(ringTexture)
        end
    })

    -- Cast Colour Picker (continues vertical flow from Centre Dot Checkbox)
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
        yOffset = -64,
        onColorChanged = function(r, g, b)
            castColor.r, castColor.g, castColor.b = r, g, b
            GetSpecDB().castColor = { r = r, g = g, b = b }
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
        label = "Cast Effect Style:",
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
            GetSpecDB().castStyle = value
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
            GetSpecDB().ringColor = ringColor
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
            GetSpecDB().mouseTrail = mouseTrail
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
            GetSpecDB().sparkleTrail = sparkleTrail
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
        yOffset = -20,
        onColorChanged = function(r, g, b)
            trailColor.r, trailColor.g, trailColor.b = r, g, b
            GetSpecDB().trailColor = { r = r, g = g, b = b }
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
            GetSpecDB().sparkleColor = { r = r, g = g, b = b }
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
            GetSpecDB().trailFadeTime = trailFadeTime
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
            GetSpecDB().sparkleMultiplier = sparkleMultiplier
            SaveSpecSettings()
        end
    })

    -- Profile Management Section
    local profileHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    profileHeader:SetPoint("TOPLEFT", trailFadeSlider, "BOTTOMLEFT", 0, -30)
    profileHeader:SetText("Profile Management")

    -- Active Profile Status
    local profileStatusLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    profileStatusLabel:SetPoint("TOPLEFT", profileHeader, "BOTTOMLEFT", 0, -10)
    local activeProfile = profileManager:GetActiveProfile()
    local statusText = activeProfile and ("Active Profile: " .. activeProfile) or "Active Profile: None (Character Settings)"
    profileStatusLabel:SetText(statusText)

    -- Profile Name Input
    local profileNameLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    profileNameLabel:SetPoint("TOPLEFT", profileStatusLabel, "BOTTOMLEFT", 0, -15)
    profileNameLabel:SetText("Profile Name:")

    local profileNameInput = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    profileNameInput:SetPoint("LEFT", profileNameLabel, "RIGHT", 10, 0)
    profileNameInput:SetSize(120, 20)
    profileNameInput:SetAutoFocus(false)
    profileNameInput:SetMaxLetters(50)

    -- Save as Profile Button
    local saveProfileButton = OptionsPanel:AddButton(panel, {
        key = "saveProfile",
        text = "Save as New Profile",
        width = 150,
        height = 25,
        anchor = profileNameLabel,
        point = "LEFT",
        relativePoint = "LEFT",
        xOffset = 230,
        yOffset = 0,
        onClick = function()
            local newProfileName = profileNameInput:GetText()
            if newProfileName and newProfileName ~= "" then
                local currentSettings = GetCurrentSettings()
                profileManager:SaveToProfile(newProfileName, currentSettings)
                profileManager:SetActiveProfile(newProfileName)
                profileManager:SaveSettings(currentSettings)
                profileNameInput:SetText("")
                print("CursorRing: Saved settings to profile '" .. newProfileName .. "'")
                
                -- Refresh the dropdown and status
                if cursorRingOptionsPanel.RefreshProfileDropdown then
                    cursorRingOptionsPanel.RefreshProfileDropdown()
                end
                local activeProfile = profileManager:GetActiveProfile()
                local statusText = activeProfile and ("Active Profile: " .. activeProfile) or "Active Profile: None (Character Settings)"
                profileStatusLabel:SetText(statusText)
            else
                print("CursorRing: Please enter a profile name")
            end
        end
    })

	-- Profile Selection Dropdown
	local profileSelectLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	profileSelectLabel:SetPoint("TOPLEFT", profileNameLabel, "BOTTOMLEFT", 0, -40)
	profileSelectLabel:SetText("Load Profile:")

	local function GetProfileOptions()
		local options = {{ text = "None (Character Settings)", value = nil }}
		local profiles = profileManager:GetProfileList()
		for _, name in ipairs(profiles) do
			table.insert(options, { text = name, value = name })
		end
		return options
	end

	-- Store the onSelect value so it can be reused
	local function ProfileSelectHandler(value)
		if value then
			-- Load the selected profile
			local settings = profileManager:LoadFromProfile(value)
			if settings then
				ApplySettings(settings)
				profileManager:SetActiveProfile(value)
				profileManager:SaveSettings(GetCurrentSettings())
				
				-- Update all UI elements
				UpdateRingSize(ringSize)
				UpdateRingColor(ringColor.r, ringColor.g, ringColor.b)
				UpdateRingTexture(ringTexture)
				UpdateCastColor(castColor.r, castColor.g, castColor.b)
				UpdateCastStyle(castStyle)
				UpdateShowOutOfCombat(showOutOfCombat)
				UpdateMouseTrail(mouseTrail)
				UpdateRingVisibility()
				UpdateMouseTrailVisibility()
				
				-- Update UI controls directly
				OptionsPanel:UpdateCheckbox(panel, "showOutOfCombat", showOutOfCombat)
				OptionsPanel:UpdateCheckbox(panel, "ringEnabled", ringEnabled)
				OptionsPanel:UpdateCheckbox(panel, "castEnabled", castEnabled)
				OptionsPanel:UpdateCheckbox(panel, "mouseTrail", mouseTrail)
				OptionsPanel:UpdateCheckbox(panel, "sparkleTrail", sparkleTrail)
				OptionsPanel:UpdateCheckbox(panel, "noDot", noDot)
				OptionsPanel:UpdateSlider(panel, "ringSize", ringSize)
				OptionsPanel:UpdateSlider(panel, "combatAlpha", combatAlpha)
				OptionsPanel:UpdateSlider(panel, "outOfCombatAlpha", outOfCombatAlpha)
				OptionsPanel:UpdateSlider(panel, "trailFadeTime", trailFadeTime)
				OptionsPanel:UpdateSlider(panel, "sparkleMultiplier", sparkleMultiplier)
				OptionsPanel:UpdateColorPicker(panel, "ringColor", ringColor.r, ringColor.g, ringColor.b)
				OptionsPanel:UpdateColorPicker(panel, "castColor", castColor.r, castColor.g, castColor.b)
				OptionsPanel:UpdateColorPicker(panel, "trailColor", trailColor.r, trailColor.g, trailColor.b)
				OptionsPanel:UpdateColorPicker(panel, "sparkleColor", sparkleColor.r, sparkleColor.g, sparkleColor.b)
				
				cursorRingOptionsPanel.RefreshProfileDropdown()
				print("CursorRing: Loaded profile '" .. value .. "'")
				local statusText = "Active Profile: " .. value
				profileStatusLabel:SetText(statusText)
			else
				print("CursorRing: Failed to load profile '" .. value .. "'")
			end
		else
			-- Switch back to character settings
			profileManager:SetActiveProfile(nil)
			LoadSpecSettings()
			
			-- Update all UI elements
			UpdateRingSize(ringSize)
			UpdateRingColor(ringColor.r, ringColor.g, ringColor.b)
			UpdateRingTexture(ringTexture)
			UpdateCastColor(castColor.r, castColor.g, castColor.b)
			UpdateCastStyle(castStyle)
			UpdateShowOutOfCombat(showOutOfCombat)
			UpdateMouseTrail(mouseTrail)
			UpdateRingVisibility()
			UpdateMouseTrailVisibility()
			
			-- Update UI controls directly
			OptionsPanel:UpdateCheckbox(panel, "showOutOfCombat", showOutOfCombat)
			OptionsPanel:UpdateCheckbox(panel, "ringEnabled", ringEnabled)
			OptionsPanel:UpdateCheckbox(panel, "castEnabled", castEnabled)
			OptionsPanel:UpdateCheckbox(panel, "mouseTrail", mouseTrail)
			OptionsPanel:UpdateCheckbox(panel, "sparkleTrail", sparkleTrail)
			OptionsPanel:UpdateCheckbox(panel, "noDot", noDot)
			OptionsPanel:UpdateSlider(panel, "ringSize", ringSize)
			OptionsPanel:UpdateSlider(panel, "combatAlpha", combatAlpha)
			OptionsPanel:UpdateSlider(panel, "outOfCombatAlpha", outOfCombatAlpha)
			OptionsPanel:UpdateSlider(panel, "trailFadeTime", trailFadeTime)
			OptionsPanel:UpdateSlider(panel, "sparkleMultiplier", sparkleMultiplier)
			OptionsPanel:UpdateColorPicker(panel, "ringColor", ringColor.r, ringColor.g, ringColor.b)
			OptionsPanel:UpdateColorPicker(panel, "castColor", castColor.r, castColor.g, castColor.b)
			OptionsPanel:UpdateColorPicker(panel, "trailColor", trailColor.r, trailColor.g, trailColor.b)
			OptionsPanel:UpdateColorPicker(panel, "sparkleColor", sparkleColor.r, sparkleColor.g, sparkleColor.b)
			
			cursorRingOptionsPanel.RefreshProfileDropdown()
			print("CursorRing: Using character settings")
			profileStatusLabel:SetText("Active Profile: None (Character Settings)")
		end
	end

	local currentProfile = profileManager:GetActiveProfile()
	local profileDropdown, profileDropdownLabel = OptionsPanel:AddDropdown(panel, {
		key = "profileSelect",
		label = "",
		labelOffset = 0,
		width = 200,
		default = currentProfile,
		options = GetProfileOptions(),
		anchor = profileSelectLabel,
		point = "LEFT",
		relativePoint = "RIGHT",
		xOffset = 10,
		yOffset = 0,
		onSelect = ProfileSelectHandler
	})

    -- Delete Profile Button
    local deleteProfileButton = OptionsPanel:AddButton(panel, {
        key = "deleteProfile",
        text = "Delete Selected Profile",
        width = 150,
        height = 25,
        anchor = profileSelectLabel,
        point = "LEFT",
        relativePoint = "LEFT",
        xOffset = 230,
        yOffset = 0,
		onClick = function()
			local activeProfile = profileManager:GetActiveProfile()
			if activeProfile then
				profileManager:DeleteProfile(activeProfile)
				
				-- Always clean up and reset to defaults
				profileManager:SetActiveProfile(nil)
				
				-- Reset all values to defaults
				local _, class = UnitClass("player")
				local defaultClassColor = RAID_CLASS_COLORS[class]
				
				ringEnabled = DEFAULTS.ringEnabled
				castEnabled = DEFAULTS.castEnabled
				ringSize = DEFAULTS.ringSize
				showOutOfCombat = DEFAULTS.showOutOfCombat
				combatAlpha = DEFAULTS.combatAlpha
				outOfCombatAlpha = DEFAULTS.outOfCombatAlpha
				ringTexture = DEFAULTS.ringTexture
				ringColor = { r = defaultClassColor.r, g = defaultClassColor.g, b = defaultClassColor.b }
				castColor = { r = 1, g = 1, b = 1 }
				castStyle = DEFAULTS.castStyle
				currentCastStyle = DEFAULTS.castStyle
				mouseTrail = DEFAULTS.mouseTrail
				sparkleTrail = DEFAULTS.sparkleTrail
				trailFadeTime = DEFAULTS.trailFadeTime
				trailColor = { r = 1, g = 1, b = 1 }
				sparkleColor = { r = 1, g = 1, b = 1 }
				sparkleMultiplier = DEFAULTS.sparkleMultiplier
				noDot = DEFAULTS.noDot
				
				-- Save defaults to character settings
				profileManager:SaveSettings(GetCurrentSettings())
				
				-- Update all UI elements
				UpdateRingSize(ringSize)
				UpdateRingColor(ringColor.r, ringColor.g, ringColor.b)
				UpdateRingTexture(ringTexture)
				UpdateCastColor(castColor.r, castColor.g, castColor.b)
				UpdateCastStyle(castStyle)
				UpdateShowOutOfCombat(showOutOfCombat)
				UpdateMouseTrail(mouseTrail)
				UpdateRingVisibility()
				UpdateMouseTrailVisibility()
				
				-- Update UI controls directly
				OptionsPanel:UpdateCheckbox(panel, "showOutOfCombat", showOutOfCombat)
				OptionsPanel:UpdateCheckbox(panel, "ringEnabled", ringEnabled)
				OptionsPanel:UpdateCheckbox(panel, "castEnabled", castEnabled)
				OptionsPanel:UpdateCheckbox(panel, "mouseTrail", mouseTrail)
				OptionsPanel:UpdateCheckbox(panel, "sparkleTrail", sparkleTrail)
				OptionsPanel:UpdateCheckbox(panel, "noDot", noDot)
				OptionsPanel:UpdateSlider(panel, "ringSize", ringSize)
				OptionsPanel:UpdateSlider(panel, "combatAlpha", combatAlpha)
				OptionsPanel:UpdateSlider(panel, "outOfCombatAlpha", outOfCombatAlpha)
				OptionsPanel:UpdateSlider(panel, "trailFadeTime", trailFadeTime)
				OptionsPanel:UpdateSlider(panel, "sparkleMultiplier", sparkleMultiplier)
				OptionsPanel:UpdateColorPicker(panel, "ringColor", ringColor.r, ringColor.g, ringColor.b)
				OptionsPanel:UpdateColorPicker(panel, "castColor", castColor.r, castColor.g, castColor.b)
				OptionsPanel:UpdateColorPicker(panel, "trailColor", trailColor.r, trailColor.g, trailColor.b)
				OptionsPanel:UpdateColorPicker(panel, "sparkleColor", sparkleColor.r, sparkleColor.g, sparkleColor.b)
				
				-- Refresh dropdown
				cursorRingOptionsPanel.RefreshProfileDropdown()
				
				-- Verify deletion
				if not profileManager:ProfileExists(activeProfile) then
					print("CursorRing: Deleted profile '" .. activeProfile .. "' and reset to defaults")
				else
					print("CursorRing: Failed to delete profile '" .. activeProfile .. "'")
				end
				
				profileStatusLabel:SetText("Active Profile: None (Character Settings)")
			else
				print("CursorRing: No profile selected")
			end
		end
    })

    -- Function to refresh profile dropdown
	function cursorRingOptionsPanel.RefreshProfileDropdown()
		local options = GetProfileOptions()
		local activeProfile = profileManager:GetActiveProfile()
		local displayText = activeProfile or "None (Character Settings)"
		
		local dropdown = panel.elements["profileSelect"].dropdown
		
		-- Reinitialize dropdown with current profile list
		UIDropDownMenu_Initialize(dropdown, function(self)
			for _, opt in ipairs(options) do
				local info = UIDropDownMenu_CreateInfo()
				info.text = opt.text
				info.arg1 = opt.value
				info.func = function(self, value)
					ProfileSelectHandler(value)
				end
				info.checked = (activeProfile == opt.value)
				UIDropDownMenu_AddButton(info)
			end
		end)
		
		UIDropDownMenu_SetSelectedValue(dropdown, activeProfile)
		UIDropDownMenu_SetText(dropdown, displayText)
	end

    -- Store references for UpdateOptionsPanel
    cursorRingOptionsPanel.ringColorTexture = ringColorTexture
    cursorRingOptionsPanel.castColorTexture = castColorTexture
    cursorRingOptionsPanel.trailColorTexture = trailColorTexture
    cursorRingOptionsPanel.sparkleColorTexture = sparkleColorTexture
    cursorRingOptionsPanel.profileStatusLabel = profileStatusLabel

    -- Register Panel
    OptionsPanel:Register(panel)
end

-- Refresh the options panel UI to reflect current spec's settings
local function UpdateOptionsPanel()
    if not panelLoaded or not cursorRingOptionsPanel then return end
    local specDB = GetSpecDB()

    -- Update all controls
    OptionsPanel:UpdateCheckbox(cursorRingOptionsPanel, "showOutOfCombat", showOutOfCombat or false)
    OptionsPanel:UpdateCheckbox(cursorRingOptionsPanel, "ringEnabled", ringEnabled ~= false)
	OptionsPanel:UpdateCheckbox(cursorRingOptionsPanel, "castEnabled", castEnabled ~= false)
    OptionsPanel:UpdateSlider(cursorRingOptionsPanel, "ringSize", ringSize or 48)
    OptionsPanel:UpdateSlider(cursorRingOptionsPanel, "trailFadeTime", trailFadeTime or 1.0)
    OptionsPanel:UpdateSlider(cursorRingOptionsPanel, "sparkleMultiplier", sparkleMultiplier or 1.0)
    OptionsPanel:UpdateCheckbox(cursorRingOptionsPanel, "mouseTrail", mouseTrail or false)
    OptionsPanel:UpdateCheckbox(cursorRingOptionsPanel, "sparkleTrail", sparkleTrail or false)
    OptionsPanel:UpdateCheckbox(cursorRingOptionsPanel, "noDot", noDot or false)

    -- Update color pickers
	OptionsPanel:UpdateColorPicker(cursorRingOptionsPanel, "ringColor", ringColor.r, ringColor.g, ringColor.b)
    OptionsPanel:UpdateColorPicker(cursorRingOptionsPanel, "castColor", castColor.r, castColor.g, castColor.b)
    OptionsPanel:UpdateColorPicker(cursorRingOptionsPanel, "trailColor", trailColor.r, trailColor.g, trailColor.b)
    OptionsPanel:UpdateColorPicker(cursorRingOptionsPanel, "sparkleColor", sparkleColor.r, sparkleColor.g, sparkleColor.b)


    -- Update dropdowns
    local texName = "Ring"
    for _, opt in ipairs(outerRingOptions) do
        if opt.file == ringTexture then
            texName = opt.name
            break
        end
    end
    OptionsPanel:UpdateDropdown(cursorRingOptionsPanel, "ringTexture", ringTexture, texName)

    local styleName = currentCastStyle == "fill" and "Fill" or (currentCastStyle == "wedge" and "Wedge" or "Ring")
    OptionsPanel:UpdateDropdown(cursorRingOptionsPanel, "castStyle", currentCastStyle, styleName)

    -- Refresh style dropdown
    if cursorRingOptionsPanel.RefreshStyleDropdown then
        cursorRingOptionsPanel.RefreshStyleDropdown()
    end
 
    -- Update profile status
    if cursorRingOptionsPanel.profileStatusLabel then
        local activeProfile = profileManager:GetActiveProfile()
        local statusText = activeProfile and ("Active Profile: " .. activeProfile) or "Active Profile: None (Character Settings)"
        cursorRingOptionsPanel.profileStatusLabel:SetText(statusText)
    end
    
    -- Refresh profile dropdown
    if cursorRingOptionsPanel.RefreshProfileDropdown then
        cursorRingOptionsPanel.RefreshProfileDropdown()
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

addon:SetScript("OnEvent", function(self,event,...)
    if event=="PLAYER_ENTERING_WORLD" or event=="PLAYER_SPECIALIZATION_CHANGED" then
        LoadSpecSettings()
        CreateCursorRing()
        UpdateCastStyle(currentCastStyle)
        CreateOptionsPanel()
        UpdateOptionsPanel()
        UpdateRingVisibility()
        UpdateMouseTrailVisibility()
        if ring then
            ring:SetTexture("Interface\\AddOns\\CursorRing\\"..ApplyNoDotSuffix(ringTexture))
			ring:SetVertexColor(ringColor.r, ringColor.g, ringColor.b, 1)
            if debugMode then
				print("CursorRing: Updated ring texture to " .. ringTexture)
			end
        end
        if castFill then
            castFill:SetTexture("Interface\\AddOns\\CursorRing\\" .. GetFillTextureForRing(ringTexture))
			castFill:SetVertexColor(castColor.r, castColor.g, castColor.b, 1)
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
            UpdateCastStyle(currentCastStyle)
            CreateOptionsPanel()
            UpdateOptionsPanel()
            UpdateRingVisibility()
            UpdateMouseTrailVisibility()
        end
    end
end)

-- Slash command for debug toggle
SLASH_CURSORRING1 = "/cursorring"
SlashCmdList["CURSORRING"] = function(msg)
    if msg == "debug" then
        debugMode = not debugMode
        CursorRingGlobalDB.debugMode = debugMode
        print("CursorRing: Debug mode " .. (debugMode and "enabled" or "disabled"))
    else
        print("CursorRing commands:")
        print("  /cursorring debug - Toggle debug output")
    end
end
