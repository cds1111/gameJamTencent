extends "res://scripts/abilities/ShiftAbility.gd"
class_name AbilityLetterToggle


func _init() -> void:
	ability_name = "LetterToggle"
	hold_to_maintain = false


func execute(_player: CharacterBody2D) -> void:
	emit_ability_used()


func cancel(_player: CharacterBody2D) -> void:
	emit_ability_used()
