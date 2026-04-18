extends "res://scripts/abilities/ShiftAbility.gd"
class_name AbilitySprint

@export var dash_distance: float = 64.0


func _init() -> void:
	ability_name = "Sprint"


func execute(player: CharacterBody2D) -> void:
	if player == null:
		return
	if player.has_method("try_sprint") and player.try_sprint(dash_distance):
		emit_ability_used()


func cancel(player: CharacterBody2D) -> void:
	pass
