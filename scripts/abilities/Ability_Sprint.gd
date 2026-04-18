extends "res://scripts/abilities/ShiftAbility.gd"
class_name AbilitySprint

@export var speed_multiplier: float = 2.0


func _init() -> void:
	ability_name = "Sprint"


func execute(player: CharacterBody2D) -> void:
	if player == null:
		return
	if player.has_method("set_speed_multiplier"):
		player.set_speed_multiplier(speed_multiplier)
	emit_ability_used()


func cancel(player: CharacterBody2D) -> void:
	if player == null:
		return
	if player.has_method("set_speed_multiplier"):
		player.set_speed_multiplier(1.0)
