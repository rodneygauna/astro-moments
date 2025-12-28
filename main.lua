-- Love2D Imports
local love = require("love")

-- Module imports
local Player = require("src/player")
local Settings = require("src/settings")
local SFX = require("src/sfx")
local MenuScreen = require("screens/menu_screen")
local MiningScreen = require("screens/mining_screen")
local CashoutScreen = require("screens/cashout_screen")
local MapScreen = require("screens/map_screen")
local BuffSelectionScreen = require("screens/buff_selection_screen")
local UpgradeScreen = require("screens/upgrade_screen")
local SettingsScreen = require("screens/settings_screen")
local CreditsScreen = require("screens/credits_screen")
local ChangelogScreen = require("screens/changelog_screen")
local cameraFile = require("libs/hump/camera")

-- Global game fonts (will be initialized in love.load() and accessible to all screens)
GameFonts = {}

-- Global music state
local musicTracks = {}
local currentTrackIndex = 1

-- Global game state
local player
local cam
local currentScreen
local currentGameState

-- Game state definitions
local gameStates = {
    MENU = "menu",
    SKILL_TREE = "skill_tree",
    ROUND_START_BUFF_SELECTION = "round_start_buff_selection",
    MAP_SELECTION = "map_selection",
    MINING = "mining",
    CASHOUT = "cashout",
    PAUSED = "paused",
    GAME_OVER = "game_over",
    SETTINGS = "settings",
    CREDITS = "credits",
    CHANGELOG = "changelog"
}

-- Function to change game state
local function changeGameState(newState, ...)
    currentGameState = newState

    if newState == gameStates.MENU then
        currentScreen = MenuScreen
    elseif newState == gameStates.MINING then
        local sectorId, fuelCost = ...
        MiningScreen.load(cam, player, gameStates, changeGameState, sectorId, fuelCost)
        currentScreen = MiningScreen
    elseif newState == gameStates.CASHOUT then
        local sector, cargo = ...
        CashoutScreen.load(player, gameStates, changeGameState, sector, cargo)
        currentScreen = CashoutScreen
    elseif newState == gameStates.MAP_SELECTION then
        local loadedPlayer = ...
        if loadedPlayer then
            player = loadedPlayer -- Update global player with loaded data
        end
        MapScreen.load(player, gameStates, changeGameState)
        currentScreen = MapScreen
    elseif newState == gameStates.SETTINGS then
        SettingsScreen.load(gameStates, changeGameState)
        currentScreen = SettingsScreen
    elseif newState == gameStates.CREDITS then
        CreditsScreen.load(gameStates, changeGameState)
        currentScreen = CreditsScreen
    elseif newState == gameStates.CHANGELOG then
        ChangelogScreen.load(gameStates, changeGameState)
        currentScreen = ChangelogScreen
    elseif newState == gameStates.SKILL_TREE then
        UpgradeScreen.load(player, gameStates, changeGameState)
        currentScreen = UpgradeScreen
    elseif newState == gameStates.ROUND_START_BUFF_SELECTION then
        BuffSelectionScreen.load(player, gameStates, changeGameState)
        currentScreen = BuffSelectionScreen
    end
end

-- Love2D load function
function love.load()
    -- Set random seed
    math.randomseed(os.time())

    -- Load and apply settings
    Settings.load()
    Settings.apply()

    -- Load custom fonts in various sizes (accessible globally as GameFonts)
    GameFonts.small = love.graphics.newFont("fonts/prstartk.ttf", 12)
    GameFonts.normal = love.graphics.newFont("fonts/prstartk.ttf", 14)
    GameFonts.medium = love.graphics.newFont("fonts/prstartk.ttf", 16)
    GameFonts.large = love.graphics.newFont("fonts/prstartk.ttf", 20)
    GameFonts.title = love.graphics.newFont("fonts/prstartk.ttf", 36)
    GameFonts.huge = love.graphics.newFont("fonts/prstartk.ttf", 48)

    -- Set default font
    love.graphics.setFont(GameFonts.medium)

    -- Load background music tracks (streamed for memory efficiency)
    musicTracks = {love.audio.newSource("music/bg/Starlight_Code.ogg", "stream"),
                   love.audio.newSource("music/bg/Cosmic_Arcade.ogg", "stream"),
                   love.audio.newSource("music/bg/Pixel_Stars.ogg", "stream"),
                   love.audio.newSource("music/bg/Stellar_Drift.ogg", "stream")}

    -- Start playing the first track
    currentTrackIndex = 1
    love.audio.play(musicTracks[currentTrackIndex])

    -- Load sound effects
    SFX.load()

    -- Initialize player
    player = Player.new()

    -- Initialize camera
    cam = cameraFile()

    -- Initialize menu screen
    MenuScreen.load(gameStates, changeGameState)

    -- Set starting game state
    currentGameState = gameStates.MENU
    currentScreen = MenuScreen

