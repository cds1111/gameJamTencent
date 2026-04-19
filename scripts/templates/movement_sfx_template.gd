extends Node

const WALK_SOUND: AudioStream = preload("res://assets/music/scroll_002.ogg")
const RUN_SOUND: AudioStream = preload("res://assets/music/scroll_005.ogg")
const JUMP_SOUND: AudioStream = preload("res://assets/music/maximize_002.ogg")
const LAND_SOUND: AudioStream = preload("res://assets/music/drop_002.ogg")

@onready var walk_player: AudioStreamPlayer2D = $WalkPlayer
@onready var run_player: AudioStreamPlayer2D = $RunPlayer
@onready var jump_player: AudioStreamPlayer2D = $JumpPlayer
@onready var land_player: AudioStreamPlayer2D = $LandPlayer

func _ready() -> void:
	walk_player.stream = WALK_SOUND
	run_player.stream = RUN_SOUND
	jump_player.stream = JUMP_SOUND
	land_player.stream = LAND_SOUND


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


func stop_movement_loops() -> void:
	if walk_player.playing:
		walk_player.stop()
	if run_player.playing:
		run_player.stop()
