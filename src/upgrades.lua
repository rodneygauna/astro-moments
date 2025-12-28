-- Upgrade module
-- Manages player upgrades and their effects
local Upgrades = {}

-- Define available upgrades
Upgrades.catalog = {
    -- Movement & Navigation
    engine_boost = {
        id = "engine_boost",
        name = "Engine Boost",
        description = "Increases maximum ship speed",
        category = "movement",
        maxLevel = 5,
        baseCost = 100,
        costMultiplier = 1.5,
        effect = {
            stat = "movementSpeedBonus",
            type = "percentage",
            valuePerLevel = 20 -- +20% per level
        }
    },

    thruster_efficiency = {
        id = "thruster_efficiency",
        name = "Thruster Efficiency",
        description = "Improves acceleration and deceleration",
        category = "movement",
        maxLevel = 5,
        baseCost = 80,
        costMultiplier = 1.5,
        effect = {
            stat = "accelerationBonus",
            type = "percentage",
            valuePerLevel = 15 -- +15% per level
        }
    },

    -- Collection System
    magnetic_field = {
        id = "magnetic_field",
        name = "Magnetic Field",
        description = "Increases collection radius size",
        category = "collection",
        maxLevel = 5,
        baseCost = 150,
        costMultiplier = 1.8,
        effect = {
            stat = "collectionRadiusBonus",
            type = "flat",
            valuePerLevel = 20 -- +20 radius per level
        }
    },

    collection_speed = {
        id = "collection_speed",
        name = "Collection Speed",
        description = "Faster asteroid collection meter fill rate",
        category = "collection",
        maxLevel = 5,
        baseCost = 120,
        costMultiplier = 1.6,
        effect = {
            stat = "collectionSpeedBonus",
            type = "percentage",
            valuePerLevel = 15 -- +15% per level
        }
    },

    decay_resistance = {
        id = "decay_resistance",
        name = "Decay Resistance",
        description = "Slower meter decay when asteroids leave field",
        category = "collection",
        maxLevel = 4,
        baseCost = 100,
        costMultiplier = 1.7,
        effect = {
            stat = "decayReduction",
            type = "percentage",
            valuePerLevel = 20 -- -20% decay per level
        }
    },

    auto_collect = {
        id = "auto_collect",
        name = "Auto-Collect",
        description = "Instantly collect asteroids below threshold",
        category = "collection",
        maxLevel = 3,
        baseCost = 200,
        costMultiplier = 2.0,
        effect = {
            stat = "autoCollectThreshold",
            type = "threshold",
            values = {90, 80, 70} -- Thresholds per level
        }
    },

    -- Cargo & Storage
    cargo_expansion = {
        id = "cargo_expansion",
        name = "Cargo Expansion",
        description = "More cargo space per run",
        category = "cargo",
        maxLevel = 10,
        baseCost = 100,
        costMultiplier = 1.5,
        effect = {
            stat = "cargoCapacityBonus",
            type = "flat",
            valuePerLevel = 30 -- +30 cargo per level (max 300 at level 10)
        }
    },

    -- Economy & Rewards
    cashout_multiplier = {
        id = "cashout_multiplier",
        name = "Cashout Multiplier",
        description = "Increases gold earned from asteroids",
        category = "economy",
        maxLevel = 5,
        baseCost = 150,
        costMultiplier = 1.8,
        effect = {
            stat = "goldMultiplier",
            type = "percentage",
            valuePerLevel = 10 -- +10% per level
        }
    },

    -- Time & Efficiency
    extended_mission = {
        id = "extended_mission",
        name = "Extended Mission",
        description = "Adds time to each round",
        category = "time",
        maxLevel = 5,
        baseCost = 200,
        costMultiplier = 1.6,
        effect = {
            stat = "missionTimeBonus",
            type = "flat",
            valuePerLevel = 10 -- +10 seconds per level
        }
    },

    fuel_efficiency = {
        id = "fuel_efficiency",
        name = "Fuel Efficiency",
        description = "Reduces fuel cost per sector",
        category = "efficiency",
        maxLevel = 5,
        baseCost = 120,
        costMultiplier = 1.5,
        effect = {
            stat = "fuelEfficiency",
            type = "percentage",
            valuePerLevel = 10 -- -10% fuel cost per level
        }
    },

    fuel_tank_expansion = {
        id = "fuel_tank_expansion",
        name = "Fuel Tank Expansion",
        description = "Increases maximum fuel capacity",
        category = "efficiency",
        maxLevel = 5,
        baseCost = 150,
        costMultiplier = 1.8,
        effect = {
            stat = "fuelCapacityBonus",
            type = "flat",
            valuePerLevel = 4 -- +4 max fuel per level (5 levels = +20, total max 25)
        }
    },

    -- Spawn Control
    asteroid_density = {
        id = "asteroid_density",
        name = "Asteroid Density",
        description = "More asteroids spawn per round",
        category = "spawning",
        maxLevel = 4,
        baseCost = 180,
        costMultiplier = 1.7,
        effect = {
            stat = "spawnRateBonus",
            type = "percentage",
            valuePerLevel = 25 -- +25% per level
        }
    }
}

