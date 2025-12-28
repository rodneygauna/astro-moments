-- Credits Screen
-- Displays game credits and acknowledgments
local CreditsScreen = {}

-- Credits state
local stars = {}
local spaceObjects = {} -- Spaceship, planet, and moon
local gameStates
local changeState

-- Initialize credits screen
function CreditsScreen.load(states, stateChanger)
    gameStates = states
    changeState = stateChanger

    -- Generate random star background
    stars = {}
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    for i = 1, 100 do
        local colorVariant = math.random()
        local starColor
        if colorVariant < 0.6 then
            starColor = {1, 1, 1} -- White
        elseif colorVariant < 0.85 then
            starColor = {0.7, 0.8, 1} -- Blue-white
        else
            starColor = {1, 0.95, 0.7} -- Yellow-white
        end

        table.insert(stars, {
            x = math.random() * screenWidth,
            y = math.random() * screenHeight,
            size = 1 + math.random() * 1.5,
            brightness = 0.4 + math.random() * 0.6,
            color = starColor
        })
    end

    -- Load and position space objects around the outskirts
    spaceObjects = {}

    -- Helper function to get a random position near the edges (but inside window)
    local function getEdgePosition()
        local edge = math.random(1, 4) -- 1=top, 2=right, 3=bottom, 4=left
        local margin = 50 -- Distance from edge
        local x, y

        if edge == 1 then -- Top edge
            x = margin + math.random() * (screenWidth - margin * 2)
            y = margin + math.random() * 100
        elseif edge == 2 then -- Right edge
            x = screenWidth - margin - math.random() * 100
            y = margin + math.random() * (screenHeight - margin * 2)
        elseif edge == 3 then -- Bottom edge
            x = margin + math.random() * (screenWidth - margin * 2)
            y = screenHeight - margin - math.random() * 100
        else -- Left edge
            x = margin + math.random() * 100
            y = margin + math.random() * (screenHeight - margin * 2)
        end

        return x, y
    end

    -- Load spaceship
    local spaceshipImage = love.graphics.newImage("sprites/ships/Spaceship.png")
    spaceshipImage:setFilter("nearest", "nearest")
    local spaceshipX, spaceshipY = getEdgePosition()
    table.insert(spaceObjects, {
        image = spaceshipImage,
        x = spaceshipX,
        y = spaceshipY,
        scale = 1.5 + math.random() * 1.0, -- 1.5 to 2.5
        rotation = math.random() * 2 * math.pi,
        alpha = 0.6 + math.random() * 0.3
    })

    -- Load planet
    local planetImage = love.graphics.newImage("sprites/planets/Planet-Green-Blue.png")
    planetImage:setFilter("nearest", "nearest")
    local planetX, planetY = getEdgePosition()
    local planetRotation = math.random() * 2 * math.pi
    table.insert(spaceObjects, {
        image = planetImage,
        x = planetX,
        y = planetY,
        scale = 1.5 + math.random() * 1.5, -- 1.5 to 3.0
        rotation = planetRotation,
        alpha = 0.7 + math.random() * 0.3
    })

    -- Load moon - position it near the planet and match rotation
    local moonImage = love.graphics.newImage("sprites/planets/Moon.png")
    moonImage:setFilter("nearest", "nearest")
    -- Offset moon from planet position
    local moonAngle = math.random() * 2 * math.pi
    local moonOffset = 150 + math.random() * 100 -- Distance 150-250 pixels from planet
    local moonX = planetX + math.cos(moonAngle) * moonOffset
    local moonY = planetY + math.sin(moonAngle) * moonOffset
    -- Clamp moon position to stay within window bounds
    local moonMargin = 50
    moonX = math.max(moonMargin, math.min(screenWidth - moonMargin, moonX))
    moonY = math.max(moonMargin, math.min(screenHeight - moonMargin, moonY))
    table.insert(spaceObjects, {
        image = moonImage,
        x = moonX,
        y = moonY,
        scale = 0.8 + math.random() * 0.7, -- 0.8 to 1.5
        rotation = planetRotation, -- Match planet rotation
        alpha = 0.6 + math.random() * 0.3
    })
