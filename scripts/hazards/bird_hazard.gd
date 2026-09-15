class_name BirdHazard
extends BaseHazard
## Hazard 1: Flying Bird.
## Traverses horizontally across the screen with wing flapping animation.

@export var fly_speed: float = 180.0
@export var horizontal_bounds: float = 400.0 # Screen half-width + margin

var direction: float = 1.0 # 1.0 = Right, -1.0 = Left
var flap_timer: float = 0.0
var flap_speed: float = 12.0
var wing_angle: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	super._ready()
	# Ensure collision shape exists if created dynamically
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 16.0
		collision_shape.shape = circle
		add_child(collision_shape)

func activate(spawn_pos: Vector2, params: Dictionary = {}) -> void:
	super.activate(spawn_pos, params)
	# Randomize direction: 1 = left to right, -1 = right to left
	direction = params.get("direction", 1.0 if randf() > 0.5 else -1.0)
	fly_speed = params.get("speed", randf_range(140.0, 240.0))
	flap_timer = randf() * TAU

func _physics_process(delta: float) -> void:
	if not is_in_use:
		return
	
	# Horizontal movement
	position.x += direction * fly_speed * delta
	
	# Gentle vertical sine bobbing
	position.y += sin(flap_timer * 0.5) * 0.6
	
	# Flap cycle
	flap_timer += delta * flap_speed
	wing_angle = sin(flap_timer) * 0.4
	
	# Reverse direction if hitting horizontal boundaries
	if direction > 0 and position.x > horizontal_bounds:
		direction = -1.0
	elif direction < 0 and position.x < -horizontal_bounds:
		direction = 1.0
	
	queue_redraw()

func _draw() -> void:
	if not is_in_use:
		return
	
	var bird_color := Color(0.2, 0.2, 0.25)
	var beak_color := Color(0.95, 0.65, 0.1)
	
	# Bird body
	draw_circle(Vector2.ZERO, 12.0, bird_color)
	
	# Beak pointing towards movement direction
	var beak_tip := Vector2(direction * 18.0, 0)
	var beak_top := Vector2(direction * 10.0, -4)
	var beak_bot := Vector2(direction * 10.0, 4)
	draw_colored_polygon(PackedVector2Array([beak_top, beak_tip, beak_bot]), beak_color)
	
	# Flapping wings
	var wing_y := sin(flap_timer) * 14.0
	var wing_poly := PackedVector2Array([
		Vector2(-direction * 2, -4),
		Vector2(-direction * 14, wing_y - 8),
		Vector2(-direction * 8, 2)
	])
	draw_colored_polygon(wing_poly, bird_color.lightened(0.15))
	
	# Eye
	var eye_pos := Vector2(direction * 6, -3)
	draw_circle(eye_pos, 2.5, Color.WHITE)
	draw_circle(eye_pos + Vector2(direction * 0.5, 0), 1.2, Color.BLACK)
