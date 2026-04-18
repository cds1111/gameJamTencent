extends Node
class_name LevelController

@export var player_scene: PackedScene = preload("res://scenes/entities/Player.tscn")
@export var starting_ability: Resource
@export var next_level_id: int = 2
@export var level_title_text: String = "LEVEL"

@onready var _entities: Node2D = $"../Entities"
@onready var _player_spawn: Marker2D = $"../Entities/PlayerSpawn"
@onready var _goal: Area2D = $"../Entities/Goal"
@onready var _title_label: Label = $"../LevelUI/TopRightMargin/TitleBackground/TitleText"

var _player: CharacterBody2D
var _is_restarting: bool = false


func _ready() -> void:
	_apply_level_title()
	_spawn_player()
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_game_music()
	if is_instance_valid(_goal):
		_goal.body_entered.connect(_on_goal_body_entered)
	var signal_manager := get_node_or_null("/root/SignalManager")
	if signal_manager != null and not signal_manager.player_died.is_connected(_on_player_died):
		signal_manager.player_died.connect(_on_player_died)


func _apply_level_title() -> void:
	if is_instance_valid(_title_label):
		_title_label.text = level_title_text


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart_level"):
		if is_instance_valid(_player) and _player.has_method("die"):
			_player.die()
		else:
			_restart_level()


func _spawn_player() -> void:
	if player_scene == null or _entities == null or _player_spawn == null:
		return

	_player = _entities.get_node_or_null("Player") as CharacterBody2D
	if _player == null:
		_player = player_scene.instantiate() as CharacterBody2D
		if _player == null:
			return
		_entities.add_child(_player)

	_player.global_position = _player_spawn.global_position

	if starting_ability != null and _player.has_method("set_current_ability"):
		var ability := _build_ability_instance(starting_ability) as ShiftAbility
		if ability != null:
			_player.set_current_ability(ability)


func _build_ability_instance(source: Resource) -> Resource:
	if source == null:
		return null
	if source.resource_path.ends_with(".gd") and source is Script:
		return (source as Script).new()
	return source.duplicate(true)


func _on_goal_body_entered(body: Node) -> void:
	if body != _player:
		return
	var signal_manager := get_node_or_null("/root/SignalManager")
	if signal_manager != null:
		signal_manager.level_completed.emit(next_level_id)


func _on_player_died() -> void:
	if _is_restarting:
		return
	print("[LevelController] player_died received -> restart current scene after 0.5s")
	call_deferred("_restart_level_with_delay")


func _restart_level() -> void:
	if _is_restarting:
		return
	_is_restarting = true
	print("[LevelController] reload_current_scene")
	var transition_manager: Node = get_node_or_null("/root/SceneTransitionManager")
	if transition_manager != null:
		transition_manager.reload_current_scene()
	else:
		get_tree().call_deferred("reload_current_scene")


func _restart_level_with_delay() -> void:
	if _is_restarting:
		return
	await get_tree().create_timer(0.5).timeout
	_restart_level()
