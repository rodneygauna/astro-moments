-- Love2D Imports
local love = require("love")

-- Library imports
local cameraFile = require("libs/hump/camera")

-- Helper Functions --

-- Check if a save file exists
function hasSaveFile()
    -- Check if save file exists (implement later with file I/O)
    return false
end

-- Get menu button position
function getButtonY(index, totalButtons)
    local totalHeight = (totalButtons * menu.buttonHeight) + ((totalButtons - 1) * menu.buttonSpacing)
    local startY = (love.graphics.getHeight() - totalHeight) / 2
    return startY + (index - 1) * (menu.buttonHeight + menu.buttonSpacing)
end

-- Check if mouse is over a button
function isMouseOverButton(buttonIndex)
    local mouseX, mouseY = love.mouse.getPosition()
    local buttonX = (love.graphics.getWidth() - menu.buttonWidth) / 2
    local buttonY = getButtonY(buttonIndex, #menu.buttons)

    return mouseX >= buttonX and mouseX <= buttonX + menu.buttonWidth and mouseY >= buttonY and mouseY <= buttonY +
               menu.buttonHeight
end

-- Handle menu button action
function handleMenuAction(action)
    if action == "continue" then
        -- Load save file and continue
        currentGameState = gameStates.SKILL_TREE
    elseif action == "new_game" then
        -- Reset player progress and start new game
        currentGameState = gameStates.SKILL_TREE
    elseif action == "settings" then
        currentGameState = gameStates.SETTINGS
    elseif action == "credits" then
        currentGameState = gameStates.CREDITS
    elseif action == "exit" then
        love.event.quit()
    end
end

-- Love2D load function
function love.load()
    -- Set random seed
    math.randomseed(os.time())

    -- Player data structure
    player = {}
    player.name = "Captain" -- Player's name
    player.shipName = "Starfarer" -- Ship's name
    player.currency = {
        gold = 0, -- Mining currency earned from collecting asteroids
        fuel = 100 -- Fuel currency for traveling to sectors/maps
    }
    player.skills = {
        -- Purchased skills from skill tree (to be implemented)
        -- Example: {id = "faster_mining", level = 2, maxLevel = 5}
    }
    player.stats = {
        -- Permanent stat upgrades from skill tree
        collectionSpeedBonus = 0, -- Percentage bonus
        cargoCapacityBonus = 0, -- Flat bonus
        movementSpeedBonus = 0, -- Percentage bonus
        fuelEfficiency = 0 -- Reduces fuel cost per mission
    }
    player.progress = {
        unlockedMaps = {"sector_1"}, -- List of unlocked map/sector IDs
        completedMissions = 0, -- Total missions completed
        totalAsteroidsCollected = 0, -- Lifetime asteroid count
        playTime = 0 -- Total playtime in seconds
    }
    player.settings = {
        -- Player preferences
        musicVolume = 1.0,
        sfxVolume = 1.0,
        fullscreen = false,
        vsync = true
    }

    -- Initialize game variables
    maxTime = 30 -- Maximum time for mining phase in seconds
    timeLeft = maxTime

    -- Menu system
    menu = {}
    menu.buttons = {{
        text = "Continue",
        action = "continue",
        enabled = false
    }, {
        text = "New Game",
        action = "new_game",
        enabled = true
    }, {
        text = "Settings",
        action = "settings",
        enabled = true
    }, {
        text = "Credits",
        action = "credits",
        enabled = true
    }, {
        text = "Exit",
        action = "exit",
        enabled = true
    }}
    menu.selectedIndex = 1 -- Currently selected button index
    menu.buttonHeight = 50
    menu.buttonWidth = 200
    menu.buttonSpacing = 10

    -- Check if there is a save file (to be implemented)
    function hasSaveFile()
        return false
    end

    -- Get menu button position
    function getMenuButtonY(index, totalButtons)
        local totalHeight = (totalButtons * menu.buttonHeight) + ((totalButtons - 1) * menu.buttonSpacing)
        local startY = (love.graphics.getHeight() - totalHeight) / 2
        return startY + (index - 1) * (menu.buttonHeight + menu.buttonSpacing)
    end

    -- Check if mouse is over a button
    function isMouseOverButton(buttonIndex)
        local mouseX, mouseY = love.mouse.getPosition()
        local buttonX = (love.graphics.getWidth() - menu.buttonWidth) / 2
        local buttonY = getButtonY(buttonIndex, #menu.buttons)
        return mouseX >= buttonX and mouseX <= buttonX + menu.buttonWidth and mouseY >= buttonY and mouseY <= buttonY +
                   menu.buttonHeight
    end

    -- Handle menu button action
    function handleMenuAction(action)
        if action == "continue" then
            -- Load save file and continue (to be implemented)
            currentGameState = gameStates.MAP_SELECTION
        elseif action == "new_game" then
            -- Reset player's progress and start new game (to be implemented)
            currentGameState = gameStates.ROUND_START_BUFF_SELECTION
        elseif action == "settings" then
            -- Open settings menu (to be implemented)
            currentGameState = gameStates.SETTINGS
        elseif action == "credits" then
            -- Open credits screen (to be implemented)
            currentGameState = gameStates.CREDITS
        elseif action == "exit" then
            love.event.quit()
        end
    end

    -- Set the playable area size (circle)
    playableArea = {}
    -- Calculate radius to fill 90% of the smaller dimension (width or height)
    local smallerDimension = math.min(love.graphics.getWidth(), love.graphics.getHeight())
    playableArea.radius = (smallerDimension * 0.9) / 2
    playableArea.x = love.graphics.getWidth() / 2
    playableArea.y = love.graphics.getHeight() / 2

    -- Asteroid initialization
    asteroids = {}
    asteroids.maxAsteroids = 20
    asteroids.speed = 30
    asteroids.collectionSpeed = 50 -- Percentage per second when in field
    asteroids.decaySpeed = 30 -- Percentage per second when out of field

    -- Spaceship initialization (runtime state)
    spaceship = {}
    spaceship.x = love.graphics.getWidth() / 2
    spaceship.y = love.graphics.getHeight() / 2
    spaceship.maxSpeed = 100 + (100 * player.stats.movementSpeedBonus / 100) -- Base speed + bonus
    spaceship.acceleration = 200 -- How fast spaceship speeds up
    spaceship.deceleration = 150 -- How fast it slows down
    spaceship.velocityX = 0
    spaceship.velocityY = 0
    spaceship.currentSpeed = 0
    spaceship.collectionRadius = 100
    spaceship.isMoving = false
    spaceship.maxCargo = 5 + player.stats.cargoCapacityBonus -- Base cargo + bonus from skills
    spaceship.currentCargo = 0

    -- Game state definitions
    gameStates = {
        MENU = "menu",
        SKILL_TREE = "skill_tree",
        ROUND_START_BUFF_SELECTION = "round_start_buff_selection", -- choosing buffs at the start of a round
        MAP_SELECTION = "map_selection", -- choosing which map/sector to play
        MINING = "mining", -- mining phase
        CASHOUT = "cashout", -- cashing out phase (tally of collected asteroids for currency)
        PAUSED = "paused",
        GAME_OVER = "game_over",
        SETTINGS = "settings",
        CREDITS = "credits"
    }
    currentGameState = gameStates.MENU

    -- Camera initialization
    cam = cameraFile()

    -- Buff definitions
    buffs = { -- {{
    -- Property definitions:
    -- id: Unique identifier for the buff
    -- name: Display name of the buff
    -- description: Description of the buff's effect
    -- type: "multiplier" (increases by percentage) or "flat" (increases by fixed amount), boolean, etc.
    -- value: The amount or percentage the buff affects (starting as nil because the value will be determine randomly upon populating the buff selection)
    -- rarity: The rarity of the buff (common, rare, epic, etc.). Can influence how often it appears in selections.
    -- }}
    {
        id = "faster_collection",
        name = "Faster Collection",
        description = "Increases collection speed by a percentage.",
        type = "multiplier",
        value = nil,
        rarity = "common"
    }, {
        id = "decay_speed_reduction",
        name = "Decay Speed Reduction",
        description = "Reduces decay speed by a percentage.",
        type = "multiplier",
        value = nil,
        rarity = "common"
    }, {
        id = "increased_collection_radius",
        name = "Increased Collection Radius",
        description = "Increases the collection field radius by a flat amount.",
        type = "multiplier",
        value = nil,
        rarity = "uncommon"
    }, {
        id = "max_speed_boost",
        name = "Max Speed Boost",
        description = "Increases the spaceship's maximum speed by a flat amount.",
        type = "multiplier",
        value = nil,
        rarity = "uncommon"
    }, {
        id = "acceleration_boost",
        name = "Acceleration Boost",
        description = "Increases the spaceship's acceleration by a flat amount.",
        type = "multiplier",
        value = nil,
        rarity = "uncommon"
    }, {
        id = "max_hull_capacity",
        name = "Max Hull Capacity",
        description = "Increases the spaceship's maximum hull capacity by a flat amount.",
        type = "multiplier",
        value = nil,
        rarity = "rare"
    }, {
        id = "value_boost",
        name = "Value Boost",
        description = "Increases the value of collected asteroids by a multiplier (e.g., 1.5x).",
        type = "multiplier",
        value = nil,
        rarity = "rare"
    }}
end

-- Love2D update function
function love.update(dt)
    -- Mining Phase Logic
    if currentGameState == gameStates.MINING then
        -- Check if cargo is full
        if spaceship.currentCargo >= spaceship.maxCargo then
            -- Transition to cashout phase
            currentGameState = gameStates.CASHOUT
            return
        end
        -- Check if time is up
        if timeLeft <= 0 then
            -- Transition to cashout phase
            currentGameState = gameStates.CASHOUT
            return
        end

        -- Decrease time left
        timeLeft = timeLeft - dt
        if timeLeft < 0 then
            timeLeft = 0
        end

        -- Spawn asteroids periodically
        if #asteroids < asteroids.maxAsteroids then
            -- They must spawn within the playable area
            local angle = math.random() * 2 * math.pi
            local radius = math.random() * playableArea.radius
            local asteroidX = playableArea.x + radius * math.cos(angle)
            local asteroidY = playableArea.y + radius * math.sin(angle)

            -- Calculate dynamic spawn duration based on asteroid count
            -- More asteroids = slower spawn (0.9s), fewer asteroids = faster spawn (0.1s)
            local asteroidRatio = #asteroids / asteroids.maxAsteroids
            local dynamicSpawnDuration = 0.1 + (asteroidRatio * 0.8) -- Range: 0.1 to 0.9 seconds

            table.insert(asteroids, {
                x = asteroidX,
                y = asteroidY,
                spawnTimer = 0,
                spawnDuration = dynamicSpawnDuration
            })
        end

        -- Update camera position to follow the spaceship
        cam:lookAt(spaceship.x + 15, spaceship.y + 15)

        -- Spaceship movement with velocity-based physics
        spaceship.isMoving = false
        local inputX = 0
        local inputY = 0

        -- Get player input direction
        if love.keyboard.isDown("w", "up") then
            inputY = inputY - 1
            spaceship.isMoving = true
        end
        if love.keyboard.isDown("s", "down") then
            inputY = inputY + 1
            spaceship.isMoving = true
        end
        if love.keyboard.isDown("a", "left") then
            inputX = inputX - 1
            spaceship.isMoving = true
        end
        if love.keyboard.isDown("d", "right") then
            inputX = inputX + 1
            spaceship.isMoving = true
        end

        if spaceship.isMoving then
            -- Normalize input direction
            local inputLength = math.sqrt(inputX * inputX + inputY * inputY)
            if inputLength > 0 then
                inputX = inputX / inputLength
                inputY = inputY / inputLength
            end

            -- Calculate angle between current velocity and input direction
            local currentVelLength = math.sqrt(spaceship.velocityX * spaceship.velocityX + spaceship.velocityY *
                                                   spaceship.velocityY)
            local speedMultiplier = 1.0

            if currentVelLength > 0.1 then
                -- Normalize current velocity
                local currentDirX = spaceship.velocityX / currentVelLength
                local currentDirY = spaceship.velocityY / currentVelLength

                -- Calculate angle difference using dot product
                local dotProduct = currentDirX * inputX + currentDirY * inputY
                dotProduct = math.max(-1, math.min(1, dotProduct)) -- Clamp to [-1, 1]
                local angleDifference = math.acos(dotProduct) -- Result in radians

                -- Apply speed penalty based on angle difference
                if angleDifference < math.rad(45) then
                    speedMultiplier = 0.9 + (1 - angleDifference / math.rad(45)) * 0.1 -- 90-100%
                elseif angleDifference < math.rad(90) then
                    speedMultiplier = 0.7 + (1 - (angleDifference - math.rad(45)) / math.rad(45)) * 0.2 -- 70-90%
                else
                    speedMultiplier = 0.5 + (1 - (angleDifference - math.rad(90)) / math.rad(90)) * 0.2 -- 50-70%
                end
            end

            -- Target velocity with speed multiplier
            local targetVelX = inputX * spaceship.maxSpeed * speedMultiplier
            local targetVelY = inputY * spaceship.maxSpeed * speedMultiplier

            -- Accelerate toward target velocity
            local accel = spaceship.acceleration * dt
            spaceship.velocityX = spaceship.velocityX + (targetVelX - spaceship.velocityX) *
                                      math.min(accel / spaceship.maxSpeed, 1)
            spaceship.velocityY = spaceship.velocityY + (targetVelY - spaceship.velocityY) *
                                      math.min(accel / spaceship.maxSpeed, 1)
        else
            -- Decelerate when no input
            local decel = spaceship.deceleration * dt
            local currentVelLength = math.sqrt(spaceship.velocityX * spaceship.velocityX + spaceship.velocityY *
                                                   spaceship.velocityY)

            if currentVelLength > 0 then
                local decelAmount = math.min(decel, currentVelLength)
                spaceship.velocityX = spaceship.velocityX * (1 - decelAmount / currentVelLength)
                spaceship.velocityY = spaceship.velocityY * (1 - decelAmount / currentVelLength)
            end
        end

        -- Update current speed for reference
        spaceship.currentSpeed = math.sqrt(spaceship.velocityX * spaceship.velocityX + spaceship.velocityY *
                                               spaceship.velocityY)

        -- Apply velocity to position
        local newX = spaceship.x + spaceship.velocityX * dt
        local newY = spaceship.y + spaceship.velocityY * dt

        -- Check if new position is within circular playable area
        local spaceshipCenterX = newX + 15
        local spaceshipCenterY = newY + 15
        local distanceFromCenter = math.sqrt((spaceshipCenterX - playableArea.x) ^ 2 +
                                                 (spaceshipCenterY - playableArea.y) ^ 2)

        -- Keep spaceship within circular boundary
        if distanceFromCenter <= playableArea.radius then
            spaceship.x = newX
            spaceship.y = newY
        else
            -- Clamp spaceship to edge of circle and stop velocity in that direction
            local angle = math.atan2(spaceshipCenterY - playableArea.y, spaceshipCenterX - playableArea.x)
            spaceship.x = playableArea.x + math.cos(angle) * playableArea.radius - 15
            spaceship.y = playableArea.y + math.sin(angle) * playableArea.radius - 15

            -- Reduce velocity when hitting boundary
            spaceship.velocityX = spaceship.velocityX * 0.5
            spaceship.velocityY = spaceship.velocityY * 0.5
        end

        -- If the spaceship is moving, the collection field radius decreases to half its size over 1 second
        if spaceship.isMoving then
            spaceship.collectionRadius = math.max(20, spaceship.collectionRadius - 20 * dt)
        else
            spaceship.collectionRadius = math.min(40, spaceship.collectionRadius + 20 * dt)
        end

        -- Update asteroid positions (move in a random direction until they hit a boundary)
        for _, a in ipairs(asteroids) do
            -- Update spawn animation timer
            if a.spawnTimer < a.spawnDuration then
                a.spawnTimer = a.spawnTimer + dt
            end

            if not a.direction then
                a.direction = math.random() * 2 * math.pi
            end
            local newX = a.x + math.cos(a.direction) * asteroids.speed * dt
            local newY = a.y + math.sin(a.direction) * asteroids.speed * dt
            local distanceFromCenter = math.sqrt((newX - playableArea.x) ^ 2 + (newY - playableArea.y) ^ 2)
            if distanceFromCenter <= playableArea.radius then
                a.x = newX
                a.y = newY
            else
                a.direction = math.random() * 2 * math.pi
            end
        end

        -- Check if asteroid is within the collection field and update collection meter
        for i = #asteroids, 1, -1 do
            local a = asteroids[i]
            local distance = math.sqrt((a.x - (spaceship.x + 15)) ^ 2 + (a.y - (spaceship.y + 15)) ^ 2) -- center of the spaceship

            -- Initialize collection meter if it doesn't exist
            if not a.collectionMeter then
                a.collectionMeter = 0
            end

            if distance < spaceship.collectionRadius then
                -- Asteroid is in field - increase collection meter
                a.collectionMeter = a.collectionMeter + asteroids.collectionSpeed * dt
                if a.collectionMeter >= 100 then
                    a.collectionMeter = 100
                    -- Asteroid is collected!
                    table.remove(asteroids, i)
                    spaceship.currentCargo = spaceship.currentCargo + 1
                end
            else
                -- Asteroid is out of field - decrease collection meter
                a.collectionMeter = a.collectionMeter - asteroids.decaySpeed * dt
                if a.collectionMeter < 0 then
                    a.collectionMeter = 0
                end
            end
        end
    end
end

-- Love2D draw function
function love.draw()
    -- Menu Screen
    if currentGameState == gameStates.MENU then
        -- Draw title
        love.graphics.setColor(1, 1, 1)
        local titleFont = love.graphics.newFont(48)
        love.graphics.setFont(titleFont)
        love.graphics.printf("Astro Momments", 0, 100, love.graphics.getWidth(), "center")

        -- Reset to default font for buttons
        love.graphics.setFont(love.graphics.newFont(20))

        -- Draw buttons
        for i, button in ipairs(menu.buttons) do
            local buttonX = (love.graphics.getWidth() - menu.buttonWidth) / 2
            local buttonY = getButtonY(i, #menu.buttons)

            -- Determine button color
            if not button.enabled then
                love.graphics.setColor(0.3, 0.3, 0.3) -- Disabled
            elseif isMouseOverButton(i) or menu.selectedIndex == i then
                love.graphics.setColor(0.7, 0.7, 1) -- Highlighted
            else
                love.graphics.setColor(0.5, 0.5, 0.5) -- Normal
            end

            -- Draw button background
            love.graphics.rectangle("fill", buttonX, buttonY, menu.buttonWidth, menu.buttonHeight)

            -- Draw button border
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", buttonX, buttonY, menu.buttonWidth, menu.buttonHeight)

            -- Draw button text
            local textColor = button.enabled and {1, 1, 1} or {0.5, 0.5, 0.5}
            love.graphics.setColor(textColor)
            love.graphics.printf(button.text, buttonX, buttonY + (menu.buttonHeight - 20) / 2, menu.buttonWidth,
                "center")
        end
        return
    end
    -- Skill Tree Screen (not implemented, placeholder)
    if currentGameState == gameStates.SKILL_TREE then
        love.graphics.printf("Skill Tree Screen (Not Implemented)", 0, love.graphics.getHeight() / 2 - 20,
            love.graphics.getWidth(), "center")
        return
    end

    -- Round Start Buff Selection Screen (not implemented, placeholder)
    if currentGameState == gameStates.ROUND_START_BUFF_SELECTION then
        love.graphics.printf("Round Start Buff Selection Screen (Not Implemented)", 0,
            love.graphics.getHeight() / 2 - 20, love.graphics.getWidth(), "center")
        return
    end

    -- Map Screen (not implemented, placeholder
    if currentGameState == gameStates.MAP_SELECTION then
        love.graphics.printf("Map Selection Screen (Not Implemented)", 0, love.graphics.getHeight() / 2 - 20,
            love.graphics.getWidth(), "center")
        return
    end

    -- Mining Phase Screen
    if currentGameState == gameStates.MINING then
        -- Attach camera
        cam:attach()

        -- Draw playable area (space sector)
        love.graphics.setColor(0.1, 0.1, 0.2, 0.3) -- Dark space with transparency
        love.graphics.circle("fill", playableArea.x, playableArea.y, playableArea.radius)
        love.graphics.setColor(0.5, 0.5, 0.7) -- Light gray outline
        love.graphics.circle("line", playableArea.x, playableArea.y, playableArea.radius)

        -- Prototype for the spaceship (a square)
        love.graphics.setColor(0, 1, 0) -- Green color
        love.graphics.rectangle("fill", spaceship.x, spaceship.y, 30, 30)

        -- Prototype of the collection field around the spaceship
        love.graphics.setColor(0, 1, 1) -- Cyan color
        love.graphics.circle("line", spaceship.x + 15, spaceship.y + 15, spaceship.collectionRadius)

        -- Draw asteroids
        for _, a in ipairs(asteroids) do
            -- Calculate spawn scale (ease in from 0 to 1)
            local spawnScale = 1
            if a.spawnTimer < a.spawnDuration then
                local progress = a.spawnTimer / a.spawnDuration
                -- Ease out cubic for smooth spawn
                spawnScale = 1 - math.pow(1 - progress, 3)
            end

            love.graphics.setColor(0.6, 0.4, 0.2) -- Brown/gray color for asteroids
            love.graphics.circle("fill", a.x, a.y, 10 * spawnScale)

            -- Draw collection meter above asteroid if it's being collected
            if a.collectionMeter and a.collectionMeter > 0 then
                -- Background bar
                love.graphics.setColor(0.3, 0.3, 0.3)
                love.graphics.rectangle("fill", a.x - 15, a.y - 20, 30, 5)

                -- Progress bar
                love.graphics.setColor(0, 1, 1) -- Cyan
                love.graphics.rectangle("fill", a.x - 15, a.y - 20, 30 * (a.collectionMeter / 100), 5)

                -- Outline
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("line", a.x - 15, a.y - 20, 30, 5)
            end
        end

        -- Detach camera
        cam:detach()

        -- Draw UI elements in screen space (after detaching camera)
        -- Draw cargo capacity (middle top - current cargo / max cargo)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Cargo: " .. spaceship.currentCargo .. " / " .. spaceship.maxCargo, 0, 10,
            love.graphics.getWidth(), "center")

        -- Draw time left (top right)
        love.graphics.printf("Time Left: " .. math.ceil(timeLeft) .. "s", love.graphics.getWidth() - 200, 10, 200,
            "right")
    end

    -- Cashout Screen (not implemented, placeholder)
    if currentGameState == gameStates.CASHOUT then
        love.graphics.printf("Cashout Screen (Not Implemented)", 0, love.graphics.getHeight() / 2 - 20,
            love.graphics.getWidth(), "center")
        return
    end

    -- Paused Screen (not implemented, placeholder)
    if currentGameState == gameStates.PAUSED then
        love.graphics.printf("Paused Screen (Not Implemented)", 0, love.graphics.getHeight() / 2 - 20,
            love.graphics.getWidth(), "center")
        return
    end
end

-- Love2D keypressed function
function love.keypressed(key)
    -- Menu screen input handling
    if currentGameState == gameStates.MENU then
        if key == "up" then
            -- Move selection up (skip disabled buttons)
            repeat
                menu.selectedIndex = menu.selectedIndex - 1
                if menu.selectedIndex < 1 then
                    menu.selectedIndex = #menu.buttons
                end
            until menu.buttons[menu.selectedIndex].enabled
        elseif key == "down" then
            -- Move selection down (skip disabled buttons)
            repeat
                menu.selectedIndex = menu.selectedIndex + 1
                if menu.selectedIndex > #menu.buttons then
                    menu.selectedIndex = 1
                end
            until menu.buttons[menu.selectedIndex].enabled
        elseif key == "return" or key == "space" then
            handleMenuAction(menu.buttons[menu.selectedIndex].action)
        elseif key == "escape" then
            love.event.quit()
        end
        return
    end

    -- Other game state input handling
    if currentGameState == gameStates.ROUND_START_BUFF_SELECTION and key == "return" then
        -- Placeholder to go to map selection
        currentGameState = gameStates.MAP_SELECTION
    elseif currentGameState == gameStates.MAP_SELECTION and key == "return" then
        -- Start mining phase
        currentGameState = gameStates.MINING
    elseif currentGameState == gameStates.CASHOUT and key == "return" then
        -- Placeholder to go back to map selection
        currentGameState = gameStates.MAP_SELECTION
    elseif currentGameState == gameStates.SETTINGS then
        if key == "escape" then
            currentGameState = gameStates.MENU
        end
    elseif currentGameState == gameStates.CREDITS then
        if key == "escape" then
            currentGameState = gameStates.MENU
        end
    end
end

-- Love2D mousepressed function
function love.mousepressed(x, y, button)
    if currentGameState == gameStates.MENU and button == 1 then
        for i, menuButton in ipairs(menu.buttons) do
            if menuButton.enabled and isMouseOverButton(i) then
                handleMenuAction(menuButton.action)
                break
            end
        end
    end
end
