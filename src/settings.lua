-- Settings Module
-- Handles game settings storage and management
local Settings = {}
local json = require("libs/dkjson/dkjson")

-- Default settings
local defaultSettings = {
    audio = {
        musicVolume = 0.7, -- 0.0 to 1.0
        musicMuted = false,
        sfxVolume = 0.7, -- 0.0 to 1.0
        sfxMuted = false
    },
    video = {
        width = 1024,
        height = 720,
        fullscreen = false,
        vsync = true
    }
}

-- Available resolution presets
Settings.resolutionPresets = {{
    width = 800,
    height = 600,
    label = "800x600"
}, {
    width = 1024,
    height = 720,
    label = "1024x720"
}, {
    width = 1280,
    height = 720,
    label = "1280x720"
}, {
    width = 1920,
    height = 1080,
    label = "1920x1080"
}}

-- Settings file path
local SETTINGS_FILE = "settings.json"

-- Current settings (loaded from file or defaults)
local currentSettings = nil

-- Initialize settings (load from file or use defaults)
function Settings.load()
    local info = love.filesystem.getInfo(SETTINGS_FILE)
    if info then
        local contents, err = love.filesystem.read(SETTINGS_FILE)
        if contents then
            local decoded, pos, err = json.decode(contents)
            if decoded then
                currentSettings = decoded

                -- Merge with defaults for any missing properties
                for category, settings in pairs(defaultSettings) do
                    if not currentSettings[category] then
                        currentSettings[category] = {}
                    end
                    for key, value in pairs(settings) do
                        if currentSettings[category][key] == nil then
                            currentSettings[category][key] = value
                        end
                    end
                end

                return true
            end
        end
    end

    -- Use defaults if file doesn't exist or failed to load
    currentSettings = {}
    for k, v in pairs(defaultSettings) do
        currentSettings[k] = {}
        for sk, sv in pairs(v) do
            currentSettings[k][sk] = sv
        end
    end
    return false
end

-- Save settings to file
function Settings.save()
    if not currentSettings then
        return false, "No settings to save"
    end

    local encoded = json.encode(currentSettings, {
        indent = true
    })
    if not encoded then
        return false, "Failed to encode settings"
    end

    local writeSuccess, writeError = love.filesystem.write(SETTINGS_FILE, encoded)
    if not writeSuccess then
        return false, writeError
    end

    return true
end

-- Get current settings
function Settings.get()
    if not currentSettings then
        Settings.load()
    end
    return currentSettings
end

-- Apply settings to Love2D
function Settings.apply()
    if not currentSettings then
        Settings.load()
    end

    -- Apply video settings
    love.window.setMode(currentSettings.video.width, currentSettings.video.height, {
        fullscreen = currentSettings.video.fullscreen,
        vsync = currentSettings.video.vsync,
        resizable = false
    })

    -- Note: Audio settings are applied per-source
    -- Music tracks must have their volume set individually in main.lua
    -- SFX volume is applied when each sound effect is played
end

-- Update specific setting
function Settings.set(category, key, value)
    if not currentSettings then
        Settings.load()
    end

    if currentSettings[category] then
        currentSettings[category][key] = value
        return true
    end
    return false
end

-- Reset to defaults
function Settings.reset()
    currentSettings = {}
    for k, v in pairs(defaultSettings) do
        currentSettings[k] = {}
        for sk, sv in pairs(v) do
            currentSettings[k][sk] = sv
        end
    end
    Settings.save()
    Settings.apply()
end

return Settings
