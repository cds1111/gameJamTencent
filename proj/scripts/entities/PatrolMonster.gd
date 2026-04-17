extends Node2D
class_name PatrolMonster

@export var patrol_distance: float = 96.0
@export var patrol_speed: float = 70.0

var _origin_x: float
var _direction: float = 1.0


func _ready() -> void:
	add_to_group("swappable")
	var hurtbox := get_node_or_null("Hurtbox")
	if hurtbox != null:
		hurtbox.add_to_group("hazard")
	_origin_x = global_position.x


func _physics_process(delta: float) -> void:
	position.x += patrol_speed * _direction * delta
	if absf(global_position.x - _origin_x) >= patrol_distance:
		_direction *= -1.0
