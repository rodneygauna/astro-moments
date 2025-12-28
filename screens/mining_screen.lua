-- Mining Screen
-- Handles the mining gameplay phase
local MiningScreen = {}

local Spaceship = require("src/spaceship")
local Asteroid = require("src/asteroid")
local Sector = require("src/sector")
local Buff = require("src/buff")
local Obstacle = require("src.obstacles.init")
local Settings = require("src/settings")

-- Mining state
local cam
local spaceship
local asteroids
local obstacles
local playableArea
local timeLeft
local maxTime
local maxAsteroidsAllowed
local player
local gameStates
local changeState
local currentSector
local gameState -- For storing buff-related state like value multiplier
local farStars -- Background star layer (slow parallax)
local nearStars -- Foreground star layer (fast parallax)
local planetSprite -- Planet background image
local planetPosition -- Planet position and scale data
local moonSprite -- Moon background image
local moonPosition -- Moon position and scale data
local fuelCostForThisSector = 0 -- Track fuel cost for refund if player quits early

-- Pause overlay state
local isPaused = false
local pausePromptImage
local pauseButtonNormalImage
local pauseButtonHoverImage
local pauseMenu = {
    selectedButton = 1,
    buttons = {}
}

-- Helper function to get asteroid types for current sector
local function getSectorAsteroidTypes()
    local allowedTypes = {}
    for _, typeId in ipairs(currentSector.asteroidTypes) do
        -- Find the matching type in Asteroid.types by id
        for _, asteroidType in ipairs(Asteroid.types) do
            if asteroidType.id == typeId then
                table.insert(allowedTypes, asteroidType)
                break
            end
        end
    end
    return allowedTypes
end

-- Helper function: Check if mouse is over a pause button
local function isMouseOverPauseButton(buttonIndex)
    local mouseX, mouseY = love.mouse.getPosition()
    local button = pauseMenu.buttons[buttonIndex]
    if not button then
        return false
    end

    return mouseX >= button.x and mouseX <= button.x + button.width and mouseY >= button.y and mouseY <= button.y +
               button.height
end

-- Helper function: Setup pause menu buttons
local function setupPauseMenu()
    local dialogWidth = 650
    local dialogHeight = 450
    local dialogX = (love.graphics.getWidth() - dialogWidth) / 2
    local dialogY = (love.graphics.getHeight() - dialogHeight) / 2

    local buttonWidth = 200
    local buttonHeight = 50

    local resumeY = dialogY + 100
    local stopButtonY = dialogY + dialogHeight - 180
    local exitButtonY = dialogY + dialogHeight - 115
    local buttonX = dialogX + (dialogWidth - buttonWidth) / 2

    pauseMenu.buttons = {{
        text = "Resume Game",
        action = "resume",
        x = buttonX,
        y = resumeY,
        width = buttonWidth,
        height = buttonHeight
    }, {
        text = "Stop Mining",
        action = "stop_mining",
        x = buttonX,
        y = stopButtonY,
        width = buttonWidth,
        height = buttonHeight
    }, {
        text = "Exit Game",
        action = "exit_game",
        x = buttonX,
        y = exitButtonY,
        width = buttonWidth,
        height = buttonHeight
    }}
end

-- Helper function: Handle pause menu action
local function handlePauseAction(action)
    if action == "resume" then
        isPaused = false
    elseif action == "stop_mining" then
        -- Refund fuel and return to map
        if fuelCostForThisSector > 0 then
            player.currency.fuel = player.currency.fuel + fuelCostForThisSector
        end
        local Save = require("src.save")
        Save.write(player)
        changeState(gameStates.MAP_SELECTION, player)
    elseif action == "exit_game" then
        -- Refund fuel before exiting
        if fuelCostForThisSector > 0 then
            player.currency.fuel = player.currency.fuel + fuelCostForThisSector
        end
        local Save = require("src.save")
        Save.write(player)
        love.event.quit()
    end
end

