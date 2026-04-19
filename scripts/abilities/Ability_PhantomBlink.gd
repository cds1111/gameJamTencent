extends "res://scripts/abilities/ShiftAbility.gd"
class_name AbilityPhantomBlink

@export var phantom_distance: float = 64.0
@export var switch_interval: float = 0.5
@export var follow_interval: float = 0.016
@export var level_top_left: Vector2 = Vector2(-1406.0, -509.0)
@export var level_bottom_right: Vector2 = Vector2(-914.0, -242.0)

var _phantom_node: Node2D
var _phantom_icon: CanvasItem
var _switch_timer: Timer
var _follow_timer: Timer
var _current_direction: Vector2 = Vector2.RIGHT

var _directions: Array[Vector2] = [
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.UP,
	Vector2.DOWN,
	Vector2(0.70710678, 0.70710678),
	Vector2(0.70710678, -0.70710678),
	Vector2(-0.70710678, 0.70710678),
	Vector2(-0.70710678, -0.70710678),
]


func _init() -> void:
	ability_name = "PhantomBlink"
	# 使用 HOLD 模式：每次按下 shift 都触发 execute，松开只走 cancel（空实现）。
	hold_to_maintain = true


func on_equipped(player: CharacterBody2D) -> void:
	if not _ensure_scene_nodes(player):
		return

	_roll_next_direction(true)
	_set_visual_enabled(true)
	_update_phantom_position(_resolve_player())
	_start_timers()


func on_unequipped(_player: CharacterBody2D) -> void:
	_stop_and_free_timers()
	_set_visual_enabled(false)
	_phantom_node = null
	_phantom_icon = null


func execute(player: CharacterBody2D) -> void:
	var target_player := player
	if target_player == null:
		target_player = _resolve_player()
	if target_player == null:
		return
	if not _ensure_scene_nodes(target_player):
		return

	# 先根据玩家当前位置重算一次虚影点位，避免使用陈旧坐标导致远距离传送。
	_update_phantom_position(target_player)
	target_player.global_position = _phantom_node.global_position
	_roll_next_direction(false)
	_update_phantom_position(target_player)
	emit_ability_used()


func cancel(_player: CharacterBody2D) -> void:
	# HOLD 模式下松开 shift 不做任何事。
	pass


func _ensure_scene_nodes(player: CharacterBody2D) -> bool:
	var scene_root: Node = null
	if player != null and player.get_tree() != null:
		scene_root = player.get_tree().current_scene
	if scene_root == null:
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			scene_root = tree.current_scene
	if scene_root == null:
		return false

	if _phantom_node == null:
		_phantom_node = scene_root.get_node_or_null("Entities/PhantomGhost") as Node2D
		if _phantom_node == null:
			push_warning("[AbilityPhantomBlink] Missing scene node: Entities/PhantomGhost")
			return false

	if _phantom_icon == null:
		_phantom_icon = _phantom_node.get_node_or_null("Icon") as CanvasItem
		if _phantom_icon == null:
			for child in _phantom_node.get_children():
				if child is CanvasItem:
					_phantom_icon = child as CanvasItem
					break
		if _phantom_icon == null:
			push_warning("[AbilityPhantomBlink] Missing visual child under Entities/PhantomGhost")
			return false

	return true


func _start_timers() -> void:
	if _phantom_node == null:
		return

	if _switch_timer == null:
		_switch_timer = Timer.new()
		_switch_timer.name = "PhantomSwitchTimer"
		_switch_timer.one_shot = false
		_switch_timer.wait_time = maxf(switch_interval, 0.05)
		_phantom_node.add_child(_switch_timer)
		_switch_timer.timeout.connect(_on_switch_timeout)

	if _follow_timer == null:
		_follow_timer = Timer.new()
		_follow_timer.name = "PhantomFollowTimer"
		_follow_timer.one_shot = false
		_follow_timer.wait_time = maxf(follow_interval, 0.008)
		_phantom_node.add_child(_follow_timer)
		_follow_timer.timeout.connect(_on_follow_timeout)

	_switch_timer.start()
	_follow_timer.start()


func _stop_and_free_timers() -> void:
	if _switch_timer != null and is_instance_valid(_switch_timer):
		if _switch_timer.timeout.is_connected(_on_switch_timeout):
			_switch_timer.timeout.disconnect(_on_switch_timeout)
		_switch_timer.stop()
		_switch_timer.queue_free()
	_switch_timer = null

	if _follow_timer != null and is_instance_valid(_follow_timer):
		if _follow_timer.timeout.is_connected(_on_follow_timeout):
			_follow_timer.timeout.disconnect(_on_follow_timeout)
		_follow_timer.stop()
		_follow_timer.queue_free()
	_follow_timer = null


func _on_switch_timeout() -> void:
	_roll_next_direction(false)
	_update_phantom_position(_resolve_player())


func _on_follow_timeout() -> void:
	_update_phantom_position(_resolve_player())


func _roll_next_direction(allow_same: bool) -> void:
	var next_direction: Vector2 = _directions[randi() % _directions.size()]
	if not allow_same:
		var guard := 0
		while next_direction == _current_direction and guard < 8:
			next_direction = _directions[randi() % _directions.size()]
			guard += 1
	_current_direction = next_direction


func _update_phantom_position(player: CharacterBody2D) -> void:
	if _phantom_node == null or player == null:
		return
	var candidate := player.global_position + _current_direction * phantom_distance
	_phantom_node.global_position = _clamp_to_level_bounds(candidate)


func _clamp_to_level_bounds(point: Vector2) -> Vector2:
	var min_x := minf(level_top_left.x, level_bottom_right.x)
	var max_x := maxf(level_top_left.x, level_bottom_right.x)
	var min_y := minf(level_top_left.y, level_bottom_right.y)
	var max_y := maxf(level_top_left.y, level_bottom_right.y)
	return Vector2(clampf(point.x, min_x, max_x), clampf(point.y, min_y, max_y))


func _set_visual_enabled(enabled: bool) -> void:
	if _phantom_node != null:
		_phantom_node.visible = enabled


func _resolve_player() -> CharacterBody2D:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return null

	var player := tree.current_scene.get_node_or_null("Entities/Player") as CharacterBody2D
	if player != null:
		return player

	var players := tree.get_nodes_in_group("player")
	if players.size() > 0 and players[0] is CharacterBody2D:
		return players[0] as CharacterBody2D

	return null
