-- Upgrade Screen
-- Displays available upgrades and allows purchasing permanent stat boosts
local UpgradeScreen = {}

local Upgrades = require("src/upgrades")
local Save = require("src/save")
local SFX = require("src/sfx")

-- Screen state
local player
local gameStates
local changeState
local selectedUpgradeId
local upgradeList -- Ordered list of upgrade IDs for navigation
local selectedIndex
local scrollOffset
local maxVisibleUpgrades
local categoryColors
local cardNormalImage
local cardHoverImage
local detailPanelImage
local previousHoveredIndex

-- Initialize upgrade screen
function UpgradeScreen.load(playerData, states, stateChanger)
    player = playerData
    gameStates = states
    changeState = stateChanger
    selectedIndex = 1
    scrollOffset = 0
    maxVisibleUpgrades = 6

    -- Load card sprite images
    cardNormalImage = love.graphics.newImage("sprites/buttons/Btn_380x80.png")
    cardNormalImage:setFilter("nearest", "nearest")
    cardHoverImage = love.graphics.newImage("sprites/buttons/Btn-Hover_380x80.png")
    cardHoverImage:setFilter("nearest", "nearest")

    -- Load detail panel image
    detailPanelImage = love.graphics.newImage("sprites/prompts/UpgradePanel_486x530.png")
    detailPanelImage:setFilter("nearest", "nearest")

    -- Build ordered upgrade list (12 total upgrades)
    upgradeList = {"engine_boost", "thruster_efficiency", "magnetic_field", "collection_speed", "decay_resistance",
                   "auto_collect", "cargo_expansion", "cashout_multiplier", "extended_mission", "fuel_efficiency",
                   "fuel_tank_expansion", "asteroid_density"}

    selectedUpgradeId = upgradeList[selectedIndex]

    -- Category colors for visual organization
    categoryColors = {
        movement = {0.3, 0.7, 1.0}, -- Blue
        collection = {0.3, 1.0, 0.5}, -- Green
        cargo = {1.0, 0.8, 0.3}, -- Orange
        economy = {1.0, 0.8, 0.0}, -- Gold
        time = {0.8, 0.3, 1.0}, -- Purple
        efficiency = {0.5, 0.9, 0.9}, -- Cyan
        spawning = {1.0, 0.5, 0.5} -- Red
    }

    -- Apply all upgrade effects to player stats
    Upgrades.applyUpgradeEffects(player)
end

-- Handle navigation
local function navigateUp()
    if selectedIndex > 1 then
        SFX.playButtonHover()
        selectedIndex = selectedIndex - 1
        selectedUpgradeId = upgradeList[selectedIndex]

        -- Adjust scroll if needed
        if selectedIndex < scrollOffset + 1 then
            scrollOffset = selectedIndex - 1
        end
    end
end

local function navigateDown()
    if selectedIndex < #upgradeList then
        SFX.playButtonHover()
        selectedIndex = selectedIndex + 1
        selectedUpgradeId = upgradeList[selectedIndex]

        -- Adjust scroll if needed
        if selectedIndex > scrollOffset + maxVisibleUpgrades then
            scrollOffset = selectedIndex - maxVisibleUpgrades
        end
    end
end

-- Attempt to purchase selected upgrade
local function purchaseUpgrade()
    SFX.playButtonClick()
    local success, message = Upgrades.purchase(player, selectedUpgradeId)

    if success then
        -- Play purchase sound (TODO)
        -- Save player progress
        Save.write(player)
    else
        -- Play error sound (TODO)
    end
end

-- Return to previous screen
local function exitUpgradeScreen()
    SFX.playButtonClick()
    changeState(gameStates.MAP_SELECTION)
end

