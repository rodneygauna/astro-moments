-- SFX Module
-- Handles sound effects playback with volume and mute settings
local SFX = {}

local Settings = require("src/settings")

-- Sound effect sources
local sounds = {}

-- Load all sound effects
function SFX.load()
    sounds.buttonHover = love.audio.newSource("music/sfx/button_move-hover.wav", "static")
    sounds.buttonClick = love.audio.newSource("music/sfx/button_select-click.wav", "static")
    sounds.asteroidCapture = love.audio.newSource("music/sfx/sfx_capture_complete.wav", "static")
end

-- Play a sound effect with volume and mute settings applied
local function playSound(soundName)
    if not sounds[soundName] then
        return
    end

    local settings = Settings.get()
    if settings.audio.sfxMuted then
        return -- Don't play if muted
    end

    -- Clone the sound for overlapping playback
    local sound = sounds[soundName]:clone()
    sound:setVolume(settings.audio.sfxVolume)
    sound:play()
end

-- Public functions to play specific sounds
function SFX.playButtonHover()
    playSound("buttonHover")
end

function SFX.playButtonClick()
    playSound("buttonClick")
end

function SFX.playAsteroidCapture()
    playSound("asteroidCapture")
end

-- Get the raw sound source (for passing to other modules)
function SFX.getSound(soundName)
    return sounds[soundName]
end

return SFX
