-- Cashout Screen
-- Displays collected materials and calculates earnings
local CashoutScreen = {}

local Player = require("src/player")
local Save = require("src/save")
local SFX = require("src/sfx")

-- Cashout state
local player
local gameStates
local changeState
local sectorName
local collectedMaterials
local cargoUsed
local cargoMax
local totalValue
local hasProcessedReward
local baseValue -- Value before multiplier
local valueMultiplier -- Multiplier from buffs
local goldMultiplier -- Multiplier from upgrades
local emergencyPenalty -- Emergency beacon penalty
local isBlackHoleLoss -- Flag for black hole death

-- Initialize cashout screen
function CashoutScreen.load(playerData, states, stateChanger, sector, cargo)
    player = playerData
    gameStates = states
    changeState = stateChanger
    sectorName = sector.name
    cargoUsed = cargo.used
    cargoMax = cargo.max
    hasProcessedReward = false
    isBlackHoleLoss = cargo.blackHoleLoss or false

    -- Process collected materials
    collectedMaterials = {}
    totalValue = 0
    baseValue = 0

    -- Count each material type
    for _, asteroid in ipairs(cargo.items) do
        local typeId = asteroid.asteroidType.id
        local typeValue = asteroid.asteroidType.value

        if not collectedMaterials[typeId] then
            collectedMaterials[typeId] = {
                id = typeId,
                quantity = 0,
                value = typeValue,
                total = 0
            }
        end

        collectedMaterials[typeId].quantity = collectedMaterials[typeId].quantity + 1
        collectedMaterials[typeId].total = collectedMaterials[typeId].quantity * typeValue
        baseValue = baseValue + typeValue
    end

    -- Apply value multiplier from buffs if active
    valueMultiplier = cargo.valueMultiplier or 1.0

    -- Apply gold multiplier from upgrades
    goldMultiplier = 1.0 + ((player.stats.goldMultiplier or 0) / 100)

    -- Apply emergency beacon penalty if active
    emergencyPenalty = 1.0
    if player.progress.emergencyBeaconPenalty then
        emergencyPenalty = 0.9 -- 10% reduction
        -- Clear the penalty flag after applying it
        player.progress.emergencyBeaconPenalty = false
    end

    totalValue = math.floor(baseValue * valueMultiplier * goldMultiplier * emergencyPenalty)

    -- Award gold to player
    Player.addGold(player, totalValue)
    hasProcessedReward = true

    -- Save player progress
    Save.write(player)
end

-- Update cashout screen
function CashoutScreen.update(dt)
    -- Nothing to update
end

