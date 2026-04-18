extends "res://scripts/abilities/ShiftAbility.gd"
class_name AbilityGiant

@export var giant_scale: Vector2 = Vector2(2.0, 2.0)
@export var jump_multiplier: float = 1.5


func _init() -> void:
	ability_name = "Giant"


func execute(player: CharacterBody2D) -> void:
	if player == null:
		return
	player.scale = giant_scale
	if player.has_method("set_jump_multiplier"):
		player.set_jump_multiplier(jump_multiplier)
	emit_ability_used()


func cancel(player: CharacterBody2D) -> void:
	if player == null:
		return
	player.scale = Vector2.ONE
	if player.has_method("set_jump_multiplier"):
		player.set_jump_multiplier(1.0)
