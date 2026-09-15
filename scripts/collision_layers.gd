class_name CollisionLayers
extends RefCounted
## Centralized collision layer and bitmask definitions for "Balloon Commute".
## Godot 4 uses 1-based indices in Project Settings and bitmasks (1 << (index - 1)) in code.

# Layer Indices (1-based, matches Project Settings -> Layer Names -> 2D Physics)
const LAYER_WORLD_PHYSICS: int = 1
const LAYER_PLAYER_HURTBOX: int = 2
const LAYER_HAZARDS: int = 3
const LAYER_COLLECTIBLES: int = 4
const LAYER_KILL_ZONE: int = 5

# Bitmasks (Values applied to collision_layer and collision_mask properties)
const MASK_WORLD_PHYSICS: int = 1 << (LAYER_WORLD_PHYSICS - 1)   # 1  (Bit 0)
const MASK_PLAYER_HURTBOX: int = 1 << (LAYER_PLAYER_HURTBOX - 1) # 2  (Bit 1)
const MASK_HAZARDS: int = 1 << (LAYER_HAZARDS - 1)               # 4  (Bit 2)
const MASK_COLLECTIBLES: int = 1 << (LAYER_COLLECTIBLES - 1)     # 8  (Bit 3)
const MASK_KILL_ZONE: int = 1 << (LAYER_KILL_ZONE - 1)           # 16 (Bit 4)
