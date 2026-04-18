extends Area2D
class_name Spike

@export var startup_grace_physics_frames: int = 2

var _can_kill: bool = false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	call_deferred("_enable_kill_after_grace")


func _enable_kill_after_grace() -> void:
	for _i in range(maxi(startup_grace_physics_frames, 0)):
		await get_tree().physics_frame
	_can_kill = true


func _on_body_entered(body: Node2D) -> void:
	print("Spike detected body: ", body.name)
	if not _can_kill:
		return
	if not body.is_in_group("player"):
		return
	if not overlaps_body(body):
		return

	var signal_manager := get_node_or_null("/root/SignalManager")
	if signal_manager != null:
		signal_manager.player_died.emit()
