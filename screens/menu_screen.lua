-- Menu Screen
-- Handles main menu display and interaction
local MenuScreen = {}

local Save = require("src.save")
local Upgrades = require("src.upgrades")
local Version = require("version")
local SFX = require("src/sfx")

-- Menu state
local menu = {}
local backgroundImage
local buttonNormalImage
local buttonHoverImage
local dialogButtonNormalImage
local dialogButtonHoverImage
local versionBadgeNormalImage
local versionBadgeHoverImage
local confirmationPromptImage
local confirmationDialog = {
    visible = false,
    selectedButton = 1 -- 1 = Yes, 2 = No
}

-- Track previous hover state for sound effects
local previousHoveredButton = nil
local previousHoveredVersionBadge = false

-- Animated background elements
local farStars -- Background star layer
local nearStars -- Foreground star layer (slowly drifting)
local planetSprite
local planetPosition
local moonSprite
local moonPosition
local spaceshipSprite
local spaceshipPosition
local spaceshipVelocity
local starDriftTime = 0 -- Time accumulator for star drift

-- Version badge state
local versionBadge = {
    x = 0,
    y = 0,
    width = 150,
    height = 50,
    hovered = false
}

-- Helper function: Get menu button Y position
local function getButtonY(index, totalButtons)
    local totalHeight = (totalButtons * menu.buttonHeight) + ((totalButtons - 1) * menu.buttonSpacing)
    local startY = (love.graphics.getHeight() - totalHeight) / 2
    return startY + (index - 1) * (menu.buttonHeight + menu.buttonSpacing)
end

