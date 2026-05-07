# GoBuyPandaChronicle Chapter 1

A retro-style 2D space shooter game built with Godot 4.

## Screenshots

![Gameplay](docs/screenshots/gameplay.png)

## Game Features

- Classic 8-bit space shooter gameplay
- Three enemy types: Basic Drone, Sweeper, and Chaser
- Score and lives system
- Pixel-perfect rendering with CRT-style visual effects

## Controls

| Action | Keys |
|--------|------|
| Move | Arrow Keys / WASD |
| Shoot | Spacebar |

## How to Run

1. Open the project in Godot 4.x
2. Press F5 or click "Run" to start

## Project Structure

```
.
├── player.gd         # Player ship logic
├── enemy.gd         # Enemy AI and behavior
├── bullet.gd        # Bullet mechanics
├── main.gd          # Game flow and spawning
├── hud.gd           # UI display
├── *.tscn           # Godot scenes
├── *.png            # Game sprites
└── project.godot   # Project configuration
```

## License

MIT