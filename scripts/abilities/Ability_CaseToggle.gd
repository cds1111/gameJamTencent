extends "res://scripts/abilities/ShiftAbility.gd"
class_name AbilityCaseToggle


func _init() -> void:
	ability_name = "CaseToggle"
	hold_to_maintain = false


func execute(player: CharacterBody2D) -> void:
	emit_ability_used()


func cancel(player: CharacterBody2D) -> void:
	emit_ability_used()
