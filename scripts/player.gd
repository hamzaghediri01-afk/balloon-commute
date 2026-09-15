class_name Player
extends RigidBody2D
## Player Controller for "Balloon Commute".
## Represents a commuter character suspended by a cluster of up to 4 balloons.
## Handles physics integration (lift, upright torque, steering impulses) and collision hurtbox.

signal balloon_count_changed(active_count: int, max_count: int)
signal balloon_popped(balloon: Balloon, remaining_count: int)
signal balloon_replenished(balloon: Balloon, remaining_count: int)
signal all_balloons_lost
signal hazard_collided(hazard: Area2D)
signal collectible_collected(collectible: Area2D)

const MAX_BALLOONS: int = 4

# Physics tuning
@export_group("Balloon Physics")
@export var lift_force_per_balloon: float = 380.0
@export var upright_spring_stiffness: float = 450.0
@export var upright_damping: float = 35.0
@export var max_upward_velocity: float = 450.0
@export var max_fall_velocity: float = 900.0
@export var max_horizontal_velocity: float = 350.0

@export_group("Steering Impulses")
@export var pop_angular_impulse: float = 75.0
@export var pop_horizontal_impulse: float = 140.0
@export var pop_lift_puff: float = 80.0

@export_group("Balloon Offsets")
# Offsets relative to center of mass (X: left/right spread, Y: balloon height above player)
@export var balloon_offsets: Array[Vector2] = [
	Vector2(-52.0, -78.0), # Index 0: Far Left
	Vector2(-18.0, -96.0), # Index 1: Mid Left
	Vector2(18.0, -96.0),  # Index 2: Mid Right
	Vector2(52.0, -78.0)   # Index 3: Far Right
]

@export var balloon_palette: Array[Color] = [
	Color(0.96, 0.26, 0.21), # Red
	Color(1.00, 0.76, 0.03), # Gold
	Color(0.13, 0.59, 0.95), # Blue
	Color(0.61, 0.15, 0.69)  # Purple
]

# State
var balloons: Array[Balloon] = []
var is_freefalling: bool = false
var is_alive: bool = true

@onready var hurtbox: Area2D = $Hurtbox
@onready var balloon_container: Node2D = $Balloons

func _ready() -> void:
	# Configure rigid body properties
	gravity_scale = 1.0
	linear_damp = 1.2
	angular_damp = 2.0
	collision_layer = CollisionLayers.MASK_WORLD_PHYSICS
	collision_mask = CollisionLayers.MASK_WORLD_PHYSICS
	
	_setup_balloons()
	_setup_hurtbox()

func _setup_balloons() -> void:
	balloons.clear()
	for i in range(MAX_BALLOONS):
		var balloon := Balloon.new()
		balloon.name = "Balloon_%d" % i
		balloon_container.add_child(balloon)
		balloon.initialize(balloon_offsets[i], balloon_palette[i % balloon_palette.size()])
		balloons.append(balloon)
	
	balloon_count_changed.emit(get_active_balloon_count(), MAX_BALLOONS)

func _setup_hurtbox() -> void:
	if not hurtbox:
		return
	
	# Hurtbox monitors Hazards (layer 3) and Collectibles (layer 4)
	hurtbox.collision_layer = CollisionLayers.MASK_PLAYER_HURTBOX
	hurtbox.collision_mask = CollisionLayers.MASK_HAZARDS | CollisionLayers.MASK_COLLECTIBLES | CollisionLayers.MASK_KILL_ZONE
	
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if not is_alive:
		return
	
	var active_count := get_active_balloon_count()
	
	# 1. Apply upward lift force per active balloon at its local attachment point
	for balloon in balloons:
		if balloon.is_active:
			# Calculate the offset rotated into world space
			var world_offset := balloon.target_offset.rotated(rotation)
			# Apply upward force at the balloon's lateral offset (generates natural tilting physics)
			state.apply_force(Vector2.UP * lift_force_per_balloon, world_offset)
	
	# 2. Upright stabilization torque (spring-damper to keep character mostly upright)
	if active_count > 0:
		var current_angle := rotation
		var angular_vel := state.angular_velocity
		var upright_torque := (-current_angle * upright_spring_stiffness) - (angular_vel * upright_damping)
		state.apply_torque(upright_torque)
	
	# 3. Clamp linear velocities for stable runner physics
	var vel := state.linear_velocity
	vel.x = clampf(vel.x, -max_horizontal_velocity, max_horizontal_velocity)
	# Godot 2D: -Y is upward, +Y is downward
	vel.y = clampf(vel.y, -max_upward_velocity, max_fall_velocity)
	state.linear_velocity = vel

