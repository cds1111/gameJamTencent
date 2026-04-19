extends "res://scripts/abilities/ShiftAbility.gd"
class_name AbilityWind

@export var wind_force_x: float = 90.0

var _wind_points_right: bool = false


func _init() -> void:
	ability_name = "Wind"
	hold_to_maintain = false


func on_equipped(player: CharacterBody2D) -> void:
	_wind_points_right = false
	_apply_wind(player)


func on_unequipped(player: CharacterBody2D) -> void:
	if player == null:
		return
	if player.has_method("set_wind_force"):
		player.set_wind_force(0.0)


func execute(player: CharacterBody2D) -> void:
	if player == null:
		return
	_wind_points_right = true
	_apply_wind(player)
	emit_ability_used()


func cancel(player: CharacterBody2D) -> void:
	if player == null:
		return
	_wind_points_right = false
	_apply_wind(player)
	emit_ability_used()


func _apply_wind(player: CharacterBody2D) -> void:
	if player == null:
		return
	if player.has_method("set_wind_force"):
		player.set_wind_force(absf(wind_force_x) if _wind_points_right else -absf(wind_force_x))
