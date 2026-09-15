class_name Spawner
extends Node2D
## Procedural vertical spawner and object pool manager for hazards and collectibles.
## Generates hazards ahead of the player's upward ascent at procedural intervals
## and recycles off-screen objects to maintain zero-allocation gameplay.

enum HazardType {
	BIRD,
	POWER_LINE,
	FAN
}

@export_group("References")
@export var camera: VerticalCamera
@export var player: Player

@export_group("Spawning Parameters")
@export var spawn_ahead_distance: float = 900.0  # Distance above camera top to pre-generate
@export var min_vertical_interval: float = 180.0 # Min vertical gap between hazard waves
@export var max_vertical_interval: float = 280.0 # Max vertical gap
@export var collectible_chance: float = 0.35      # 35% chance to spawn a balloon pickup
@export var pool_size_per_type: int = 8

# Pools
var bird_pool: Array[BirdHazard] = []
var power_line_pool: Array[PowerLineHazard] = []
var fan_pool: Array[SpinningFanHazard] = []
var pickup_pool: Array[BalloonPickup] = []

# Spawning tracking
var highest_spawn_y: float = 0.0
var is_active: bool = true

func _ready() -> void:
	_initialize_pools()
	if player:
		# Start spawning slightly above the player's starting position
		highest_spawn_y = player.global_position.y - 300.0

func _initialize_pools() -> void:
	# 1. Bird Pool
	for i in range(pool_size_per_type):
		var bird := BirdHazard.new()
		bird.name = "Bird_%d" % i
		add_child(bird)
		bird_pool.append(bird)
	
	# 2. Power Line Pool
	for i in range(pool_size_per_type):
		var pl := PowerLineHazard.new()
		pl.name = "PowerLine_%d" % i
		add_child(pl)
		power_line_pool.append(pl)
	
	# 3. Spinning Fan Pool
	for i in range(pool_size_per_type):
		var fan := SpinningFanHazard.new()
		fan.name = "Fan_%d" % i
		add_child(fan)
		fan_pool.append(fan)
	
	# 4. Balloon Pickup Pool
	for i in range(pool_size_per_type):
		var pickup := BalloonPickup.new()
		pickup.name = "Pickup_%d" % i
		add_child(pickup)
		pickup_pool.append(pickup)

func _process(_delta: float) -> void:
	if not is_active or not camera:
		return
	
	_generate_ahead()
	_cull_offscreen()

func _generate_ahead() -> void:
	# Calculate target generation horizon ahead of the camera's upper view edge
	var horizon_y := camera.get_top_visible_y() - spawn_ahead_distance
	
	while highest_spawn_y > horizon_y:
		# Advance procedural altitude (Godot Y decreases going upward)
		var interval := randf_range(min_vertical_interval, max_vertical_interval)
		highest_spawn_y -= interval
		
		# Spawn hazard wave
		_spawn_random_hazard(highest_spawn_y)
		
		# Occasionally spawn a collectible balloon between waves
		if randf() < collectible_chance:
			var pickup_y := highest_spawn_y + (interval * 0.5)
			_spawn_collectible(pickup_y)

func _spawn_random_hazard(spawn_y: float) -> void:
	var roll := randf()
	
	if roll < 0.38:
		# Spawn flying bird across screen
		var bird := _get_available_bird()
		if bird:
			var direction := 1.0 if randf() > 0.5 else -1.0
			var start_x := -300.0 if direction > 0 else 300.0
			bird.activate(Vector2(start_x, spawn_y), {
				"direction": direction,
				"speed": randf_range(150.0, 230.0)
			})
	elif roll < 0.72:
		# Spawn static power line with navigation gap
		var pl := _get_available_power_line()
		if pl:
			pl.activate(Vector2(0, spawn_y), {
				"gap_x": randf_range(-140.0, 140.0)
			})
	else:
		# Spawn spinning ceiling fan
		var fan := _get_available_fan()
		if fan:
			var x_offset := randf_range(-160.0, 160.0)
			fan.activate(Vector2(x_offset, spawn_y), {
				"direction": 1.0 if randf() > 0.5 else -1.0,
				"speed": randf_range(2.0, 3.4)
			})

func _spawn_collectible(spawn_y: float) -> void:
	var pickup := _get_available_pickup()
	if pickup:
		var x_pos := randf_range(-180.0, 180.0)
		pickup.activate(Vector2(x_pos, spawn_y))

func _cull_offscreen() -> void:
	var bottom_cam_y := camera.get_bottom_visible_y()
	
	for bird in bird_pool:
		bird.check_cull_distance(bottom_cam_y)
	for pl in power_line_pool:
		pl.check_cull_distance(bottom_cam_y)
	for fan in fan_pool:
		fan.check_cull_distance(bottom_cam_y)
	for pickup in pickup_pool:
		pickup.check_cull_distance(bottom_cam_y)

# Helper pool fetchers (retrieves first inactive node or creates a fallback)
func _get_available_bird() -> BirdHazard:
	for b in bird_pool:
		if not b.is_in_use:
			return b
	return null

func _get_available_power_line() -> PowerLineHazard:
	for p in power_line_pool:
		if not p.is_in_use:
			return p
	return null

func _get_available_fan() -> SpinningFanHazard:
	for f in fan_pool:
		if not f.is_in_use:
			return f
	return null

func _get_available_pickup() -> BalloonPickup:
	for p in pickup_pool:
		if not p.is_in_use:
			return p
	return null

func reset() -> void:
	for b in bird_pool:
		b.deactivate()
	for p in power_line_pool:
		p.deactivate()
	for f in fan_pool:
		f.deactivate()
	for p in pickup_pool:
		p.deactivate()
	if player:
		highest_spawn_y = player.global_position.y - 300.0
