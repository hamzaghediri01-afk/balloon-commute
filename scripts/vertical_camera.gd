class_name VerticalCamera
extends Camera2D
## Vertical scrolling camera that follows the player upward.
## Does not scroll backwards/downwards, creating high-tension vertical runner mechanics.
## Also maintains the bottom kill zone trigger.

signal kill_zone_reached(body: Node2D)

@export var target: Node2D
@export var smooth_speed: float = 6.0
@export var vertical_lead_offset: float = 120.0 # Distance ahead of the player to show
@export var kill_margin: float = 80.0          # Distance below visible screen for kill zone

var highest_y: float = 0.0
var is_active: bool = true

@onready var kill_zone: Area2D = $KillZone
@onready var kill_shape: CollisionShape2D = $KillZone/CollisionShape2D

func _ready() -> void:
	if target:
		highest_y = target.global_position.y
		global_position.y = highest_y - vertical_lead_offset
	
	_setup_kill_zone()

func _setup_kill_zone() -> void:
	if not kill_zone:
		return
	
	kill_zone.collision_layer = CollisionLayers.MASK_KILL_ZONE
	# Kill zone monitors Player Hurtbox (layer 2)
	kill_zone.collision_mask = CollisionLayers.MASK_PLAYER_HURTBOX

func _physics_process(delta: float) -> void:
	if not is_active or not is_instance_valid(target):
		return
	
	# Only scroll upward (negative Y in Godot)
	var target_y := target.global_position.y - vertical_lead_offset
	if target_y < highest_y:
		highest_y = target_y
	
	# Smoothly interpolate towards highest reached altitude
	global_position.y = lerpf(global_position.y, highest_y, smooth_speed * delta)
	
	# Keep horizontal position centered or slightly following
	global_position.x = lerpf(global_position.x, target.global_position.x * 0.3, smooth_speed * 0.5 * delta)
	
	# Update kill zone position to stay pinned to the bottom of the camera view
	_update_kill_zone_position()

func _update_kill_zone_position() -> void:
	if not kill_zone:
		return
	
	var half_height := (get_viewport_rect().size.y * 0.5) * (1.0 / zoom.y)
	kill_zone.global_position = Vector2(global_position.x, global_position.y + half_height + kill_margin)

## Returns the top Y coordinate currently visible to the camera in world space
func get_top_visible_y() -> float:
	var half_height := (get_viewport_rect().size.y * 0.5) * (1.0 / zoom.y)
	return global_position.y - half_height

## Returns the bottom Y coordinate currently visible to the camera in world space
func get_bottom_visible_y() -> float:
	var half_height := (get_viewport_rect().size.y * 0.5) * (1.0 / zoom.y)
	return global_position.y + half_height
