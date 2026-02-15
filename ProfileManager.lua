-- ProfileManager.lua
-- Reusable profile management system for WoW addons... that given the difficulty of this first implementation, I may never want to do again :P

local ProfileManager = {}

function ProfileManager:Initialize(config)
    local manager = {
        db = config.savedVariableTable,
        settingKeys = config.settingKeys or {},
        onProfileChanged = config.onProfileChanged,
        activeProfile = nil,
        currentCharacterKey = nil,
        currentSpecKey = nil
    }
    
    setmetatable(manager, { __index = self })
    
    -- Initialize structure
    manager.db.Profiles = manager.db.Profiles or {}
    manager.db.characters = manager.db.characters or {}
    
    return manager
end

-- Get current character-spec key
function ProfileManager:GetCharacterSpecKey()
    local realm = GetRealmName()
    local name = UnitName("player")
    local specIndex = GetSpecialization()
    local specKey = "NoSpec"
    
    if specIndex then
        local _, specName = GetSpecializationInfo(specIndex)
        specKey = specName or ("Spec" .. specIndex)
    end
    
    return realm .. "-" .. name, specKey
end

-- Update internal charactr/spec tracking
function ProfileManager:UpdateContext()
    self.currentCharacterKey, self.currentSpecKey = self:GetCharacterSpecKey()
    
    -- Ensure character-spec entry exists
    self.db.characters = self.db.characters or {}
    self.db.characters[self.currentCharacterKey] = self.db.characters[self.currentCharacterKey] or {}
    self.db.characters[self.currentCharacterKey][self.currentSpecKey] = 
        self.db.characters[self.currentCharacterKey][self.currentSpecKey] or {}
end

