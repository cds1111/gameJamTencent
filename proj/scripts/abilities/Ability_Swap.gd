extends "res://scripts/abilities/ShiftAbility.gd"
class_name AbilitySwap


func _init() -> void:
	ability_name = "Swap"
	hold_to_maintain = false


func execute(player: CharacterBody2D) -> void:
	if player == null or player.get_tree() == null:
		return

	var nearest: Node2D = _find_nearest_swappable(player)
	if nearest == null:
		return

	var player_pos := player.global_position
	player.global_position = nearest.global_position
	nearest.global_position = player_pos
	emit_ability_used()


func cancel(player: CharacterBody2D) -> void:
	# Swap is instant; no persistent state to rollback.
	pass


func _find_nearest_swappable(player: CharacterBody2D) -> Node2D:
	var candidates := player.get_tree().get_nodes_in_group("swappable")
	var nearest: Node2D = null
	var nearest_distance := INF

	for node in candidates:
		if node == null or node == player or not (node is Node2D):
			continue
		var distance := player.global_position.distance_to((node as Node2D).global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = node as Node2D

	return nearest
