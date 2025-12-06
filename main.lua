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

    -- Fish initialization
    fish = {}
    fish.maxFish = 20
    fish.speed = 30
    fish.captureSpeed = 50 -- Percentage per second when in ring
    fish.decaySpeed = 30 -- Percentage per second when out of ring

    -- Boat initialization
    boat = {}
    boat.x = love.graphics.getWidth() / 2
    boat.y = love.graphics.getHeight() / 2
    boat.maxSpeed = 100
    boat.acceleration = 200 -- How fast boat speeds up
    boat.deceleration = 150 -- How fast it slows down
    boat.velocityX = 0
    boat.velocityY = 0
    boat.currentSpeed = 0
    boat.catchRadius = 100
    boat.isMoving = false

    -- Camera initialization
    cam = cameraFile()
end

-- Love2D update function
function love.update(dt)
    -- Spawn fish periodically
    if #fish < fish.maxFish then
        -- They must spawn within the playable area
        local angle = math.random() * 2 * math.pi
        local radius = math.random() * playableArea.radius
        local fishX = playableArea.x + radius * math.cos(angle)
        local fishY = playableArea.y + radius * math.sin(angle)

        -- Calculate dynamic spawn duration based on fish count
        -- More fish = slower spawn (0.6s), fewer fish = faster spawn (0.1s)
        local fishRatio = #fish / fish.maxFish
        local dynamicSpawnDuration = 0.1 + (fishRatio * 0.8) -- Range: 0.1 to 0.9 seconds

        table.insert(fish, {
            x = fishX,
            y = fishY,
            spawnTimer = 0,
            spawnDuration = dynamicSpawnDuration
        })
    end

    -- Update camera position to follow the boat
    cam:lookAt(boat.x + 15, boat.y + 15)

    -- Boat movement with velocity-based physics
    boat.isMoving = false
    local inputX = 0
    local inputY = 0

    -- Get player input direction
    if love.keyboard.isDown("w") then
        inputY = inputY - 1
        boat.isMoving = true
    end
    if love.keyboard.isDown("s") then
        inputY = inputY + 1
        boat.isMoving = true
    end
    if love.keyboard.isDown("a") then
        inputX = inputX - 1
        boat.isMoving = true
    end
    if love.keyboard.isDown("d") then
        inputX = inputX + 1
        boat.isMoving = true
    end

    if boat.isMoving then
        -- Normalize input direction
        local inputLength = math.sqrt(inputX * inputX + inputY * inputY)
        if inputLength > 0 then
            inputX = inputX / inputLength
            inputY = inputY / inputLength
        end

        -- Calculate angle between current velocity and input direction
        local currentVelLength = math.sqrt(boat.velocityX * boat.velocityX + boat.velocityY * boat.velocityY)
        local speedMultiplier = 1.0

        if currentVelLength > 0.1 then
            -- Normalize current velocity
            local currentDirX = boat.velocityX / currentVelLength
            local currentDirY = boat.velocityY / currentVelLength

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
        local targetVelX = inputX * boat.maxSpeed * speedMultiplier
        local targetVelY = inputY * boat.maxSpeed * speedMultiplier

        -- Accelerate toward target velocity
        local accel = boat.acceleration * dt
        boat.velocityX = boat.velocityX + (targetVelX - boat.velocityX) * math.min(accel / boat.maxSpeed, 1)
        boat.velocityY = boat.velocityY + (targetVelY - boat.velocityY) * math.min(accel / boat.maxSpeed, 1)
    else
        -- Decelerate when no input
        local decel = boat.deceleration * dt
        local currentVelLength = math.sqrt(boat.velocityX * boat.velocityX + boat.velocityY * boat.velocityY)

        if currentVelLength > 0 then
            local decelAmount = math.min(decel, currentVelLength)
            boat.velocityX = boat.velocityX * (1 - decelAmount / currentVelLength)
            boat.velocityY = boat.velocityY * (1 - decelAmount / currentVelLength)
        end
    end

    -- Update current speed for reference
    boat.currentSpeed = math.sqrt(boat.velocityX * boat.velocityX + boat.velocityY * boat.velocityY)

    -- Apply velocity to position
    local newX = boat.x + boat.velocityX * dt
    local newY = boat.y + boat.velocityY * dt

    -- Check if new position is within circular playable area
    local boatCenterX = newX + 15
    local boatCenterY = newY + 15
    local distanceFromCenter = math.sqrt((boatCenterX - playableArea.x) ^ 2 + (boatCenterY - playableArea.y) ^ 2)

    -- Keep boat within circular boundary
    if distanceFromCenter <= playableArea.radius then
        boat.x = newX
        boat.y = newY
    else
        -- Clamp boat to edge of circle and stop velocity in that direction
        local angle = math.atan2(boatCenterY - playableArea.y, boatCenterX - playableArea.x)
        boat.x = playableArea.x + math.cos(angle) * playableArea.radius - 15
        boat.y = playableArea.y + math.sin(angle) * playableArea.radius - 15

        -- Reduce velocity when hitting boundary
        boat.velocityX = boat.velocityX * 0.5
        boat.velocityY = boat.velocityY * 0.5
    end

    -- If the boat is moving, the catching ring radius decreases to half its size over 1 second
    if boat.isMoving then
        boat.catchRadius = math.max(20, boat.catchRadius - 20 * dt)
    else
        boat.catchRadius = math.min(40, boat.catchRadius + 20 * dt)
    end

    -- Update fish positions (move in a random direction until they hit a boundary)
    for _, f in ipairs(fish) do
        -- Update spawn animation timer
        if f.spawnTimer < f.spawnDuration then
            f.spawnTimer = f.spawnTimer + dt
        end

        if not f.direction then
            f.direction = math.random() * 2 * math.pi
        end
        local newX = f.x + math.cos(f.direction) * fish.speed * dt
        local newY = f.y + math.sin(f.direction) * fish.speed * dt
        local distanceFromCenter = math.sqrt((newX - playableArea.x) ^ 2 + (newY - playableArea.y) ^ 2)
        if distanceFromCenter <= playableArea.radius then
            f.x = newX
            f.y = newY
        else
            f.direction = math.random() * 2 * math.pi
        end
    end

    -- Check if fish is within the catching ring and update capture meter
    for i = #fish, 1, -1 do
        local f = fish[i]
        local distance = math.sqrt((f.x - (boat.x + 15)) ^ 2 + (f.y - (boat.y + 15)) ^ 2) -- center of the boat

        -- Initialize capture meter if it doesn't exist
        if not f.captureMeter then
            f.captureMeter = 0
        end

        if distance < boat.catchRadius then
            -- Fish is in ring - increase capture meter
            f.captureMeter = f.captureMeter + fish.captureSpeed * dt
            if f.captureMeter >= 100 then
                f.captureMeter = 100
                -- Fish is caught!
                table.remove(fish, i)
            end
        else
            -- Fish is out of ring - decrease capture meter
            f.captureMeter = f.captureMeter - fish.decaySpeed * dt
            if f.captureMeter < 0 then
                f.captureMeter = 0
            end
        end
    end