-- Save current settings to a named profile
function ProfileManager:SaveToProfile(name, settings)
    if not self.db then self:UpdateContext() end
    
    if not self.db.Profiles then 
        self.db.Profiles = {} 
    end
    
	if debugMode then
		-- Debug Block
		print("=== DEBUG SaveToProfile: " .. name .. " ===")
		print("INPUT settings:")
		print("  ringEnabled = " .. tostring(settings.ringEnabled))
		print("  castEnabled = " .. tostring(settings.castEnabled))
		print("  ringSize = " .. tostring(settings.ringSize))
		if settings.ringColor then
			print("  ringColor = {r=" .. tostring(settings.ringColor.r) .. ", g=" .. tostring(settings.ringColor.g) .. ", b=" .. tostring(settings.ringColor.b) .. "}")
		end
		print("  ringTexture = " .. tostring(settings.ringTexture))
		if settings.castColor then
			print("  castColor = {r=" .. tostring(settings.castColor.r) .. ", g=" .. tostring(settings.castColor.g) .. ", b=" .. tostring(settings.castColor.b) .. "}")
		end
		print("  castStyle = " .. tostring(settings.castStyle))
		print("  showOutOfCombat = " .. tostring(settings.showOutOfCombat))
		print("  combatAlpha = " .. tostring(settings.combatAlpha))
		print("  outOfCombatAlpha = " .. tostring(settings.outOfCombatAlpha))
		print("  mouseTrail = " .. tostring(settings.mouseTrail))
		print("  sparkleTrail = " .. tostring(settings.sparkleTrail))
		print("  trailFadeTime = " .. tostring(settings.trailFadeTime))
		if settings.trailColor then
			print("  trailColor = {r=" .. tostring(settings.trailColor.r) .. ", g=" .. tostring(settings.trailColor.g) .. ", b=" .. tostring(settings.trailColor.b) .. "}")
		end
		if settings.sparkleColor then
			print("  sparkleColor = {r=" .. tostring(settings.sparkleColor.r) .. ", g=" .. tostring(settings.sparkleColor.g) .. ", b=" .. tostring(settings.sparkleColor.b) .. "}")
		end
		print("  sparkleMultiplier = " .. tostring(settings.sparkleMultiplier))
		print("  noDot = " .. tostring(settings.noDot))
		-- End Debug
	end
	
    self.db.Profiles[name] = CopyTable(settings)
	
	if debugMode then
		-- Debug Block
		print("STORED in db.Profiles[" .. name .. "]:")
		print("  ringEnabled = " .. tostring(self.db.Profiles[name].ringEnabled))
		print("  castEnabled = " .. tostring(self.db.Profiles[name].castEnabled))
		print("  ringSize = " .. tostring(self.db.Profiles[name].ringSize))
		if self.db.Profiles[name].ringColor then
			print("  ringColor = {r=" .. tostring(self.db.Profiles[name].ringColor.r) .. ", g=" .. tostring(self.db.Profiles[name].ringColor.g) .. ", b=" .. tostring(self.db.Profiles[name].ringColor.b) .. "}")
		end
		print("  ringTexture = " .. tostring(self.db.Profiles[name].ringTexture))
		if self.db.Profiles[name].castColor then
			print("  castColor = {r=" .. tostring(self.db.Profiles[name].castColor.r) .. ", g=" .. tostring(self.db.Profiles[name].castColor.g) .. ", b=" .. tostring(self.db.Profiles[name].castColor.b) .. "}")
		end
		print("  castStyle = " .. tostring(self.db.Profiles[name].castStyle))
		print("  showOutOfCombat = " .. tostring(self.db.Profiles[name].showOutOfCombat))
		print("  combatAlpha = " .. tostring(self.db.Profiles[name].combatAlpha))
		print("  outOfCombatAlpha = " .. tostring(self.db.Profiles[name].outOfCombatAlpha))
		print("  mouseTrail = " .. tostring(self.db.Profiles[name].mouseTrail))
		print("  sparkleTrail = " .. tostring(self.db.Profiles[name].sparkleTrail))
		print("  trailFadeTime = " .. tostring(self.db.Profiles[name].trailFadeTime))
		if self.db.Profiles[name].trailColor then
			print("  trailColor = {r=" .. tostring(self.db.Profiles[name].trailColor.r) .. ", g=" .. tostring(self.db.Profiles[name].trailColor.g) .. ", b=" .. tostring(self.db.Profiles[name].trailColor.b) .. "}")
		end
		if self.db.Profiles[name].sparkleColor then
			print("  sparkleColor = {r=" .. tostring(self.db.Profiles[name].sparkleColor.r) .. ", g=" .. tostring(self.db.Profiles[name].sparkleColor.g) .. ", b=" .. tostring(self.db.Profiles[name].sparkleColor.b) .. "}")
		end
		print("  sparkleMultiplier = " .. tostring(self.db.Profiles[name].sparkleMultiplier))
		print("  noDot = " .. tostring(self.db.Profiles[name].noDot))
		-- End Debug
	end 
    self:SetActiveProfile(name)
	
    print("|cFF00FF00CursorRing:|r Profile '" .. name .. "' saved successfully.")
end

