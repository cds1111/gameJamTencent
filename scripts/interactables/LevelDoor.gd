extends StaticBody2D
class_name LevelDoor

@onready var _sprite: CanvasItem = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D


func open() -> void:
	if _sprite != null:
		_sprite.visible = false
	if _collision != null:
		_collision.set_deferred("disabled", true)