end

-- Love2D update function
function love.update(dt)
    -- Update player playtime
    Player.updatePlaytime(player, dt)

    -- Apply music volume settings to all tracks
    local settings = Settings.get()
    for _, track in ipairs(musicTracks) do
        if settings.audio.musicMuted then
            track:setVolume(0)
        else
            track:setVolume(settings.audio.musicVolume)
        end
    end

    -- Check if current music track has finished and start next track
    if not musicTracks[currentTrackIndex]:isPlaying() then
        -- Move to next track (loop back to 1 after track 4)
        currentTrackIndex = currentTrackIndex + 1
        if currentTrackIndex > #musicTracks then
            currentTrackIndex = 1
        end
        love.audio.play(musicTracks[currentTrackIndex])
    end

    -- Delegate to current screen
    if currentScreen and currentScreen.update then
        currentScreen.update(dt)
    end

    -- Placeholder screens that just wait for input (handled in keypressed)
end

-- Love2D draw function
function love.draw()
    -- Delegate to current screen
    if currentScreen and currentScreen.draw then
        currentScreen.draw()
    else
        -- Fallback for unimplemented screens
        love.graphics.setColor(1, 1, 1)
        if currentGameState == gameStates.SKILL_TREE then
            love.graphics.printf("Skill Tree Screen (Not Implemented)", 0, love.graphics.getHeight() / 2 - 20,
                love.graphics.getWidth(), "center")
        elseif currentGameState == gameStates.ROUND_START_BUFF_SELECTION then
            love.graphics.printf("Round Start Buff Selection Screen (Not Implemented)", 0,
                love.graphics.getHeight() / 2 - 20, love.graphics.getWidth(), "center")
        elseif currentGameState == gameStates.MAP_SELECTION then
            love.graphics.printf("Map Selection Screen (Not Implemented)", 0, love.graphics.getHeight() / 2 - 20,
                love.graphics.getWidth(), "center")
        elseif currentGameState == gameStates.CASHOUT then
            love.graphics.printf("Cashout Screen (Not Implemented)", 0, love.graphics.getHeight() / 2 - 20,
                love.graphics.getWidth(), "center")
        elseif currentGameState == gameStates.PAUSED then
            love.graphics.printf("Paused Screen (Not Implemented)", 0, love.graphics.getHeight() / 2 - 20,
                love.graphics.getWidth(), "center")
        elseif currentGameState == gameStates.SETTINGS then
            love.graphics.printf("Settings Screen (Not Implemented)\nPress ESC to return", 0,
                love.graphics.getHeight() / 2 - 20, love.graphics.getWidth(), "center")

        end
    end
end

-- Love2D keypressed function
function love.keypressed(key)
    -- Delegate to current screen
    if currentScreen and currentScreen.keypressed then
        currentScreen.keypressed(key)
    else
        -- Fallback for unimplemented screens
        if currentGameState == gameStates.ROUND_START_BUFF_SELECTION and key == "return" then
            changeGameState(gameStates.MAP_SELECTION)
        elseif currentGameState == gameStates.MAP_SELECTION and key == "return" then
            changeGameState(gameStates.MINING)
        elseif currentGameState == gameStates.CASHOUT and key == "return" then
            changeGameState(gameStates.MAP_SELECTION)
        elseif currentGameState == gameStates.SETTINGS and key == "escape" then
            changeGameState(gameStates.MENU)
        end
    end
end

-- Love2D mousepressed function
function love.mousepressed(x, y, button)
    -- Delegate to current screen
    if currentScreen and currentScreen.mousepressed then
        currentScreen.mousepressed(x, y, button)
    end
end

-- Love2D mousemoved function
function love.mousemoved(x, y, dx, dy)
    -- Delegate to current screen (for slider dragging in settings)
    if currentScreen and currentScreen.mousemoved then
        currentScreen.mousemoved(x, y, dx, dy)
    end
end

-- Love2D wheelmoved function
function love.wheelmoved(x, y)
    -- Delegate to current screen (for scrolling)
    if currentScreen and currentScreen.wheelmoved then
        currentScreen.wheelmoved(x, y)
    end
end
