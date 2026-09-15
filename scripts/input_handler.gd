class_name InputHandler
extends Node
## Handles screen-space touch and pointer inputs for steering.
## Tapping the left half pops the leftmost balloon (steers right).
## Tapping the right half pops the rightmost balloon (steers left).

signal left_half_tapped
signal right_half_tapped

@export var enabled: bool = true
@export var player: Player

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	
	# Mobile Touch
	if event is InputEventScreenTouch and event.pressed:
		_process_screen_tap(event.position)
		get_viewport().set_input_as_handled()
		return
	
	# Desktop Mouse Click (Left Button)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_process_screen_tap(event.position)
		get_viewport().set_input_as_handled()
		return
	
	# Keyboard fallbacks for desktop development (A / Left, D / Right)
	if event.is_action_pressed("ui_left"):
		_trigger_left()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_trigger_right()
		get_viewport().set_input_as_handled()

func _process_screen_tap(screen_pos: Vector2) -> void:
	var viewport_width := get_viewport().get_visible_rect().size.x
	var half_screen := viewport_width * 0.5
	
	if screen_pos.x < half_screen:
		_trigger_left()
	else:
		_trigger_right()

func _trigger_left() -> void:
	left_half_tapped.emit()
	if player:
		player.pop_leftmost()

func _trigger_right() -> void:
	right_half_tapped.emit()
	if player:
		player.pop_rightmost()
