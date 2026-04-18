extends "res://scripts/abilities/ShiftAbility.gd"
class_name AbilityGravityFlip


func _init() -> void:
	ability_name = "GravityFlip"
	hold_to_maintain = false


func execute(player: CharacterBody2D) -> void:
	if player == null:
		return
	if player.has_method("toggle_gravity_flip"):
		player.toggle_gravity_flip()
	emit_ability_used()


func cancel(player: CharacterBody2D) -> void:
	if player == null:
		return
	if player.has_method("set_gravity_flipped"):
		player.set_gravity_flipped(false)
