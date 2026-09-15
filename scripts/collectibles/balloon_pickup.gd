class_name BalloonPickup
extends Area2D
## Collectible Balloon Pickup that spawns along the vertical ascent.
## Replenishes lost balloons on the player (up to max capacity of 4).

signal collected(player: Player)
signal recycled(pickup: BalloonPickup)

@export var pickup_radius: float = 16.0
@export var float_amplitude: float = 8.0
@export var float_speed: float = 2.5
@export var pickup_color: Color = Color(0.15, 0.85, 0.35) # Bright green bonus balloon

var is_in_use: bool = false
var base_position: Vector2 = Vector2.ZERO
var anim_phase: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision_layer = CollisionLayers.MASK_COLLECTIBLES
	collision_mask = CollisionLayers.MASK_PLAYER_HURTBOX
	
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = pickup_radius + 4.0
		collision_shape.shape = circle
		add_child(collision_shape)
	
	area_entered.connect(_on_area_entered)
	deactivate()

func activate(spawn_pos: Vector2, _params: Dictionary = {}) -> void:
	base_position = spawn_pos
	global_position = spawn_pos
	is_in_use = true
	visible = true
	anim_phase = randf() * TAU
	scale = Vector2.ONE
	set_process(true)
	monitoring = true
	monitorable = true

func deactivate() -> void:
	is_in_use = false
	visible = false
	set_process(false)
	monitoring = false
	monitorable = false
	recycled.emit(self)

func _process(delta: float) -> void:
	if not is_in_use:
		return
	
	anim_phase += delta * float_speed
	position.y = base_position.y + sin(anim_phase) * float_amplitude
	position.x = base_position.x + cos(anim_phase * 0.7) * (float_amplitude * 0.4)
	queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	if not is_in_use:
		return
	
	var player := area.get_parent() as Player
	if player:
		# Attempt to replenish balloon
		var restored := player.add_balloon()
		if restored:
			collected.emit(player)
			_play_pickup_animation()

func _play_pickup_animation() -> void:
	# Quick burst pop & fade tween
	monitoring = false
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.25).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(Callable(self, "deactivate"))

func check_cull_distance(bottom_camera_y: float, buffer: float = 150.0) -> void:
	if is_in_use and global_position.y > bottom_camera_y + buffer:
		deactivate()

func _draw() -> void:
	if not is_in_use:
		return
	
	# Glowing aura ring
	var aura_alpha := 0.35 + 0.15 * sin(anim_phase * 2.0)
	draw_circle(Vector2.ZERO, pickup_radius * 1.35, Color(pickup_color.r, pickup_color.g, pickup_color.b, aura_alpha))
	
	# Balloon body
	draw_circle(Vector2(0, -pickup_radius * 0.2), pickup_radius, pickup_color)
	
	# Plus icon in the center indicating replenish
	var plus_color := Color.WHITE
	var pw := 3.0
	var pl := 7.0
	draw_line(Vector2(-pl, -pickup_radius * 0.2), Vector2(pl, -pickup_radius * 0.2), plus_color, pw)
	draw_line(Vector2(0, -pickup_radius * 0.2 - pl), Vector2(0, -pickup_radius * 0.2 + pl), plus_color, pw)
	
	# Highlight shine
	draw_circle(Vector2(-pickup_radius * 0.35, -pickup_radius * 0.5), pickup_radius * 0.25, Color(1, 1, 1, 0.6))
	
	# Knot
	var knot := PackedVector2Array([
		Vector2(-3, pickup_radius * 0.8),
		Vector2(3, pickup_radius * 0.8),
		Vector2(0, pickup_radius * 1.1)
	])
	draw_colored_polygon(knot, pickup_color.darkened(0.25))
