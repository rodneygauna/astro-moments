-- Settings Screen
-- Handles settings display and interaction
local SettingsScreen = {}

local Settings = require("src/settings")
local SFX = require("src/sfx")

-- Screen state
local gameStates
local changeState
local settings
local selectedControl = 1
local hoveredControl = nil

-- UI controls
local controls = {}
local backButton
local backButtonNormalImage
local backButtonHoverImage

-- Helper: Check if mouse is over a control
local function isMouseOverControl(control)
    local mouseX, mouseY = love.mouse.getPosition()
    return mouseX >= control.x and mouseX <= control.x + control.width and mouseY >= control.y and mouseY <= control.y +
               control.height
end

-- Helper: Draw a slider
local function drawSlider(control, value)
    local sliderX = control.x
    local sliderY = control.y
    local sliderWidth = control.width
    local sliderHeight = 20

    -- Background track
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", sliderX, sliderY, sliderWidth, sliderHeight, 4, 4)

    -- Filled portion
    local fillWidth = sliderWidth * value
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.rectangle("fill", sliderX, sliderY, fillWidth, sliderHeight, 4, 4)

    -- Thumb
    local thumbX = sliderX + fillWidth - 8
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", thumbX + 8, sliderY + 10, 12)
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.circle("fill", thumbX + 8, sliderY + 10, 10)
end

-- Helper: Draw a checkbox
local function drawCheckbox(control, checked)
    local boxSize = 30
    local boxX = control.x
    local boxY = control.y

    -- Box background
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", boxX, boxY, boxSize, boxSize, 4, 4)

    -- Box border
    local isHovered = (hoveredControl == control) or (selectedControl == control.id)
    if isHovered then
        love.graphics.setColor(0.3, 0.8, 1)
    else
        love.graphics.setColor(0.4, 0.4, 0.5)
    end
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", boxX, boxY, boxSize, boxSize, 4, 4)

    -- Checkmark
    if checked then
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.setLineWidth(3)
        love.graphics.line(boxX + 7, boxY + 15, boxX + 12, boxY + 22)
        love.graphics.line(boxX + 12, boxY + 22, boxX + 23, boxY + 8)
    end

    love.graphics.setLineWidth(1)
end

-- Helper: Draw a resolution selector (like slider but with arrows)
local function drawResolutionSelector(control, selectedIndex)
    local selectorX = control.x
    local selectorY = control.y
    local selectorWidth = control.width
    local selectorHeight = 40

    -- Background
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", selectorX, selectorY, selectorWidth, selectorHeight, 4, 4)

    -- Border
    local isHovered = (hoveredControl == control) or (selectedControl == control.id)
    if isHovered then
        love.graphics.setColor(0.3, 0.8, 1)
    else
        love.graphics.setColor(0.4, 0.4, 0.5)
    end
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", selectorX, selectorY, selectorWidth, selectorHeight, 4, 4)
    love.graphics.setLineWidth(1)

    -- Selected resolution text (centered)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(GameFonts.normal)
    local selectedText = control.options[selectedIndex].label
    love.graphics.printf(selectedText, selectorX, selectorY + 13, selectorWidth, "center")

    -- Left arrow
    if selectedIndex > 1 then
        love.graphics.setColor(0.7, 0.7, 0.7)
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
    end
    love.graphics.polygon("fill", selectorX + 15, selectorY + 20, selectorX + 25, selectorY + 13, selectorX + 25,
        selectorY + 27)

    -- Right arrow
    if selectedIndex < #control.options then
        love.graphics.setColor(0.7, 0.7, 0.7)
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
    end
    love.graphics.polygon("fill", selectorX + selectorWidth - 15, selectorY + 20, selectorX + selectorWidth - 25,
        selectorY + 13, selectorX + selectorWidth - 25, selectorY + 27)
end

