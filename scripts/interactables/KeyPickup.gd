extends Area2D
class_name KeyPickup

signal collected(key: KeyPickup)

@export var auto_free_on_collect: bool = true

var _is_collected: bool = false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _is_collected:
		return
	if body == null or not body.is_in_group("player"):
		return

	_is_collected = true
	monitoring = false
	visible = false
	collected.emit(self )

	if auto_free_on_collect:
		queue_free()
