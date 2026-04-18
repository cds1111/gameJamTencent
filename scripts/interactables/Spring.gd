extends Area2D
class_name Spring

@export var launch_force: float = 520.0
@export var horizontal_force: float = 0.0
@export var cooldown_seconds: float = 0.12
@export var require_downward_motion: bool = true

var _is_on_cooldown := false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _is_on_cooldown:
		return
	if not body.is_in_group("player"):
		return
	if not body.has_method("launch_from_spring"):
		return
	if require_downward_motion and not _is_body_moving_toward_spring(body):
		return

	_is_on_cooldown = true
	body.launch_from_spring(launch_force, horizontal_force)
	_start_cooldown()


func _is_body_moving_toward_spring(body: Node2D) -> bool:
	if not ("velocity" in body):
		return true

	var body_velocity: Vector2 = body.velocity
	if "up_direction" in body:
		var up_direction: Vector2 = body.up_direction
		return body_velocity.dot(-up_direction) > 0.0
	return body_velocity.y > 0.0


func _start_cooldown() -> void:
	if cooldown_seconds <= 0.0:
		_is_on_cooldown = false
		return

	await get_tree().create_timer(cooldown_seconds).timeout
	_is_on_cooldown = false