-- Initialize settings screen
function SettingsScreen.load(states, stateChanger)
    gameStates = states
    changeState = stateChanger
    settings = Settings.get()
    selectedControl = 1
    hoveredControl = nil

    -- Load button images
    backButtonNormalImage = love.graphics.newImage("sprites/buttons/Btn_200x50.png")
    backButtonNormalImage:setFilter("nearest", "nearest")
    backButtonHoverImage = love.graphics.newImage("sprites/buttons/Btn-Hover_200x50.png")
    backButtonHoverImage:setFilter("nearest", "nearest")

    -- Create back button
    backButton = {
        id = 99,
        x = (love.graphics.getWidth() - 200) / 2,
        y = love.graphics.getHeight() - 100,
        width = 200,
        height = 50,
        text = "Save & Back"
    }

    -- Find current resolution index
    local currentResIndex = 1
    for i, preset in ipairs(Settings.resolutionPresets) do
        if preset.width == settings.video.width and preset.height == settings.video.height then
            currentResIndex = i
            break
        end
    end

    -- Create controls
    controls = { -- Video section
    {
        id = 1,
        type = "dropdown",
        label = "Resolution",
        x = 350,
        y = 180,
        width = 300,
        height = 40,
        options = Settings.resolutionPresets,
        selectedIndex = currentResIndex,
        getValue = function()
            return currentResIndex
        end,
        setValue = function(index)
            currentResIndex = index
            local preset = Settings.resolutionPresets[index]
            Settings.set("video", "width", preset.width)
            Settings.set("video", "height", preset.height)
        end
    }, {
        id = 2,
        type = "checkbox",
        label = "Fullscreen",
        x = 350,
        y = 250,
        width = 30,
        height = 30,
        getValue = function()
            return settings.video.fullscreen
        end,
        setValue = function(value)
            Settings.set("video", "fullscreen", value)
            settings.video.fullscreen = value
        end
    }, {
        id = 3,
        type = "checkbox",
        label = "VSync",
        x = 350,
        y = 310,
        width = 30,
        height = 30,
        getValue = function()
            return settings.video.vsync
        end,
        setValue = function(value)
            Settings.set("video", "vsync", value)
            settings.video.vsync = value
        end
    }, -- Audio section
    {
        id = 4,
        type = "slider",
        label = "Music Volume",
        x = 350,
        y = 410,
        width = 300,
        height = 20,
        getValue = function()
            return settings.audio.musicVolume
        end,
        setValue = function(value)
            Settings.set("audio", "musicVolume", value)
            settings.audio.musicVolume = value
            -- Volume will be applied to music tracks on next update
        end
    }, {
        id = 5,
        type = "checkbox",
        label = "Mute Music",
        x = 350,
        y = 470,
        width = 30,
        height = 30,
        getValue = function()
            return settings.audio.musicMuted
        end,
        setValue = function(value)
            Settings.set("audio", "musicMuted", value)
            settings.audio.musicMuted = value
            -- Mute status will be applied to music tracks on next update
        end
    }, {
        id = 6,
        type = "slider",
        label = "SFX Volume",
        x = 350,
        y = 530,
        width = 300,
        height = 20,
        getValue = function()
            return settings.audio.sfxVolume
        end,
        setValue = function(value)
            Settings.set("audio", "sfxVolume", value)
            settings.audio.sfxVolume = value
        end
    }, {
        id = 7,
        type = "checkbox",
        label = "Mute SFX",
        x = 350,
        y = 590,
        width = 30,
        height = 30,
        getValue = function()
            return settings.audio.sfxMuted
        end,
        setValue = function(value)
            Settings.set("audio", "sfxMuted", value)
            settings.audio.sfxMuted = value
        end
    }}
end

-- Update settings screen
function SettingsScreen.update(dt)
    local mouseX, mouseY = love.mouse.getPosition()
    local previousHovered = hoveredControl
    hoveredControl = nil

    -- Check back button hover
    if isMouseOverControl(backButton) then
        hoveredControl = backButton
        if previousHovered ~= hoveredControl then
            SFX.playButtonHover()
        end
        return
    end

    -- Check control hovers
    for _, control in ipairs(controls) do
        if isMouseOverControl(control) then
            hoveredControl = control
            if previousHovered ~= hoveredControl then
                SFX.playButtonHover()
            end
            break
        end
    end
end