-- Load settings from a profile
function ProfileManager:LoadFromProfile(profileName)
    if not self.db then self:UpdateContext() end
    
    if self.db.Profiles and self.db.Profiles[profileName] then
	
		if debugMode then
			-- Debug Block
			print("=== DEBUG LoadFromProfile: " .. profileName .. " ===")
			print("STORED in db.Profiles[" .. profileName .. "]:")
			print("  ringEnabled = " .. tostring(self.db.Profiles[profileName].ringEnabled))
			print("  castEnabled = " .. tostring(self.db.Profiles[profileName].castEnabled))
			print("  ringSize = " .. tostring(self.db.Profiles[profileName].ringSize))
			if self.db.Profiles[profileName].ringColor then
				print("  ringColor = {r=" .. tostring(self.db.Profiles[profileName].ringColor.r) .. ", g=" .. tostring(self.db.Profiles[profileName].ringColor.g) .. ", b=" .. tostring(self.db.Profiles[profileName].ringColor.b) .. "}")
			end
			print("  ringTexture = " .. tostring(self.db.Profiles[profileName].ringTexture))
			if self.db.Profiles[profileName].castColor then
				print("  castColor = {r=" .. tostring(self.db.Profiles[profileName].castColor.r) .. ", g=" .. tostring(self.db.Profiles[profileName].castColor.g) .. ", b=" .. tostring(self.db.Profiles[profileName].castColor.b) .. "}")
			end
			print("  castStyle = " .. tostring(self.db.Profiles[profileName].castStyle))
			print("  showOutOfCombat = " .. tostring(self.db.Profiles[profileName].showOutOfCombat))
			print("  combatAlpha = " .. tostring(self.db.Profiles[profileName].combatAlpha))
			print("  outOfCombatAlpha = " .. tostring(self.db.Profiles[profileName].outOfCombatAlpha))
			print("  mouseTrail = " .. tostring(self.db.Profiles[profileName].mouseTrail))
			print("  sparkleTrail = " .. tostring(self.db.Profiles[profileName].sparkleTrail))
			print("  trailFadeTime = " .. tostring(self.db.Profiles[profileName].trailFadeTime))
			if self.db.Profiles[profileName].trailColor then
				print("  trailColor = {r=" .. tostring(self.db.Profiles[profileName].trailColor.r) .. ", g=" .. tostring(self.db.Profiles[profileName].trailColor.g) .. ", b=" .. tostring(self.db.Profiles[profileName].trailColor.b) .. "}")
			end
			if self.db.Profiles[profileName].sparkleColor then
				print("  sparkleColor = {r=" .. tostring(self.db.Profiles[profileName].sparkleColor.r) .. ", g=" .. tostring(self.db.Profiles[profileName].sparkleColor.g) .. ", b=" .. tostring(self.db.Profiles[profileName].sparkleColor.b) .. "}")
			end
			print("  sparkleMultiplier = " .. tostring(self.db.Profiles[profileName].sparkleMultiplier))
			print("  noDot = " .. tostring(self.db.Profiles[profileName].noDot))
			-- End Debug
		end 
		
        local loaded = CopyTable(self.db.Profiles[profileName])
        
		if debugMode then
			-- Debug Block
			print("COPIED settings:")
			print("  ringEnabled = " .. tostring(loaded.ringEnabled))
			print("  castEnabled = " .. tostring(loaded.castEnabled))
			print("  ringSize = " .. tostring(loaded.ringSize))
			if loaded.ringColor then
				print("  ringColor = {r=" .. tostring(loaded.ringColor.r) .. ", g=" .. tostring(loaded.ringColor.g) .. ", b=" .. tostring(loaded.ringColor.b) .. "}")
			end
			print("  ringTexture = " .. tostring(loaded.ringTexture))
			if loaded.castColor then
				print("  castColor = {r=" .. tostring(loaded.castColor.r) .. ", g=" .. tostring(loaded.castColor.g) .. ", b=" .. tostring(loaded.castColor.b) .. "}")
			end
			print("  castStyle = " .. tostring(loaded.castStyle))
			print("  showOutOfCombat = " .. tostring(loaded.showOutOfCombat))
			print("  combatAlpha = " .. tostring(loaded.combatAlpha))
			print("  outOfCombatAlpha = " .. tostring(loaded.outOfCombatAlpha))
			print("  mouseTrail = " .. tostring(loaded.mouseTrail))
			print("  sparkleTrail = " .. tostring(loaded.sparkleTrail))
			print("  trailFadeTime = " .. tostring(loaded.trailFadeTime))
			if loaded.trailColor then
				print("  trailColor = {r=" .. tostring(loaded.trailColor.r) .. ", g=" .. tostring(loaded.trailColor.g) .. ", b=" .. tostring(loaded.trailColor.b) .. "}")
			end
			if loaded.sparkleColor then
				print("  sparkleColor = {r=" .. tostring(loaded.sparkleColor.r) .. ", g=" .. tostring(loaded.sparkleColor.g) .. ", b=" .. tostring(loaded.sparkleColor.b) .. "}")
			end
			print("  sparkleMultiplier = " .. tostring(loaded.sparkleMultiplier))
			print("  noDot = " .. tostring(loaded.noDot))
			-- End Debug
		end
        return CopyTable(self.db.Profiles[profileName])
    end
    
    return nil
end

-- Set active profile for current character-spec
function ProfileManager:SetActiveProfile(profileName)
	if not self.db then self:UpdateContext() end
    if not self.db.ActiveProfiles then self.db.ActiveProfiles = {} end
    
    local key = self.currentCharacterKey .. "-" .. self.currentSpecKey
    self.db.ActiveProfiles[key] = profileName -- Stores the name string or nil
end

