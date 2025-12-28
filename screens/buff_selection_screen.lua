-- Buff Selection Screen
-- Allows player to choose temporary buffs before starting mining rounds
local BuffSelectionScreen = {}

local Player = require("src/player")
local Buff = require("src/buff")
local SFX = require("src/sfx")

-- Buff selection state
local player
local gameStates
local changeState
local buffChoices
local selectedBuffs
local selectionsRemaining
local maxSelections
local hoveredButton
local previousHoveredButton
local selectedIndex
local buffButtonNormalImage
local buffButtonHoverImage

-- Initialize buff selection screen
function BuffSelectionScreen.load(playerData, states, stateChanger)
    player = playerData
    gameStates = states
    changeState = stateChanger
    hoveredButton = nil
    previousHoveredButton = nil
    selectedIndex = 1

    -- Load buff button images
    buffButtonNormalImage = love.graphics.newImage("sprites/buttons/Btn-GrayScale_700x130.png")
    buffButtonNormalImage:setFilter("nearest", "nearest")
    buffButtonHoverImage = love.graphics.newImage("sprites/buttons/Btn-GrayScale-Hover_700x130.png")
    buffButtonHoverImage:setFilter("nearest", "nearest")

    -- Initialize selection state
    maxSelections = 3
    selectionsRemaining = maxSelections
    selectedBuffs = {}

    -- Generate initial buff choices
    buffChoices = Buff.generateSelection(3)
end

