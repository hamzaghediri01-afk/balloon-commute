# 🎈 Balloon Commute

[![Build & Release Android APK](https://github.com/hamzaghediri01-afk/balloon-commute/actions/workflows/build-apk.yml/badge.svg)](https://github.com/hamzaghediri01-afk/balloon-commute/actions/workflows/build-apk.yml)
[![Direct APK Download](https://img.shields.io/badge/Download-Android%20APK-brightgreen?logo=android&logoColor=white)](https://github.com/hamzaghediri01-afk/balloon-commute/releases/latest/download/BalloonCommute.apk)

A 2D vertical physics endless runner built with **Godot 4** and **GDScript**.

Navigate your morning commute suspended by a delicate cluster of 4 balloons. Pop balloons strategically to steer through treacherous city airspace filled with pigeons, buzzing high-voltage power lines, and rooftop industrial fans—while catching bonus balloons to keep ascending!

---

## 🎮 Core Gameplay Loop

1. **Upward Float & Pendulum Physics**:
   - The player is a `RigidBody2D` hanging from 4 balloons.
   - Upward lift is continuously calculated based on the count of active balloons.
   - Off-center balloon forces naturally tilt and swing the commuter.
   - With 4 or 3 balloons, you climb upward. With 2 or 1, you slowly sink. With 0 balloons, you enter complete freefall!

2. **Touch Steering via Balloon Popping**:
   - **Tap Left Half of Screen**: Pops your leftmost balloon, imparting a sharp clockwise angular impulse that steers the commuter **right**.
   - **Tap Right Half of Screen**: Pops your rightmost balloon, imparting a counter-clockwise angular impulse that steers the commuter **left**.

3. **Procedural Hazards & Object Pooling**:
   - **Flying Birds**: Traverse horizontally across your flight path with animated wings.
   - **Static Power Lines**: High-voltage cables spanning the corridor with a designated navigation gap.
   - **Spinning Ceiling Fans**: Industrial multi-blade rotors that continuously sweep through airspace.
   - Zero garbage-collection stutter via pre-allocated object pools.

4. **Balloon Replenishment Pickups**:
   - Glowing collectible balloons spawn procedurally between hazard waves.
   - Touching a pickup restores one popped balloon (up to max 4), recovering your upward lift.

5. **Scoring**:
   - Score equals the maximum vertical altitude achieved in meters.
   - Persistent high score saved locally.

---

## 📲 Download & Install (Android APK)

Download the ready-to-install Android APK directly from the GitHub Releases page:

👉 **[Download BalloonCommute.apk](https://github.com/hamzaghediri01-afk/balloon-commute/releases/latest/download/BalloonCommute.apk)**

*(Or visit the [Releases page](https://github.com/hamzaghediri01-afk/balloon-commute/releases) to view all builds).*

---

## 🛠️ Collision Matrix

| Layer Index | Name | Bitmask | Purpose |
| :--- | :--- | :--- | :--- |
| **Layer 1** | `PlayerBody` | `1` (`1 << 0`) | Physical character `RigidBody2D` |
| **Layer 2** | `PlayerHurtbox` | `2` (`1 << 1`) | Character vulnerability & item collection `Area2D` |
| **Layer 3** | `Hazards` | `4` (`1 << 2`) | Birds, Power Lines, Ceiling Fans |
| **Layer 4** | `Collectibles` | `8` (`1 << 3`) | Replenishment Balloon pickups |
| **Layer 5** | `KillZone` | `16` (`1 << 4`) | Bottom viewport boundary attached to the camera |

---

## 📁 Repository Structure

```
balloon_commute/
├── .github/
│   └── workflows/
│       └── build-apk.yml          # Automated Godot 4.3 Android APK build & GitHub release
├── scenes/
│   └── main.tscn                  # Pre-wired main gameplay scene
├── scripts/
│   ├── collision_layers.gd        # Centralized collision layer constants
│   ├── balloon.gd                 # Balloon component & procedural rope/wobble drawing
│   ├── player.gd                  # RigidBody2D physics, lift, spring torque & steering impulses
│   ├── input_handler.gd           # Screen-space touch partition & keyboard fallbacks
│   ├── vertical_camera.gd         # Upward-only follower camera & bottom kill zone
│   ├── spawner.gd                 # Object pool manager & procedural wave generation
│   ├── game_manager.gd            # Altitude score tracking & game over orchestration
│   ├── hud.gd                     # CanvasLayer HUD, active balloon meter & game over screen
│   ├── hazards/
│   │   ├── base_hazard.gd         # Base pooled Area2D hazard class
│   │   ├── bird_hazard.gd         # Horizontal moving bird obstacle
│   │   ├── power_line_hazard.gd   # Static electric line with passage gap
│   │   └── spinning_fan_hazard.gd # Rotating multi-blade obstacle
│   └── collectibles/
│       └── balloon_pickup.gd      # Replenishment balloon collectible
├── export_presets.cfg             # Godot Android export preset configuration
├── project.godot                  # Engine configuration (viewport 540x960, collision layers)
└── README.md
```

---

## 🖥️ Running Locally in Godot 4

1. Clone this repository:
   ```bash
   git clone https://github.com/hamzaghediri01-afk/balloon-commute.git
   ```
2. Open **Godot Engine 4.3+**.
3. Click **Import** and select `project.godot`.
4. Press **F5** to run the game! (Use Left / Right Arrow keys or mouse clicks on the left/right halves of the window).
