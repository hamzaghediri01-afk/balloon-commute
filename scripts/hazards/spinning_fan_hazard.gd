class_name SpinningFanHazard
extends BaseHazard
## Hazard 3: Spinning Ceiling Fan.
## Continuously rotates industrial blades around a central mounting hub.

@export var rotation_speed: float = 2.8
@export var blade_count: int = 3
@export var blade_length: float = 65.0
@export var blade_width: float = 14.0

var current_rotation: float = 0.0
var rotation_direction: float = 1.0

var collision_shapes: Array[CollisionShape2D] = []

func _ready() -> void:
	super._ready()
	_generate_blade_colliders()

func _generate_blade_colliders() -> void:
	# Clear any previous generated shapes
	for shape in collision_shapes:
		if is_instance_valid(shape):
			shape.queue_free()
	collision_shapes.clear()
	
	var angle_step := TAU / float(blade_count)
	for i in range(blade_count):
		var blade_angle := angle_step * float(i)
		var col := CollisionShape2D.new()
		col.name = "Blade_%d" % i
		var rect := RectangleShape2D.new()
		rect.size = Vector2(blade_length, blade_width)
		col.shape = rect
		# Position center of the blade outward along the angle
		var center_offset := blade_length * 0.5
		col.position = Vector2(cos(blade_angle), sin(blade_angle)) * center_offset
		col.rotation = blade_angle
		add_child(col)
		collision_shapes.append(col)

func activate(spawn_pos: Vector2, params: Dictionary = {}) -> void:
	super.activate(spawn_pos, params)
	rotation_direction = params.get("direction", 1.0 if randf() > 0.5 else -1.0)
	rotation_speed = params.get("speed", randf_range(2.0, 3.6))
	current_rotation = randf() * TAU
	rotation = current_rotation

func _physics_process(delta: float) -> void:
	if not is_in_use:
		return
	
	current_rotation += rotation_direction * rotation_speed * delta
	rotation = current_rotation
	queue_redraw()

func _draw() -> void:
	if not is_in_use:
		return
	
	var hub_color := Color(0.3, 0.32, 0.35)
	var blade_color := Color(0.45, 0.48, 0.52)
	var blade_edge_color := Color(0.85, 0.2, 0.2) # Hazard warning stripes
	
	var angle_step := TAU / float(blade_count)
	for i in range(blade_count):
		var angle := angle_step * float(i)
		var dir := Vector2(cos(angle), sin(angle))
		var norm := Vector2(-sin(angle), cos(angle))
		
		var p1 := norm * (blade_width * 0.5)
		var p2 := dir * blade_length + norm * (blade_width * 0.4)
		var p3 := dir * blade_length - norm * (blade_width * 0.4)
		var p4 := -norm * (blade_width * 0.5)
		
		# Draw blade body
		draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), blade_color)
		
		# Draw hazard warning tip
		var tip1 := dir * (blade_length - 8.0) + norm * (blade_width * 0.4)
		var tip2 := dir * (blade_length - 8.0) - norm * (blade_width * 0.4)
		draw_colored_polygon(PackedVector2Array([tip1, p2, p3, tip2]), blade_edge_color)
	
	# Center Hub & mounting nut
	draw_circle(Vector2.ZERO, 16.0, hub_color)
	draw_circle(Vector2.ZERO, 7.0, hub_color.darkened(0.3))
	draw_circle(Vector2.ZERO, 3.0, Color.GOLD)
