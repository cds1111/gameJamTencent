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
	var target_pos := nearest.global_position
	player.global_position = target_pos
	nearest.global_position = player_pos

	# 交换后立刻清理速度，避免把上一帧惯性带到新位置。
	if player is CharacterBody2D:
		(player as CharacterBody2D).velocity = Vector2.ZERO
	if nearest is CharacterBody2D:
		(nearest as CharacterBody2D).velocity = Vector2.ZERO

	# 通知可交换对象做位置重定位后的内部状态刷新（如巡逻原点重置）。
	if nearest.has_method("on_swapped"):
		nearest.call("on_swapped")
	if player.has_method("on_swapped"):
		player.call("on_swapped")

	if player.has_method("grant_damage_invulnerability"):
		player.grant_damage_invulnerability()
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