-- Calculate upgrade cost for a specific level
function Upgrades.getCost(upgradeId, currentLevel)
    local upgrade = Upgrades.catalog[upgradeId]
    if not upgrade then
        return nil
    end

    if currentLevel >= upgrade.maxLevel then
        return nil -- Max level reached
    end

    -- Cost increases exponentially: baseCost * (multiplier ^ currentLevel)
    return math.floor(upgrade.baseCost * (upgrade.costMultiplier ^ currentLevel))
end

-- Get the effect value for a specific level
function Upgrades.getEffectValue(upgradeId, level)
    local upgrade = Upgrades.catalog[upgradeId]
    if not upgrade then
        return 0
    end

    if upgrade.effect.type == "threshold" then
        return upgrade.effect.values[level] or 0
    else
        return upgrade.effect.valuePerLevel * level
    end
end

-- Check if player can afford an upgrade
function Upgrades.canAfford(player, upgradeId)
    local currentLevel = Upgrades.getPlayerUpgradeLevel(player, upgradeId)
    local cost = Upgrades.getCost(upgradeId, currentLevel)

    if not cost then
        return false
    end -- Max level or invalid upgrade

    return player.currency.gold >= cost
end

-- Purchase an upgrade
function Upgrades.purchase(player, upgradeId)
    local currentLevel = Upgrades.getPlayerUpgradeLevel(player, upgradeId)
    local cost = Upgrades.getCost(upgradeId, currentLevel)
    local upgrade = Upgrades.catalog[upgradeId]

    if not cost or not upgrade then
        return false, "Invalid upgrade"
    end

    if not Upgrades.canAfford(player, upgradeId) then
        return false, "Not enough gold"
    end

    -- Deduct cost
    player.currency.gold = player.currency.gold - cost

    -- Find or create skill entry
    local skillEntry = nil
    for _, skill in ipairs(player.skills) do
        if skill.id == upgradeId then
            skillEntry = skill
            break
        end
    end

    if not skillEntry then
        skillEntry = {
            id = upgradeId,
            level = 0
        }
        table.insert(player.skills, skillEntry)
    end

    -- Increase level
    skillEntry.level = skillEntry.level + 1

    -- Apply stat bonus
    Upgrades.applyUpgradeEffects(player)

    return true, "Upgrade purchased"
end

-- Get player's current level for an upgrade
function Upgrades.getPlayerUpgradeLevel(player, upgradeId)
    for _, skill in ipairs(player.skills) do
        if skill.id == upgradeId then
            return skill.level
        end
    end
    return 0
end

-- Apply all upgrade effects to player stats
function Upgrades.applyUpgradeEffects(player)
    -- Reset stats to base values
    player.stats.movementSpeedBonus = 0
    player.stats.accelerationBonus = 0
    player.stats.collectionRadiusBonus = 0
    player.stats.collectionSpeedBonus = 0
    player.stats.decayReduction = 0
    player.stats.autoCollectThreshold = nil
    player.stats.cargoCapacityBonus = 0
    player.stats.goldMultiplier = 0
    player.stats.missionTimeBonus = 0
    player.stats.fuelEfficiency = 0
    player.stats.fuelCapacityBonus = 0
    player.stats.spawnRateBonus = 0

    -- Apply all purchased upgrades
    for _, skill in ipairs(player.skills) do
        local upgrade = Upgrades.catalog[skill.id]
        if upgrade and skill.level > 0 then
            local effectValue = Upgrades.getEffectValue(skill.id, skill.level)

            if upgrade.effect.type == "threshold" then
                player.stats[upgrade.effect.stat] = effectValue
            else
                player.stats[upgrade.effect.stat] = player.stats[upgrade.effect.stat] + effectValue
            end
        end
    end
end

-- Get all upgrades grouped by category
function Upgrades.getByCategory()
    local categories = {}

    for _, upgrade in pairs(Upgrades.catalog) do
        if not categories[upgrade.category] then
            categories[upgrade.category] = {}
        end
        table.insert(categories[upgrade.category], upgrade)
    end

    return categories
end

return Upgrades