end

-- Love2D draw function
function love.draw()
    -- Attach camera
    cam:attach()

    -- Draw playable area
    love.graphics.setColor(0.5, 0.5, 1, 0.3) -- Light blue with transparency
    love.graphics.circle("fill", playableArea.x, playableArea.y, playableArea.radius)
    love.graphics.setColor(0, 0, 0) -- Black outline
    love.graphics.circle("line", playableArea.x, playableArea.y, playableArea.radius)

    -- Prototype for the ship (a square)
    love.graphics.setColor(0, 1, 0) -- Green color
    love.graphics.rectangle("fill", boat.x, boat.y, 30, 30)

    -- Prototype of the catching ring around the boat
    love.graphics.setColor(1, 0, 0) -- Red color
    love.graphics.circle("line", boat.x + 15, boat.y + 15, boat.catchRadius)

    -- Draw fish
    for _, f in ipairs(fish) do
        -- Calculate spawn scale (ease in from 0 to 1)
        local spawnScale = 1
        if f.spawnTimer < f.spawnDuration then
            local progress = f.spawnTimer / f.spawnDuration
            -- Ease out cubic for smooth spawn
            spawnScale = 1 - math.pow(1 - progress, 3)
        end

        love.graphics.setColor(0, 0, 1) -- Blue color
        love.graphics.circle("fill", f.x, f.y, 10 * spawnScale)

        -- Draw capture meter above fish if it's being caught
        if f.captureMeter and f.captureMeter > 0 then
            -- Background bar
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", f.x - 15, f.y - 20, 30, 5)

            -- Progress bar
            love.graphics.setColor(0, 1, 0) -- Green
            love.graphics.rectangle("fill", f.x - 15, f.y - 20, 30 * (f.captureMeter / 100), 5)

            -- Outline
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", f.x - 15, f.y - 20, 30, 5)
        end
    end

    -- Detach camera
    cam:detach()
end

function spawnFish()
    local newFish = {}
    newFish.x = math.random(0, love.graphics.getWidth())
    newFish.y = math.random(0, love.graphics.getHeight())
    table.insert(fish, newFish)
end
