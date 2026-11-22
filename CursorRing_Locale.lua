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
        ENABLE_GCD                  = "Enable Global Cooldown Ring",

        -- Sliders
        RING_SIZE                   = "Ring Size",
        COMBAT_OPACITY              = "In Combat Opacity",
        OUT_OF_COMBAT_OPACITY       = "Out of Combat Opacity",
        FISHING_OPACITY             = "Fishing Opacity",
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
        GCD_COLOR                   = "GCD Color:",

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

    -- French (provided by a Canadian, thank you Stephan G.!).
    ["frFR"] = {
        -- Options panel title
        PANEL_TITLE                 = "Paramètres de CursorRing",

        -- Checkboxes
        SHOW_OUT_OF_COMBAT          = "Afficher l'anneau et la traînée de la souris hors des instances",
        ENABLE_RING                 = "Activer l'anneau du curseur/d'incantation",
        ENABLE_CAST                 = "Activer l'effet d'incantation",
        REMOVE_CENTER_DOT           = "Retirer le point central",
        ENABLE_OUTLINE              = "Activer le contour de l'anneau",
        ENABLE_TRAIL                = "Activer la traînée de la souris",
        ENABLE_SPARKLE              = "Activer l'effet d'étincelles sur la traînée de la souris",
        ENABLE_GCD                  = "Activer l'anneau du temps de recharge global",

        -- Sliders
        RING_SIZE                   = "Taille de l'anneau",
        COMBAT_OPACITY              = "Opacité en combat",
        OUT_OF_COMBAT_OPACITY       = "Opacité hors combat",
        FISHING_OPACITY             = "Opacité pendant la pêche",
        OUTLINE_THICKNESS           = "Épaisseur du contour",
        TRAIL_LENGTH                = "Longueur de la traînée de la souris",
        SPARKLE_SIZE                = "Multiplicateur de taille des étincelles",

        -- Slider endpoint labels
        SIZE_SMALL                  = "Petite",
        SIZE_LARGE                  = "Grande",
        PCT_0                       = "0 %",
        PCT_100                     = "100 %",
        THICKNESS_THIN              = "Mince",
        THICKNESS_THICK             = "Épais",
        LENGTH_SHORT                = "Courte",
        LENGTH_LONG                 = "Longue",

        -- Color picker labels
        RING_COLOR                  = "Couleur de l'anneau :",
        CAST_COLOR                  = "Couleur de l'effet d'incantation :",
        OUTLINE_COLOR               = "Couleur du contour :",
        TRAIL_COLOR                 = "Couleur de la traînée de la souris :",
        SPARKLE_COLOR               = "Couleur des étincelles :",
        GCD_COLOR                   = "Couleur du temps de recharge global :",

        -- Buttons
        RESET                       = "Réinitialiser",
        SAVE_PROFILE                = "Enregistrer comme nouveau profil",
        DELETE_PROFILE              = "Supprimer le profil sélectionné",

        -- Dropdown labels
        RING_SHAPE                  = "Forme de l'anneau :",
        CAST_STYLE                  = "Style de l'effet d'incantation :",
        LOAD_PROFILE                = "Charger un profil :",

        -- Cast style dropdown options
        STYLE_RING                  = "Anneau",
        STYLE_FILL                  = "Remplissage",
        STYLE_WEDGE                 = "Secteur",

        -- Ring shape dropdown options
        SHAPE_RING                  = "Anneau",
        SHAPE_THIN_RING             = "Anneau mince",
        SHAPE_STAR                  = "Étoile",
        SHAPE_HEX                   = "Hexagone",
        SHAPE_HEX90                 = "Hexagone 90",

        -- Profile management
        PROFILE_MANAGEMENT          = "Gestion des profils",
        PROFILE_NAME                = "Nom du profil :",
        ACTIVE_PROFILE              = "Profil actif : %s",
        ACTIVE_PROFILE_NONE         = "Profil actif : aucun (paramètres du personnage)",
        PROFILE_NONE                = "Aucun (paramètres du personnage)",

        -- Chat print messages (format strings use %s for dynamic values)
        MSG_CREATED_PROFILE         = "CursorRing : profil par défaut « %s » créé",
        MSG_PLEASE_ENTER_NAME       = "CursorRing : veuillez saisir un nom de profil",
        MSG_SAVED_PROFILE           = "CursorRing : paramètres enregistrés dans le profil « %s »",
        MSG_LOADED_PROFILE          = "CursorRing : profil « %s » chargé",
        MSG_FAILED_LOAD             = "CursorRing : échec du chargement du profil « %s »",
        MSG_USING_CHAR              = "CursorRing : utilisation des paramètres du personnage",
        MSG_DELETED_PROFILE         = "CursorRing : profil « %s » supprimé et valeurs par défaut rétablies",
        MSG_FAILED_DELETE           = "CursorRing : échec de la suppression du profil « %s »",
        MSG_NO_PROFILE              = "CursorRing : aucun profil sélectionné",

        -- Debug / slash command messages
        MSG_DEBUG_TEXTURE           = "CursorRing : texture de l'anneau mise à jour pour %s",
        MSG_DEBUG_ENABLED           = "CursorRing : mode de debug activé",
        MSG_DEBUG_DISABLED          = "CursorRing : mode de debug désactivé",
        MSG_COMMANDS                = "Commandes de CursorRing :",
        MSG_CMD_DEBUG               = "  /cursorring debug - Activer ou désactiver la sortie de débogage",

        -- ProfileManager messages (colored with inline color codes)
        MSG_PM_SAVED                = "|cFF00FF00CursorRing :|r profil « %s » enregistré avec succès.",
        MSG_PM_DELETED              = "|cFFFF0000CursorRing :|r profil « %s » supprimé.",
    },
}
CursorRing_L = L[GetLocale()] or L["enUS"]