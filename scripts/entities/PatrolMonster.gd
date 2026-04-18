extends CharacterBody2D
class_name PatrolMonster

@export var patrol_distance: float = 96.0
@export var patrol_speed: float = 70.0
@export var chase_speed: float = 90.0
@export var gravity: float = 980.0
@export var wall_probe_distance: float = 4.0
@export var edge_probe_forward: float = 14.0
@export var edge_probe_depth: float = 36.0
@export var chase_detection_range: float = 640.0
@export var chase_reaction_delay: float = 0.6
@export var horizontal_line_tolerance: float = 6.0
@export var floor_alignment_tolerance: float = 6.0
@export var floor_connectivity_step: float = 16.0
@export var floor_probe_margin: float = 8.0
@export var debug_logs: bool = false

var _origin_x: float
var _patrol_direction: float = 1.0
var _chase_direction: float = 1.0
var _move_direction: float = 1.0
var _hurtbox: Area2D
var _body_collision: CollisionShape2D
var _player: CharacterBody2D
var _is_currently_chasing: bool = false
var _behavior_log_timer: float = 0.0
var _last_behavior_reason: String = "init"
var _pending_chase_direction: float = 0.0
var _chase_reaction_timer: float = 0.0


func _ready() -> void:
	add_to_group("swappable")
	_origin_x = global_position.x
	_hurtbox = get_node_or_null("Hurtbox") as Area2D
	_body_collision = get_node_or_null("BodyCollisionShape") as CollisionShape2D
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	if _hurtbox != null:
		_hurtbox.add_to_group("hazard")
		if not _hurtbox.body_entered.is_connected(_on_hurtbox_body_entered):
			_hurtbox.body_entered.connect(_on_hurtbox_body_entered)


func _physics_process(delta: float) -> void:
	if debug_logs:
		_behavior_log_timer += delta

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	var detected_chase_direction: float = _evaluate_chase_direction()
	_update_chase_state(delta, detected_chase_direction)

	if _is_currently_chasing:
		_run_chase()
	else:
		_run_patrol()

	move_and_slide()

	if is_on_wall():
		_move_direction *= -1.0
		if _is_currently_chasing:
			_chase_direction = _move_direction
		else:
			_patrol_direction = _move_direction
		_last_behavior_reason = "turn around: wall collision"

	_update_facing()
	_log_behavior_tick()


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


func _run_patrol() -> void:
	_apply_patrol_boundary()

	_move_direction = _patrol_direction
	var turn_reason: String = _get_turn_reason(_move_direction)
	if not turn_reason.is_empty():
		_move_direction *= -1.0
		_patrol_direction = _move_direction
		_last_behavior_reason = "turn around: %s" % turn_reason

	velocity.x = patrol_speed * _move_direction


func _run_chase() -> void:
	_move_direction = _chase_direction
	var turn_reason: String = _get_turn_reason(_move_direction)
	if not turn_reason.is_empty():
		_move_direction *= -1.0
		_chase_direction = _move_direction
		_last_behavior_reason = "turn around: %s" % turn_reason

	velocity.x = chase_speed * _move_direction
	if turn_reason.is_empty():
		_last_behavior_reason = "same platform"


func _apply_patrol_boundary() -> void:
	if patrol_distance <= 0.0:
		return

	var distance_from_origin: float = global_position.x - _origin_x
	if distance_from_origin >= patrol_distance:
		_patrol_direction = -1.0
	elif distance_from_origin <= -patrol_distance:
		_patrol_direction = 1.0


