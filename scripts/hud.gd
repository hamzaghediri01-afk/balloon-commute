class_name HUD
extends CanvasLayer
## User Interface controller for "Balloon Commute".
## Renders altitude scoring, active balloon indicators, touch prompt cues, and game over overlay.

@export_group("Dependencies")
@export var game_manager: GameManager
@export var player: Player

# UI Node References
@onready var altitude_label: Label = $Control/TopBar/AltitudeLabel
@onready var best_label: Label = $Control/TopBar/BestLabel
@onready var balloon_indicator_container: HBoxContainer = $Control/TopBar/BalloonIndicators
@onready var game_over_panel: Control = $Control/GameOverPanel
@onready var game_over_title: Label = $Control/GameOverPanel/VBox/TitleLabel
@onready var game_over_reason: Label = $Control/GameOverPanel/VBox/ReasonLabel
@onready var final_score_label: Label = $Control/GameOverPanel/VBox/FinalScoreLabel
@onready var best_score_label: Label = $Control/GameOverPanel/VBox/BestScoreLabel
@onready var restart_button: Button = $Control/GameOverPanel/VBox/RestartButton

var balloon_indicator_icons: Array[ColorRect] = []

func _ready() -> void:
	if game_over_panel:
		game_over_panel.visible = false
	
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	
	_setup_balloon_indicators()
	_connect_signals()

func _setup_balloon_indicators() -> void:
	if not balloon_indicator_container:
		return
	
	# Clear placeholder children
	for child in balloon_indicator_container.get_children():
		child.queue_free()
	balloon_indicator_icons.clear()
	
	# Create 4 indicator dots
	for i in range(Player.MAX_BALLOONS):
		var rect := ColorRect.new()
		rect.custom_minimum_size = Vector2(20, 20)
		rect.color = Color(1.0, 0.3, 0.3, 1.0)
		balloon_indicator_container.add_child(rect)
		balloon_indicator_icons.append(rect)

func _connect_signals() -> void:
	if game_manager:
		game_manager.altitude_updated.connect(_on_altitude_updated)
		game_manager.game_over_triggered.connect(_on_game_over_triggered)
		best_label.text = "Best: %d m" % game_manager.best_altitude
	
	if player:
		player.balloon_count_changed.connect(_on_balloon_count_changed)

func _on_altitude_updated(_current: int, maximum: int) -> void:
	if altitude_label:
		altitude_label.text = "%d m" % maximum

func _on_balloon_count_changed(active_count: int, _max_count: int) -> void:
	for i in range(balloon_indicator_icons.size()):
		if i < active_count:
			balloon_indicator_icons[i].color = Color(0.15, 0.85, 0.35, 1.0) # Active: green
			balloon_indicator_icons[i].modulate.a = 1.0
		else:
			balloon_indicator_icons[i].color = Color(0.4, 0.4, 0.4, 0.4) # Inactive: dim gray
			balloon_indicator_icons[i].modulate.a = 0.35

func _on_game_over_triggered(final_altitude: int, best_altitude: int, cause: String) -> void:
	if not game_over_panel:
		return
	
	game_over_panel.visible = true
	game_over_reason.text = cause
	final_score_label.text = "Altitude: %d m" % final_altitude
	best_score_label.text = "All-time Record: %d m" % best_altitude
	
	# Fade-in animation
	game_over_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.4)

func _on_restart_pressed() -> void:
	if game_manager:
		game_manager.restart_game()
	else:
		get_tree().reload_current_scene()
