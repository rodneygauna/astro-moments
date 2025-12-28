-- Buff module
-- Handles temporary buff definitions and selection for rounds
local Buff = {}

-- Buff definitions
-- Buffs are temporary bonuses that apply to a single mining round
Buff.definitions = {{
    id = "faster_collection",
    name = "Faster Collection",
    description = "Increases collection speed by a percentage.",
    type = "multiplier",
    minValue = 5,
    maxValue = 15,
    rarity = "common"
}, {
    id = "decay_speed_reduction",
    name = "Decay Speed Reduction",
    description = "Reduces decay speed by a percentage.",
    type = "multiplier",
    minValue = 5,
    maxValue = 15,
    rarity = "common"
}, {
    id = "increased_collection_radius",
    name = "Increased Collection Radius",
    description = "Increases the collection field radius by a percentage.",
    type = "multiplier",
    minValue = 5,
    maxValue = 15,
    rarity = "uncommon"
}, {
    id = "max_speed_boost",
    name = "Max Speed Boost",
    description = "Increases the spaceship's maximum speed by a flat amount.",
    type = "flat",
    minValue = 10,
    maxValue = 25,
    rarity = "uncommon"
}, {
    id = "acceleration_boost",
    name = "Acceleration Boost",
    description = "Increases the spaceship's acceleration by a flat amount.",
    type = "flat",
    minValue = 10,
    maxValue = 25,
    rarity = "uncommon"
}, {
    id = "value_boost",
    name = "Value Boost",
    description = "Increases the value of collected asteroids by a multiplier.",
    type = "multiplier",
    minValue = 20,
    maxValue = 100,
    rarity = "rare"
}, {
    id = "extended_time",
    name = "Extended Time",
    description = "Adds extra seconds to the mining round timer.",
    type = "flat",
    minValue = 5,
    maxValue = 15,
    rarity = "rare"
}}

-- Rarity weights for random selection
Buff.rarityWeights = {
    common = 60,
    uncommon = 30,
    rare = 10
}

-- Generate a random buff with a random value within its range
function Buff.generateRandom()
    -- Calculate total weight
    local totalWeight = 0
    for _, weight in pairs(Buff.rarityWeights) do
        totalWeight = totalWeight + weight
    end

    -- Select a rarity based on weights
    local roll = math.random() * totalWeight
    local selectedRarity = nil
    local currentWeight = 0

    for rarity, weight in pairs(Buff.rarityWeights) do
        currentWeight = currentWeight + weight
        if roll <= currentWeight then
            selectedRarity = rarity
            break
        end
    end

    -- Get all buffs of the selected rarity
    local availableBuffs = {}
    for _, buff in ipairs(Buff.definitions) do
        if buff.rarity == selectedRarity then
            table.insert(availableBuffs, buff)
        end
    end

    -- Select a random buff from available ones
    if #availableBuffs == 0 then
        return nil
    end

    local selectedBuff = availableBuffs[math.random(1, #availableBuffs)]

    -- Generate a random value within the buff's range
    local value = math.random(selectedBuff.minValue, selectedBuff.maxValue)

    -- Round up to the nearest ten
    value = math.ceil(value / 10) * 10

    -- Create a buff instance
    return {
        id = selectedBuff.id,
        name = selectedBuff.name,
        description = selectedBuff.description,
        type = selectedBuff.type,
        value = value,
        rarity = selectedBuff.rarity
    }
end

-- Generate multiple random buffs for selection
function Buff.generateSelection(count)
    local selection = {}
    for i = 1, count do
        local buff = Buff.generateRandom()
        if buff then
            table.insert(selection, buff)
        end
    end
    return selection
end

-- Apply a buff to the spaceship or game state
function Buff.apply(buff, spaceship, gameState)
    if buff.id == "faster_collection" then
        -- Increase collection speed
        spaceship.collectionSpeedBonus = (spaceship.collectionSpeedBonus or 0) + buff.value
    elseif buff.id == "decay_speed_reduction" then
        -- Reduce decay speed
        spaceship.decaySpeedReduction = (spaceship.decaySpeedReduction or 0) + buff.value
    elseif buff.id == "increased_collection_radius" then
        -- Increase collection radius by percentage
        local radiusIncrease = spaceship.baseCollectionRadius * (buff.value / 100)
        spaceship.collectionRadius = spaceship.collectionRadius + radiusIncrease
        spaceship.baseCollectionRadius = spaceship.baseCollectionRadius + radiusIncrease
        spaceship.minCollectionRadius = spaceship.minCollectionRadius + radiusIncrease
        spaceship.maxCollectionRadius = spaceship.maxCollectionRadius + radiusIncrease
    elseif buff.id == "max_speed_boost" then
        -- Increase max speed
        spaceship.maxSpeed = spaceship.maxSpeed + buff.value
    elseif buff.id == "acceleration_boost" then
        -- Increase acceleration
        spaceship.acceleration = spaceship.acceleration + buff.value
        -- Also increase deceleration proportionally to maintain control
        spaceship.deceleration = spaceship.deceleration + (buff.value * 0.75)
    elseif buff.id == "value_boost" then
        -- Store value multiplier for cashout calculation
        gameState.valueMultiplier = (gameState.valueMultiplier or 1.0) + (buff.value / 100)
    elseif buff.id == "extended_time" then
        -- Add extra time to the round
        gameState.maxTime = gameState.maxTime + buff.value
        gameState.timeLeft = gameState.timeLeft + buff.value
    end
end

-- Get buff display color based on rarity
function Buff.getRarityColor(rarity)
    if rarity == "common" then
        return {0.7, 0.7, 0.7} -- Gray
    elseif rarity == "uncommon" then
        return {0.3, 0.8, 0.3} -- Green
    elseif rarity == "rare" then
        return {0.3, 0.5, 1.0} -- Blue
    else
        return {1, 1, 1} -- White (fallback)
    end
end

return Buff
