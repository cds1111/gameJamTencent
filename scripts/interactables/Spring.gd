extends Area2D
class_name Spring

@export var launch_force: float = 520.0
@export var horizontal_force: float = 0.0
@export var cooldown_seconds: float = 0.12
@export var require_downward_motion: bool = true
@export var giant_scale_threshold: float = 1.5
@export var giant_downward_tolerance: float = 8.0

@onready var _animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer

var _is_on_cooldown := false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


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
		if require_downward_motion and not _is_body_moving_toward_spring(body):
			continue
		_trigger_spring(body)
		break


func _on_body_entered(body: Node2D) -> void:
	# 仅用于“首次进入即触发”的响应；稳定触发由 _physics_process 覆盖。
	if not body.is_in_group("player"):
		return
	if not body.has_method("launch_from_spring"):
		return

	if _is_on_cooldown:
		return
	if require_downward_motion and not _is_body_moving_toward_spring(body):
		return
	_trigger_spring(body)


func _trigger_spring(body: Node2D) -> void:
	_is_on_cooldown = true
	_play_bounce_animation()
	body.launch_from_spring(launch_force, horizontal_force)
	_start_cooldown()


func _is_body_moving_toward_spring(body: Node2D) -> bool:
	if not ("velocity" in body):
		return true

	var body_velocity: Vector2 = body.velocity
	if "up_direction" in body:
		var up_direction: Vector2 = body.up_direction
		var downward_component := body_velocity.dot(-up_direction)
		if downward_component > 0.0:
			return true
		return _is_giant_pressing_spring(body, up_direction, downward_component)

	if body_velocity.y > 0.0:
		return true
	return _is_giant_pressing_spring(body, Vector2.UP, body_velocity.y)


func _is_giant_pressing_spring(body: Node2D, up_direction: Vector2, downward_component: float) -> bool:
	# 仅对巨人形态做兜底特判，普通体型维持原逻辑不变。
	if not _is_giant_body(body):
		return false
	if downward_component < -giant_downward_tolerance:
		return false

	var character := body as CharacterBody2D
	if character == null or not character.is_on_floor():
		return false

	# 仍需角色位于弹簧上方，避免巨人在弹簧下侧/反向时误触发。
	var spring_to_body := character.global_position - global_position
	return spring_to_body.dot(up_direction) > 0.0


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
