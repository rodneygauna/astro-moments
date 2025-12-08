# Astro Moments — Game Design Document (GDD)

## 0. Game Summary

Title: Astro Moments
Genre: Action Space Mining Microgame + Upgrade Loop
Engine: LÖVE (Love2D)
Theme: The player has a limited amount of time to mine as many asteroids as possible.
Core Loop: Play a timed mining round → Collect asteroids → Earn currency → Buy upgrades → Repeat.

## 1. Game Loop Overview

### 1.1 Macro Loop (Between Rounds)

- Player completes a timed round.
- Asteroids collected convert into currency.
- Player purchases upgrades.
- Player begins next round or unlocks the next sector.

### 1.2 Micro Loop (In-Round)

- Timer begins.
- Spaceship movement and asteroid spawning.
- Player collects asteroids by keeping them inside a collection field.
- Timer ends → Round summary → Upgrade menu.

## 2. Core Systems

### 2.1 Spaceship Movement

- Player moves using WASD or Arrow Keys.
- Speed and maneuverability upgradeable.

### 2.2 Asteroid Behavior

- Asteroids drift randomly through space.
- Each asteroid has:
  - Position
  - Speed
  - Value
  - Rarity
  - Collection meter (0–100)
- Asteroids spawn at intervals.

### 2.3 Collection Field System

- Player spaceship has a circular collection field.
- Asteroids inside field increase collection meter.
- Asteroids outside field decrease it.
- When meter reaches 100, asteroid is collected.

### 2.4 Timer System

- Default duration: 60 seconds.
- Countdown displayed during round.
- Round ends at 0.

### 2.5 Currency System

- Asteroids have set values.
- Total round currency = sum of asteroids collected.

### 2.6 Upgrades

Categories:

- Movement: speed, maneuverability
- Collection: field radius, collection speed, decay resistance
- Spawn: more asteroids, rarity chance
- Time: extra seconds, boost mode, time dilation ability

## 3. Space Sectors

### Sector 1: Asteroid Belt

- Slow, common asteroids.

### Sector 2: Debris Field

- Faster asteroids, more variety.

### Sector 3: Deep Space

- Rare high-value asteroids.

## 4. Game Flow

### Start Screen

- Start Game
- Upgrades (after first round)
- Quit

### Round Flow

1. Round starts
2. Timer begins
3. Player catches fish
4. Round ends
5. Summary + upgrades

### Upgrade Screen

- Displays currency
- Buttons for upgrades
- Unlock next zone

## 5. User Interface

### During Round

- Timer
- Asteroids collected counter
- Collection field
- Asteroid sprites

### Round Summary

- Asteroids collected list
- Total currency
- Continue button

## 6. Technical Implementation

### Data Structures

Spaceship:

```lua
spaceship = { x, y, speed, radius, collectionSpeed, decaySpeed }
```

Asteroid:

```lua
asteroid = { x, y, speed, value, rarity, collectionMeter }
```

Round:

```lua
round = { timer, asteroidList, spawnTimer }
```

Upgrades:

```lua
upgrades = { speed, radius, collectionSpeed, decay, spawnRate, rareChance, timeBonus }
```

### Distance Check

```lua
distance = math.sqrt((sx - ax)^2 + (sy - ay)^2)
if distance < radius then collectionMeter = collectionMeter + collectionSpeed * dt
else collectionMeter = collectionMeter - decaySpeed * dt
```

## 7. Audio

- Ambient space atmosphere
- Soft mining beam sound
- Chime on collection

## 8. Art Style

- Cozy, pastel space tones
- Simple asteroid sprites
- Soft particle effects

## 9. Balancing

- Early: 3–5 asteroids per round
- Mid: 8–12 asteroids
- Late: rare asteroid focus

## 10. Future Expansions

- Power-ups
- Boss asteroids
- Space hazards
- Endless mode

## 11. Game Jam MVP Scope

### Required

- Spaceship movement
- Asteroid movement
- Collection system
- Timer
- Summary screen
- Upgrades

### Optional

- Multiple sectors
- Sound
- Animations
