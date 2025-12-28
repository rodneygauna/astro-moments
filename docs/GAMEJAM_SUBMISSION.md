# Astro Moments

## About This Game

**Astro Moments** is a relaxing yet engaging space mining microgame where every minute counts! Navigate your tiny spaceship through the depths of space, collecting drifting asteroids with your collection field. Earn currency, upgrade your ship, and unlock new sectors filled with escalating challenges in this cozy arcade-style experience.

Built for the **Codedex Winter 2025 Game Jam** using LÖVE 2D.

## Key Features

- **Dynamic Physics-Based Movement** - Realistic spaceship controls with momentum and turning penalties that make navigation feel weighty and satisfying
- **Progressive Collection System** - Watch asteroids fill up as they stay in your collection field, with visual feedback showing your progress
- **Persistent Upgrade System** - Enhance your spaceship's speed, collection radius, and efficiency between runs to tackle harder sectors
- **Strategic Buff Selection** - Choose temporary boosts before each mining session to optimize your strategy
- **10 Unique Sectors** - Progress through increasingly challenging environments with unique obstacles:
  - Solar flares
  - Cosmic dust clouds
  - Space debris fields
  - Meteor showers
  - Black hole boss encounter
  - Chaotic final sector with randomized hazards
- **Save System** - Your progress, upgrades, and unlocked sectors persist between sessions
- **Retro Pixel Art** - Clean, handcrafted sprites with a nostalgic arcade aesthetic
- **Original Soundtrack** - AI-generated atmospheric space music to enhance the cozy mining experience

## Gameplay

### Core Loop

1. **Select Your Sector** - Choose from unlocked sectors, each with unique challenges
2. **Pick Your Buffs** - Select temporary enhancements to optimize your strategy
3. **Mine Asteroids** - Navigate your spaceship to collect drifting asteroids within the time limit
4. **Earn Currency** - Cash out your collected asteroids for gold
5. **Upgrade Your Ship** - Invest in permanent improvements to tackle harder sectors
6. **Unlock New Sectors** - Progress through increasingly challenging environments

### Controls

- **W / Up Arrow** - Move forward
- **A / Left Arrow** - Move left
- **S / Down Arrow** - Move backward
- **D / Right Arrow** - Move right

### Strategy Tips

- **Stop to collect faster** - Moving reduces your collection radius
- **Plan your route** - Sharp turns slow you down, so think ahead
- **Watch the meters** - Keep asteroids in your field until their collection meter fills
- **Balance upgrades** - Speed, radius, and collection rate all matter

## Technical Details

### Built With

- **Engine**: LÖVE 2D 11.5
- **Language**: Lua 5.1
- **Libraries**:
  - HUMP - Camera system and utilities
  - dkjson - JSON save system
- **Art**: Aseprite pixel art
- **Music**: AI-generated tracks via Suno

### Platforms

- Windows (Standalone .exe)
- macOS (Native .app)
- Linux (.love file)

---

## Download & Play

### Pre-built Releases

Download the latest version for your platform:

**[Download from GitHub Releases](https://github.com/rodneygauna/astro-moments/releases)**

#### Windows

1. Download `AstroMoments-[version]-Windows.zip`
2. Extract and run `AstroMoments.exe`
3. No installation required!

#### macOS

1. Download `AstroMoments-[version]-macOS.zip`
2. Extract and drag `AstroMoments.app` to Applications
3. Right-click → Open on first launch (if security warning appears)

#### Linux

1. Install LÖVE: `sudo apt install love` (or equivalent)
2. Download `AstroMoments-[version]-Linux.tar.gz`
3. Extract and run: `love AstroMoments.love`

## Development Journey

**Astro Moments** was created for the Codedex Winter 2025 Game Jam with the goal of building a cozy, accessible game that combines arcade action with progression systems.

### Design Philosophy

- **Short sessions, long-term progression** - Each mining run takes just a few minutes, but the upgrade and sector progression systems provide depth
- **Physics-based feel** - The spaceship movement adds weight and intentionality to player actions
- **Escalating challenge** - 10 handcrafted sectors introduce obstacles gradually, culminating in a boss fight and chaotic final sector
- **Cozy atmosphere** - Pixel art aesthetic and calming music create a relaxing experience despite the timer

### Challenges Overcome

- Balancing collection mechanics to feel fair but challenging
- Creating varied obstacles across sectors without overwhelming players
- Implementing a progressive economy that stays engaging across all 10 sectors
- Optimizing physics and collision detection for smooth 60 FPS gameplay

## Credits

**Developer**: Rodney Gauna
**GitHub**: [github.com/rodneygauna](https://github.com/rodneygauna)

### Special Thanks

- **Codedex** - For hosting the Winter 2025 Game Jam
- **LÖVE Community** - For the excellent game framework and helpful documentation
- **Font**: Press Start by Cody "Codeman38" Boisclair
- **Music**: AI-generated tracks via Suno

## Links

- **Play the Game**: [Download from Releases](https://github.com/rodneygauna/astro-moments/releases)
- **Source Code**: [GitHub Repository](https://github.com/rodneygauna/astro-moments)
- **Documentation**: [Game Design Document](https://github.com/rodneygauna/astro-moments/blob/main/docs/ASTRO_MOMENTS_GAME_DESIGN_DOCUMENT.md)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
