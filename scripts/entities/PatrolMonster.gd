extends CharacterBody2D
class_name PatrolMonster

@export var patrol_distance: float = 0.0
@export var patrol_speed: float = 70.0
@export var chase_speed: float = 90.0
@export var gravity: float = 980.0

@export var edge_probe_forward: float = 1.0
@export var edge_probe_depth: float = 36.0
@export var floor_probe_margin: float = 8.0
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
var _behavior_log_timer: float = 0.0
var _last_behavior_reason: String = "init"
var _last_turn_probe_details: String = "none"
var _last_edge_probe_details: String = "none"

var _hurtbox: Area2D
var _body_collision: CollisionShape2D
var _player: CharacterBody2D

@onready var _animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


func _ready() -> void:
	add_to_group("swappable")
	_origin_x = global_position.x

	_hurtbox = get_node_or_null("Hurtbox") as Area2D
	_body_collision = get_node_or_null("BodyCollisionShape") as CollisionShape2D
	_refresh_player_ref()

	if _hurtbox != null:
		_hurtbox.add_to_group("hazard")
		if not _hurtbox.body_entered.is_connected(_on_hurtbox_body_entered):
			_hurtbox.body_entered.connect(_on_hurtbox_body_entered)

	if _animated_sprite != null:
		if force_flip_v_correction:
			_animated_sprite.flip_v = true
		_animated_sprite.play("default")

	_update_facing()


func _physics_process(delta: float) -> void:
	if debug_logs:
		_behavior_log_timer += delta

	_refresh_player_ref()
	_update_chase_state()

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	if _turn_cooldown_left > 0.0:
		_turn_cooldown_left = maxf(_turn_cooldown_left - delta, 0.0)

	if not _is_chasing:
		_apply_patrol_boundary()

	var desired_direction: float = _get_desired_direction()
	if not is_zero_approx(desired_direction):
		_move_direction = desired_direction

	if _turn_cooldown_left <= 0.0 and _should_turn_for_edge(_move_direction):
		_log_turn_event("chase" if _is_chasing else "patrol", "edge ahead", _move_direction)
		_turn_around("edge ahead")

	var speed: float = chase_speed if _is_chasing else patrol_speed
	velocity.x = _move_direction * speed

	move_and_slide()

	if is_on_wall() and _turn_cooldown_left <= 0.0:
		_last_turn_probe_details = "wall collision contact dir=%.2f pos=%s vel=%s" % [
			_move_direction,
			global_position,
			velocity,
		]
		_log_turn_event("physics", "wall collision", _move_direction)
		_turn_around("wall collision")

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
		_last_behavior_reason = "no player found"
		return

	var dx: float = absf(_player.global_position.x - global_position.x)
	var dy: float = absf(_player.global_position.y - global_position.y)

	if _is_chasing:
		if dx > lose_chase_range or dy > chase_vertical_tolerance * 1.4 or not _has_line_of_sight_to_player():
			_is_chasing = false
			_last_behavior_reason = "lost player"
		else:
			_last_behavior_reason = "chasing player"
		return

	if dx <= chase_detection_range and dy <= chase_vertical_tolerance and _has_line_of_sight_to_player():
		_is_chasing = true
		_last_behavior_reason = "chasing player"
		return

	if dy > chase_vertical_tolerance:
		_last_behavior_reason = "player not on horizontal line monster_y=%.1f player_y=%.1f" % [
			global_position.y,
			_player.global_position.y,
		]
	else:
		_last_behavior_reason = "player out of range dist=%.1f" % dx


func _get_desired_direction() -> float:
	if _is_chasing and _player != null:
		var chase_dir: float = signf(_player.global_position.x - global_position.x)
		if not is_zero_approx(chase_dir):
			return chase_dir
	return _patrol_direction


