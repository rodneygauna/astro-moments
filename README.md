# 🚀 Astro Moments

> **Codedex 2025 Game Jam Entry**

A cozy space mining microgame where every minute counts! Collect as many asteroids as possible within the time limit, earn currency, and upgrade your spaceship to become the ultimate miner.

![Game Status](https://img.shields.io/badge/status-in%20development-yellow)
![Love2D](https://img.shields.io/badge/LÖVE-11.5-EA316E)
![Lua](https://img.shields.io/badge/Lua-5.1-blue)

## 🎮 Game Overview

Navigate your tiny spaceship through the depths of space, collecting asteroids with your collection field. The longer an asteroid stays within your field, the closer you are to collecting it! But be careful—asteroids can escape if they leave your radius, and your collection ability changes as you move.

### Core Gameplay Loop

1. **Mine** - Navigate your spaceship to collect drifting asteroids
2. **Earn** - Convert collected asteroids into currency
3. **Upgrade** - Improve your spaceship's speed, field radius, and collection abilities
4. **Repeat** - Collect even more asteroids in the next round!

## ✨ Features

- **Dynamic Physics-Based Movement** - Realistic spaceship controls with momentum and turning penalties
- **Collection Meter System** - Progressive asteroid collection with visual feedback
- **Smart Spawning** - Asteroids spawn dynamically with smooth ease-in animations
- **Upgrade System** - Enhance your spaceship's capabilities between rounds
- **Circular Play Area** - Navigate within a contained space sector
- **Camera Follow** - Smooth camera tracking for optimal gameplay

## 🕹️ How to Play

### Controls

- **W / Up Arrow** - Move forward
- **A / Left Arrow** - Move left
- **S / Down Arrow** - Move backward
- **D / Right Arrow** - Move right

### Tips

- Keep asteroids inside your cyan collection field to fill their meter
- Sharp turns slow you down—plan your movements!
- Moving reduces your collection radius, so stop to collect more efficiently
- Watch the collection meter above each asteroid to track your progress

## 🚀 Getting Started

### Prerequisites

- [LÖVE 2D](https://love2d.org/) (version 11.5 or higher)

### Installation & Running

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

## 🛠️ Built With

### Core Technologies

- **[Lua](https://www.lua.org/)** - Programming language
- **[LÖVE 2D](https://love2d.org/)** - Game framework
- **[Aseprite](https://www.aseprite.org/)** - Pixel art creation

### Libraries

- **[HUMP](https://github.com/vrld/hump)** - Camera system and helper utilities

## 📋 Development Roadmap

### Implemented ✅

- [x] Basic spaceship movement with physics
- [x] Asteroid spawning and behavior
- [x] Collection field system
- [x] Progressive collection meter
- [x] Circular playable area
- [x] Dynamic spawn animations
- [x] Camera following

### In Progress 🚧

- [ ] Round timer system
- [ ] Currency and scoring
- [ ] Upgrade system
- [ ] Game state management (menu, gameplay, upgrades)

### Planned 📝

- [ ] Multiple asteroid types and rarities
- [ ] Sprites and animations
- [ ] Sound effects and music
- [ ] Save/load functionality
- [ ] Particle effects
- [ ] Polish and balancing
- [ ] Multiple space sectors

## 📁 Project Structure

```text
astro-moments/
├── main.lua              # Main game file
├── libs/                 # External libraries
│   └── hump/            # Camera and utility library
├── docs/                # Documentation
│   ├── MINNOW_MINUTES_GAME_DESIGN_DOCUMENT.md
│   └── EPICS_AND_USER_STORIES.md
└── README.md            # You are here!
```

## 🎨 Game Design

For detailed game design documentation, see:

- [Game Design Document](docs/ASTRO_MOMENTS_GAME_DESIGN_DOCUMENT.md)

## 🤝 Contributing

This is a game jam project, but feedback and suggestions are welcome! Feel free to open an issue or reach out.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Codedex** - For hosting the 2025 Game Jam
- **LÖVE Community** - For the amazing game framework
- **HUMP Library** - For making camera work seamless

---

Made with ❤️ for the Codedex 2025 Game Jam
