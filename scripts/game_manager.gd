class_name GameManager
extends Node
## Central Game State and Score Manager for "Balloon Commute".
## Tracks maximum altitude achieved, orchestrates game loop transitions,
## and connects collision signals to game over conditions.

signal state_changed(new_state: GameState)
signal altitude_updated(current_altitude: int, max_altitude: int)
signal game_over_triggered(final_altitude: int, best_altitude: int, cause: String)

enum GameState {
	READY,
	PLAYING,
	GAME_OVER
}

@export_group("Dependencies")
@export var player: Player
@export var camera: VerticalCamera
@export var spawner: Spawner
@export var input_handler: InputHandler

@export_group("Scoring Parameters")
@export var pixels_per_meter: float = 30.0 # 30 pixels traveled upward = 1 meter altitude

var current_state: GameState = GameState.READY
var start_y: float = 0.0
var max_altitude: int = 0
var current_altitude: int = 0
var best_altitude: int = 0

const HIGH_SCORE_PATH: String = "user://balloon_commute_highscore.save"

func _ready() -> void:
	_load_high_score()
	if player:
		start_y = player.global_position.y
		_connect_player_signals()
	
	start_game()

func _connect_player_signals() -> void:
	player.hazard_collided.connect(_on_player_hazard_collided)
	player.all_balloons_lost.connect(_on_all_balloons_lost)

func _physics_process(_delta: float) -> void:
	if current_state != GameState.PLAYING or not is_instance_valid(player):
		return
	
	# Calculate vertical altitude (Godot Y decreases as altitude increases)
	var delta_y: float = start_y - player.global_position.y
	current_altitude = maxi(0, int(delta_y / pixels_per_meter))
	
	if current_altitude > max_altitude:
		max_altitude = current_altitude
		altitude_updated.emit(current_altitude, max_altitude)

func start_game() -> void:
	current_state = GameState.PLAYING
	state_changed.emit(current_state)
	max_altitude = 0
	current_altitude = 0
	if input_handler:
		input_handler.enabled = true
	altitude_updated.emit(0, 0)

func trigger_game_over(cause: String) -> void:
	if current_state == GameState.GAME_OVER:
		return
	
	current_state = GameState.GAME_OVER
	state_changed.emit(current_state)
	
	if input_handler:
		input_handler.enabled = false
	
	if player:
		player.kill()
	
	if camera:
		camera.is_active = false
	
	if spawner:
		spawner.is_active = false
	
	# Update High Score
	if max_altitude > best_altitude:
		best_altitude = max_altitude
		_save_high_score()
	
	game_over_triggered.emit(max_altitude, best_altitude, cause)

func _on_player_hazard_collided(hazard_area: Area2D) -> void:
	var cause := "Hazard Collision"
	if hazard_area.collision_layer & CollisionLayers.MASK_KILL_ZONE:
		cause = "Fell off commute screen!"
	elif hazard_area is BirdHazard:
		cause = "Hit by a stray pigeon!"
	elif hazard_area is PowerLineHazard:
		cause = "Zapped by power lines!"
	elif hazard_area is SpinningFanHazard:
		cause = "Chopped by ceiling fan!"
	
	trigger_game_over(cause)

func _on_all_balloons_lost() -> void:
	# Freefall initiated - when player eventually drops below camera or hits obstacle, game over triggers
	# If player hits bottom boundary, _on_player_hazard_collided will catch the KillZone area
	pass

func restart_game() -> void:
	get_tree().reload_current_scene()

func _save_high_score() -> void:
	var file := FileAccess.open(HIGH_SCORE_PATH, FileAccess.WRITE)
	if file:
		file.store_32(best_altitude)

func _load_high_score() -> void:
	if FileAccess.file_exists(HIGH_SCORE_PATH):
		var file := FileAccess.open(HIGH_SCORE_PATH, FileAccess.READ)
		if file:
			best_altitude = file.get_32()