-- Update upgrade screen
function UpgradeScreen.update(dt)
    -- Check for hover changes on upgrade cards
    local mouseX, mouseY = love.mouse.getPosition()
    local hoveredIndex = nil

    local listPanelX = 50
    local listPanelY = 130
    local listPanelWidth = 400
    local itemHeight = 90
    local itemPadding = 10

    local startIndex = scrollOffset + 1
    local endIndex = math.min(scrollOffset + maxVisibleUpgrades, #upgradeList)

    for i = startIndex, endIndex do
        local itemY = listPanelY + ((i - scrollOffset - 1) * itemHeight) + itemPadding
        local itemX = listPanelX + itemPadding
        local itemWidth = listPanelWidth - (itemPadding * 2)
        local itemButtonHeight = 80

        if mouseX >= itemX and mouseX <= itemX + itemWidth and mouseY >= itemY and mouseY <= itemY + itemButtonHeight then
            hoveredIndex = i
            break
        end
    end

    -- Play hover sound when hovering over a new item
    if hoveredIndex ~= previousHoveredIndex and hoveredIndex ~= nil then
        SFX.playButtonHover()
    end
    previousHoveredIndex = hoveredIndex
end

-- Draw upgrade screen
function UpgradeScreen.draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Draw background
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(GameFonts.title)
    love.graphics.printf("UPGRADE STATION", 0, 30, screenWidth, "center")

    -- Draw player currency
    love.graphics.setFont(GameFonts.large)
    love.graphics.setColor(1, 0.9, 0.3)
    love.graphics.printf("Gold: " .. player.currency.gold, 0, 80, screenWidth, "center")

    -- Layout dimensions
    local listPanelX = 50
    local listPanelY = 130
    local listPanelWidth = 400
    local listPanelHeight = screenHeight - 200

    local scrollbarWidth = 8
    local scrollbarSpacing = 10
    local itemHeight = 90
    local itemPadding = 10

    local detailPanelX = listPanelX + listPanelWidth + scrollbarSpacing + scrollbarWidth + 20
    local detailPanelY = listPanelY + itemPadding
    local detailPanelWidth = screenWidth - detailPanelX - 50
    local detailPanelHeight = (maxVisibleUpgrades * itemHeight) - itemPadding

    -- Draw upgrade list items
    local startIndex = scrollOffset + 1
    local endIndex = math.min(scrollOffset + maxVisibleUpgrades, #upgradeList)

    for i = startIndex, endIndex do
        local upgradeId = upgradeList[i]
        local upgrade = Upgrades.catalog[upgradeId]
        local currentLevel = Upgrades.getPlayerUpgradeLevel(player, upgradeId)
        local cost = Upgrades.getCost(upgradeId, currentLevel)
        local canAfford = Upgrades.canAfford(player, upgradeId)
        local isMaxLevel = currentLevel >= upgrade.maxLevel

        local itemY = listPanelY + ((i - scrollOffset - 1) * itemHeight) + itemPadding
        local itemX = listPanelX + itemPadding
        local itemWidth = listPanelWidth - (itemPadding * 2)

        -- Draw card background sprite
        local cardImage = (i == selectedIndex) and cardHoverImage or cardNormalImage
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(cardImage, itemX, itemY)

        -- Draw upgrade name
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(GameFonts.medium)
        love.graphics.print(upgrade.name, itemX + 15, itemY + 12)

        -- Draw level indicator
        love.graphics.setFont(GameFonts.normal)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("Level: " .. currentLevel .. "/" .. upgrade.maxLevel, itemX + 15, itemY + 36)

        -- Draw cost or max level indicator
        if isMaxLevel then
            love.graphics.setColor(0.3, 1, 0.3)
            love.graphics.print("MAX", itemX + 15, itemY + 56)
        else
            if canAfford then
                love.graphics.setColor(1, 0.9, 0.3)
            else
                love.graphics.setColor(0.8, 0.3, 0.3)
            end
            love.graphics.print("Cost: " .. cost .. " gold", itemX + 15, itemY + 56)
        end
    end

    -- Draw scrollbar if needed
    if #upgradeList > maxVisibleUpgrades then
        local listHeight = (maxVisibleUpgrades * itemHeight)

        local scrollbarX = listPanelX + listPanelWidth + 10
        local scrollbarY = listPanelY + itemPadding
        local scrollbarWidth = 8
        local scrollbarHeight = listHeight - itemPadding

        -- Scrollbar background
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 4, 4)

        -- Scrollbar thumb
        local thumbHeight = (maxVisibleUpgrades / #upgradeList) * scrollbarHeight
        local thumbY = scrollbarY + (scrollOffset / (#upgradeList - maxVisibleUpgrades)) *
                           (scrollbarHeight - thumbHeight)

        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.rectangle("fill", scrollbarX, thumbY, scrollbarWidth, thumbHeight, 4, 4)
    end

    -- Draw detail panel
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(detailPanelImage, detailPanelX, detailPanelY)

    -- Draw selected upgrade details
    if selectedUpgradeId then
        local upgrade = Upgrades.catalog[selectedUpgradeId]
        local currentLevel = Upgrades.getPlayerUpgradeLevel(player, selectedUpgradeId)
        local cost = Upgrades.getCost(selectedUpgradeId, currentLevel)
        local isMaxLevel = currentLevel >= upgrade.maxLevel
        local categoryColor = categoryColors[upgrade.category] or {0.5, 0.5, 0.5}

        local detailX = detailPanelX + 20
        local detailY = detailPanelY + 20

        -- Draw upgrade name
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(GameFonts.large)
        love.graphics.print(upgrade.name, detailX, detailY)

        -- Draw category
        love.graphics.setColor(categoryColor[1], categoryColor[2], categoryColor[3])
        love.graphics.setFont(GameFonts.normal)
        love.graphics.print(upgrade.category:upper(), detailX, detailY + 30)

        -- Draw description
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.setFont(GameFonts.medium)
        love.graphics.printf(upgrade.description, detailX, detailY + 60, detailPanelWidth - 40, "left")

        -- Draw current level and max level
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(GameFonts.medium)
        love.graphics.print("Current Level: " .. currentLevel .. " / " .. upgrade.maxLevel, detailX, detailY + 110)

        -- Draw current effect
        if currentLevel > 0 then
            local effectValue = Upgrades.getEffectValue(selectedUpgradeId, currentLevel)
            love.graphics.setColor(0.3, 1, 0.3)
            love.graphics.setFont(GameFonts.medium)

            local effectText
            if upgrade.effect.type == "percentage" then
                effectText = "Current Bonus: +" .. effectValue .. "%"
            elseif upgrade.effect.type == "threshold" then
                effectText = "Current Threshold: " .. effectValue .. "%"
            else
                effectText = "Current Bonus: +" .. effectValue
            end
            love.graphics.print(effectText, detailX, detailY + 140)
        end

        -- Draw next level preview
        if not isMaxLevel then
            local nextLevel = currentLevel + 1
            local nextEffectValue = Upgrades.getEffectValue(selectedUpgradeId, nextLevel)
            love.graphics.setColor(0.7, 0.7, 1)
            love.graphics.setFont(GameFonts.medium)

            local nextEffectText
            if upgrade.effect.type == "percentage" then
                nextEffectText = "Next Level: +" .. nextEffectValue .. "%"
            elseif upgrade.effect.type == "threshold" then
                nextEffectText = "Next Level: " .. nextEffectValue .. "%"
            else
                nextEffectText = "Next Level: +" .. nextEffectValue
            end
            love.graphics.print(nextEffectText, detailX, detailY + 170)

            -- Draw cost
            love.graphics.setColor(1, 0.9, 0.3)
            love.graphics.setFont(GameFonts.large)
            love.graphics.print("Cost: " .. cost .. " gold", detailX, detailY + 210)
        else
            love.graphics.setColor(0.3, 1, 0.3)
            love.graphics.setFont(GameFonts.large)
            love.graphics.print("MAX LEVEL REACHED", detailX, detailY + 170)
        end
    end

    -- Draw controls help
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(GameFonts.normal)
    love.graphics.printf("[W/S or UP/DOWN] Navigate  [ENTER/SPACE or CLICK] Purchase  [ESC] Exit", 0,
        love.graphics.getHeight() - 40, love.graphics.getWidth(), "center")

    -- Reset line width
    love.graphics.setLineWidth(1)
end

-- Handle keyboard input
function UpgradeScreen.keypressed(key)
    if key == "w" or key == "up" then
        navigateUp()
    elseif key == "s" or key == "down" then
        navigateDown()
    elseif key == "space" or key == "return" then
        purchaseUpgrade()
    elseif key == "escape" then
        exitUpgradeScreen()
    end
end

-- Handle mouse input
function UpgradeScreen.mousepressed(x, y, button)
    if button == 1 then
        -- Check if clicking on upgrade list items
        local listPanelX = 50
        local listPanelY = 130
        local listPanelWidth = 400
        local itemHeight = 70
        local itemPadding = 10

        local startIndex = scrollOffset + 1
        local endIndex = math.min(scrollOffset + maxVisibleUpgrades, #upgradeList)

        for i = startIndex, endIndex do
            local itemY = listPanelY + ((i - scrollOffset - 1) * itemHeight) + itemPadding
            local itemX = listPanelX + itemPadding
            local itemWidth = listPanelWidth - (itemPadding * 2)

            if x >= itemX and x <= itemX + itemWidth and y >= itemY and y <= itemY + itemHeight - itemPadding then
                SFX.playButtonClick()
                selectedIndex = i
                selectedUpgradeId = upgradeList[selectedIndex]
                return
            end
        end
    end
end

-- Handle mouse wheel scrolling
function UpgradeScreen.wheelmoved(x, y)
    local maxScroll = math.max(0, #upgradeList - maxVisibleUpgrades)
    scrollOffset = math.max(0, math.min(maxScroll, scrollOffset - y))
end

return UpgradeScreen