end

-- Update credits screen
function CreditsScreen.update(dt)
    -- Future: Could add scrolling credits animation
end

-- Draw credits screen
function CreditsScreen.draw()
    -- Draw black background
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw stars
    for _, star in ipairs(stars) do
        love.graphics.setColor(star.color[1], star.color[2], star.color[3], star.brightness)
        love.graphics.circle("fill", star.x, star.y, star.size)
    end

    -- Draw space objects (spaceship, planet, moon) with transparency
    for _, obj in ipairs(spaceObjects) do
        love.graphics.setColor(1, 1, 1, obj.alpha)
        local originX = obj.image:getWidth() / 2
        local originY = obj.image:getHeight() / 2
        love.graphics.draw(obj.image, obj.x, obj.y, obj.rotation, obj.scale, obj.scale, originX, originY)
    end

    -- Draw credits content
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(GameFonts.title)
    love.graphics.printf("Astro Moments", 0, 30, love.graphics.getWidth(), "center")

    love.graphics.setFont(GameFonts.medium)
    love.graphics.printf("Credits", 0, 75, love.graphics.getWidth(), "center")

    love.graphics.setFont(GameFonts.normal)
    local creditsY = 120
    local lineSpacing = 30

    -- Credits
    love.graphics.printf("Game Design & Development", 0, creditsY, love.graphics.getWidth(), "center")
    creditsY = creditsY + lineSpacing
    love.graphics.printf("Rodney 's0n0f4L1ch' Gauna", 0, creditsY, love.graphics.getWidth(), "center")

    creditsY = creditsY + lineSpacing * 2
    love.graphics.printf("Libraries & Tools", 0, creditsY, love.graphics.getWidth(), "center")
    creditsY = creditsY + lineSpacing
    love.graphics.printf("LÖVE2D Framework", 0, creditsY, love.graphics.getWidth(), "center")
    creditsY = creditsY + lineSpacing
    love.graphics.printf("HUMP Library", 0, creditsY, love.graphics.getWidth(), "center")
    creditsY = creditsY + lineSpacing
    love.graphics.printf("dkjson Library", 0, creditsY, love.graphics.getWidth(), "center")

    creditsY = creditsY + lineSpacing * 2
    love.graphics.printf("Font", 0, creditsY, love.graphics.getWidth(), "center")
    creditsY = creditsY + lineSpacing
    love.graphics.printf("Press Start by Cody 'Codeman38' Boisclair", 0, creditsY, love.graphics.getWidth(), "center")

    creditsY = creditsY + lineSpacing * 2
    love.graphics.printf("Music", 0, creditsY, love.graphics.getWidth(), "center")
    creditsY = creditsY + lineSpacing
    love.graphics.printf("AI-Generated Tracks via Suno", 0, creditsY, love.graphics.getWidth(), "center")

    creditsY = creditsY + lineSpacing * 2
    love.graphics.printf("Special Thanks", 0, creditsY, love.graphics.getWidth(), "center")
    creditsY = creditsY + lineSpacing
    love.graphics.printf("To my wife Jaclyn for her support", 0, creditsY, love.graphics.getWidth(), "center")
    creditsY = creditsY + lineSpacing
    love.graphics.printf("To my son Max for giving me joy and confidence", 0, creditsY, love.graphics.getWidth(),
        "center")

    creditsY = creditsY + lineSpacing * 2
    love.graphics.printf("Built for the Codedex Winter 2025 Game Jam", 0, creditsY, love.graphics.getWidth(), "center")

    -- Controls hint at bottom
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(GameFonts.normal)
    love.graphics.printf("[ESC] Return to Menu", 0, love.graphics.getHeight() - 40, love.graphics.getWidth(), "center")
end

-- Handle keyboard input
function CreditsScreen.keypressed(key)
    if key == "escape" then
        changeState(gameStates.MENU)
    end
end

return CreditsScreen