-- Initialize mining screen
function MiningScreen.load(camera, playerData, states, stateChanger, sectorId, fuelCost)
    cam = camera
    player = playerData
    gameStates = states
    changeState = stateChanger
    currentSector = Sector.definitions[sectorId] or Sector.definitions["sector_01"]
    fuelCostForThisSector = fuelCost or 0 -- Store the fuel cost for potential refund
    isPaused = false -- Reset pause state
    maxTime = 30 + (player.stats.missionTimeBonus or 0) -- Base time + mission time bonus
    timeLeft = maxTime

    -- Load pause overlay images
    if not pausePromptImage then
        pausePromptImage = love.graphics.newImage("sprites/prompts/ConfirmationPrompt_650x450.png")
        pausePromptImage:setFilter("nearest", "nearest")
    end
    if not pauseButtonNormalImage then
        pauseButtonNormalImage = love.graphics.newImage("sprites/buttons/Btn_200x50.png")
        pauseButtonNormalImage:setFilter("nearest", "nearest")
    end
    if not pauseButtonHoverImage then
        pauseButtonHoverImage = love.graphics.newImage("sprites/buttons/Btn-Hover_200x50.png")
        pauseButtonHoverImage:setFilter("nearest", "nearest")
    end

    -- Setup pause menu buttons
    setupPauseMenu()

    -- Set the playable area size (circle)
    playableArea = {}
    local smallerDimension = math.min(love.graphics.getWidth(), love.graphics.getHeight())
    playableArea.radius = (smallerDimension * 0.9) / 2
    playableArea.x = love.graphics.getWidth() / 2
    playableArea.y = love.graphics.getHeight() / 2

    -- Load and position planet sprite if sector has one
    planetSprite = nil
    planetPosition = nil
    if currentSector.planetImage then
        planetSprite = love.graphics.newImage(currentSector.planetImage)
        planetSprite:setFilter("nearest", "nearest") -- Pixel art filter

        -- Generate random position just outside playable area but still visible
        local angle = math.random() * 2 * math.pi
        local distance = playableArea.radius * (1.0 + math.random() * 0.4) -- Between 1.0x and 1.4x radius
        planetPosition = {
            x = playableArea.x + math.cos(angle) * distance,
            y = playableArea.y + math.sin(angle) * distance,
            scale = 1.2 + math.random() * 0.8, -- Random scale between 1.2 and 2.0 for better visibility
            rotation = math.random() * 2 * math.pi -- Random rotation in radians (0 to 2π)
        }
    end

    -- Load and position moon sprite (always present)
    moonSprite = love.graphics.newImage("sprites/planets/Moon.png")
    moonSprite:setFilter("nearest", "nearest") -- Pixel art filter

    -- Position moon relative to planet (or center if no planet) to create a pair
    local moonBaseX, moonBaseY
    if planetPosition then
        -- Position moon near the planet
        moonBaseX = planetPosition.x
        moonBaseY = planetPosition.y
    else
        -- No planet, position moon relative to center
        local baseAngle = math.random() * 2 * math.pi
        local baseDistance = playableArea.radius * (1.0 + math.random() * 0.4)
        moonBaseX = playableArea.x + math.cos(baseAngle) * baseDistance
        moonBaseY = playableArea.y + math.sin(baseAngle) * baseDistance
    end

    -- Offset moon from its base position (planet or random center point)
    local moonAngle = math.random() * 2 * math.pi
    local moonOffset = 150 + math.random() * 100 -- Distance 150-250 pixels from planet/base
    moonPosition = {
        x = moonBaseX + math.cos(moonAngle) * moonOffset,
        y = moonBaseY + math.sin(moonAngle) * moonOffset,
        scale = 0.4 + math.random() * 1.0, -- Random scale between 0.4 and 1.4 for more variety
        rotation = planetPosition and planetPosition.rotation or (math.random() * 2 * math.pi) -- Match planet rotation or random
    }

    -- Generate parallax star field
    -- Far layer: smaller, dimmer stars across a larger area
    farStars = {}
    local starFieldSize = playableArea.radius * 3 -- Larger than playable area
    for i = 1, 150 do
        local angle = math.random() * 2 * math.pi
        local distance = math.random() * starFieldSize
        local colorVariant = math.random()
        local starColor
        if colorVariant < 0.6 then
            starColor = {1, 1, 1} -- White
        elseif colorVariant < 0.85 then
            starColor = {0.7, 0.8, 1} -- Blue-white
        else
            starColor = {1, 0.95, 0.7} -- Yellow-white
        end
        table.insert(farStars, {
            x = playableArea.x + math.cos(angle) * distance,
            y = playableArea.y + math.sin(angle) * distance,
            size = 1,
            brightness = 0.3 + math.random() * 0.3,
            color = starColor
        })
    end

    -- Near layer: larger, brighter stars
    nearStars = {}
    for i = 1, 80 do
        local angle = math.random() * 2 * math.pi
        local distance = math.random() * starFieldSize
        local colorVariant = math.random()
        local starColor
        if colorVariant < 0.6 then
            starColor = {1, 1, 1} -- White
        elseif colorVariant < 0.85 then
            starColor = {0.7, 0.8, 1} -- Blue-white
        else
            starColor = {1, 0.95, 0.7} -- Yellow-white
        end
        table.insert(nearStars, {
            x = playableArea.x + math.cos(angle) * distance,
            y = playableArea.y + math.sin(angle) * distance,
            size = 1.5 + math.random() * 0.5,
            brightness = 0.5 + math.random() * 0.5,
            color = starColor
        })
    end

    -- Initialize spaceship
    spaceship = Spaceship.new(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, player)

    -- Calculate max asteroids with spawn rate bonus
    local spawnRateBonus = (player.stats.spawnRateBonus or 0) / 100
    maxAsteroidsAllowed = math.floor(Asteroid.maxAsteroids * (1 + spawnRateBonus))

    -- Initialize game state for buffs
    gameState = {
        maxTime = maxTime,
        timeLeft = timeLeft,
        valueMultiplier = 1.0
    }

    -- Apply active buffs if any
    if player.activeBuffs then
        for _, buff in ipairs(player.activeBuffs) do
            Buff.apply(buff, spaceship, gameState)
        end
        -- Update time values if buffs modified them
        maxTime = gameState.maxTime
        timeLeft = gameState.timeLeft
    end

    -- Initialize asteroids list
    asteroids = {}

    -- Initialize obstacles based on sector configuration
    obstacles = {}

    -- Check for random obstacles configuration
    if currentSector.randomObstacles and currentSector.randomObstacles.enabled then
        -- Select random obstacles from the pool
        local pool = currentSector.randomObstacles.pool
        local minCount = currentSector.randomObstacles.minCount or 3
        local maxCount = currentSector.randomObstacles.maxCount or 5
        local numObstacles = love.math.random(minCount, maxCount)

        -- Shuffle the pool and take the first numObstacles
        local shuffledPool = {}
        for i, obstacleConfig in ipairs(pool) do
            table.insert(shuffledPool, obstacleConfig)
        end

        -- Fisher-Yates shuffle
        for i = #shuffledPool, 2, -1 do
            local j = love.math.random(i)
            shuffledPool[i], shuffledPool[j] = shuffledPool[j], shuffledPool[i]
        end

        -- Create the selected obstacles
        for i = 1, math.min(numObstacles, #shuffledPool) do
            local obstacleConfig = shuffledPool[i]
            for j = 1, obstacleConfig.count do
                local obstacle = Obstacle.create(obstacleConfig, playableArea, obstacles, j)
                if obstacle then
                    table.insert(obstacles, obstacle)
                end
            end
        end
    elseif currentSector.obstacles then
        -- Normal obstacle initialization
        for _, obstacleConfig in ipairs(currentSector.obstacles) do
            for i = 1, obstacleConfig.count do
                local obstacle = Obstacle.create(obstacleConfig, playableArea, obstacles, i)
                if obstacle then
                    table.insert(obstacles, obstacle)
                end
            end
        end
    end
end

-- Reset mining screen for a new round
function MiningScreen.reset()
    timeLeft = maxTime
    Spaceship.reset(spaceship, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    asteroids = {}
end

-- Update mining screen
function MiningScreen.update(dt)
    -- Don't update game logic if paused
    if isPaused then
        return
    end

    -- Check if cargo is full
    if Spaceship.isCargoFull(spaceship) then
        changeState(gameStates.CASHOUT, currentSector, {
            used = spaceship.currentCargo,
            max = spaceship.maxCargo,
            items = spaceship.collectedAsteroids,
            valueMultiplier = gameState.valueMultiplier
        })
        return
    end

    -- Check if time is up
    if timeLeft <= 0 then
        changeState(gameStates.CASHOUT, currentSector, {
            used = spaceship.currentCargo,
            max = spaceship.maxCargo,
            items = spaceship.collectedAsteroids,
            valueMultiplier = gameState.valueMultiplier
        })
        return
    end

    -- Decrease time left
    timeLeft = timeLeft - dt
    if timeLeft < 0 then
        timeLeft = 0
    end

    -- Spawn asteroids periodically
    if #asteroids < maxAsteroidsAllowed then
        local allowedTypes = getSectorAsteroidTypes()
        table.insert(asteroids, Asteroid.spawn(playableArea, #asteroids, allowedTypes))
    end

    -- Update camera position to follow the spaceship
    local centerX, centerY = Spaceship.getCenter(spaceship)
    cam:lookAt(centerX, centerY)

    -- Update spaceship
    Spaceship.update(spaceship, dt, playableArea)

    -- Update all asteroids
    Asteroid.updateAll(asteroids, dt, playableArea, spaceship, player.stats)

    -- Update obstacles
    for _, obstacle in ipairs(obstacles) do
        Obstacle.update(obstacle, dt, asteroids, spaceship, playableArea)
    end

    -- Check for collisions with space debris
    for _, obstacle in ipairs(obstacles) do
        if obstacle.type == "space_debris" then
            -- Create a collision target with ship's center position
            local shipCenter = {
                x = spaceship.x + 15,
                y = spaceship.y + 15
            }
            if Obstacle.checkCollision(obstacle, shipCenter) then
                -- Calculate bounce direction (away from debris, using center)
                local dx = shipCenter.x - obstacle.x
                local dy = shipCenter.y - obstacle.y
                local distance = math.sqrt(dx * dx + dy * dy)

                if distance > 0 then
                    -- Normalize and apply bounce
                    local bounceForce = 200
                    spaceship.velocityX = (dx / distance) * bounceForce
                    spaceship.velocityY = (dy / distance) * bounceForce

                    -- Stun spaceship for 1 second
                    spaceship.stunned = true
                    spaceship.stunTimer = 1.0

                    -- Trigger warning for 3 seconds
                    obstacle.warningTimer = 3.0

                    -- Stop capture if in progress
                    if spaceship.capturing then
                        spaceship.capturing = false
                        spaceship.captureProgress = 0
                        spaceship.targetAsteroid = nil
                    end
                end
            end
        elseif obstacle.type == "meteor" then
            -- Create a collision target with ship's center position
            local shipCenter = {
                x = spaceship.x + 15,
                y = spaceship.y + 15
            }
            if Obstacle.checkCollision(obstacle, shipCenter) then
                -- Calculate bounce direction (away from meteor, using center)
                local dx = shipCenter.x - obstacle.x
                local dy = shipCenter.y - obstacle.y
                local distance = math.sqrt(dx * dx + dy * dy)

                if distance > 0 then
                    -- Normalize and apply strong bounce with gradual slowdown from friction
                    local bounceForce = 800
                    spaceship.velocityX = (dx / distance) * bounceForce
                    spaceship.velocityY = (dy / distance) * bounceForce

                    -- Check if bounce would push player outside boundary and clamp if needed
                    local testX = spaceship.x + spaceship.velocityX * 0.1
                    local testY = spaceship.y + spaceship.velocityY * 0.1
                    local testCenterX = testX + 15
                    local testCenterY = testY + 15
                    local distFromCenter = math.sqrt(
                        (testCenterX - playableArea.x) ^ 2 + (testCenterY - playableArea.y) ^ 2)

                    -- If bounce would push outside, reduce bounce force toward center
                    if distFromCenter > playableArea.radius - 50 then
                        local toCenterX = playableArea.x - shipCenter.x
                        local toCenterY = playableArea.y - shipCenter.y
                        local toCenterDist = math.sqrt(toCenterX * toCenterX + toCenterY * toCenterY)
                        if toCenterDist > 0 then
                            spaceship.velocityX = (toCenterX / toCenterDist) * bounceForce * 0.5
                            spaceship.velocityY = (toCenterY / toCenterDist) * bounceForce * 0.5
                        end
                    end

                    -- Stun spaceship for 1 second
                    spaceship.stunned = true
                    spaceship.stunTimer = 1.0

                    -- Trigger warning for 3 seconds
                    obstacle.warningTimer = 3.0

                    -- Stop capture if in progress
                    if spaceship.capturing then
                        spaceship.capturing = false
                        spaceship.captureProgress = 0
                        spaceship.targetAsteroid = nil
                    end
                end
            end
        elseif obstacle.type == "black_hole" then
            -- Check if ship touches the danger zone (center)
            local shipCenter = {
                x = spaceship.x + 15,
                y = spaceship.y + 15
            }
            if Obstacle.checkCollision(obstacle, shipCenter) then
                -- Trigger warning
                obstacle.warningTimer = 3.0

                -- End mining session - player loses all collected asteroids
                -- Clear all collected asteroids and cargo
                spaceship.collectedAsteroids = {}
                spaceship.currentCargo = 0

                -- Transition to cashout screen with empty cargo
                changeState(gameStates.CASHOUT, currentSector, {
                    used = 0,
                    max = spaceship.maxCargo,
                    items = {}, -- Empty items
                    valueMultiplier = 0, -- No value multiplier
                    blackHoleLoss = true -- Flag to show special message
                })
                return
            end

            -- Check if any asteroids touch the black hole danger zone and remove them
            for i = #asteroids, 1, -1 do
                local asteroid = asteroids[i]
                local asteroidTarget = {
                    x = asteroid.x,
                    y = asteroid.y
                }
                if Obstacle.checkCollision(obstacle, asteroidTarget) then
                    -- Remove asteroid that was consumed by black hole
                    table.remove(asteroids, i)
                end
            end
        end
    end
end

-- Draw mining screen
function MiningScreen.draw()
    -- Draw background stars with parallax (before camera attach)
    local camX, camY = cam:position()
    local centerX, centerY = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2

    -- Draw far stars (20% parallax - slower movement)
    for _, star in ipairs(farStars) do
        local offsetX = (camX - centerX) * 0.2
        local offsetY = (camY - centerY) * 0.2
        love.graphics.setColor(star.color[1], star.color[2], star.color[3], star.brightness)
        love.graphics.circle("fill", star.x - offsetX, star.y - offsetY, star.size)
    end

    -- Draw near stars (60% parallax - faster movement)
    for _, star in ipairs(nearStars) do
        local offsetX = (camX - centerX) * 0.6
        local offsetY = (camY - centerY) * 0.6
        love.graphics.setColor(star.color[1], star.color[2], star.color[3], star.brightness)
        love.graphics.circle("fill", star.x - offsetX, star.y - offsetY, star.size)
    end

    -- Draw moon sprite with subtle parallax (15% - slowest, furthest back)
    if moonSprite and moonPosition then
        local offsetX = (camX - centerX) * 0.15
        local offsetY = (camY - centerY) * 0.15
        love.graphics.setColor(1, 1, 1, 0.85) -- Slight transparency
        local moonX = moonPosition.x - offsetX
        local moonY = moonPosition.y - offsetY
        local originX = moonSprite:getWidth() / 2
        local originY = moonSprite:getHeight() / 2
        love.graphics.draw(moonSprite, moonX, moonY, moonPosition.rotation, moonPosition.scale, moonPosition.scale,
            originX, originY)
    end

    -- Draw planet sprite with subtle parallax (20% - slower than stars)
    if planetSprite and planetPosition then
        local offsetX = (camX - centerX) * 0.2
        local offsetY = (camY - centerY) * 0.2
        love.graphics.setColor(1, 1, 1, 0.9) -- Slight transparency
        local planetX = planetPosition.x - offsetX
        local planetY = planetPosition.y - offsetY
        local originX = planetSprite:getWidth() / 2
        local originY = planetSprite:getHeight() / 2
        love.graphics.draw(planetSprite, planetX, planetY, planetPosition.rotation, planetPosition.scale,
            planetPosition.scale, originX, originY)
    end

    -- Attach camera for world rendering
    cam:attach()

    -- Draw playable area (space sector)
    love.graphics.setColor(0.1, 0.1, 0.2, 0.3) -- Dark space with transparency
    love.graphics.circle("fill", playableArea.x, playableArea.y, playableArea.radius)
    love.graphics.setColor(0.5, 0.5, 0.7) -- Light gray outline
    love.graphics.circle("line", playableArea.x, playableArea.y, playableArea.radius)

    -- Draw spaceship
    Spaceship.draw(spaceship)

    -- Draw all asteroids
    Asteroid.drawAll(asteroids)

    -- Draw obstacles
    for _, obstacle in ipairs(obstacles) do
        Obstacle.draw(obstacle)
    end

    -- Detach camera
    cam:detach()

    -- Draw UI elements in screen space (after detaching camera)
    love.graphics.setColor(1, 1, 1)

    -- Draw cargo capacity (middle top)
    love.graphics.printf("Cargo: " .. spaceship.currentCargo .. " / " .. spaceship.maxCargo, 0, 10,
        love.graphics.getWidth(), "center")

    -- Draw time left (top right) - flash red when 10 seconds or less
    if timeLeft <= 10 then
        local flashAlpha = 0.5 + 0.5 * math.abs(math.sin(love.timer.getTime() * 5))
        love.graphics.setColor(1, 0.2, 0.2, flashAlpha)
    else
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.printf("Time Left: " .. math.ceil(timeLeft) .. "s", love.graphics.getWidth() - 200, 10, 200, "right")
    love.graphics.setColor(1, 1, 1) -- Reset color

    -- Draw gold (top left)
    love.graphics.print("Gold: " .. player.currency.gold, 10, 10)

    -- Draw obstacle warnings at bottom center
    if obstacles and #obstacles > 0 then
        local uniqueWarnings = {}
        for _, obstacle in ipairs(obstacles) do
            local warning = Obstacle.getWarning(obstacle)
            if warning then
                uniqueWarnings[warning] = true
            end
        end

        -- Convert unique warnings to array
        local warningList = {}
        for warning, _ in pairs(uniqueWarnings) do
            table.insert(warningList, warning)
        end

        if #warningList > 0 then
            local warningText
            if #warningList >= 2 then
                warningText = "WARNING: Systems Overloaded!"
            else
                warningText = warningList[1]
            end

            -- Pulsing effect for warning text (never fully transparent)
            local pulseAlpha = 0.8 + 0.2 * math.sin(love.timer.getTime() * 4)
            love.graphics.setColor(1, 0.3, 0.3, pulseAlpha)
            love.graphics.setFont(GameFonts.large)
            love.graphics.printf(warningText, 0, love.graphics.getHeight() - 40, love.graphics.getWidth(), "center")
        end
    end

    -- Draw pause overlay if paused
    if isPaused then
        -- Draw semi-transparent overlay
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        -- Dialog box dimensions
        local dialogWidth = 650
        local dialogHeight = 450
        local dialogX = (love.graphics.getWidth() - dialogWidth) / 2
        local dialogY = (love.graphics.getHeight() - dialogHeight) / 2

        -- Draw pause prompt image
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(pausePromptImage, dialogX, dialogY)

        -- Draw title
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(GameFonts.large)
        love.graphics.printf("Game Paused", dialogX, dialogY + 30, dialogWidth, "center")

        -- Draw warning text
        love.graphics.setFont(GameFonts.small)
        love.graphics.setColor(1, 0.7, 0.7)
        love.graphics.printf("Stopping mining or exiting will not save", dialogX + 20, dialogY + 210, dialogWidth - 40,
            "center")
        love.graphics.printf("any progress for this sector.", dialogX + 20, dialogY + 230, dialogWidth - 40, "center")

        -- Draw buttons
        for i, button in ipairs(pauseMenu.buttons) do
            local isHovered = (i == pauseMenu.selectedButton) or isMouseOverPauseButton(i)
            local buttonImage = isHovered and pauseButtonHoverImage or pauseButtonNormalImage

            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(buttonImage, button.x, button.y)

            -- Draw button text
            love.graphics.setFont(GameFonts.medium)
            love.graphics.printf(button.text, button.x, button.y + 15, button.width, "center")
        end

        -- Draw controls hint
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setFont(GameFonts.small)
        love.graphics.printf("[ESC or P] Resume  [CLICK] Select", dialogX, dialogY + dialogHeight - 35, dialogWidth,
            "center")
    end
end

-- Handle keyboard input
function MiningScreen.keypressed(key)
    if isPaused then
        -- Handle pause menu input
        if key == "escape" or key == "p" then
            isPaused = false
        elseif key == "up" or key == "w" then
            pauseMenu.selectedButton = pauseMenu.selectedButton - 1
            if pauseMenu.selectedButton < 1 then
                pauseMenu.selectedButton = #pauseMenu.buttons
            end
        elseif key == "down" or key == "s" then
            pauseMenu.selectedButton = pauseMenu.selectedButton + 1
            if pauseMenu.selectedButton > #pauseMenu.buttons then
                pauseMenu.selectedButton = 1
            end
        elseif key == "return" or key == "space" then
            local button = pauseMenu.buttons[pauseMenu.selectedButton]
            if button then
                handlePauseAction(button.action)
            end
        end
    else
        -- Normal gameplay input
        if key == "escape" or key == "p" then
            isPaused = true
            pauseMenu.selectedButton = 1
        end
    end
end

-- Handle mouse input
function MiningScreen.mousepressed(x, y, button)
    if isPaused and button == 1 then
        -- Check which pause button was clicked
        for i, btn in ipairs(pauseMenu.buttons) do
            if isMouseOverPauseButton(i) then
                handlePauseAction(btn.action)
                break
            end
        end
    end
end

return MiningScreen