func _update_chase_state(delta: float, detected_chase_direction: float) -> void:
	if is_zero_approx(detected_chase_direction):
		_pending_chase_direction = 0.0
		_chase_reaction_timer = 0.0
		if _is_currently_chasing:
			_is_currently_chasing = false
			_patrol_direction = _move_direction
		return

	if _is_currently_chasing and is_equal_approx(detected_chase_direction, _chase_direction):
		_pending_chase_direction = 0.0
		_chase_reaction_timer = 0.0
		return

	if not is_equal_approx(_pending_chase_direction, detected_chase_direction):
		_pending_chase_direction = detected_chase_direction
		_chase_reaction_timer = 0.0

	_chase_reaction_timer += delta
	_last_behavior_reason = "chase warming up %.2f/%.2f" % [_chase_reaction_timer, chase_reaction_delay]
	if _chase_reaction_timer < chase_reaction_delay:
		return

	_is_currently_chasing = true
	_chase_direction = _pending_chase_direction
	_move_direction = _chase_direction
	_pending_chase_direction = 0.0
	_chase_reaction_timer = 0.0
	_last_behavior_reason = "same platform"


func _evaluate_chase_direction() -> float:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if _player == null:
		_last_behavior_reason = "no player found"
		return 0.0

	var horizontal_distance: float = absf(_player.global_position.x - global_position.x)
	if horizontal_distance > chase_detection_range:
		_last_behavior_reason = "player out of range dist=%.1f" % horizontal_distance
		return 0.0

	if not _is_player_on_horizontal_line(_player):
		return 0.0

	var floor_check: Dictionary = _check_floor_connectivity(_player)
	if not bool(floor_check.get("connected", false)):
		_last_behavior_reason = String(floor_check.get("reason", "floor disconnected"))
		return 0.0

	if _has_obstacle_between_player(_player):
		_last_behavior_reason = "obstacle between player and monster"
		return 0.0

	var toward_player: float = signf(_player.global_position.x - global_position.x)
	if is_zero_approx(toward_player):
		_last_behavior_reason = "player overlap"
		return 0.0

	_last_behavior_reason = "same platform"
	if debug_logs:
		print("[PatrolMonster] same_platform_detected monster=%s player=%s dir=%.1f" % [global_position, _player.global_position, toward_player])
	return toward_player


func _is_player_on_horizontal_line(player: CharacterBody2D) -> bool:
	var player_bounds: Dictionary = _get_player_vertical_bounds(player)
	var monster_line_y: float = global_position.y
	var min_y: float = float(player_bounds.get("min_y", monster_line_y))
	var max_y: float = float(player_bounds.get("max_y", monster_line_y))

	if monster_line_y < min_y - horizontal_line_tolerance or monster_line_y > max_y + horizontal_line_tolerance:
		_last_behavior_reason = "player not on horizontal line monster_y=%.1f player_range=[%.1f, %.1f]" % [monster_line_y, min_y, max_y]
		return false

	return true


func _check_floor_connectivity(player: CharacterBody2D) -> Dictionary:
	var monster_floor: Dictionary = _sample_floor_point(global_position.x, self)
	var player_floor: Dictionary = _sample_floor_point(player.global_position.x, player)
	if monster_floor.is_empty() or player_floor.is_empty():
		return {
			"connected": false,
			"reason": "floor miss monster_empty=%s player_empty=%s" % [monster_floor.is_empty(), player_floor.is_empty()],
		}

	var monster_floor_y: float = (monster_floor.get("position") as Vector2).y
	var player_floor_y: float = (player_floor.get("position") as Vector2).y
	if absf(monster_floor_y - player_floor_y) > floor_alignment_tolerance:
		return {
			"connected": false,
			"reason": "floor height mismatch monster=%s player=%s" % [monster_floor.get("position"), player_floor.get("position")],
		}

	var from_x: float = global_position.x
	var to_x: float = player.global_position.x
	var step: float = floor_connectivity_step
	if to_x < from_x:
		step *= -1.0

	var sample_x: float = from_x
	while absf(sample_x - to_x) > floor_connectivity_step:
		sample_x += step
		var sample_floor: Dictionary = _sample_floor_point(sample_x, null)
		if sample_floor.is_empty():
			return {
				"connected": false,
				"reason": "platform gap at x=%.1f" % sample_x,
			}

		var sample_floor_y: float = (sample_floor.get("position") as Vector2).y
		if absf(sample_floor_y - monster_floor_y) > floor_alignment_tolerance:
			return {
				"connected": false,
				"reason": "floor height mismatch monster=%s player=%s sample=(%.1f, %.1f)" % [
					monster_floor.get("position"),
					player_floor.get("position"),
					sample_x,
					sample_floor_y,
				],
			}

	return {
		"connected": true,
		"reason": "same platform",
	}


