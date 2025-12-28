-- Asteroid module
-- Handles asteroid spawning, movement, and collection logic
local Asteroid = {}

-- Asteroid type definitions (Interesting read: https://en.wikipedia.org/wiki/Asteroid_mining)
Asteroid.types = {{
    id = "silicates", -- Olivine, pyroxene; most common
    value = 2,
    color = {0.5, 0.4, 0.3} -- Gray-brown
}, {
    id = "carbonaceous", -- Organic-rich material
    value = 3,
    color = {0.2, 0.15, 0.1} -- Dark brown/black
}, {
    id = "iron", -- Metallic iron
    value = 4,
    color = {0.4, 0.4, 0.45} -- Dark metallic gray
}, {
    id = "nickel", -- Iron-nickel alloy component
    value = 6,
    color = {0.45, 0.45, 0.4} -- Nickel gray
}, {
    id = "magnesium_silicates", -- Olivine variants
    value = 8,
    color = {0.5, 0.5, 0.35} -- Olive-green gray
}, {
    id = "aluminum_minerals", -- Plagioclase group
    value = 12,
    color = {0.7, 0.7, 0.7} -- Light gray
}, {
    id = "calcium_minerals", -- Anorthite, etc.
    value = 16,
    color = {0.8, 0.8, 0.75} -- Off-white
}, {
    id = "sulfides", -- Troilite (FeS)
    value = 24,
    color = {0.6, 0.5, 0.2} -- Brassy yellow-brown
}, {
    id = "water_ice", -- Often found in outer-belt asteroids
    value = 32,
    color = {0.7, 0.9, 1.0} -- Light blue
}, {
    id = "carbonates", -- Calcite, dolomite
    value = 48,
    color = {0.9, 0.9, 0.85} -- Cream white
}, {
    id = "clay_minerals", -- Phyllosilicates
    value = 64,
    color = {0.55, 0.45, 0.35} -- Clay brown
}, {
    id = "graphite", -- Pure carbon crystals
    value = 96,
    color = {0.15, 0.15, 0.15} -- Very dark gray
}, {
    id = "chromium_oxides", -- Chromite and related minerals
    value = 128,
    color = {0.3, 0.3, 0.25} -- Dark gray-green
}, {
    id = "cobalt", -- Trace metal in iron meteorites
    value = 192,
    color = {0.5, 0.5, 0.6} -- Blue-gray metallic
}, {
    id = "titanium_oxides", -- Rutile, ilmenite
    value = 256,
    color = {0.3, 0.25, 0.3} -- Dark purple-gray
}, {
    id = "rare_earths", -- REE-bearing minerals
    value = 384,
    color = {0.6, 0.4, 0.7} -- Purple-tinted
}, {
    id = "platinum_group", -- Pt, Ir, Os, Pd
    value = 512,
    color = {0.8, 0.8, 0.85} -- Silver-white
}, {
    id = "gold", -- Present in trace amounts
    value = 768,
    color = {1.0, 0.84, 0} -- Golden
}, {
    id = "microdiamonds", -- Nanodiamonds from impacts
    value = 1024,
    color = {0.9, 0.95, 1.0} -- Bright white-cyan
}, {
    id = "amino_acids", -- Extremely rare organic precursors
    value = 1536,
    color = {0.4, 0.6, 0.5} -- Organic green-gray
}}

-- Asteroid configuration
Asteroid.maxAsteroids = 20
Asteroid.speed = 30
Asteroid.collectionSpeed = 50 -- Percentage per second when in field
Asteroid.decaySpeed = 30 -- Percentage per second when out of field

-- Create a new asteroid at a random position within the playable area
function Asteroid.spawn(playableArea, currentAsteroidCount, allowedTypes)
    -- Default to all types if not specified
    allowedTypes = allowedTypes or Asteroid.types

    -- Select random type from allowed types
    local typeIndex = math.random(1, #allowedTypes)
    local asteroidType = allowedTypes[typeIndex]

    local angle = math.random() * 2 * math.pi
    local radius = math.random() * playableArea.radius
    local asteroidX = playableArea.x + radius * math.cos(angle)
    local asteroidY = playableArea.y + radius * math.sin(angle)

    -- Calculate dynamic spawn duration based on asteroid count
    -- More asteroids = slower spawn (0.9s), fewer asteroids = faster spawn (0.1s)
    local asteroidRatio = currentAsteroidCount / Asteroid.maxAsteroids
    local dynamicSpawnDuration = 0.1 + (asteroidRatio * 0.8) -- Range: 0.1 to 0.9 seconds

    -- Generate random polygon vertices for jagged appearance
    local numVertices = math.random(6, 9) -- 6-9 sided polygon
    local vertices = {}
    local baseRadius = 10
    for i = 1, numVertices do
        local angleStep = (2 * math.pi) / numVertices
        local angle = (i - 1) * angleStep + math.random() * 0.3 -- Add randomness to angle
        local radiusVariation = baseRadius * (0.7 + math.random() * 0.6) -- 70% to 130% of base
        table.insert(vertices, math.cos(angle) * radiusVariation)
        table.insert(vertices, math.sin(angle) * radiusVariation)
    end

    return {
        x = asteroidX,
        y = asteroidY,
        spawnTimer = 0,
        spawnDuration = dynamicSpawnDuration,
        direction = nil,
        collectionMeter = 0,
        asteroidType = asteroidType, -- Store the type data
        vertices = vertices -- Store polygon shape
    }
end

-- Update asteroid position and state
function Asteroid.update(asteroid, dt, playableArea)
    -- Update spawn animation timer
    if asteroid.spawnTimer < asteroid.spawnDuration then
        asteroid.spawnTimer = asteroid.spawnTimer + dt
    end

    -- Initialize random direction if not set
    if not asteroid.direction then
        asteroid.direction = math.random() * 2 * math.pi
    end

    -- Apply speed multiplier if slowed by obstacle
    local speedMultiplier = asteroid.speedMultiplier or 1.0

    -- Decay the slowdown effect over time
    if asteroid.slowedTimer and asteroid.slowedTimer > 0 then
        asteroid.slowedTimer = asteroid.slowedTimer - dt
        if asteroid.slowedTimer <= 0 then
            asteroid.speedMultiplier = 1.0
            asteroid.slowedTimer = nil
        end
    end

    -- Calculate new position with speed multiplier
    local effectiveSpeed = Asteroid.speed * speedMultiplier
    local newX = asteroid.x + math.cos(asteroid.direction) * effectiveSpeed * dt
    local newY = asteroid.y + math.sin(asteroid.direction) * effectiveSpeed * dt
    local distanceFromCenter = math.sqrt((newX - playableArea.x) ^ 2 + (newY - playableArea.y) ^ 2)

    -- Update position if within bounds, otherwise change direction
    if distanceFromCenter <= playableArea.radius then
        asteroid.x = newX
        asteroid.y = newY
    else
        asteroid.direction = math.random() * 2 * math.pi
    end
end

-- Update asteroid collection meter
function Asteroid.updateCollection(asteroid, dt, spaceshipCenterX, spaceshipCenterY, collectionRadius, playerStats,
    spaceship)
    local distance = math.sqrt((asteroid.x - spaceshipCenterX) ^ 2 + (asteroid.y - spaceshipCenterY) ^ 2)

    -- Calculate collection speed with bonus from both upgrades and buffs
    local upgradeCollectionBonus = (playerStats and playerStats.collectionSpeedBonus) or 0
    local buffCollectionBonus = (spaceship and spaceship.collectionSpeedBonus) or 0
    local totalCollectionBonus = upgradeCollectionBonus + buffCollectionBonus
    local effectiveCollectionSpeed = Asteroid.collectionSpeed * (1 + totalCollectionBonus / 100)

    -- Calculate decay speed with resistance from both upgrades and buffs
    local upgradeDecayReduction = (playerStats and playerStats.decayReduction) or 0
    local buffDecayReduction = (spaceship and spaceship.decaySpeedReduction) or 0
    local totalDecayReduction = upgradeDecayReduction + buffDecayReduction
    local effectiveDecaySpeed = Asteroid.decaySpeed * (1 - totalDecayReduction / 100)

    -- Check for auto-collect threshold
    local autoCollectThreshold = (playerStats and playerStats.autoCollectThreshold) or nil
    if autoCollectThreshold and asteroid.collectionMeter >= autoCollectThreshold then
        asteroid.collectionMeter = 100
        return true -- Auto-collected!
    end

    if distance < collectionRadius then
        -- Apply radiation debuff if active (25% reduction)
        local captureMultiplier = 1.0
        if spaceship.radiationDebuff then
            captureMultiplier = 0.75 -- 25% reduction
        end

        -- Asteroid is in field - increase collection meter
        asteroid.collectionMeter = asteroid.collectionMeter + effectiveCollectionSpeed * captureMultiplier * dt
        if asteroid.collectionMeter >= 100 then
            asteroid.collectionMeter = 100
            return true -- Asteroid is collected!
        end
    else
        -- Asteroid is out of field - decrease collection meter
        asteroid.collectionMeter = asteroid.collectionMeter - effectiveDecaySpeed * dt
        if asteroid.collectionMeter < 0 then
            asteroid.collectionMeter = 0
        end
    end

    return false -- Not collected yet
end

-- Draw an asteroid
function Asteroid.draw(asteroid)
    -- Calculate spawn scale (ease in from 0 to 1)
    local spawnScale = 1
    if asteroid.spawnTimer < asteroid.spawnDuration then
        local progress = asteroid.spawnTimer / asteroid.spawnDuration
        -- Ease out cubic for smooth spawn
        spawnScale = 1 - math.pow(1 - progress, 3)
    end

    -- Use material-specific color
    local color = asteroid.asteroidType.color or {0.5, 0.4, 0.3}

    -- Apply orange tint if slowed by solar flare
    if asteroid.slowedTimer and asteroid.slowedTimer > 0 then
        love.graphics.setColor(color[1] * 0.7 + 1.0 * 0.3, -- Mix with orange
        color[2] * 0.7 + 0.5 * 0.3, color[3] * 0.7)
    else
        love.graphics.setColor(color[1], color[2], color[3])
    end

    -- Draw polygon asteroid with spawn scale
    love.graphics.push()
    love.graphics.translate(asteroid.x, asteroid.y)
    love.graphics.scale(spawnScale, spawnScale)
    love.graphics.polygon("fill", asteroid.vertices)
    love.graphics.pop()

    -- Draw collection meter above asteroid if it's being collected
    if asteroid.collectionMeter and asteroid.collectionMeter > 0 then
        -- Background bar
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", asteroid.x - 15, asteroid.y - 20, 30, 5)

        -- Progress bar
        love.graphics.setColor(0, 1, 1) -- Cyan
        love.graphics.rectangle("fill", asteroid.x - 15, asteroid.y - 20, 30 * (asteroid.collectionMeter / 100), 5)

        -- Outline
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", asteroid.x - 15, asteroid.y - 20, 30, 5)
    end
end

-- Update all asteroids in a list
function Asteroid.updateAll(asteroids, dt, playableArea, spaceship, playerStats)
    -- Update positions
    for _, asteroid in ipairs(asteroids) do
        Asteroid.update(asteroid, dt, playableArea)
    end

    -- Check collection and remove collected asteroids
    local spaceshipCenterX, spaceshipCenterY = spaceship.x + 15, spaceship.y + 15
    for i = #asteroids, 1, -1 do
        local collected = Asteroid.updateCollection(asteroids[i], dt, spaceshipCenterX, spaceshipCenterY,
            spaceship.collectionRadius, playerStats, spaceship)
        if collected then
            -- Store the collected asteroid data
            table.insert(spaceship.collectedAsteroids, asteroids[i])
            table.remove(asteroids, i)
            spaceship.currentCargo = spaceship.currentCargo + 1

            -- Play capture sound effect
            local SFX = require("src/sfx")
            SFX.playAsteroidCapture()
        end
    end
end

-- Draw all asteroids in a list
function Asteroid.drawAll(asteroids)
    for _, asteroid in ipairs(asteroids) do
        Asteroid.draw(asteroid)
    end
end

return Asteroid
