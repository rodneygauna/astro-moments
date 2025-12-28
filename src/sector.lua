-- Sector module
-- Handles sector data, including asteroid spawning and layout
local Sector = {}

-- Sector definitions
Sector.definitions = {
    sector_01 = {
        id = "sector_01",
        name = "Silicate Plains",
        description = "A common mining zone filled with basic silicate and carbonaceous asteroids. Perfect for beginners learning the ropes.",
        obstacle = "None - This is a beginner-friendly sector with no environmental hazards.",
        asteroidTypes = {"silicates", "carbonaceous"},
        spawnRate = 1.0,
        unlock_cost = 0, -- Free sector to start with
        fuel_cost = 1, -- Fuel cost to travel to this sector
        planetImage = "sprites/planets/Planet-Green-Blue.png" -- Background planet sprite
    },
    sector_02 = {
        id = "sector_02",
        name = "Ironclad Belt",
        description = "Dense metallic asteroids drift through this industrial sector. Iron and nickel deposits make this a staple mining route.",
        obstacle = "Solar Flare Warning Zones - Pulsing warning circles appear before solar flares that briefly slow your ship and nearby asteroids.",
        asteroidTypes = {"iron", "nickel"},
        spawnRate = 1.0,
        unlock_cost = 50, -- Cost to unlock this sector
        fuel_cost = 2, -- Fuel cost to travel to this sector
        planetImage = "sprites/planets/Planet-Ammo_80x80.png", -- Background planet sprite
        obstacles = {{
            type = "solar_flare",
            count = 2,
            spawnInterval = 0
        }}
    },
    sector_03 = {
        id = "sector_03",
        name = "Magnesium Expanse",
        description = "Shimmering green-tinted asteroids rich in magnesium silicates and aluminum minerals dominate this vast field.",
        obstacle = "Cosmic Dust Cloud - Reduced visibility makes it harder to see distant asteroids and navigate the area.",
        asteroidTypes = {"magnesium_silicates", "aluminum_minerals"},
        spawnRate = 1.0,
        unlock_cost = 125, -- Cost to unlock this sector
        fuel_cost = 3, -- Fuel cost to travel to this sector
        planetImage = "sprites/planets/Planet-Eulbink_80x80.png", -- Background planet sprite
        obstacles = {{
            type = "cosmic_dust",
            count = 1,
            spawnInterval = 0,
            obscurity = 0.6 -- Mild dust for Sector 3 (0.0 = light, 1.0 = thick)
        }}
    },
    sector_04 = {
        id = "sector_04",
        name = "Calcite Reef",
        description = "Ancient calcium-rich asteroids intermingle with sulfide deposits in this chemically diverse sector.",
        obstacle = "Space Debris - Non-moving space junk (2-3 pieces) that causes your ship to bounce and stop upon collision, interrupting capture progress.",
        asteroidTypes = {"calcium_minerals", "sulfides"},
        spawnRate = 1.0,
        unlock_cost = 250, -- Cost to unlock this sector
        fuel_cost = 4, -- Fuel cost to travel to this sector
        planetImage = "sprites/planets/Planet-Justparchment_80x80.png", -- Background planet sprite
        obstacles = {{
            type = "space_debris",
            count = 3,
            spawnInterval = 0,
            movementSpeed = 0 -- Stationary for Sector 4 (can be set to value like 30 for moving debris)
        }}
    },
    sector_05 = {
        id = "sector_05",
        name = "Frozen Frontier",
        description = "Ice-laden asteroids glimmer in the void alongside carbonates. Water and mineral wealth await hardy prospectors.",
        obstacle = "Combined Hazards - Solar flares and space debris create a dangerous mining environment requiring constant vigilance.",
        asteroidTypes = {"water_ice", "carbonates"},
        spawnRate = 1.0,
        unlock_cost = 500, -- Cost to unlock this sector
        fuel_cost = 5, -- Fuel cost to travel to this sector
        planetImage = "sprites/planets/Planet-Mahyellaw_80x80.png", -- Background planet sprite
        obstacles = {{
            type = "solar_flare",
            count = 2,
            spawnInterval = 0
        }, {
            type = "space_debris",
            count = 2,
            spawnInterval = 0,
            movementSpeed = 0
        }}
    },
    sector_06 = {
        id = "sector_06",
        name = "Clay Fields",
        description = "A sediment-rich zone where clay minerals and graphite crystals form unusual asteroid compositions.",
        obstacle = "Meteor - A single meteor periodically flies across the screen in a predictable path. Collision causes bounce and interrupts capture.",
        asteroidTypes = {"clay_minerals", "graphite"},
        spawnRate = 1.0,
        unlock_cost = 1000, -- Cost to unlock this sector
        fuel_cost = 6, -- Fuel cost to travel to this sector
        planetImage = "sprites/planets/Planet-MidnightAblaze_80x80.png", -- Background planet sprite
        obstacles = {{
            type = "meteor",
            count = 1,
            spawnInterval = 0,
            speed = 150, -- Meteor speed (can increase for later sectors)
            size = 20 -- Meteor radius (can vary for difficulty)
        }}
    },
    sector_07 = {
        id = "sector_07",
        name = "Chromium Wastes",
        description = "Dark asteroids bearing chromium oxides and cobalt deposits drift through this hazardous mining zone.",
        obstacle = "Meteor Shower - Multiple meteors (2-3) appear with varied timing, requiring careful attention to surroundings.",
        asteroidTypes = {"chromium_oxides", "cobalt"},
        spawnRate = 1.0,
        unlock_cost = 10000, -- Cost to unlock this sector
        fuel_cost = 7, -- Fuel cost to travel to this sector
        planetImage = "sprites/planets/Planet-Paradise_80x80.png", -- Background planet sprite
        obstacles = {{
            type = "meteor",
            count = 3,
            spawnInterval = 0,
            speed = 180, -- Faster than Sector 6
            size = 18 -- Slightly smaller, more challenging
        }}
    },
    sector_08 = {
        id = "sector_08",
        name = "Titanium Reaches",
        description = "Valuable titanium oxide asteroids cluster alongside rare earth deposits in this contested sector.",
        obstacle = "Meteor Storm in Nebula - Combined challenge of meteor shower and cosmic dust reducing visibility. Navigate with extreme caution.",
        asteroidTypes = {"titanium_oxides", "rare_earths"},
        spawnRate = 1.0,
        unlock_cost = 22000, -- Cost to unlock this sector
        fuel_cost = 8, -- Fuel cost to travel to this sector
        planetImage = "sprites/planets/Planet-Slso_80x80.png", -- Background planet sprite
        obstacles = {{
            type = "cosmic_dust",
            count = 1,
            spawnInterval = 0,
            obscurity = 0.8 -- Heavy dust for reduced visibility
        }, {
            type = "meteor",
            count = 4,
            spawnInterval = 0,
            speed = 200, -- Faster than Sector 7
            size = 16 -- Smaller, more dangerous
        }}
    },
    sector_09 = {
        id = "sector_09",
        name = "Platinum Verge",
        description = "The crown jewel of mining territories. Platinum group metals and gold asteroids drift in dangerous proximity.",
        obstacle = "Black Hole (BOSS) - A slowly moving black hole with gravitational pull. Touching the center ends mining with all asteroids lost!",
        asteroidTypes = {"platinum_group", "gold"},
        spawnRate = 1.0,
        unlock_cost = 40000, -- Cost to unlock this sector
        fuel_cost = 9, -- Fuel cost to travel to this sector
        planetImage = "sprites/planets/Planet-VelvetCherry_80x80.png", -- Background planet sprite
        obstacles = {{
            type = "black_hole",
            count = 1,
            spawnInterval = 0,
            size = 30, -- Visual radius of black hole
            dangerRadius = 20, -- Instant death zone radius
            gravityRadius = 240, -- How far gravity reaches
            gravityStrength = 28, -- Pull force (lower = weaker pull)
            moveSpeed = 20 -- Movement speed (lower = slower, easier)
        }}
    },
    sector_10 = {
        id = "sector_10",
        name = "Genesis Cluster",
        description = "The rarest sector in known space. Microdiamonds and organic amino acid asteroids hold mysteries of cosmic origins.",
        obstacle = "Chaos Zone - A random mix of 3-5 hazards creates unpredictable mining conditions. Every session is different!",
        asteroidTypes = {"microdiamonds", "amino_acids"},
        spawnRate = 1.0,
        unlock_cost = 1000000, -- Cost to unlock this sector
        fuel_cost = 10, -- Fuel cost to travel to this sector
        planetImage = "sprites/planets/Planet-Twilight_80x80.png", -- Background planet sprite
        randomObstacles = {
            enabled = true,
            minCount = 2, -- Minimum number of random obstacles (adjustable for balance)
            maxCount = 5, -- Maximum number of random obstacles (adjustable for balance)
            pool = {{
                type = "solar_flare",
                count = 2,
                spawnInterval = 0
            }, {
                type = "cosmic_dust",
                count = 1,
                spawnInterval = 0,
                obscurity = 0.7
            }, {
                type = "space_debris",
                count = 3,
                spawnInterval = 0,
                movementSpeed = 0
            }, {
                type = "meteor",
                count = 2,
                spawnInterval = 0,
                speed = 180,
                size = 18
            }, {
                type = "black_hole",
                count = 1,
                spawnInterval = 0,
                size = 30,
                dangerRadius = 20,
                gravityRadius = 240,
                gravityStrength = 28,
                moveSpeed = 20
            }}
        }
    }
}

return Sector
