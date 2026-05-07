# 8-Bit Space Shooter - Godot Game

## Project Overview
- **Project Name**: Retro Space Shooter
- **Type**: 2D pixel-art arcade shooter game
- **Core Functionality**: Classic 8-bit style space shooter where player controls a spaceship, shoots enemies, and scores points
- **Target Users**: Retro game enthusiasts, casual gamers

## UI/UX Specification

### Visual Design

**Color Palette**
- Background: Deep space black `#0a0a0f`
- Stars: White `#ffffff`, Dim white `#666666`
- Player ship: Cyan accent `#00ffff`, Dark gray `#333344`
- Enemies: Red `#ff3333`, Orange `#ff6600`
- Bullets: Yellow `#ffff00`, Cyan `#00ffff`
- UI Text: Bright green `#00ff00`
- UI Background: Dark purple `#1a0a2e`

**Typography**
- Pixel-style bitmap font (Godot default font with pixel settings)
- Score display: 16px
- Game over text: 32px

**Visual Effects**
- Scanline overlay effect for CRT feel
- Pixel-perfect rendering (nearest neighbor filtering)
- Screen shake on player hit
- Explosion particles (simple pixel squares)
- Bullet trails with slight glow

### Layout Structure
- Game viewport: 320x180 (16:9 pixel-perfect)
- HUD: Top-left corner for score, top-right for lives
- Centered start screen with "PRESS SPACE" prompt
- Game over screen with final score and restart option

### Components

**Player Ship**
- 16x16 pixel sprite
- Simple geometric shape (triangle/arrow pointing up)
- Cyan highlight on edges
- Thruster flame animation (2 frames)

**Enemies**
- 12x12 pixel sprites
- 3 types:
  1. Basic drone (red, moves straight down)
  2. Sweeper (orange, sine wave movement)
  3. Chaser (purple, follows player slowly)

**Bullets**
- Player: 4x8 pixel, yellow with cyan glow
- Enemy: 4x4 pixel, red

**Explosions**
- 8-frame animation
- Expanding pixel squares in orange/yellow

## Functionality Specification

### Core Features

**Player Controls**
- Arrow keys OR WASD for movement
- Spacebar to shoot
- Player bounded to screen area

**Shooting Mechanics**
- Player fires single bullet
- Fire rate: 3 bullets per second max
- Bullets travel upward at 300 pixels/second

**Enemy Behavior**
- Spawn from top of screen at random X positions
- Spawn rate increases over time (starts at 1 per 2 seconds, increases to 1 per 0.5 seconds)
- Different movement patterns per enemy type

**Collision System**
- Player bullet hits enemy: Enemy dies, +10 points
- Enemy hits player: Player loses 1 life, brief invincibility (2 seconds)
- Enemy bullet hits player: Player loses 1 life

**Scoring**
- Basic enemy: 10 points
- Sweeper enemy: 25 points
- Chaser enemy: 50 points

**Lives System**
- Start with 3 lives
- Game over when lives reach 0

### User Interactions
1. Press SPACE on title screen to start
2. Move with arrow keys/WASD, shoot with SPACE
3. Press SPACE on game over to restart

### Edge Cases
- Pause not implemented (keep it simple)
- No continues (game over = restart)
- Bullets despawn when leaving screen

## Acceptance Criteria

1. ✓ Game starts with title screen showing "PRESS SPACE"
2. ✓ Player can move in all 4 directions within screen bounds
3. ✓ Player can shoot bullets that travel upward
4. ✓ Enemies spawn and move downward
5. ✓ Collisions register correctly (bullet-enemy, player-enemy, player-enemy-bullet)
6. ✓ Score increments correctly
7. ✓ Lives decrement on damage
8. ✓ Game over triggers at 0 lives
9. ✓ Game can be restarted
10. ✓ 8-bit visual aesthetic is achieved (pixel art, limited colors, scanlines)