# 🚀 Astro Moments

> **Codedex 2025 Game Jam Entry**

A cozy space mining microgame where every minute counts! Collect as many asteroids as possible within the time limit, earn currency, and upgrade your spaceship to become the ultimate miner.

![Game Status](https://img.shields.io/badge/status-in%20development-yellow)
![Love2D](https://img.shields.io/badge/LÖVE-11.5-EA316E)
![Lua](https://img.shields.io/badge/Lua-5.1-blue)

## Game Overview

Navigate your tiny spaceship through the depths of space, collecting asteroids with your collection field. The longer an asteroid stays within your field, the closer you are to collecting it! But be careful—asteroids can escape if they leave your radius, and your collection ability changes as you move.

### Core Gameplay Loop

1. **Mine** - Navigate your spaceship to collect drifting asteroids
2. **Earn** - Convert collected asteroids into currency
3. **Upgrade** - Improve your spaceship's speed, field radius, and collection abilities
4. **Repeat** - Collect even more asteroids in the next round!

## Features

- **Dynamic Physics-Based Movement** - Realistic spaceship controls with momentum and turning penalties
- **Collection Meter System** - Progressive asteroid collection with visual feedback
- **Smart Spawning** - Asteroids spawn dynamically with smooth ease-in animations
- **Upgrade System** - Enhance your spaceship's capabilities between rounds
- **Buff Selection** - Choose temporary boosts before each mining session
- **Progressive Sector System** - 10 unique sectors with escalating challenges
- **Environmental Obstacles** - Solar flares, cosmic dust, space debris, meteors, and a black hole boss
- **Random Obstacle Generation** - Final sector features unpredictable hazard combinations
- **Circular Play Area** - Navigate within a contained space sector
- **Camera Follow** - Smooth camera tracking for optimal gameplay
- **Save/Load System** - Persistent progress across play sessions
- **Customizable Settings** - Adjust resolution, fullscreen, vsync, and audio volume

## How to Play

### Controls

- **W / Up Arrow** - Move forward
- **A / Left Arrow** - Move left
- **S / Down Arrow** - Move backward
- **D / Right Arrow** - Move right

### Tips

- Keep asteroids inside your collection field to fill their meter
- Sharp turns slow you down—plan your movements!
- Moving reduces your collection radius, so stop to collect more efficiently
- Watch the collection meter above each asteroid to track your progress

## Getting Started

### For Players (Pre-built Releases)

Download the latest release for your platform from the [Releases page](https://github.com/rodneygauna/astro-moments/releases).

#### Windows

1. Download `AstroMoments-[version]-Windows.zip`
2. Extract the ZIP file to any folder
3. Double-click `AstroMoments.exe` to play
   - No installation required - it's a standalone executable
   - All dependencies included

#### macOS

1. Download `AstroMoments-[version]-macOS.zip`
2. Extract the ZIP file
3. Drag `AstroMoments.app` to your Applications folder (optional)
4. Double-click `AstroMoments.app` to play
   - First launch may show a security warning: Right-click → Open → Confirm

#### Linux

1. **Install LÖVE** from your package manager:

   ```bash
   # Debian/Ubuntu
   sudo apt install love

   # Arch
   sudo pacman -S love

   # Fedora
   sudo dnf install love
   ```

2. **Download and run**:

   ```bash
   # Download AstroMoments-[version]-Linux.tar.gz
   tar -xzf AstroMoments-*.tar.gz
   cd linux
   love AstroMoments.love
   ```

   Or double-click `AstroMoments.love` if file associations are set up.

### For Developers (Running from Source)

#### Prerequisites

- [LÖVE 2D](https://love2d.org/) (version 11.5 or higher)

#### Installation & Running

1. **Clone the repository**

   ```bash
   git clone https://github.com/rodneygauna/astro-moments.git
   cd astro-moments
   ```

2. **Run the game**

   ```bash
   love .
   ```

   Or drag the folder onto the LÖVE executable.

## Save Files

Your game progress and settings are automatically saved in JSON format, making them human-readable and easy to backup or transfer between systems.

### Player Progress

Your game progress is automatically saved when you:

- Complete a mining run and earn currency
- Purchase upgrades
- Unlock new sectors

### Game Settings

Your game settings are automatically saved when you:

- Adjust audio volume or mute music
- Change resolution or fullscreen mode
- Toggle vsync

### Save File Locations

Astro Moments uses LÖVE's filesystem, which stores files in platform-specific directories:

- **Linux**: `~/.local/share/love/astro-moments/`
- **Windows**: `%APPDATA%/LOVE/astro-moments/`
- **macOS**: `~/Library/Application Support/LOVE/astro-moments/`

Files stored:

- `player_save.json` - Player progress, currency, upgrades, and unlocked sectors
- `settings.json` - Video and audio settings

## Built With

### Core Technologies

- **[Lua](https://www.lua.org/)** - Programming language
- **[LÖVE 2D](https://love2d.org/)** - Game framework
- **[Aseprite](https://www.aseprite.org/)** - Pixel art creation
- **[Suno](https://suno.com/)** - AI-generated music tracks

### Libraries

- **[HUMP](https://github.com/vrld/hump)** - Camera system and helper utilities
- **[dkjson](https://github.com/LuaDist/dkjson)** - JSON encoding and decoding
- **[Press Start Font by Cody 'Codeman38' Boisclair](https://www.dafont.com/profile.php?user=155190)** - Font used for UI and text

## Sector Progression

Astro Moments features 10 unique sectors, each with escalating challenges and environmental obstacles:

1. **Asteroid Belt** - Tutorial sector with no obstacles
2. **Solar Flare Zones** - Harmless visual cues to teach awareness
3. **Cosmic Dust Cloud** - Reduced visibility challenge
4. **Debris Field** - Space junk obstacles that interrupt capture
5. **Combined Hazards** - Solar flares and space debris together
6. **Meteor Approach** - Single predictable meteor
7. **Meteor Shower** - Multiple meteors with varied timing
8. **Meteor Storm in Nebula** - Combined meteor shower and low visibility
9. **Black Hole (Boss)** - Gravitational pull affecting player and asteroids
10. **Chaos Zone** - Random mix of 3-5 hazards creating unpredictable challenges

The progression creates a balanced difficulty curve, culminating in a boss encounter followed by an ultimate chaos challenge where random obstacles create unpredictable and highly replayable scenarios.

## Project Structure

```text
astro-moments/
├── main.lua              # Main game file and state management
├── conf.lua              # LÖVE configuration
├── src/                  # Core game logic
│   ├── asteroid.lua     # Asteroid behavior and spawning
│   ├── buff.lua         # Buff system
│   ├── player.lua       # Player data management
│   ├── save.lua         # Save/load system
│   ├── sector.lua       # Sector definitions
│   ├── settings.lua     # Game settings
│   ├── spaceship.lua    # Spaceship physics and controls
│   └── upgrades.lua     # Upgrade system
├── screens/              # Game screens
│   ├── menu_screen.lua
│   ├── map_screen.lua
│   ├── mining_screen.lua
│   ├── buff_selection_screen.lua
│   ├── cashout_screen.lua
│   ├── upgrade_screen.lua
│   ├── settings_screen.lua
│   └── credits_screen.lua
├── libs/                 # External libraries
│   ├── hump/            # Camera and utility library
│   └── dkjson/          # JSON encoding/decoding
├── sprites/              # Game graphics
├── fonts/                # Font files
├── music/                # Game audio
├── docs/                 # Documentation
│   └── ASTRO_MOMENTS_GAME_DESIGN_DOCUMENT.md
└── README.md            # You are here!
```

## Game Design

For detailed game design documentation, see:

- [Game Design Document](docs/ASTRO_MOMENTS_GAME_DESIGN_DOCUMENT.md)

## Contributing

This is a game jam project, but feedback and suggestions are welcome! Feel free to open an issue or reach out.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- **Codedex** - For hosting the 2025 Game Jam
- **LÖVE Community** - For the amazing game framework
- **HUMP Library** - For making camera work seamless

---

Made with ❤️ for the Codedex 2025 Game Jam