-- Helper function: Check if mouse is over a button
local function isMouseOverButton(buttonIndex)
    local mouseX, mouseY = love.mouse.getPosition()
    local buttonX = (love.graphics.getWidth() - menu.buttonWidth) / 2
    local buttonY = getButtonY(buttonIndex, #menu.buttons)

    return mouseX >= buttonX and mouseX <= buttonX + menu.buttonWidth and mouseY >= buttonY and mouseY <= buttonY +
               menu.buttonHeight
end

-- Helper function: Check if mouse is over version badge
local function isMouseOverVersionBadge()
    local mouseX, mouseY = love.mouse.getPosition()
    return mouseX >= versionBadge.x and mouseX <= versionBadge.x + versionBadge.width and mouseY >= versionBadge.y and
               mouseY <= versionBadge.y + versionBadge.height
end

-- Helper function: Draw a button with generic sprite and text overlay
local function drawButton(button, buttonX, buttonY, isHovered)
    -- Draw button sprite
    local buttonImage = isHovered and buttonHoverImage or buttonNormalImage
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(buttonImage, buttonX, buttonY)

    -- Draw button text on top
    love.graphics.setFont(GameFonts.large)
    local textColor = button.enabled and {1, 1, 1} or {0.5, 0.5, 0.5}
    love.graphics.setColor(textColor)
    love.graphics.printf(button.text, buttonX, buttonY + 30, menu.buttonWidth, "center")
end

-- Helper function: Rebuild button list based on current save state
local function rebuildButtonList()
    menu.buttons = {}

    -- Add Continue button only if save file exists
    if Save.exists() then
        table.insert(menu.buttons, {
            text = "Continue",
            action = "continue",
            enabled = true
        })
    end

    -- Add remaining buttons
    table.insert(menu.buttons, {
        text = "New Game",
        action = "new_game",
        enabled = true
    })
    table.insert(menu.buttons, {
        text = "Settings",
        action = "settings",
        enabled = true
    })
    table.insert(menu.buttons, {
        text = "Credits",
        action = "credits",
        enabled = true
    })
    table.insert(menu.buttons, {
        text = "Exit",
        action = "exit",
        enabled = true
    })

    -- Ensure selectedIndex is valid
    if menu.selectedIndex > #menu.buttons then
        menu.selectedIndex = 1
    end

    -- Start with first enabled button selected if current selection is invalid
    if not menu.buttons[menu.selectedIndex] or not menu.buttons[menu.selectedIndex].enabled then
        menu.selectedIndex = 1
        for i, button in ipairs(menu.buttons) do
            if button.enabled then
                menu.selectedIndex = i
                break
            end
        end
    end
end

-- Initialize menu
function MenuScreen.load(gameStates, changeState)
    -- Load generic button images
    buttonNormalImage = love.graphics.newImage("sprites/buttons/Btn_380x80.png")
    buttonNormalImage:setFilter("nearest", "nearest")
    buttonHoverImage = love.graphics.newImage("sprites/buttons/Btn-Hover_380x80.png")
    buttonHoverImage:setFilter("nearest", "nearest")

    -- Load dialog button images (for Yes/No buttons)
    dialogButtonNormalImage = love.graphics.newImage("sprites/buttons/Btn_150x50.png")
    dialogButtonNormalImage:setFilter("nearest", "nearest")
    dialogButtonHoverImage = love.graphics.newImage("sprites/buttons/Btn-Hover_150x50.png")
    dialogButtonHoverImage:setFilter("nearest", "nearest")

    -- Load version badge button images
    versionBadgeNormalImage = love.graphics.newImage("sprites/buttons/Btn_150x50.png")
    versionBadgeNormalImage:setFilter("nearest", "nearest")
    versionBadgeHoverImage = love.graphics.newImage("sprites/buttons/Btn-Hover_150x50.png")
    versionBadgeHoverImage:setFilter("nearest", "nearest")

    -- Load confirmation prompt image
    confirmationPromptImage = love.graphics.newImage("sprites/prompts/ConfirmationPrompt_650x320.png")
    confirmationPromptImage:setFilter("nearest", "nearest")

    -- Load planet and moon sprites
    planetSprite = love.graphics.newImage("sprites/planets/Planet-Green-Blue.png")
    planetSprite:setFilter("nearest", "nearest")
    moonSprite = love.graphics.newImage("sprites/planets/Moon.png")
    moonSprite:setFilter("nearest", "nearest")

    -- Load spaceship sprite
    spaceshipSprite = love.graphics.newImage("sprites/ships/Spaceship.png")
    spaceshipSprite:setFilter("nearest", "nearest")

    -- Position planet (left side of screen)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local baseAngle = (math.random() * 0.5 - 0.25) * math.pi -- Limit angle to keep it more centered left
    local baseDistance = 50 + math.random() * 50 -- Reduced distance for closer positioning
    planetPosition = {
        x = screenWidth * 0.15 + math.cos(baseAngle) * baseDistance,
        y = screenHeight * 0.4 + math.sin(baseAngle) * baseDistance,
        scale = 1.6 + math.random() * 0.8,
        rotation = math.random() * 2 * math.pi
    }

    -- Position moon near planet
    local moonAngle = math.random() * 2 * math.pi
    local moonOffset = 150 + math.random() * 100
    moonPosition = {
        x = planetPosition.x + math.cos(moonAngle) * moonOffset,
        y = planetPosition.y + math.sin(moonAngle) * moonOffset,
        scale = 0.8 + math.random() * 0.4,
        rotation = math.random() * 2 * math.pi
    }

    -- Initialize spaceship position and velocity
    spaceshipPosition = {
        x = screenWidth * 0.7,
        y = screenHeight * 0.3,
        rotation = 0
    }
    spaceshipVelocity = {
        x = 20, -- pixels per second
        y = 15
    }

    -- Generate parallax star field
    farStars = {}
    for i = 1, 150 do
        table.insert(farStars, {
            x = math.random() * screenWidth,
            y = math.random() * screenHeight,
            size = 0.5 + math.random() * 1,
            brightness = 0.3 + math.random() * 0.3
        })
    end

    -- Near layer: larger, brighter stars that drift
    nearStars = {}
    for i = 1, 80 do
        table.insert(nearStars, {
            x = math.random() * screenWidth,
            y = math.random() * screenHeight,
            size = 1.5 + math.random() * 1.5,
            brightness = 0.6 + math.random() * 0.4
        })
    end

    menu = {}
    menu.buttonHeight = 80
    menu.buttonWidth = 380
    menu.buttonSpacing = 15
    menu.gameStates = gameStates
    menu.changeState = changeState
    menu.selectedIndex = 1

    -- Build initial button list
    rebuildButtonList()
end

-- Handle menu button action
local function handleMenuAction(action)
    if not menu.changeState or not menu.gameStates then
        return
    end

    if action == "continue" then
        -- Load save file and continue
        local player, error = Save.read()
        if player then
            -- Recalculate all upgrade effects from skills
            Upgrades.applyUpgradeEffects(player)
            -- Successfully loaded, go to map selection with loaded player
            menu.changeState(menu.gameStates.MAP_SELECTION, player)
        else
            -- Failed to load save
            -- Could show error message to user here
        end
    elseif action == "new_game" then
        -- Check if save file exists
        if Save.exists() then
            -- Show confirmation dialog
            confirmationDialog.visible = true
            confirmationDialog.selectedButton = 1 -- Default to "Yes"
        else
            -- No save file, proceed directly
            menu.changeState(menu.gameStates.ROUND_START_BUFF_SELECTION)
        end
    elseif action == "settings" then
        menu.changeState(menu.gameStates.SETTINGS)
    elseif action == "credits" then
        menu.changeState(menu.gameStates.CREDITS)
    elseif action == "exit" then
        love.event.quit()
    end
end

-- Update menu (currently no animation/logic needed)
function MenuScreen.update(dt)
    if not nearStars or not spaceshipPosition then
        return
    end

    -- Check for button hover changes and play sound
    if menu.buttons then
        local currentHoveredButton = nil
        for i = 1, #menu.buttons do
            if isMouseOverButton(i) then
                currentHoveredButton = i
                break
            end
        end
        if currentHoveredButton ~= previousHoveredButton and currentHoveredButton ~= nil then
            SFX.playButtonHover()
        end
        previousHoveredButton = currentHoveredButton
    end

    -- Check for version badge hover changes and play sound
    local currentHoveredVersionBadge = isMouseOverVersionBadge()
    if currentHoveredVersionBadge and not previousHoveredVersionBadge then
        SFX.playButtonHover()
    end
    previousHoveredVersionBadge = currentHoveredVersionBadge

    -- Update star drift time
    starDriftTime = starDriftTime + dt
    local driftSpeed = 5 -- pixels per second

    -- Slowly drift near stars
    for _, star in ipairs(nearStars) do
        star.x = star.x + driftSpeed * dt
        -- Wrap around screen
        if star.x > love.graphics.getWidth() then
            star.x = 0
        end
    end

    -- Update spaceship position
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    spaceshipPosition.x = spaceshipPosition.x + spaceshipVelocity.x * dt
    spaceshipPosition.y = spaceshipPosition.y + spaceshipVelocity.y * dt

    -- Bounce off screen edges with smooth direction changes
    local margin = 100
    if spaceshipPosition.x < margin or spaceshipPosition.x > screenWidth - margin then
        spaceshipVelocity.x = -spaceshipVelocity.x
        spaceshipPosition.rotation = math.atan2(spaceshipVelocity.y, spaceshipVelocity.x) + math.pi / 2
    end
    if spaceshipPosition.y < margin or spaceshipPosition.y > screenHeight - margin then
        spaceshipVelocity.y = -spaceshipVelocity.y
        spaceshipPosition.rotation = math.atan2(spaceshipVelocity.y, spaceshipVelocity.x) + math.pi / 2
    end

    -- Gradually rotate spaceship towards movement direction
    local targetRotation = math.atan2(spaceshipVelocity.y, spaceshipVelocity.x) + math.pi / 2
    spaceshipPosition.rotation = spaceshipPosition.rotation + (targetRotation - spaceshipPosition.rotation) * dt * 2
end

-- Called when entering the menu screen for the first time
function MenuScreen.enter()
    -- Rebuild button list to reflect current save state
    rebuildButtonList()
end

-- Called when returning to the menu screen from another state
function MenuScreen.resume()
    -- Rebuild button list to reflect current save state
    rebuildButtonList()
end

-- Draw menu
function MenuScreen.draw()
    -- Draw dark space background
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw far stars (static)
    if farStars then
        for _, star in ipairs(farStars) do
            love.graphics.setColor(star.brightness, star.brightness, star.brightness + 0.2)
            love.graphics.circle("fill", star.x, star.y, star.size)
        end
    end

    -- Draw planet
    if planetSprite and planetPosition then
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.draw(planetSprite, planetPosition.x, planetPosition.y, planetPosition.rotation,
            planetPosition.scale, planetPosition.scale, planetSprite:getWidth() / 2, planetSprite:getHeight() / 2)
    end

    -- Draw moon
    if moonSprite and moonPosition then
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.draw(moonSprite, moonPosition.x, moonPosition.y, moonPosition.rotation, moonPosition.scale,
            moonPosition.scale, moonSprite:getWidth() / 2, moonSprite:getHeight() / 2)
    end

    -- Draw near stars (drifting)
    if nearStars then
        for _, star in ipairs(nearStars) do
            love.graphics.setColor(star.brightness, star.brightness, star.brightness + 0.2)
            love.graphics.circle("fill", star.x, star.y, star.size)
        end
    end

    -- Draw spaceship
    if spaceshipSprite and spaceshipPosition then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.draw(spaceshipSprite, spaceshipPosition.x, spaceshipPosition.y, spaceshipPosition.rotation, 1.5,
            1.5, spaceshipSprite:getWidth() / 2, spaceshipSprite:getHeight() / 2)
    end

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(GameFonts.huge)
    love.graphics.printf("Astro Moments", 0, 50, love.graphics.getWidth(), "center")

    -- Reset to default font for buttons
    love.graphics.setFont(GameFonts.large)

    -- Draw buttons
    for i, button in ipairs(menu.buttons) do
        local buttonX = (love.graphics.getWidth() - menu.buttonWidth) / 2
        local buttonY = getButtonY(i, #menu.buttons)
        local isHovered = isMouseOverButton(i) or menu.selectedIndex == i

        drawButton(button, buttonX, buttonY, isHovered)
    end

    -- Draw version badge in bottom right corner (above controls text)
    versionBadge.x = love.graphics.getWidth() - versionBadge.width - 20
    versionBadge.y = love.graphics.getHeight() - versionBadge.height - 70
    versionBadge.hovered = isMouseOverVersionBadge()

    -- Draw badge button sprite
    local badgeImage = versionBadge.hovered and versionBadgeHoverImage or versionBadgeNormalImage
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(badgeImage, versionBadge.x, versionBadge.y)

    -- Badge text
    love.graphics.setFont(GameFonts.small)
    if versionBadge.hovered then
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(0.7, 0.7, 0.7)
    end
    love.graphics.printf("v" .. Version.current, versionBadge.x, versionBadge.y + 17, versionBadge.width, "center")

    -- Draw controls help
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(GameFonts.normal)
    local controlsY = love.graphics.getHeight() - 50
    love.graphics.printf("[W/S or UP/DOWN] Navigate  [ENTER/SPACE or CLICK] Select  [ESC] Quit", 0, controlsY,
        love.graphics.getWidth(), "center")

    -- Draw confirmation dialog if visible
    if confirmationDialog.visible then
        -- Draw semi-transparent overlay
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        -- Dialog box dimensions
        local dialogWidth = 650
        local dialogHeight = 320
        local dialogX = (love.graphics.getWidth() - dialogWidth) / 2
        local dialogY = (love.graphics.getHeight() - dialogHeight) / 2

        -- Draw confirmation prompt image
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(confirmationPromptImage, dialogX, dialogY)

        -- Draw warning message
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(GameFonts.large)
        love.graphics.printf("Start New Game?", dialogX, dialogY + 30, dialogWidth, "center")

        love.graphics.setFont(GameFonts.medium)
        love.graphics.setColor(1, 0.7, 0.7)
        love.graphics.printf("Your current save file will be deleted.", dialogX + 20, dialogY + 80, dialogWidth - 40,
            "center")
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.printf("This action cannot be undone.", dialogX + 20, dialogY + 115, dialogWidth - 40, "center")

        -- Draw Yes/No buttons
        local buttonWidth = 150
        local buttonHeight = 50
        local buttonSpacing = 20
        local yesButtonX = dialogX + (dialogWidth / 2) - buttonWidth - (buttonSpacing / 2)
        local noButtonX = dialogX + (dialogWidth / 2) + (buttonSpacing / 2)
        local buttonY = dialogY + dialogHeight - 110

        -- Yes button
        local yesButtonImage = (confirmationDialog.selectedButton == 1) and dialogButtonHoverImage or
                                   dialogButtonNormalImage
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(yesButtonImage, yesButtonX, buttonY)
        love.graphics.printf("Yes", yesButtonX, buttonY + 15, buttonWidth, "center")

        -- No button
        local noButtonImage = (confirmationDialog.selectedButton == 2) and dialogButtonHoverImage or
                                  dialogButtonNormalImage
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(noButtonImage, noButtonX, buttonY)
        love.graphics.printf("No", noButtonX, buttonY + 15, buttonWidth, "center")

        -- Draw dialog controls hint
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setFont(GameFonts.small)
        love.graphics.printf("[LEFT/RIGHT or A/D] Choose  [ENTER/SPACE] Confirm", dialogX, dialogY + dialogHeight - 50,
            dialogWidth, "center")
    end
end

-- Handle keyboard input
function MenuScreen.keypressed(key)
    if not menu or not menu.buttons then
        return
    end

    -- Handle confirmation dialog input separately
    if confirmationDialog.visible then
        if key == "left" or key == "a" then
            SFX.playButtonHover()
            confirmationDialog.selectedButton = 1 -- Yes
        elseif key == "right" or key == "d" then
            SFX.playButtonHover()
            confirmationDialog.selectedButton = 2 -- No
        elseif key == "return" or key == "space" then
            SFX.playButtonClick()
            if confirmationDialog.selectedButton == 1 then
                -- Yes - Delete save and start new game
                Save.delete()
                confirmationDialog.visible = false
                menu.changeState(menu.gameStates.ROUND_START_BUFF_SELECTION)
            else
                -- No - Close dialog
                confirmationDialog.visible = false
            end
        elseif key == "escape" then
            -- ESC also closes dialog (acts as "No")
            confirmationDialog.visible = false
        end
        return
    end

    -- Normal menu navigation
    if key == "up" or key == "w" then
        -- Move selection up (skip disabled buttons)
        repeat
            menu.selectedIndex = menu.selectedIndex - 1
            if menu.selectedIndex < 1 then
                menu.selectedIndex = #menu.buttons
            end
        until menu.buttons[menu.selectedIndex].enabled
        SFX.playButtonHover()
    elseif key == "down" or key == "s" then
        -- Move selection down (skip disabled buttons)
        repeat
            menu.selectedIndex = menu.selectedIndex + 1
            if menu.selectedIndex > #menu.buttons then
                menu.selectedIndex = 1
            end
        until menu.buttons[menu.selectedIndex].enabled
        SFX.playButtonHover()
    elseif key == "return" or key == "space" then
        SFX.playButtonClick()
        if menu.buttons[menu.selectedIndex] then
            handleMenuAction(menu.buttons[menu.selectedIndex].action)
        end
    elseif key == "escape" then
        love.event.quit()
    end
end

-- Handle mouse input
function MenuScreen.mousepressed(x, y, button)
    if not menu or not menu.buttons then
        return
    end

    if button == 1 then
        -- Handle confirmation dialog clicks
        if confirmationDialog.visible then
            local dialogWidth = 500
            local dialogHeight = 200
            local dialogX = (love.graphics.getWidth() - dialogWidth) / 2
            local dialogY = (love.graphics.getHeight() - dialogHeight) / 2

            local buttonWidth = 120
            local buttonHeight = 40
            local buttonSpacing = 20
            local yesButtonX = dialogX + (dialogWidth / 2) - buttonWidth - (buttonSpacing / 2)
            local noButtonX = dialogX + (dialogWidth / 2) + (buttonSpacing / 2)
            local buttonY = dialogY + dialogHeight - 60

            -- Check Yes button click
            if x >= yesButtonX and x <= yesButtonX + buttonWidth and y >= buttonY and y <= buttonY + buttonHeight then
                SFX.playButtonClick()
                -- Yes - Delete save and start new game
                Save.delete()
                confirmationDialog.visible = false
                menu.changeState(menu.gameStates.ROUND_START_BUFF_SELECTION)
                return
            end

            -- Check No button click
            if x >= noButtonX and x <= noButtonX + buttonWidth and y >= buttonY and y <= buttonY + buttonHeight then
                SFX.playButtonClick()
                -- No - Close dialog
                confirmationDialog.visible = false
                return
            end

            -- Click outside dialog closes it
            if x < dialogX or x > dialogX + dialogWidth or y < dialogY or y > dialogY + dialogHeight then
                confirmationDialog.visible = false
            end
            return
        end

        -- Check version badge click
        if isMouseOverVersionBadge() then
            SFX.playButtonClick()
            if menu.changeState and menu.gameStates then
                menu.changeState(menu.gameStates.CHANGELOG)
            end
            return
        end

        -- Normal menu button clicks
        for i, menuButton in ipairs(menu.buttons) do
            if menuButton.enabled and isMouseOverButton(i) then
                SFX.playButtonClick()
                handleMenuAction(menuButton.action)
                break
            end
        end
    end
end

return MenuScreen
