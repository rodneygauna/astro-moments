# Minnow Minutes

> **Codedex 2025 Game Jam Entry**

A cozy action fishing microgame where every minute counts! Catch as many fish as possible within the time limit, earn currency, and upgrade your boat to become the ultimate fisher.

![Game Status](https://img.shields.io/badge/status-in%20development-yellow)
![Love2D](https://img.shields.io/badge/LÖVE-11.5-EA316E)
![Lua](https://img.shields.io/badge/Lua-5.1-blue)

## 🎮 Game Overview

Navigate your tiny boat through peaceful waters, catching fish with your capture ring. The longer a fish stays within your ring, the closer you are to catching it! But be careful—fish can escape if they leave your radius, and your catching ability changes as you move.

### Core Gameplay Loop

1. **Fish** - Navigate your boat to catch swimming fish
2. **Earn** - Convert caught fish into currency
3. **Upgrade** - Improve your boat's speed, radius, and capture abilities
4. **Repeat** - Catch even more fish in the next round!

## ✨ Features

- **Dynamic Physics-Based Movement** - Realistic boat controls with momentum and turning penalties
- **Capture Meter System** - Progressive fish catching with visual feedback
- **Smart Spawning** - Fish spawn dynamically with smooth ease-in animations
- **Upgrade System** - Enhance your boat's capabilities between rounds
- **Circular Play Area** - Navigate within a contained aquatic zone
- **Camera Follow** - Smooth camera tracking for optimal gameplay

## 🕹️ How to Play

### Controls

- **W / Up Arrow** - Move forward
- **A / Left Arrow** - Move left
- **S / Down Arrow** - Move backward
- **D / Right Arrow** - Move right

### Tips

- Keep fish inside your red capture ring to fill their meter
- Sharp turns slow you down—plan your movements!
- Moving reduces your capture radius, so stop to catch more efficiently
- Watch the capture meter above each fish to track your progress

## 🚀 Getting Started

### Prerequisites

- [LÖVE 2D](https://love2d.org/) (version 11.5 or higher)

### Installation & Running

1. **Clone the repository**

   ```bash
   git clone https://github.com/rodneygauna/minnow-minutes.git
   cd minnow-minutes
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

- [x] Basic boat movement with physics
- [x] Fish spawning and AI
- [x] Capture circle system
- [x] Progressive capture meter
- [x] Circular playable area
- [x] Dynamic spawn animations
- [x] Camera following

### In Progress 🚧

- [ ] Round timer system
- [ ] Currency and scoring
- [ ] Upgrade system
- [ ] Game state management (menu, gameplay, upgrades)

### Planned 📝

- [ ] Multiple fish types and rarities
- [ ] Sprites and animations
- [ ] Sound effects and music
- [ ] Save/load functionality
- [ ] Particle effects
- [ ] Polish and balancing
- [ ] Multiple zones/levels

## 📁 Project Structure

```text
minnow-minutes/
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

- [Game Design Document](docs/MINNOW_MINUTES_GAME_DESIGN_DOCUMENT.md)

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
