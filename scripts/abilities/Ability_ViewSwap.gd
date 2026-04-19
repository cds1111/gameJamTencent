extends "res://scripts/abilities/ShiftAbility.gd"
class_name AbilityViewSwap

var _player_only_view: bool = false


func _init() -> void:
	ability_name = "ViewSwap"
	hold_to_maintain = false


func on_equipped(player: CharacterBody2D) -> void:
	_player_only_view = false
	_apply_view_state(player)


func on_unequipped(player: CharacterBody2D) -> void:
	_restore_all_visibility(player)


func execute(player: CharacterBody2D) -> void:
	_player_only_view = true
	_apply_view_state(player)
	emit_ability_used()


func cancel(player: CharacterBody2D) -> void:
	_player_only_view = false
	_apply_view_state(player)
	emit_ability_used()


func _apply_view_state(player: CharacterBody2D) -> void:
	if player == null:
		return

	var current_scene: Node = player.get_tree().current_scene
	if current_scene == null:
		return

	_set_node_visibility(current_scene.get_node_or_null("Environment"), not _player_only_view)
	_set_node_visibility(current_scene.get_node_or_null("Spikes"), not _player_only_view)
	_set_entities_visibility(current_scene.get_node_or_null("Entities"), player)


func _set_entities_visibility(entities_root: Node, player: CharacterBody2D) -> void:
	if entities_root == null:
		return

	for child in entities_root.get_children():
		if child == player:
			_set_node_visibility(child, _player_only_view)
		else:
			_set_node_visibility(child, not _player_only_view)


func _restore_all_visibility(player: CharacterBody2D) -> void:
	if player == null:
		return

	var current_scene: Node = player.get_tree().current_scene
	if current_scene == null:
		return

	_set_node_visibility(current_scene.get_node_or_null("Environment"), true)
	_set_node_visibility(current_scene.get_node_or_null("Spikes"), true)
	_set_node_visibility(current_scene.get_node_or_null("Entities"), true)


func _set_node_visibility(node: Node, visible: bool) -> void:
	if node == null:
		return

	if node is CanvasItem:
		(node as CanvasItem).visible = visible

	for child in node.get_children():
		_set_node_visibility(child, visible)
