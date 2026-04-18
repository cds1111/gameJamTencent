extends Node
class_name KeyDoorManager

@export var required_keys: int = 3
@export_node_path("Node2D") var keys_container_path: NodePath = NodePath("../Entities/Keys")
@export_node_path("Node") var door_path: NodePath = NodePath("../Entities/Doors/LevelDoor")

var _collected_count: int = 0
var _registered_key_count: int = 0


func _ready() -> void:
	_register_keys()
	_try_open_immediately_if_no_requirement()


func _register_keys() -> void:
	var keys_container := get_node_or_null(keys_container_path) as Node
	if keys_container == null:
		return

	for child in keys_container.get_children():
		if not (child is Area2D):
			continue
		if not child.has_signal("collected"):
			continue
		_registered_key_count += 1
		var on_collected := Callable(self , "_on_key_collected")
		if not child.is_connected("collected", on_collected):
			child.connect("collected", on_collected)


func _on_key_collected(_key: Node) -> void:
	_collected_count += 1
	if _collected_count >= required_keys:
		_open_door()


func _try_open_immediately_if_no_requirement() -> void:
	if required_keys <= 0:
		_open_door()
	elif _registered_key_count > 0 and _registered_key_count < required_keys:
		# 防止关卡里钥匙数量不足导致死锁，达到实际上限也允许开门
		required_keys = _registered_key_count


func _open_door() -> void:
	var door := get_node_or_null(door_path)
	if door == null:
		return
	if door.has_method("open"):
		door.call("open")
