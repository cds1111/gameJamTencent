extends Area2D
class_name Spring

const GIANT_SPRING_READY := 0
const GIANT_SPRING_WAITING_FOR_RETURN := 1
const GIANT_SPRING_WAITING_FOR_REARM := 2

@export var launch_force: float = 520.0
@export var horizontal_force: float = 0.0
@export var cooldown_seconds: float = 0.12
@export var require_downward_motion: bool = true
@export var giant_scale_threshold: float = 1.5
@export var giant_downward_tolerance: float = 8.0
@export var giant_above_tolerance: float = 20.0
@export var giant_horizontal_tolerance: float = 24.0

@onready var _animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer

var _is_on_cooldown := false
var _giant_spring_state := GIANT_SPRING_READY


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	if _is_on_cooldown:
		return

	for node in get_overlapping_bodies():
		var body := node as Node2D
		if body == null:
			continue
		if not body.is_in_group("player"):
			continue
		if not body.has_method("launch_from_spring"):
			continue
		if not _can_trigger_spring(body):
			continue
		if require_downward_motion and not _is_body_moving_toward_spring(body):
			continue
		_trigger_spring(body)
		break


func _on_body_entered(body: Node2D) -> void:
	# First-touch response; _physics_process covers stable overlap triggering.
	if not body.is_in_group("player"):
		return
	if not body.has_method("launch_from_spring"):
		return

	if _is_on_cooldown:
		return
	if not _can_trigger_spring(body):
		return
	if require_downward_motion and not _is_body_moving_toward_spring(body):
		return
	_trigger_spring(body)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _giant_spring_state == GIANT_SPRING_WAITING_FOR_REARM:
		_giant_spring_state = GIANT_SPRING_READY


func _trigger_spring(body: Node2D) -> void:
	_is_on_cooldown = true
	if _is_giant_body(body):
		_giant_spring_state = GIANT_SPRING_WAITING_FOR_RETURN
	_play_bounce_animation()
	body.launch_from_spring(launch_force, horizontal_force)
	_start_cooldown()


func _can_trigger_spring(body: Node2D) -> bool:
	if not _is_giant_body(body):
		return true
	if _giant_spring_state == GIANT_SPRING_READY:
		return true

	var up_direction := Vector2.UP
	if "up_direction" in body:
		up_direction = body.up_direction

	var body_velocity: Vector2 = body.velocity if "velocity" in body else Vector2.ZERO
	var downward_component := body_velocity.dot(-up_direction)
	var giant_downward_component := _get_giant_downward_component(body, up_direction, downward_component)

	if _giant_spring_state == GIANT_SPRING_WAITING_FOR_RETURN:
		if _is_giant_falling_onto_spring(body, up_direction, giant_downward_component):
			_giant_spring_state = GIANT_SPRING_WAITING_FOR_REARM
		return false

	if _is_body_moving_away_from_spring(body, up_direction):
		_giant_spring_state = GIANT_SPRING_READY
		return true
	return false


func _is_body_moving_toward_spring(body: Node2D) -> bool:
	if not ("velocity" in body):
		return true

	var body_velocity: Vector2 = body.velocity
	if "up_direction" in body:
		var up_direction: Vector2 = body.up_direction
		var downward_component := body_velocity.dot(-up_direction)
		if _is_giant_body(body):
			var giant_downward_component := _get_giant_downward_component(body, up_direction, downward_component)
			return _is_giant_falling_onto_spring(body, up_direction, giant_downward_component)
		if downward_component > 0.0:
			return true
		return false

	if _is_giant_body(body):
		return _is_giant_falling_onto_spring(body, Vector2.UP, body_velocity.y)
	if body_velocity.y > 0.0:
		return true
	return false


func _get_giant_downward_component(body: Node2D, up_direction: Vector2, downward_component: float) -> float:
	if not ("_pre_move_velocity_y" in body):
		return downward_component

	var pre_move_velocity := Vector2(0.0, body._pre_move_velocity_y)
	var pre_move_downward_component := pre_move_velocity.dot(-up_direction)
	return maxf(downward_component, pre_move_downward_component)


func _is_giant_falling_onto_spring(body: Node2D, up_direction: Vector2, downward_component: float) -> bool:
	# Use the pre-move fall speed as well, because floor collision can zero velocity first.
	if downward_component <= giant_downward_tolerance:
		return false

	var spring_to_body := body.global_position - global_position
	var distance_above_spring := spring_to_body.dot(up_direction)
	if distance_above_spring < -giant_above_tolerance:
		return false

	var side_axis := Vector2(up_direction.y, -up_direction.x)
	var horizontal_distance := absf(spring_to_body.dot(side_axis))
	return horizontal_distance <= giant_horizontal_tolerance


func _is_body_moving_away_from_spring(body: Node2D, up_direction: Vector2) -> bool:
	if not ("velocity" in body):
		return false

	var body_velocity: Vector2 = body.velocity
	var upward_component := body_velocity.dot(up_direction)
	if upward_component > giant_downward_tolerance:
		return true

	if not ("_pre_move_velocity_y" in body):
		return false

	var pre_move_velocity := Vector2(0.0, body._pre_move_velocity_y)
	var pre_move_upward_component := pre_move_velocity.dot(up_direction)
	return pre_move_upward_component > giant_downward_tolerance


func _is_giant_body(body: Node2D) -> bool:
	if not ("scale" in body):
		return false
	var s: Vector2 = body.scale
	return maxf(absf(s.x), absf(s.y)) >= giant_scale_threshold


func _start_cooldown() -> void:
	if cooldown_seconds <= 0.0:
		_is_on_cooldown = false
		return

	await get_tree().create_timer(cooldown_seconds).timeout
	_is_on_cooldown = false


func _play_bounce_animation() -> void:
	if _animation_player == null:
		return

	_animation_player.stop()
	_animation_player.play(&"bounce")
