extends Node

const WALK_SOUND: AudioStream = preload("res://assets/music/scroll_002.ogg")
const RUN_SOUND: AudioStream = preload("res://assets/music/scroll_005.ogg")
const JUMP_SOUND: AudioStream = preload("res://assets/music/maximize_002.ogg")
const LAND_SOUND: AudioStream = preload("res://assets/music/drop_002.ogg")
const DEATH_SOUND: AudioStream = preload("res://assets/music/arcade_8bit_death.mp3")
const DEATH_VOLUME_DB := 2.5
const DEATH_PITCH_SCALE := 1.14
const DEATH_MAX_DISTANCE := 12000.0

@onready var walk_player: AudioStreamPlayer2D = $WalkPlayer
@onready var run_player: AudioStreamPlayer2D = $RunPlayer
@onready var jump_player: AudioStreamPlayer2D = $JumpPlayer
@onready var land_player: AudioStreamPlayer2D = $LandPlayer
@onready var death_player: AudioStreamPlayer2D = get_node_or_null("DeathPlayer") as AudioStreamPlayer2D

func _ready() -> void:
	walk_player.stream = WALK_SOUND
	run_player.stream = RUN_SOUND
	jump_player.stream = JUMP_SOUND
	land_player.stream = LAND_SOUND
	_ensure_death_player()
	death_player.stream = DEATH_SOUND
	death_player.volume_db = DEATH_VOLUME_DB
	death_player.pitch_scale = DEATH_PITCH_SCALE
	death_player.max_distance = DEATH_MAX_DISTANCE


func _ensure_death_player() -> void:
	if death_player != null:
		return

	death_player = AudioStreamPlayer2D.new()
	death_player.name = "DeathPlayer"
	add_child(death_player)


func play_walk_loop() -> void:
	if run_player.playing:
		run_player.stop()
	if not walk_player.playing:
		walk_player.play()


func play_run_loop() -> void:
	if walk_player.playing:
		walk_player.stop()
	if not run_player.playing:
		run_player.play()


func play_jump() -> void:
	stop_movement_loops()
	jump_player.play()


func play_land() -> void:
	land_player.play()


func play_death() -> void:
	stop_movement_loops()
	_ensure_death_player()
	death_player.stream = DEATH_SOUND
	death_player.volume_db = DEATH_VOLUME_DB
	death_player.pitch_scale = DEATH_PITCH_SCALE
	death_player.max_distance = DEATH_MAX_DISTANCE
	if death_player.playing:
		death_player.stop()
	death_player.play()


func stop_movement_loops() -> void:
	if walk_player.playing:
		walk_player.stop()
	if run_player.playing:
		run_player.stop()
