-- Map Selection Screen
-- Displays available sectors and allows player to select one
local MapScreen = {}

local Player = require("src/player")
local Sector = require("src/sector")
local Save = require("src/save")
local Upgrades = require("src/upgrades")
local SFX = require("src/sfx")

-- Map screen state
local player
local gameStates
local changeState
local sectorButtons
local hoveredButton
local previousHoveredButton
local upgradeButton
local refuelButton
local scrollOffset
local maxVisibleSectors
local selectedIndex
local sectorButtonNormalImage
local sectorButtonHoverImage
local refuelButtonNormalImage
local refuelButtonHoverImage
local upgradeButtonNormalImage
local upgradeButtonHoverImage
local lastSelectedIndex -- Store the last selected sector index
local detailPanelImage

-- Initialize map screen
function MapScreen.load(playerData, states, stateChanger)
    player = playerData
    gameStates = states
    changeState = stateChanger

    -- Ensure upgrade effects are applied to player stats
    Upgrades.applyUpgradeEffects(player)

    -- Load sector button images
    sectorButtonNormalImage = love.graphics.newImage("sprites/buttons/Btn_380x80.png")
    sectorButtonNormalImage:setFilter("nearest", "nearest")
    sectorButtonHoverImage = love.graphics.newImage("sprites/buttons/Btn-Hover_380x80.png")
    sectorButtonHoverImage:setFilter("nearest", "nearest")

    -- Load refuel button images
    refuelButtonNormalImage = love.graphics.newImage("sprites/buttons/Btn_200x50.png")
    refuelButtonNormalImage:setFilter("nearest", "nearest")
    refuelButtonHoverImage = love.graphics.newImage("sprites/buttons/Btn-Hover_200x50.png")
    refuelButtonHoverImage:setFilter("nearest", "nearest")

    -- Load upgrade button images
    upgradeButtonNormalImage = love.graphics.newImage("sprites/buttons/Btn_200x50.png")
    upgradeButtonNormalImage:setFilter("nearest", "nearest")
    upgradeButtonHoverImage = love.graphics.newImage("sprites/buttons/Btn-Hover_200x50.png")
    upgradeButtonHoverImage:setFilter("nearest", "nearest")

    -- Load detail panel image
    detailPanelImage = love.graphics.newImage("sprites/prompts/UpgradePanel_486x530.png")
    detailPanelImage:setFilter("nearest", "nearest")

    hoveredButton = nil
    scrollOffset = 0
    maxVisibleSectors = 6 -- Show 6 sectors at a time
    selectedIndex = lastSelectedIndex or 1 -- Restore last selected index or start with first sector

    -- Create upgrade button
    upgradeButton = {
        x = 20,
        y = 20,
        width = 200,
        height = 50,
        text = "UPGRADES"
    }

    -- Create refuel button (positioned in right corner, opposite of upgrade button)
    refuelButton = {
        x = love.graphics.getWidth() - 220,
        y = 20,
        width = 200,
        height = 50,
        text = "REFUEL"
    }

    -- Create sector buttons
    sectorButtons = {}
    local buttonWidth = 380
    local buttonHeight = 80

    -- Create buttons for each sector
    for i = 1, 10 do
        local sectorId = "sector_" .. string.format("%02d", i)
        local sector = Sector.definitions[sectorId]

        if sector then
            local isUnlocked = Player.isMapUnlocked(player, sectorId)

            table.insert(sectorButtons, {
                sectorId = sectorId,
                sector = sector,
                isUnlocked = isUnlocked,
                canAfford = Player.canAfford(player, sector.unlock_cost, 0)
            })
        end
    end

    -- Adjust scroll offset to keep selected sector visible
    if selectedIndex > maxVisibleSectors then
        scrollOffset = math.min(selectedIndex - maxVisibleSectors, #sectorButtons - maxVisibleSectors)
    end
end

-- Update map screen
function MapScreen.update(dt)
    -- Update hovered button
    local mouseX, mouseY = love.mouse.getPosition()
    hoveredButton = nil

    -- Check upgrade button hover
    if mouseX >= upgradeButton.x and mouseX <= upgradeButton.x + upgradeButton.width and mouseY >= upgradeButton.y and
        mouseY <= upgradeButton.y + upgradeButton.height then
        hoveredButton = upgradeButton
        if previousHoveredButton ~= hoveredButton then
            SFX.playButtonHover()
        end
        previousHoveredButton = hoveredButton
        return
    end

    -- Check refuel button hover
    if mouseX >= refuelButton.x and mouseX <= refuelButton.x + refuelButton.width and mouseY >= refuelButton.y and
        mouseY <= refuelButton.y + refuelButton.height then
        hoveredButton = refuelButton
        if previousHoveredButton ~= hoveredButton then
            SFX.playButtonHover()
        end
        previousHoveredButton = hoveredButton
        return
    end

    -- Check sector card hover
    local listPanelX = 50
    local listPanelY = 130
    local itemHeight = 90
    local itemPadding = 10
    local listPanelWidth = 400

    local startIndex = scrollOffset + 1
    local endIndex = math.min(scrollOffset + maxVisibleSectors, #sectorButtons)

    for i = startIndex, endIndex do
        local itemY = listPanelY + ((i - scrollOffset - 1) * itemHeight) + itemPadding
        local itemX = listPanelX + itemPadding
        local itemWidth = listPanelWidth - (itemPadding * 2)
        local itemButtonHeight = 80

        if mouseX >= itemX and mouseX <= itemX + itemWidth and mouseY >= itemY and mouseY <= itemY + itemButtonHeight then
            hoveredButton = i
            if previousHoveredButton ~= hoveredButton then
                SFX.playButtonHover()
            end
            previousHoveredButton = hoveredButton
            break
        end
    end

    -- Update previousHoveredButton if nothing is hovered
    if hoveredButton == nil then
        previousHoveredButton = nil
    end
end

-- Draw map screen
function MapScreen.draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Draw background
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(GameFonts.title)
    love.graphics.printf("SELECT SECTOR", 0, 30, screenWidth, "center")

    -- Draw upgrade button
    local isUpgradeHovered = (hoveredButton == upgradeButton)
    local upgradeButtonImage = isUpgradeHovered and upgradeButtonHoverImage or upgradeButtonNormalImage
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(upgradeButtonImage, upgradeButton.x, upgradeButton.y)
    love.graphics.setFont(GameFonts.normal)
    love.graphics.printf(upgradeButton.text, upgradeButton.x, upgradeButton.y + 15, upgradeButton.width, "center")

    -- Draw refuel button
    local isRefuelHovered = (hoveredButton == refuelButton)
    local needsEmergency = Player.needsEmergencyBeacon(player)
    local cost, fuelGained = Player.calculateRefuelCost(player)

    -- Determine button state and text
    local buttonText, textColor
    if needsEmergency then
        buttonText = "EMERGENCY BEACON"
        textColor = {1, 1, 1}
    elseif fuelGained == 0 then
        buttonText = "REFUEL (FULL)"
        textColor = {0.6, 0.6, 0.6}
    elseif player.currency.gold == 0 then
        buttonText = "Refuel (+" .. fuelGained .. "): " .. cost .. "g"
        textColor = {0.6, 0.6, 0.6}
    else
        buttonText = "Refuel (+" .. fuelGained .. "): " .. cost .. "g"
        textColor = {1, 1, 1}
    end

    local refuelButtonImage = isRefuelHovered and refuelButtonHoverImage or refuelButtonNormalImage
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(refuelButtonImage, refuelButton.x, refuelButton.y)
    love.graphics.setColor(textColor)
    love.graphics.setFont(GameFonts.normal)
    local font = love.graphics.getFont()
    local _, wrappedText = font:getWrap(buttonText, refuelButton.width)
    local textHeight = #wrappedText * font:getHeight()
    local textY = refuelButton.y + (refuelButton.height - textHeight) / 2
    love.graphics.printf(buttonText, refuelButton.x, textY, refuelButton.width, "center")

    -- Draw currency displays
    love.graphics.setFont(GameFonts.large)
    love.graphics.setColor(1, 0.9, 0.3)
    love.graphics.printf("Gold: " .. player.currency.gold, 0, 80, screenWidth, "center")
    love.graphics.setColor(0.3, 0.8, 1)
    local maxFuel = Player.getMaxFuel(player)
    love.graphics.printf("Fuel: " .. player.currency.fuel .. " / " .. maxFuel, 0, 110, screenWidth, "center")

    -- Layout dimensions (matching upgrade screen)
    local listPanelX = 50
    local listPanelY = 132
    local listPanelWidth = 400
    local scrollbarWidth = 8
    local scrollbarSpacing = 10
    local itemHeight = 90
    local itemPadding = 10

    local detailPanelX = listPanelX + listPanelWidth + scrollbarSpacing + scrollbarWidth + 20
    local detailPanelY = listPanelY + itemPadding
    local detailPanelWidth = screenWidth - detailPanelX - 50
    local detailPanelHeight = (maxVisibleSectors * itemHeight) - itemPadding

    -- Draw sector list items
    local startIndex = scrollOffset + 1
    local endIndex = math.min(scrollOffset + maxVisibleSectors, #sectorButtons)

    for i = startIndex, endIndex do
        local button = sectorButtons[i]
        local isHovered = (hoveredButton == i) or (selectedIndex == i)

        local itemY = listPanelY + ((i - scrollOffset - 1) * itemHeight) + itemPadding
        local itemX = listPanelX + itemPadding
        local itemWidth = listPanelWidth - (itemPadding * 2)

        -- Draw card background sprite
        local cardImage = isHovered and sectorButtonHoverImage or sectorButtonNormalImage
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(cardImage, itemX, itemY)

        -- Determine text color based on state
        local textColor
        if button.isUnlocked then
            textColor = {1, 1, 1}
        else
            if button.canAfford then
                textColor = {1, 1, 0.7}
            else
                textColor = {0.5, 0.5, 0.5}
            end
        end

        -- Draw sector name
        love.graphics.setFont(GameFonts.large)
        love.graphics.setColor(textColor)
        love.graphics.print(button.sector.name, itemX + 15, itemY + 30)
    end

    -- Draw scrollbar if needed
    if #sectorButtons > maxVisibleSectors then
        local listHeight = (maxVisibleSectors * itemHeight)

        local scrollbarX = listPanelX + listPanelWidth + 10
        local scrollbarY = listPanelY + itemPadding
        local scrollbarHeight = listHeight - itemPadding

        -- Scrollbar background
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 4, 4)

        -- Scrollbar thumb
        local thumbHeight = (maxVisibleSectors / #sectorButtons) * scrollbarHeight
        local thumbY = scrollbarY + (scrollOffset / (#sectorButtons - maxVisibleSectors)) *
                           (scrollbarHeight - thumbHeight)

        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.rectangle("fill", scrollbarX, thumbY, scrollbarWidth, thumbHeight, 4, 4)
    end

    -- Draw detail panel
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(detailPanelImage, detailPanelX, detailPanelY)

    -- Draw selected sector details
    if selectedIndex and sectorButtons[selectedIndex] then
        local button = sectorButtons[selectedIndex]
        local sector = button.sector

        local detailX = detailPanelX + 20
        local detailY = detailPanelY + 20

        -- Draw sector name
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(GameFonts.large)
        love.graphics.print(sector.name, detailX, detailY)

        -- Draw status (locked/unlocked)
        if button.isUnlocked then
            love.graphics.setColor(0.3, 1, 0.3)
            love.graphics.setFont(GameFonts.normal)
            love.graphics.print("UNLOCKED", detailX, detailY + 30)
        else
            love.graphics.setColor(1, 0.8, 0.3)
            love.graphics.setFont(GameFonts.normal)
            love.graphics.print("LOCKED", detailX, detailY + 30)
        end

        -- Draw description placeholder
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.setFont(GameFonts.small)
        local description = sector.description or "A sector rich with asteroids awaiting discovery."
        love.graphics.printf(description, detailX, detailY + 60, detailPanelWidth - 40, "left")

        -- Draw obstacle info
        love.graphics.setColor(1, 0.6, 0.3)
        love.graphics.setFont(GameFonts.normal)
        love.graphics.print("Hazard:", detailX, detailY + 130)
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.setFont(GameFonts.small)
        local obstacle = sector.obstacle or "Unknown hazards"
        love.graphics.printf(obstacle, detailX, detailY + 148, detailPanelWidth - 40, "left")

        -- Draw asteroid info
        love.graphics.setColor(0.7, 0.7, 1)
        love.graphics.setFont(GameFonts.normal)
        love.graphics.print("Asteroids:", detailX, detailY + 220)

        -- Display actual asteroid types from sector
        local Asteroid = require("src/asteroid")
        local yOffset = 243
        for i, asteroidTypeId in ipairs(sector.asteroidTypes) do
            -- Find the asteroid type definition
            local asteroidData = nil
            for _, aType in ipairs(Asteroid.types) do
                if aType.id == asteroidTypeId then
                    asteroidData = aType
                    break
                end
            end

            if asteroidData then
                -- Generate vertices for asteroid icon (small polygon)
                local numVertices = 7
                local vertices = {}
                local iconRadius = 6
                local iconX = detailX + 20
                local iconY = detailY + yOffset + 8

                for v = 1, numVertices do
                    local angleStep = (2 * math.pi) / numVertices
                    local angle = (v - 1) * angleStep
                    local radiusVariation = iconRadius * (0.7 + 0.3) -- Slight variation
                    table.insert(vertices, iconX + math.cos(angle) * radiusVariation)
                    table.insert(vertices, iconY + math.sin(angle) * radiusVariation)
                end

                -- Draw asteroid icon
                love.graphics.setColor(asteroidData.color)
                love.graphics.polygon("fill", vertices)
                love.graphics.setColor(1, 1, 1, 0.3)
                love.graphics.polygon("line", vertices)

                -- Draw asteroid name and value
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.setFont(GameFonts.small)
                local displayName = asteroidTypeId:gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest)
                    return first:upper() .. rest:lower()
                end)
                love.graphics.print(displayName .. " (" .. asteroidData.value .. "g)", iconX + 15, detailY + yOffset)
                yOffset = yOffset + 22
            end
        end

        -- Draw cost/fuel info
        if button.isUnlocked then
            -- Calculate actual fuel cost with efficiency
            local fuelEfficiency = (player.stats.fuelEfficiency or 0) / 100
            local actualFuelCost = math.ceil(sector.fuel_cost * (1 - fuelEfficiency))

            love.graphics.setColor(0.3, 0.8, 1)
            love.graphics.setFont(GameFonts.large)
            love.graphics.print("Fuel Cost: " .. actualFuelCost, detailX, detailY + 330)

            if fuelEfficiency > 0 then
                love.graphics.setFont(GameFonts.small)
                love.graphics.setColor(0.6, 0.6, 0.6)
                love.graphics.print("(Base: " .. sector.fuel_cost .. " -" .. math.floor(fuelEfficiency * 100) .. "%)",
                    detailX, detailY + 355)
            end

            -- Show if can afford
            if player.currency.fuel >= actualFuelCost then
                love.graphics.setColor(0.3, 1, 0.3)
                love.graphics.setFont(GameFonts.medium)
                love.graphics.print("Ready to explore!", detailX, detailY + 385)
            else
                love.graphics.setColor(1, 0.3, 0.3)
                love.graphics.setFont(GameFonts.medium)
                love.graphics.print("Not enough fuel", detailX, detailY + 385)
            end
        else
            -- Show unlock cost
            love.graphics.setColor(1, 0.9, 0.3)
            love.graphics.setFont(GameFonts.large)
            love.graphics.print("Unlock Cost: " .. sector.unlock_cost .. " gold", detailX, detailY + 330)

            -- Show if can afford
            if button.canAfford then
                love.graphics.setColor(0.3, 1, 0.3)
                love.graphics.setFont(GameFonts.medium)
                love.graphics.print("Can unlock!", detailX, detailY + 360)
            else
                love.graphics.setColor(1, 0.3, 0.3)
                love.graphics.setFont(GameFonts.medium)
                love.graphics.print("Not enough gold", detailX, detailY + 360)
            end
        end
    end

    -- Draw instructions
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(GameFonts.normal)
    love.graphics.printf("[W/S or UP/DOWN] Navigate  [ENTER/SPACE] Select  [U] Upgrades  [R] Refuel  [ESC] Menu", 0,
        screenHeight - 40, screenWidth, "center")
end

-- Handle keyboard input
function MapScreen.keypressed(key)
    if key == "escape" then
        SFX.playButtonClick()
        changeState(gameStates.MENU)
    elseif key == "u" then
        SFX.playButtonClick()
        changeState(gameStates.SKILL_TREE)
    elseif key == "r" then
        SFX.playButtonClick()
        -- Handle refuel or emergency beacon
        if Player.needsEmergencyBeacon(player) then
            local success, message = Player.useEmergencyBeacon(player)
            if success then
                -- Save player progress
                Save.write(player)
            end
        else
            local success, message = Player.refuel(player)
            if success then
                -- Save player progress
                Save.write(player)
                -- Navigate to buff selection after refueling
                changeState(gameStates.ROUND_START_BUFF_SELECTION)
            end
        end
    elseif key == "w" or key == "up" then
        -- Navigate up
        if selectedIndex > 1 then
            SFX.playButtonHover()
            selectedIndex = selectedIndex - 1
            -- Auto-scroll to keep selected button visible
            if selectedIndex < scrollOffset + 1 then
                scrollOffset = selectedIndex - 1
            end
        end
    elseif key == "s" or key == "down" then
        -- Navigate down
        if selectedIndex < #sectorButtons then
            SFX.playButtonHover()
            selectedIndex = selectedIndex + 1
            -- Auto-scroll to keep selected button visible
            if selectedIndex > scrollOffset + maxVisibleSectors then
                scrollOffset = selectedIndex - maxVisibleSectors
            end
        end
    elseif key == "return" or key == "space" then
        SFX.playButtonClick()
        -- Select the currently highlighted sector
        local btn = sectorButtons[selectedIndex]

        if btn.isUnlocked then
            -- Calculate actual fuel cost with efficiency upgrade
            local fuelEfficiency = (player.stats.fuelEfficiency or 0) / 100
            local actualFuelCost = math.ceil(btn.sector.fuel_cost * (1 - fuelEfficiency))

            -- Check if player has enough fuel
            if player.currency.fuel >= actualFuelCost then
                -- Store the selected index before leaving
                lastSelectedIndex = selectedIndex
                -- Deduct fuel and start mining
                Player.purchase(player, 0, actualFuelCost)
                changeState(gameStates.MINING, btn.sectorId, actualFuelCost)
            else
                -- Not enough fuel (could show error message)
            end
        else
            -- Try to unlock sector
            if Player.canAfford(player, btn.sector.unlock_cost, 0) then
                Player.purchase(player, btn.sector.unlock_cost, 0)
                Player.unlockMap(player, btn.sectorId)
                -- Refresh button state
                btn.isUnlocked = true
                btn.canAfford = Player.canAfford(player, btn.sector.unlock_cost, 0)

                -- Save player progress
                Save.write(player)
            else
                -- Cannot afford (could show error message)
            end
        end
    end
end

-- Handle mouse input
function MapScreen.mousepressed(x, y, button)
    if button == 1 then
        -- Check if upgrade button was clicked
        if x >= upgradeButton.x and x <= upgradeButton.x + upgradeButton.width and y >= upgradeButton.y and y <=
            upgradeButton.y + upgradeButton.height then
            SFX.playButtonClick()
            changeState(gameStates.SKILL_TREE)
            return
        end

        -- Check if refuel button was clicked
        if x >= refuelButton.x and x <= refuelButton.x + refuelButton.width and y >= refuelButton.y and y <=
            refuelButton.y + refuelButton.height then
            SFX.playButtonClick()
            if Player.needsEmergencyBeacon(player) then
                local success, message = Player.useEmergencyBeacon(player)
                if success then
                    print(message)
                    -- Save player progress
                    local saveSuccess, saveError = Save.write(player)
                    if not saveSuccess then
                        print("Failed to save player data:", saveError)
                    end
                end
            else
                local success, message = Player.refuel(player)
                if success then
                    print(message)
                    -- Save player progress
                    local saveSuccess, saveError = Save.write(player)
                    if not saveSuccess then
                        print("Failed to save player data:", saveError)
                    end
                    -- Navigate to buff selection after refueling
                    changeState(gameStates.ROUND_START_BUFF_SELECTION)
                else
                    print(message)
                end
            end
            return
        end

        -- Check sector buttons (using card-based layout)
        if hoveredButton and type(hoveredButton) == "number" then
            SFX.playButtonClick()
            local buttonIndex = hoveredButton
            local btn = sectorButtons[buttonIndex]

            if btn.isUnlocked then
                -- Calculate actual fuel cost with efficiency upgrade
                local fuelEfficiency = (player.stats.fuelEfficiency or 0) / 100
                local actualFuelCost = math.ceil(btn.sector.fuel_cost * (1 - fuelEfficiency))

                -- Check if player has enough fuel
                if player.currency.fuel >= actualFuelCost then
                    -- Store the selected index before leaving
                    lastSelectedIndex = buttonIndex
                    -- Deduct fuel and start mining
                    Player.purchase(player, 0, actualFuelCost)
                    changeState(gameStates.MINING, btn.sectorId, actualFuelCost)
                else
                    -- Not enough fuel (could show error message)
                end
            else
                -- Try to unlock sector
                if Player.canAfford(player, btn.sector.unlock_cost, 0) then
                    Player.purchase(player, btn.sector.unlock_cost, 0)
                    Player.unlockMap(player, btn.sectorId)
                    -- Refresh button state
                    btn.isUnlocked = true
                    btn.canAfford = Player.canAfford(player, btn.sector.unlock_cost, 0)

                    -- Save player progress
                    Save.write(player)
                else
                    -- Cannot afford (could show error message)
                end
            end
        end
    end
end

-- Handle mouse wheel scrolling
function MapScreen.wheelmoved(x, y)
    local maxScroll = math.max(0, #sectorButtons - maxVisibleSectors)
    scrollOffset = math.max(0, math.min(maxScroll, scrollOffset - y))
end

return MapScreen
