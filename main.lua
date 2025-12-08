-- Love2D Imports
local love = require("love")

-- Library imports
local cameraFile = require("libs/hump/camera")

-- Love2D load function
function love.load()
    -- Set random seed
    math.randomseed(os.time())

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

    -- Spaceship initialization
    spaceship = {}
    spaceship.x = love.graphics.getWidth() / 2
    spaceship.y = love.graphics.getHeight() / 2
    spaceship.maxSpeed = 100
    spaceship.acceleration = 200 -- How fast spaceship speeds up
    spaceship.deceleration = 150 -- How fast it slows down
    spaceship.velocityX = 0
    spaceship.velocityY = 0
    spaceship.currentSpeed = 0
    spaceship.collectionRadius = 100
    spaceship.isMoving = false

    -- Game state table for future use
    -- (eg. menu, skill tree, round start buff selection, playing, paused, game over)
    gameState = {}
    gameState.current = "menu"

    -- Camera initialization
    cam = cameraFile()
end

-- Love2D update function
function love.update(dt)
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
    local distanceFromCenter = math.sqrt((spaceshipCenterX - playableArea.x) ^ 2 + (spaceshipCenterY - playableArea.y) ^
                                             2)

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

-- Love2D draw function
function love.draw()
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
end

