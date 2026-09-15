class_name BaseHazard
extends Area2D
## Base class for all pooled hazards in "Balloon Commute".
## Handles collision setup, pool activation/deactivation, and off-screen recycling.

signal hazard_hit(player_hurtbox: Area2D)
signal recycled(hazard: BaseHazard)

var is_in_use: bool = false
var offscreen_despawn_y: float = INF

func _ready() -> void:
	collision_layer = CollisionLayers.MASK_HAZARDS
	collision_mask = CollisionLayers.MASK_PLAYER_HURTBOX
	area_entered.connect(_on_area_entered)
	# Start disabled in the pool
	deactivate()

func _on_area_entered(area: Area2D) -> void:
	if is_in_use and (area.collision_layer & CollisionLayers.MASK_PLAYER_HURTBOX):
		hazard_hit.emit(area)

## Called by ObjectPool when spawning
func activate(spawn_pos: Vector2, _params: Dictionary = {}) -> void:
	global_position = spawn_pos
	is_in_use = true
	visible = true
	set_process(true)
	set_physics_process(true)
	monitoring = true
	monitorable = true

## Called when recycled back into the pool
func deactivate() -> void:
	is_in_use = false
	visible = false
	set_process(false)
	set_physics_process(false)
	monitoring = false
	monitorable = false
	recycled.emit(self)

## Checked by spawner or process to cull hazards below the visible camera
func check_cull_distance(bottom_camera_y: float, buffer: float = 150.0) -> void:
	if is_in_use and global_position.y > bottom_camera_y + buffer:
		deactivate()
