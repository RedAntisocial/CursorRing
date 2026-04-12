-- CursorRing_Locale.lua
-- Localization strings for CursorRing
-- To add a language: copy the enUS block, change the key to the locale string,
-- and translate the values. Send me the block via CurseForge or GitHub and I'll check it and add it.
-- GetLocale() returns e.g. "deDE", "frFR", "zhCN", etc.
-- Falls back to enUS if the client locale has no entry.
-- I might try my hand at adding a few by using Wowhead in different languages
local L = {
    ["enUS"] = {
        -- Options panel title
        PANEL_TITLE                 = "CursorRing Settings",

        -- Checkboxes
        SHOW_OUT_OF_COMBAT          = "Show Ring and Mouse Trail outside of instances",
        ENABLE_RING                 = "Enable Cursor/Cast Ring",
        ENABLE_CAST                 = "Enable Cast Effect",
        REMOVE_CENTER_DOT           = "Remove Center Dot",
        ENABLE_OUTLINE              = "Enable Ring Outline",
        ENABLE_TRAIL                = "Enable Mouse Trail",
        ENABLE_SPARKLE              = "Enable Sparkle Effect on Mouse Trail",

        -- Sliders
        RING_SIZE                   = "Ring Size",
        COMBAT_OPACITY              = "In Combat Opacity",
        OUT_OF_COMBAT_OPACITY       = "Out of Combat Opacity",
        OUTLINE_THICKNESS           = "Outline Thickness",
        TRAIL_LENGTH                = "Mouse Trail Length",
        SPARKLE_SIZE                = "Sparkle Size Multiplier",

        -- Slider endpoint labels
        SIZE_SMALL                  = "Small",
        SIZE_LARGE                  = "Large",
        PCT_0                       = "0%",
        PCT_100                     = "100%",
        THICKNESS_THIN              = "Thin",
        THICKNESS_THICK             = "Thick",
        LENGTH_SHORT                = "Short",
        LENGTH_LONG                 = "Long",

        -- Color picker labels
        RING_COLOR                  = "Ring Color:",
        CAST_COLOR                  = "Cast Effect Color:",
        OUTLINE_COLOR               = "Outline Color:",
        TRAIL_COLOR                 = "Mouse Trail Color:",
        SPARKLE_COLOR               = "Sparkle Color:",

        -- Buttons
        RESET                       = "Reset",
        SAVE_PROFILE                = "Save as New Profile",
        DELETE_PROFILE              = "Delete Selected Profile",

        -- Dropdown labels
        RING_SHAPE                  = "Ring Shape:",
        CAST_STYLE                  = "Cast Effect Style:",
        LOAD_PROFILE                = "Load Profile:",

        -- Cast style dropdown options
        STYLE_RING                  = "Ring",
        STYLE_FILL                  = "Fill",
        STYLE_WEDGE                 = "Wedge",

        -- Ring shape dropdown options
        SHAPE_RING                  = "Ring",
        SHAPE_THIN_RING             = "Thin Ring",
        SHAPE_STAR                  = "Star",
        SHAPE_HEX                   = "Hex",
        SHAPE_HEX90                 = "Hex 90",

        -- Profile management
        PROFILE_MANAGEMENT          = "Profile Management",
        PROFILE_NAME                = "Profile Name:",
        ACTIVE_PROFILE              = "Active Profile: %s",
        ACTIVE_PROFILE_NONE         = "Active Profile: None (Character Settings)",
        PROFILE_NONE                = "None (Character Settings)",

        -- Chat print messages (format strings use %s for dynamic values)
        MSG_CREATED_PROFILE         = "CursorRing: Created default profile '%s'",
        MSG_PLEASE_ENTER_NAME       = "CursorRing: Please enter a profile name",
        MSG_SAVED_PROFILE           = "CursorRing: Saved settings to profile '%s'",
        MSG_LOADED_PROFILE          = "CursorRing: Loaded profile '%s'",
        MSG_FAILED_LOAD             = "CursorRing: Failed to load profile '%s'",
        MSG_USING_CHAR              = "CursorRing: Using character settings",
        MSG_DELETED_PROFILE         = "CursorRing: Deleted profile '%s' and reset to defaults",
        MSG_FAILED_DELETE           = "CursorRing: Failed to delete profile '%s'",
        MSG_NO_PROFILE              = "CursorRing: No profile selected",

        -- Debug / slash command messages
        MSG_DEBUG_TEXTURE           = "CursorRing: Updated ring texture to %s",
        MSG_DEBUG_ENABLED           = "CursorRing: Debug mode enabled",
        MSG_DEBUG_DISABLED          = "CursorRing: Debug mode disabled",
        MSG_COMMANDS                = "CursorRing commands:",
        MSG_CMD_DEBUG               = "  /cursorring debug - Toggle debug output",

        -- ProfileManager messages (colored with inline color codes)
        MSG_PM_SAVED                = "|cFF00FF00CursorRing:|r Profile '%s' saved successfully.",
        MSG_PM_DELETED              = "|cFFFF0000CursorRing:|r Profile '%s' deleted.",
    },
}
CursorRing_L = L[GetLocale()] or L["enUS"]