-- Draw cashout screen
function CashoutScreen.draw()
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw panel background
    local panelWidth = 600
    local panelHeight = 550
    local panelX = (love.graphics.getWidth() - panelWidth) / 2
    local panelY = (love.graphics.getHeight() - panelHeight) / 2

    love.graphics.setColor(0.15, 0.15, 0.2, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 10, 10)

    -- Draw border
    love.graphics.setColor(0.5, 0.5, 0.7)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 10, 10)
    love.graphics.setLineWidth(1)

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(GameFonts.title)
    love.graphics.printf("CASHOUT", panelX, panelY + 20, panelWidth, "center")

    -- Draw sector name
    love.graphics.setFont(GameFonts.large)
    love.graphics.setColor(0.7, 0.7, 0.9)
    love.graphics.printf(sectorName, panelX, panelY + 70, panelWidth, "center")

    -- Draw cargo info
    love.graphics.setFont(GameFonts.medium)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Cargo: " .. cargoUsed .. " / " .. cargoMax, panelX, panelY + 105, panelWidth, "center")

    -- Draw separator line
    love.graphics.setColor(0.5, 0.5, 0.7)
    love.graphics.line(panelX + 50, panelY + 135, panelX + panelWidth - 50, panelY + 135)

    -- Show black hole message OR materials list
    if isBlackHoleLoss then
        -- Black hole loss message in place of materials list
        local messageY = panelY + 250
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.setFont(GameFonts.large)
        love.graphics.printf("CONSUMED BY BLACK HOLE", panelX, messageY, panelWidth, "center")
        love.graphics.setColor(0.9, 0.5, 0.5)
        love.graphics.setFont(GameFonts.medium)
        love.graphics.printf("All cargo lost!", panelX, messageY + 40, panelWidth, "center")
    else
        -- Draw materials header
        love.graphics.setFont(GameFonts.normal)
        love.graphics.setColor(0.8, 0.8, 0.8)
        local headerY = panelY + 155
        love.graphics.printf("Material", panelX + 50, headerY, 200, "left")
        love.graphics.printf("Qty", panelX + 250, headerY, 80, "center")
        love.graphics.printf("Value", panelX + 330, headerY, 80, "center")
        love.graphics.printf("Total", panelX + 410, headerY, 100, "right")

        -- Draw materials list
        love.graphics.setColor(1, 1, 1)
        local currentY = headerY + 30
        local lineHeight = 25

        for materialId, data in pairs(collectedMaterials) do
            -- Format material name (replace underscores with spaces, capitalize first letter)
            local displayName = materialId:gsub("_", " "):gsub("^%l", string.upper)

            love.graphics.printf(displayName, panelX + 50, currentY, 200, "left")
            love.graphics.printf(tostring(data.quantity), panelX + 250, currentY, 80, "center")
            love.graphics.printf(tostring(data.value), panelX + 330, currentY, 80, "center")
            love.graphics.printf(tostring(data.total), panelX + 410, currentY, 100, "right")

            currentY = currentY + lineHeight
        end
    end

    -- Draw separator line before total
    love.graphics.setColor(0.5, 0.5, 0.7)
    love.graphics.line(panelX + 50, panelY + panelHeight - 140, panelX + panelWidth - 50, panelY + panelHeight - 140)

    -- Track current Y position for dynamic layout
    local multiplierY = panelY + panelHeight - 120

    -- Always show base value if any multipliers are active
    if valueMultiplier > 1.0 or goldMultiplier > 1.0 or emergencyPenalty < 1.0 then
        love.graphics.setFont(GameFonts.normal)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("Base Value:", panelX + 50, multiplierY, 300, "left")
        love.graphics.printf(tostring(baseValue) .. " Gold", panelX + 350, multiplierY, 200, "right")
        multiplierY = multiplierY + 20

        -- Draw buff multiplier if active
        if valueMultiplier > 1.0 then
            love.graphics.setColor(0.3, 1, 0.3)
            love.graphics.printf("Value Buff:", panelX + 50, multiplierY, 300, "left")
            love.graphics.printf("x" .. string.format("%.2f", valueMultiplier), panelX + 350, multiplierY, 200, "right")
            multiplierY = multiplierY + 20
        end

        -- Draw upgrade multiplier if active
        if goldMultiplier > 1.0 then
            love.graphics.setColor(1, 0.8, 0.3)
            love.graphics.printf("Cashout Upgrade:", panelX + 50, multiplierY, 300, "left")
            love.graphics.printf("x" .. string.format("%.2f", goldMultiplier), panelX + 350, multiplierY, 200, "right")
            multiplierY = multiplierY + 20
        end

        -- Draw emergency beacon penalty if active
        if emergencyPenalty < 1.0 then
            love.graphics.setColor(1, 0.4, 0.4)
            love.graphics.printf("Emergency Beacon:", panelX + 50, multiplierY, 300, "left")
            love.graphics
                .printf("x" .. string.format("%.2f", emergencyPenalty), panelX + 350, multiplierY, 200, "right")
            multiplierY = multiplierY + 20
        end

        -- Draw another separator
        love.graphics.setColor(0.5, 0.5, 0.7)
        love.graphics.line(panelX + 50, multiplierY + 5, panelX + panelWidth - 50, multiplierY + 5)
        multiplierY = multiplierY + 25
    end

    -- Draw total value
    love.graphics.setFont(GameFonts.large)
    love.graphics.setColor(1, 0.8, 0)
    love.graphics.printf("TOTAL EARNED:", panelX + 50, multiplierY, 300, "left")
    love.graphics.printf(tostring(totalValue) .. " Gold", panelX + 350, multiplierY, 200, "right")

    -- Draw continue prompt (at bottom of screen, outside panel)
    love.graphics.setFont(GameFonts.normal)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("Press SPACE or ENTER to continue", 0, love.graphics.getHeight() - 40,
        love.graphics.getWidth(), "center")
end

-- Handle keyboard input
function CashoutScreen.keypressed(key)
    if key == "space" or key == "return" then
        SFX.playButtonClick()
        -- Always return to map selection where player can refuel if needed
        changeState(gameStates.MAP_SELECTION)
    end
end

-- Handle mouse input
function CashoutScreen.mousepressed(x, y, button)
    if button == 1 then
        SFX.playButtonClick()
        -- Click anywhere to continue
        changeState(gameStates.MAP_SELECTION)
    end
end

return CashoutScreen
