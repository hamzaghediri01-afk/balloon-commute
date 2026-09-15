class_name Balloon
extends Node2D
## Represents an individual balloon in the player's cluster.
## Responsible for local attachment offset, string rendering, visual appearance, and pop state.

signal popped(balloon: Balloon)
signal restored(balloon: Balloon)

@export var balloon_color: Color = Color(0.95, 0.25, 0.25, 1.0)
@export var balloon_radius: float = 14.0
@export var string_color: Color = Color(0.85, 0.85, 0.85, 0.7)
@export var string_width: float = 1.5

var is_active: bool = true
var target_offset: Vector2 = Vector2.ZERO
var wobble_phase: float = 0.0
var wobble_speed: float = 3.0
var wobble_amplitude: float = 4.0

func _ready() -> void:
	wobble_phase = randf() * TAU

func _process(delta: float) -> void:
	if not is_active:
		return
	
	# Gentle floating wobble effect
	wobble_phase += delta * wobble_speed
	var wobble_offset := Vector2(sin(wobble_phase) * wobble_amplitude, cos(wobble_phase * 0.7) * (wobble_amplitude * 0.5))
	position = target_offset + wobble_offset
	queue_redraw()

func _draw() -> void:
	if not is_active:
		return
	
	# Draw the string connecting the balloon to the player's center (0, 0 in parent space)
	var local_player_origin := -position
	draw_line(Vector2.ZERO, local_player_origin, string_color, string_width, true)
	
	# Draw balloon body (ellipse + knot)
	draw_circle(Vector2(0, -balloon_radius * 0.2), balloon_radius, balloon_color)
	
	# Highlight / sheen for 3D appearance
	var highlight_pos := Vector2(-balloon_radius * 0.3, -balloon_radius * 0.5)
	draw_circle(highlight_pos, balloon_radius * 0.28, Color(1, 1, 1, 0.45))
	
	# Balloon knot
	var knot_points := PackedVector2Array([
		Vector2(-3, balloon_radius * 0.8),
		Vector2(3, balloon_radius * 0.8),
		Vector2(0, balloon_radius * 1.1)
	])
	draw_colored_polygon(knot_points, balloon_color.darkened(0.2))

## Sets the resting offset for this balloon relative to player center
func initialize(offset: Vector2, color: Color) -> void:
	target_offset = offset
	position = offset
	balloon_color = color
	is_active = true
	visible = true
	queue_redraw()

## Pops this balloon with visual feedback and emits signal
func pop() -> void:
	if not is_active:
		return
	
	is_active = false
	visible = false
	popped.emit(self)

## Restores this balloon when a pickup is collected
func restore() -> void:
	if is_active:
		return
	
	is_active = true
	visible = true
	scale = Vector2.ZERO
	# Quick scale pop-in animation
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	restored.emit(self)
	queue_redraw()