-- Draw settings screen
function SettingsScreen.draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Draw background
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(GameFonts.title)
    love.graphics.printf("SETTINGS", 0, 30, screenWidth, "center")

    -- Draw section headers
    love.graphics.setFont(GameFonts.large)
    love.graphics.printf("VIDEO", 0, 130, screenWidth, "center")
    love.graphics.printf("AUDIO", 0, 360, screenWidth, "center")

    -- Draw controls
    love.graphics.setFont(GameFonts.normal)
    for _, control in ipairs(controls) do
        -- Draw label
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.print(control.label .. ":", 150, control.y + 5)

        -- Draw control based on type
        if control.type == "slider" then
            drawSlider(control, control.getValue())
            -- Draw percentage
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(math.floor(control.getValue() * 100) .. "%", control.x + control.width + 20, control.y)
        elseif control.type == "checkbox" then
            drawCheckbox(control, control.getValue())
        elseif control.type == "dropdown" then
            drawResolutionSelector(control, control.selectedIndex or 1)
        end
    end

    -- Draw back button
    local isBackHovered = (hoveredControl == backButton) or (selectedControl == backButton.id)
    local buttonImage = isBackHovered and backButtonHoverImage or backButtonNormalImage
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(buttonImage, backButton.x, backButton.y)
    love.graphics.setFont(GameFonts.normal)
    love.graphics.printf(backButton.text, backButton.x, backButton.y + 15, backButton.width, "center")

    -- Draw instructions
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(GameFonts.small)
    love.graphics.printf("[W/S] Navigate  [A/D] Adjust  [ENTER/SPACE] Toggle  [ESC] Save & Back", 0, screenHeight - 40,
        screenWidth, "center")
end

-- Handle keyboard input
function SettingsScreen.keypressed(key)
    if key == "escape" then
        SFX.playButtonClick()
        Settings.save()
        Settings.apply()
        changeState(gameStates.MENU)
    elseif key == "w" or key == "up" then
        SFX.playButtonHover()
        selectedControl = selectedControl - 1
        if selectedControl < 1 then
            selectedControl = backButton.id
        end
    elseif key == "s" or key == "down" then
        SFX.playButtonHover()
        selectedControl = selectedControl + 1
        if selectedControl > #controls and selectedControl < backButton.id then
            selectedControl = backButton.id
        elseif selectedControl > backButton.id then
            selectedControl = 1
        end
    elseif key == "return" or key == "space" then
        SFX.playButtonClick()
        -- Check if back button is selected
        if selectedControl == backButton.id then
            Settings.save()
            Settings.apply()
            changeState(gameStates.MENU)
            return
        end

        -- Toggle checkboxes
        local control = controls[selectedControl]
        if control and control.type == "checkbox" then
            control.setValue(not control.getValue())
        end
    elseif key == "a" then
        SFX.playButtonClick()
        local control = controls[selectedControl]
        if control then
            if control.type == "slider" then
                local newValue = math.max(0, control.getValue() - 0.1)
                control.setValue(newValue)
            elseif control.type == "dropdown" then
                control.selectedIndex = math.max(1, control.selectedIndex - 1)
                control.setValue(control.selectedIndex)
            end
        end
    elseif key == "d" then
        SFX.playButtonClick()
        local control = controls[selectedControl]
        if control then
            if control.type == "slider" then
                local newValue = math.min(1, control.getValue() + 0.1)
                control.setValue(newValue)
            elseif control.type == "dropdown" then
                control.selectedIndex = math.min(#control.options, control.selectedIndex + 1)
                control.setValue(control.selectedIndex)
            end
        end
    end
end

-- Handle mouse input
function SettingsScreen.mousepressed(x, y, button)
    if button == 1 then
        -- Check back button
        if isMouseOverControl(backButton) then
            SFX.playButtonClick()
            Settings.save()
            Settings.apply()
            changeState(gameStates.MENU)
            return
        end

        -- Check controls
        for _, control in ipairs(controls) do
            if isMouseOverControl(control) then
                SFX.playButtonClick()
                if control.type == "checkbox" then
                    control.setValue(not control.getValue())
                elseif control.type == "slider" then
                    -- Calculate slider position
                    local relativeX = x - control.x
                    local newValue = math.max(0, math.min(1, relativeX / control.width))
                    control.setValue(newValue)
                elseif control.type == "dropdown" then
                    -- Check which side was clicked for left/right navigation
                    local relativeX = x - control.x
                    if relativeX < control.width / 2 and control.selectedIndex > 1 then
                        -- Left side - go to previous option
                        control.selectedIndex = control.selectedIndex - 1
                        control.setValue(control.selectedIndex)
                    elseif relativeX >= control.width / 2 and control.selectedIndex < #control.options then
                        -- Right side - go to next option
                        control.selectedIndex = control.selectedIndex + 1
                        control.setValue(control.selectedIndex)
                    end
                end
                break
            end
        end
    end
end

-- Handle mouse dragging on sliders
function SettingsScreen.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(1) then
        for _, control in ipairs(controls) do
            if control.type == "slider" and isMouseOverControl(control) then
                local relativeX = x - control.x
                local newValue = math.max(0, math.min(1, relativeX / control.width))
                control.setValue(newValue)
                break
            end
        end
    end
end

return SettingsScreen