func _sample_floor_point(sample_x: float, body_to_ignore: PhysicsBody2D) -> Dictionary:
	var probe_y: float = global_position.y + _get_half_height() - floor_probe_margin
	var ray_from: Vector2 = Vector2(sample_x, probe_y)
	var ray_to: Vector2 = Vector2(sample_x, probe_y + edge_probe_depth + floor_probe_margin * 2.0)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(ray_from, ray_to)
	query.exclude = _build_ray_exclude(body_to_ignore)
	return get_world_2d().direct_space_state.intersect_ray(query)


func _has_obstacle_between_player(player: CharacterBody2D) -> bool:
	var ray_height: float = global_position.y
	var ray_from: Vector2 = Vector2(global_position.x, ray_height)
	var ray_to: Vector2 = Vector2(player.global_position.x, ray_height)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(ray_from, ray_to)
	query.exclude = _build_ray_exclude(player)
	var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	return not result.is_empty()


func _get_turn_reason(direction: float) -> String:
	if is_zero_approx(direction):
		return ""
	if _is_blocked_ahead(direction):
		return "blocked ahead"
	if not _has_floor_ahead(direction):
		return "edge ahead"
	return ""


func _is_blocked_ahead(direction: float) -> bool:
	return test_move(global_transform, Vector2(direction * wall_probe_distance, 0.0))


func _has_floor_ahead(direction: float) -> bool:
	var probe_transform: Transform2D = global_transform
	probe_transform.origin.x += direction * edge_probe_forward
	return test_move(probe_transform, Vector2(0.0, edge_probe_depth))


func _build_ray_exclude(body_to_ignore: CollisionObject2D) -> Array[RID]:
	var exclude: Array[RID] = [get_rid()]
	if _hurtbox != null:
		exclude.append(_hurtbox.get_rid())
	if body_to_ignore != null:
		exclude.append(body_to_ignore.get_rid())
	return exclude


func _get_player_vertical_bounds(player: CharacterBody2D) -> Dictionary:
	var center_y: float = player.global_position.y
	var half_height: float = 12.0
	var player_collision: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if player_collision != null:
		center_y = player_collision.global_position.y
		if player_collision.shape is CapsuleShape2D:
			var capsule: CapsuleShape2D = player_collision.shape as CapsuleShape2D
			half_height = capsule.height * 0.5 + capsule.radius
		elif player_collision.shape is RectangleShape2D:
			var rectangle: RectangleShape2D = player_collision.shape as RectangleShape2D
			half_height = rectangle.size.y * 0.5

	return {
		"min_y": center_y - half_height,
		"max_y": center_y + half_height,
	}


func _get_half_height() -> float:
	if _body_collision == null:
		return 12.0
	if _body_collision.shape is RectangleShape2D:
		var rectangle: RectangleShape2D = _body_collision.shape as RectangleShape2D
		return rectangle.size.y * 0.5
	if _body_collision.shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = _body_collision.shape as CapsuleShape2D
		return capsule.height * 0.5 + capsule.radius
	return 12.0


func _update_facing() -> void:
	var visual: CanvasItem = get_node_or_null("Visual") as CanvasItem
	if visual == null:
		return

	var facing_direction: float = _move_direction
	visual.scale.x = absf(visual.scale.x) * (-1.0 if facing_direction < 0.0 else 1.0)


func _log_behavior_tick() -> void:
	if not debug_logs or _behavior_log_timer < 1.0:
		return
	_behavior_log_timer = 0.0

	var behavior: String = "chase" if _is_currently_chasing else "patrol"
	var behavior_direction: float = _move_direction
	print("[PatrolMonster] behavior=%s dir=%.1f vel=%s pos=%s reason=%s" % [behavior, behavior_direction, velocity, global_position, _last_behavior_reason])