## Pops the leftmost active balloon and applies a steer-right impulse
func pop_leftmost() -> bool:
	if not is_alive:
		return false
	
	var leftmost: Balloon = null
	var min_x: float = INF
	
	for balloon in balloons:
		if balloon.is_active and balloon.target_offset.x < min_x:
			min_x = balloon.target_offset.x
			leftmost = balloon
	
	if leftmost:
		leftmost.pop()
		# Steering right: positive clockwise angular impulse + rightward linear force
		apply_torque_impulse(pop_angular_impulse)
		apply_central_impulse(Vector2(pop_horizontal_impulse, -pop_lift_puff))
		_on_balloon_state_updated(leftmost, false)
		return true
	return false

## Pops the rightmost active balloon and applies a steer-left impulse
func pop_rightmost() -> bool:
	if not is_alive:
		return false
	
	var rightmost: Balloon = null
	var max_x: float = -INF
	
	for balloon in balloons:
		if balloon.is_active and balloon.target_offset.x > max_x:
			max_x = balloon.target_offset.x
			rightmost = balloon
	
	if rightmost:
		rightmost.pop()
		# Steering left: negative counter-clockwise angular impulse + leftward linear force
		apply_torque_impulse(-pop_angular_impulse)
		apply_central_impulse(Vector2(-pop_horizontal_impulse, -pop_lift_puff))
		_on_balloon_state_updated(rightmost, false)
		return true
	return false

## Restores one popped balloon (replenish up to MAX_BALLOONS). Returns true if restored.
func add_balloon() -> bool:
	if not is_alive or get_active_balloon_count() >= MAX_BALLOONS:
		return false
	
	# Prioritize restoring inner balloons first, then outer to maintain balanced lift
	var restore_order: Array[int] = [1, 2, 0, 3]
	for idx in restore_order:
		if not balloons[idx].is_active:
			balloons[idx].restore()
			_on_balloon_state_updated(balloons[idx], true)
			return true
	
	return false

func get_active_balloon_count() -> int:
	var count: int = 0
	for balloon in balloons:
		if balloon.is_active:
			count += 1
	return count

func _on_balloon_state_updated(balloon: Balloon, was_added: bool) -> void:
	var count := get_active_balloon_count()
	balloon_count_changed.emit(count, MAX_BALLOONS)
	
	if was_added:
		balloon_replenished.emit(balloon, count)
		is_freefalling = false
	else:
		balloon_popped.emit(balloon, count)
		if count <= 0 and not is_freefalling:
			is_freefalling = true
			all_balloons_lost.emit()

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not is_alive:
		return
	
	# Check layer bits
	if area.collision_layer & CollisionLayers.MASK_HAZARDS:
		hazard_collided.emit(area)
	elif area.collision_layer & CollisionLayers.MASK_COLLECTIBLES:
		collectible_collected.emit(area)
	elif area.collision_layer & CollisionLayers.MASK_KILL_ZONE:
		hazard_collided.emit(area)

func kill() -> void:
	is_alive = false
	is_freefalling = true
	# Pop all remaining balloons on death
	for balloon in balloons:
		if balloon.is_active:
			balloon.pop()
