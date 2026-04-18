extends CharacterBody2D
class_name PatrolMonster

@export var patrol_distance: float = 96.0
@export var patrol_speed: float = 70.0
@export var chase_speed: float = 90.0
@export var gravity: float = 980.0

@export var wall_probe_distance: float = 7.0
@export var edge_probe_forward: float = 12.0
@export var edge_probe_depth: float = 28.0
@export var turn_cooldown: float = 0.16
@export var stuck_pause_time: float = 0.28

@export var chase_detection_range: float = 280.0
@export var chase_vertical_tolerance: float = 28.0
@export var lose_chase_range: float = 360.0
@export var enable_chase: bool = false

@export var force_flip_v_correction: bool = false
@export var debug_logs: bool = false

var _origin_x: float
var _patrol_direction: float = 1.0
var _move_direction: float = 1.0
var _is_chasing: bool = false
var _turn_cooldown_left: float = 0.0

var _hurtbox: Area2D
var _player: CharacterBody2D

@onready var _animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


func _ready() -> void:
	add_to_group("swappable")
	_origin_x = global_position.x

	_hurtbox = get_node_or_null("Hurtbox") as Area2D
	if _hurtbox != null:
		_hurtbox.add_to_group("hazard")
		if not _hurtbox.body_entered.is_connected(_on_hurtbox_body_entered):
			_hurtbox.body_entered.connect(_on_hurtbox_body_entered)

	if _animated_sprite != null:
		if force_flip_v_correction:
			_animated_sprite.flip_v = true
		_animated_sprite.flip_h = false

	_refresh_player_ref()


func _physics_process(delta: float) -> void:
	_refresh_player_ref()
	_update_chase_state()

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	if _turn_cooldown_left > 0.0:
		_turn_cooldown_left -= delta

	var desired_direction: float = _get_desired_direction()
	if not is_zero_approx(desired_direction):
		_move_direction = desired_direction

	if _turn_cooldown_left <= 0.0:
		var blocked_forward: bool = _is_blocked_ahead(_move_direction)
		var has_floor_forward: bool = _has_floor_ahead(_move_direction)
		if blocked_forward or not has_floor_forward:
			var blocked_backward: bool = _is_blocked_ahead(-_move_direction)
			if blocked_backward and blocked_forward:
				# 两侧都堵住时不要疯狂来回转向，短暂停一下等待物理状态稳定
				velocity.x = 0.0
				_turn_cooldown_left = stuck_pause_time
			elif blocked_forward or not has_floor_forward:
				_turn_around("probe")

	var speed: float = chase_speed if _is_chasing else patrol_speed
	velocity.x = _move_direction * speed

	move_and_slide()

	# 兜底：如果仍然撞墙，且背后不堵，才允许转向。
	if is_on_wall() and _turn_cooldown_left <= 0.0 and not _is_blocked_ahead(-_move_direction):
		_turn_around("wall")

	_update_facing()
	_log_debug()


func _refresh_player_ref() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D


func _update_chase_state() -> void:
	if not enable_chase:
		_is_chasing = false
		return

	if _player == null:
		_is_chasing = false
		return

	var dx: float = absf(_player.global_position.x - global_position.x)
	var dy: float = absf(_player.global_position.y - global_position.y)

	if _is_chasing:
		if dx > lose_chase_range or dy > chase_vertical_tolerance * 1.4:
			_is_chasing = false
		return

	if dx <= chase_detection_range and dy <= chase_vertical_tolerance and _has_line_of_sight_to_player():
		_is_chasing = true


func _get_desired_direction() -> float:
	if _is_chasing and _player != null:
		var chase_dir: float = signf(_player.global_position.x - global_position.x)
		if not is_zero_approx(chase_dir):
			return chase_dir

	if patrol_distance > 0.0:
		var offset_x: float = global_position.x - _origin_x
		if offset_x >= patrol_distance:
			_patrol_direction = -1.0
		elif offset_x <= -patrol_distance:
			_patrol_direction = 1.0

	return _patrol_direction


func _has_line_of_sight_to_player() -> bool:
	if _player == null:
		return false

	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		global_position,
		_player.global_position
	)
	query.exclude = [get_rid(), _player.get_rid()]
	if _hurtbox != null:
		query.exclude.append(_hurtbox.get_rid())

	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()


func _is_blocked_ahead(direction: float) -> bool:
	return test_move(global_transform, Vector2(direction * wall_probe_distance, 0.0))


func _has_floor_ahead(direction: float) -> bool:
	var probe_transform: Transform2D = global_transform
	probe_transform.origin.x += direction * edge_probe_forward
	return test_move(probe_transform, Vector2(0.0, edge_probe_depth))


func _turn_around(reason: String) -> void:
	_move_direction *= -1.0
	_patrol_direction = _move_direction
	_turn_cooldown_left = turn_cooldown
	if debug_logs:
		print("[PatrolMonster] turn reason=%s dir=%.1f" % [reason, _move_direction])


func _update_facing() -> void:
	if _animated_sprite == null:
		return
	if is_zero_approx(_move_direction):
		return
	_animated_sprite.flip_h = _move_direction > 0.0


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body == null or not body.is_in_group("player"):
		return
	if _hurtbox != null and not _hurtbox.overlaps_body(body):
		return

	if body.has_method("die"):
		body.die()
		return

	var signal_manager: Node = get_node_or_null("/root/SignalManager")
	if signal_manager != null:
		signal_manager.player_died.emit()


func on_swapped() -> void:
	# 与玩家换位后重置内部运动状态，避免贴墙初始帧抖动。
	_origin_x = global_position.x
	_turn_cooldown_left = stuck_pause_time
	velocity = Vector2.ZERO

	# 如果当前方向被墙堵住，立即转向一次。
	if _is_blocked_ahead(_move_direction):
		_move_direction *= -1.0
		_patrol_direction = _move_direction

	_update_facing()


func _log_debug() -> void:
	if not debug_logs:
		return
	print("[PatrolMonster] mode=%s dir=%.1f vel=%s pos=%s cd=%.2f" % [
		"CHASE" if _is_chasing else "PATROL",
		_move_direction,
		velocity,
		global_position,
		_turn_cooldown_left,
	])
