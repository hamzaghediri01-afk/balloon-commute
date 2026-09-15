class_name PowerLineHazard
extends BaseHazard
## Hazard 2: Static Power Line with a navigation gap.
## Features high-voltage cables and pulsing electrical sparks.
## Forces player to steer horizontally through the opening.

@export var total_width: float = 640.0
@export var gap_width: float = 120.0
@export var cable_thickness: float = 6.0
@export var spark_frequency: float = 8.0

var gap_center_x: float = 0.0
var spark_timer: float = 0.0

@onready var shape_left: CollisionShape2D = $ShapeLeft
@onready var shape_right: CollisionShape2D = $ShapeRight

func _ready() -> void:
	super._ready()
	_ensure_shapes_exist()

func _ensure_shapes_exist() -> void:
	if not shape_left:
		shape_left = CollisionShape2D.new()
		shape_left.name = "ShapeLeft"
		shape_left.shape = RectangleShape2D.new()
		add_child(shape_left)
	if not shape_right:
		shape_right = CollisionShape2D.new()
		shape_right.name = "ShapeRight"
		shape_right.shape = RectangleShape2D.new()
		add_child(shape_right)

func activate(spawn_pos: Vector2, params: Dictionary = {}) -> void:
	super.activate(spawn_pos, params)
	# Randomize gap position across the playable width
	var max_offset := (total_width * 0.5) - (gap_width * 0.6)
	gap_center_x = params.get("gap_x", randf_range(-max_offset, max_offset))
	_configure_collision_segments()

func _configure_collision_segments() -> void:
	_ensure_shapes_exist()
	
	var half_total := total_width * 0.5
	var gap_left := gap_center_x - (gap_width * 0.5)
	var gap_right := gap_center_x + (gap_width * 0.5)
	
	# Left Segment: from -half_total to gap_left
	var left_len := maxf(0.0, gap_left - (-half_total))
	var left_center_x := -half_total + (left_len * 0.5)
	var left_rect := shape_left.shape as RectangleShape2D
	if left_rect:
		left_rect.size = Vector2(left_len, cable_thickness)
		shape_left.position = Vector2(left_center_x, 0)
		shape_left.disabled = (left_len <= 1.0)
	
	# Right Segment: from gap_right to +half_total
	var right_len := maxf(0.0, half_total - gap_right)
	var right_center_x := gap_right + (right_len * 0.5)
	var right_rect := shape_right.shape as RectangleShape2D
	if right_rect:
		right_rect.size = Vector2(right_len, cable_thickness)
		shape_right.position = Vector2(right_center_x, 0)
		shape_right.disabled = (right_len <= 1.0)

func _process(delta: float) -> void:
	if not is_in_use:
		return
	
	spark_timer += delta * spark_frequency
	queue_redraw()

func _draw() -> void:
	if not is_in_use:
		return
	
	var half_total := total_width * 0.5
	var gap_left := gap_center_x - (gap_width * 0.5)
	var gap_right := gap_center_x + (gap_width * 0.5)
	
	var cable_color := Color(0.2, 0.2, 0.25)
	var spark_color := Color(0.9, 0.95, 0.3, 0.8 + 0.2 * sin(spark_timer))
	
	# Left cable segment
	if gap_left > -half_total:
		draw_line(Vector2(-half_total, 0), Vector2(gap_left, 0), cable_color, cable_thickness)
		# Insulator pole at left edge
		draw_rect(Rect2(-half_total - 8, -12, 16, 24), Color(0.4, 0.3, 0.25))
		# Warning glow at gap edge
		draw_circle(Vector2(gap_left, 0), 4.0, spark_color)
	
	# Right cable segment
	if gap_right < half_total:
		draw_line(Vector2(gap_right, 0), Vector2(half_total, 0), cable_color, cable_thickness)
		# Insulator pole at right edge
		draw_rect(Rect2(half_total - 8, -12, 16, 24), Color(0.4, 0.3, 0.25))
		# Warning glow at gap edge
		draw_circle(Vector2(gap_right, 0), 4.0, spark_color)
	
	# High voltage electric arc sparks along cables
	if fmod(spark_timer, 2.0) < 0.5:
		var spark_x: float = randf_range(-half_total, gap_left) if randf() > 0.5 else randf_range(gap_right, half_total)
		draw_circle(Vector2(spark_x, randf_range(-3, 3)), 3.5, spark_color)