-- Update buff selection screen
function BuffSelectionScreen.update(dt)
    -- Update hovered button
    local mouseX, mouseY = love.mouse.getPosition()
    hoveredButton = nil

    -- Calculate button positions (vertical layout)
    local buttonWidth = 700
    local buttonHeight = 130
    local buttonSpacing = 20
    local totalHeight = (#buffChoices * buttonHeight) + ((#buffChoices - 1) * buttonSpacing)
    local startY = (love.graphics.getHeight() - totalHeight) / 2
    local buttonX = (love.graphics.getWidth() - buttonWidth) / 2

    for i, buff in ipairs(buffChoices) do
        local buttonY = startY + (i - 1) * (buttonHeight + buttonSpacing)

        if mouseX >= buttonX and mouseX <= buttonX + buttonWidth and mouseY >= buttonY and mouseY <= buttonY +
            buttonHeight then
            hoveredButton = i
            break
        end
    end

    -- Play hover sound when hoveredButton changes
    if hoveredButton ~= previousHoveredButton then
        if hoveredButton ~= nil then
            SFX.playButtonHover()
        end
        previousHoveredButton = hoveredButton
    end
end

-- Draw buff selection screen
function BuffSelectionScreen.draw()
    -- Draw background
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(GameFonts.title)
    love.graphics.printf("SELECT A BUFF", 0, 60, love.graphics.getWidth(), "center")

    -- Draw selections remaining
    love.graphics.setColor(0.7, 0.7, 0.9)
    love.graphics.setFont(GameFonts.large)
    love.graphics.printf("Selections Remaining: " .. selectionsRemaining .. " / " .. maxSelections, 0, 100,
        love.graphics.getWidth(), "center")

    -- Draw selected buffs count
    if #selectedBuffs > 0 then
        love.graphics.setColor(0.3, 0.8, 0.3)
        love.graphics.setFont(GameFonts.large)
        love.graphics.printf("Active Buffs: " .. #selectedBuffs, 0, 130, love.graphics.getWidth(), "center")
    end

    -- Draw buff choice buttons (vertical layout)
    local buttonWidth = 700
    local buttonHeight = 130
    local buttonSpacing = 20
    local totalHeight = (#buffChoices * buttonHeight) + ((#buffChoices - 1) * buttonSpacing)

    -- Center buttons between the "Active Buffs" text and navigation text
    local topBoundary = 160 -- Below "Active Buffs" text
    local bottomBoundary = love.graphics.getHeight() - 80 -- Above navigation text
    local availableHeight = bottomBoundary - topBoundary
    local startY = topBoundary + (availableHeight - totalHeight) / 2
    local buttonX = (love.graphics.getWidth() - buttonWidth) / 2

    for i, buff in ipairs(buffChoices) do
        local buttonY = startY + (i - 1) * (buttonHeight + buttonSpacing)
        local isHovered = (hoveredButton == i) or (selectedIndex == i)

        -- Get rarity color
        local rarityColor = Buff.getRarityColor(buff.rarity)

        -- Draw button sprite with rarity color tinting
        local buttonImage = isHovered and buffButtonHoverImage or buffButtonNormalImage
        if isHovered then
            love.graphics.setColor(rarityColor[1], rarityColor[2], rarityColor[3])
        else
            love.graphics.setColor(rarityColor[1] * 0.7, rarityColor[2] * 0.7, rarityColor[3] * 0.7)
        end
        love.graphics.draw(buttonImage, buttonX, buttonY)

        -- Draw rarity badge (top left)
        love.graphics.setFont(GameFonts.normal)
        love.graphics.setColor(rarityColor)
        love.graphics.print(buff.rarity:upper(), buttonX + 15, buttonY + 12)

        -- Draw buff value (top right)
        local valueText = ""
        if buff.type == "multiplier" then
            valueText = "+" .. buff.value .. "%"
        else
            valueText = "+" .. buff.value
        end
        love.graphics.setFont(GameFonts.large)
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.printf(valueText, buttonX + 15, buttonY + 12, buttonWidth - 30, "right")

        -- Draw buff name (center-left)
        love.graphics.setFont(GameFonts.large)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(buff.name, buttonX + 15, buttonY + 45)

        -- Draw buff description (bottom)
        love.graphics.setFont(GameFonts.normal)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf(buff.description, buttonX + 15, buttonY + 80, buttonWidth - 30, "left")
    end

    -- Draw instructions
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(GameFonts.normal)
    love.graphics.printf("[W/S or UP/DOWN] Navigate  [ENTER/SPACE or CLICK] Select  [ESC] Back", 0,
        love.graphics.getHeight() - 50, love.graphics.getWidth(), "center")
end

-- Handle keyboard input
function BuffSelectionScreen.keypressed(key)
    if key == "w" or key == "up" then
        -- Move selection up
        selectedIndex = selectedIndex - 1
        if selectedIndex < 1 then
            selectedIndex = #buffChoices
        end
        SFX.playButtonHover()
    elseif key == "s" or key == "down" then
        -- Move selection down
        selectedIndex = selectedIndex + 1
        if selectedIndex > #buffChoices then
            selectedIndex = 1
        end
        SFX.playButtonHover()
    elseif key == "return" or key == "space" then
        SFX.playButtonClick()
        -- Select the currently highlighted buff
        local selectedBuff = buffChoices[selectedIndex]

        -- Add buff to selected buffs list
        table.insert(selectedBuffs, selectedBuff)

        -- Decrease selections remaining
        selectionsRemaining = selectionsRemaining - 1

        -- Check if all selections are made
        if selectionsRemaining <= 0 then
            -- Store selected buffs in player data for later application
            player.activeBuffs = selectedBuffs

            -- Reset fuel for the new run
            Player.resetFuel(player)

            -- Move to map selection
            changeState(gameStates.MAP_SELECTION)
        else
            -- Generate new buff choices for next selection
            buffChoices = Buff.generateSelection(3)
            -- Reset selected index to first buff
            selectedIndex = 1
        end
    elseif key == "escape" and #selectedBuffs == 0 then
        SFX.playButtonClick()
        -- Allow ESC to go back to menu (only if no selections made yet)
        changeState(gameStates.MENU)
    end
end

-- Handle mouse input
function BuffSelectionScreen.mousepressed(x, y, button)
    if button == 1 and hoveredButton then
        SFX.playButtonClick()
        local selectedBuff = buffChoices[hoveredButton]

        -- Add buff to selected buffs list
        table.insert(selectedBuffs, selectedBuff)

        -- Decrease selections remaining
        selectionsRemaining = selectionsRemaining - 1

        -- Check if all selections are made
        if selectionsRemaining <= 0 then
            -- Store selected buffs in player data for later application
            player.activeBuffs = selectedBuffs

            -- Reset fuel for the new run
            Player.resetFuel(player)

            -- Move to map selection
            changeState(gameStates.MAP_SELECTION)
        else
            -- Generate new buff choices for next selection
            buffChoices = Buff.generateSelection(3)
        end
    end
end

return BuffSelectionScreen
