extends "res://scripts/abilities/ShiftAbility.gd"
class_name AbilityWind

@export var wind_force_x: float = 450.0


func _init() -> void:
	ability_name = "Wind"


func execute(player: CharacterBody2D) -> void:
	if player == null:
		return
	if player.has_method("set_wind_force"):
		player.set_wind_force(wind_force_x)
	emit_ability_used()


func cancel(player: CharacterBody2D) -> void:
	if player == null:
		return
	if player.has_method("set_wind_force"):
		player.set_wind_force(0.0)