-- Get active profile name for current character-spec
function ProfileManager:GetActiveProfile()
	-- If db is nil, force an update to link CursorRingGlobalDB
    if not self.db then 
        self:UpdateContext() 
    end

    -- Safety check: if it's still nil (e.g. called before DB is ready)
    if not self.db or not self.db.ActiveProfiles then return nil end

    local key = self.currentCharacterKey .. "-" .. self.currentSpecKey
    return self.db.ActiveProfiles[key]
end

-- Get list of all profile names (sorted alphabetically)
function ProfileManager:GetProfileList()
    if not self.db or not self.db.Profiles then 
        self:UpdateContext() -- Ensure DB is linked
    end
    
    local list = {}
    if self.db and self.db.Profiles then
        for name, _ in pairs(self.db.Profiles) do
            table.insert(list, name)
        end
    end
    
    -- Sort alphabetically so the dropdown isn't random
    table.sort(list)
    return list
end

-- Delete a profile
function ProfileManager:DeleteProfile(profileName)
    if not self.db or not self.db.Profiles then return end
    
    -- Remove the profile data
    self.db.Profiles[profileName] = nil
    
    -- Clean up ActiveProfiles references
    -- If any character/spec was using this profile, reset them to nil
    if self.db.ActiveProfiles then
        for key, activeName in pairs(self.db.ActiveProfiles) do
            if activeName == profileName then
                self.db.ActiveProfiles[key] = nil
            end
        end
    end
    
    print("|cFFFF0000CursorRing:|r Profile '" .. profileName .. "' deleted.")
end

-- Check if a profile exists
function ProfileManager:ProfileExists(profileName)
	if not self.db or not self.db.Profiles then return false end
    return self.db.Profiles[profileName] ~= nil
end

-- Rename a profile
function ProfileManager:RenameProfile(oldName, newName)
    if not self.db.Profiles[oldName] or not newName or newName == "" then
        return false
    end
    
    if self.db.Profiles[newName] then
        return false -- new name already exists
    end
    
    -- Copy profile data
    self.db.Profiles[newName] = self.db.Profiles[oldName]
    self.db.Profiles[oldName] = nil
    
    -- Update character-spec references
    for charKey, charData in pairs(self.db.characters) do
        for specKey, specData in pairs(charData) do
            if specData.activeProfile == oldName then
                specData.activeProfile = newName
            end
        end
    end
    
    -- Update active profile if needed
    if self.activeProfile == oldName then
        self.activeProfile = newName
    end
    
    return true
end

-- Get character-specific settings storage
function ProfileManager:GetCharacterSettings()
    self:UpdateContext()
	
	if not self.db.characters[self.currentCharacterKey] then
        self.db.characters[self.currentCharacterKey] = {}
    end
    if not self.db.characters[self.currentCharacterKey][self.currentSpecKey] then
        self.db.characters[self.currentCharacterKey][self.currentSpecKey] = {}
    end
	
    return self.db.characters[self.currentCharacterKey][self.currentSpecKey]
end

-- Save settings to character-specific storage
function ProfileManager:SaveToCharacterSettings(settings)
    self:UpdateContext()
    
    local charSettings = self.db.characters[self.currentCharacterKey][self.currentSpecKey]
    
    for _, key in ipairs(self.settingKeys) do
        charSettings[key] = settings[key]
    end
end

-- Load settings (from active profile or character storage)
function ProfileManager:LoadSettings()
    self:UpdateContext()
    
    local activeProfile = self:GetActiveProfile()
    
    if activeProfile and self.db.Profiles[activeProfile] then
        return self:LoadFromProfile(activeProfile)
    else
        -- Return character-specific settings
        return self:GetCharacterSettings()
    end
end

-- Save settings (to active profile and character db)
function ProfileManager:SaveSettings(settings)
    if not self.db then self:UpdateContext() end
    
    -- Save to character db
    local key = self.currentCharacterKey .. "-" .. self.currentSpecKey
    if not self.db.CharacterSettings then self.db.CharacterSettings = {} end
    self.db.CharacterSettings[key] = CopyTable(settings)
    
    -- Save to active profile
    local activeProfile = self:GetActiveProfile()
    if activeProfile then
        if not self.db.Profiles then self.db.Profiles = {} end
        self.db.Profiles[activeProfile] = CopyTable(settings)
    end
end

_G.ProfileManager = ProfileManager