func _apply_patrol_boundary() -> void:
	if patrol_distance <= 0.0:
		return

	var distance_from_origin: float = global_position.x - _origin_x
	if distance_from_origin >= patrol_distance:
		if debug_logs and _patrol_direction > 0.0:
			print("[PatrolMonster] patrol boundary turn dir=1.0 pos=%s origin_x=%.2f distance_from_origin=%.2f patrol_distance=%.2f" % [
				global_position,
				_origin_x,
				distance_from_origin,
				patrol_distance,
			])
		_patrol_direction = -1.0
	elif distance_from_origin <= -patrol_distance:
		if debug_logs and _patrol_direction < 0.0:
			print("[PatrolMonster] patrol boundary turn dir=-1.0 pos=%s origin_x=%.2f distance_from_origin=%.2f patrol_distance=%.2f" % [
				global_position,
				_origin_x,
				distance_from_origin,
				patrol_distance,
			])
		_patrol_direction = 1.0


func _has_line_of_sight_to_player() -> bool:
	if _player == null:
		return false

	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, _player.global_position)
	query.exclude = _build_ray_exclude(_player)
	query.collision_mask = collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()


func _should_turn_for_edge(direction: float) -> bool:
	_last_turn_probe_details = "idle dir=%.2f" % direction
	_last_edge_probe_details = "idle dir=%.2f" % direction

	if is_zero_approx(direction):
		return false

	if not is_on_floor():
		_last_edge_probe_details = "edge-check skipped dir=%.2f reason=not_on_floor pos=%s vel=%s" % [
			direction,
			global_position,
			velocity,
		]
		return false

	if not _has_floor_below():
		_last_edge_probe_details = "edge-check skipped dir=%.2f reason=no_floor_below pos=%s" % [
			direction,
			global_position,
		]
		return false

	var has_floor_ahead: bool = _has_floor_ahead(direction)
	if has_floor_ahead:
		_last_turn_probe_details = "edge continue dir=%.2f pos=%s %s" % [
			direction,
			global_position,
			_last_edge_probe_details,
		]
	else:
		_last_turn_probe_details = "edge turn dir=%.2f pos=%s %s" % [
			direction,
			global_position,
			_last_edge_probe_details,
		]
	return not has_floor_ahead


func _has_floor_below() -> bool:
	var body_center: Vector2 = _get_body_center()
	var half_height: float = _get_half_height()
	var probe_y: float = body_center.y + half_height - floor_probe_margin
	var ray_from: Vector2 = Vector2(body_center.x, probe_y)
	var ray_to: Vector2 = Vector2(body_center.x, probe_y + edge_probe_depth + floor_probe_margin * 2.0)
	var floor_probe: Dictionary = _intersect_navigation_ray(ray_from, ray_to)

	if debug_logs:
		if floor_probe.is_empty():
			_last_edge_probe_details = "edge-check below from=%s to=%s miss" % [ray_from, ray_to]
		else:
			_last_edge_probe_details = "edge-check below from=%s to=%s hit=%s normal=%s" % [
				ray_from,
				ray_to,
				floor_probe.get("position", Vector2.ZERO),
				floor_probe.get("normal", Vector2.ZERO),
			]
	return not floor_probe.is_empty()


func _has_floor_ahead(direction: float) -> bool:
	var body_center: Vector2 = _get_body_center()
	var half_width: float = _get_half_width()
	var half_height: float = _get_half_height()
	var probe_x: float = body_center.x + direction * (half_width + edge_probe_forward)
	var probe_y: float = body_center.y + half_height - floor_probe_margin
	var ray_from: Vector2 = Vector2(probe_x, probe_y)
	var ray_to: Vector2 = Vector2(probe_x, probe_y + edge_probe_depth + floor_probe_margin * 2.0)
	var floor_probe: Dictionary = _intersect_navigation_ray(ray_from, ray_to)

	if floor_probe.is_empty():
		_last_edge_probe_details = "edge-check ahead dir=%.2f from=%s to=%s miss" % [direction, ray_from, ray_to]
	else:
		_last_edge_probe_details = "edge-check ahead dir=%.2f from=%s to=%s hit=%s normal=%s" % [
			direction,
			ray_from,
			ray_to,
			floor_probe.get("position", Vector2.ZERO),
			floor_probe.get("normal", Vector2.ZERO),
		]
	return not floor_probe.is_empty()


func _intersect_navigation_ray(ray_from: Vector2, ray_to: Vector2, body_to_ignore: CollisionObject2D = null) -> Dictionary:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(ray_from, ray_to)
	query.exclude = _build_ray_exclude(body_to_ignore)
	query.collision_mask = collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_ray(query)


func _build_ray_exclude(body_to_ignore: CollisionObject2D) -> Array[RID]:
	var exclude: Array[RID] = [get_rid()]
	if _hurtbox != null:
		exclude.append(_hurtbox.get_rid())
	if body_to_ignore != null:
		exclude.append(body_to_ignore.get_rid())
	return exclude


func _get_body_center() -> Vector2:
	if _body_collision != null:
		return _body_collision.global_position
	return global_position


func _get_half_width() -> float:
	if _body_collision == null:
		return 8.0
	if _body_collision.shape is RectangleShape2D:
		var rectangle: RectangleShape2D = _body_collision.shape as RectangleShape2D
		return rectangle.size.x * 0.5
	if _body_collision.shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = _body_collision.shape as CapsuleShape2D
		return capsule.radius
	return 8.0


func _get_half_height() -> float:
	if _body_collision == null:
		return 7.0
	if _body_collision.shape is RectangleShape2D:
		var rectangle: RectangleShape2D = _body_collision.shape as RectangleShape2D
		return rectangle.size.y * 0.5
	if _body_collision.shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = _body_collision.shape as CapsuleShape2D
		return capsule.height * 0.5 + capsule.radius
	return 7.0


func _turn_around(reason: String) -> void:
	_move_direction *= -1.0
	_patrol_direction = _move_direction
	velocity.x = 0.0
	_turn_cooldown_left = stuck_pause_time if reason == "stuck" else turn_cooldown
	_last_behavior_reason = "turn around: %s" % reason


func _update_facing() -> void:
	if _animated_sprite == null or is_zero_approx(_move_direction):
		return
	_animated_sprite.flip_h = _move_direction > 0.0


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body == null or not body.is_in_group("player"):
		return
	if _hurtbox != null and not _hurtbox.overlaps_body(body):
		return

	if debug_logs:
		print("[PatrolMonster] kill player body=%s" % body.name)
	if body.has_method("die"):
		body.die()
		return

	var signal_manager: Node = get_node_or_null("/root/SignalManager")
	if signal_manager != null:
		signal_manager.player_died.emit()


func on_swapped() -> void:
	_origin_x = global_position.x
	velocity = Vector2.ZERO
	_turn_cooldown_left = stuck_pause_time
	_is_chasing = false
	_last_behavior_reason = "swapped reset"
	if debug_logs:
		print("[PatrolMonster] swapped reset pos=%s new_origin_x=%.2f patrol_distance=%.2f" % [
			global_position,
			_origin_x,
			patrol_distance,
		])


func _log_debug() -> void:
	if not debug_logs or _behavior_log_timer < 1.0:
		return
	_behavior_log_timer = 0.0

	var behavior: String = "chase" if _is_chasing else "patrol"
	print("[PatrolMonster] behavior=%s dir=%.1f vel=%s pos=%s reason=%s probe=%s" % [
		behavior,
		_move_direction,
		velocity,
		global_position,
		_last_behavior_reason,
		"%s edge=%s" % [_last_turn_probe_details, _last_edge_probe_details],
	])


func _log_turn_event(state: String, turn_reason: String, direction: float) -> void:
	if not debug_logs:
		return
	print("[PatrolMonster] turn state=%s reason=%s dir=%.1f pos=%s vel=%s probe=%s" % [
		state,
		turn_reason,
		direction,
		global_position,
		velocity,
		"%s edge=%s" % [_last_turn_probe_details, _last_edge_probe_details],
	])
