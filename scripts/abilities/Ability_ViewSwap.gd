extends "res://scripts/abilities/ShiftAbility.gd"
class_name AbilityViewSwap

var _player_only_view: bool = false
var _saved_visibility: Dictionary = {}


func _init() -> void:
	ability_name = "ViewSwap"
	hold_to_maintain = false


func on_equipped(player: CharacterBody2D) -> void:
	_player_only_view = false
	_restore_saved_visibility(player)


func on_unequipped(player: CharacterBody2D) -> void:
	_player_only_view = false
	_restore_saved_visibility(player)


func execute(player: CharacterBody2D) -> void:
	_player_only_view = true
	_apply_view_state(player)
	emit_ability_used()


func cancel(player: CharacterBody2D) -> void:
	_player_only_view = false
	_restore_saved_visibility(player)
	emit_ability_used()


func _apply_view_state(player: CharacterBody2D) -> void:
	if player == null:
		return

	var current_scene: Node = player.get_tree().current_scene
	if current_scene == null:
		return

	_capture_visibility(current_scene)

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


func _capture_visibility(root: Node) -> void:
	if not _saved_visibility.is_empty() or root == null:
		return
	_capture_visibility_recursive(root)


func _capture_visibility_recursive(node: Node) -> void:
	if node is CanvasItem:
		_saved_visibility[node.get_instance_id()] = (node as CanvasItem).visible
	for child in node.get_children():
		_capture_visibility_recursive(child)


func _restore_saved_visibility(player: CharacterBody2D) -> void:
	if _saved_visibility.is_empty():
		return

	for instance_id in _saved_visibility.keys():
		var obj := instance_from_id(int(instance_id))
		if obj != null and obj is CanvasItem:
			(obj as CanvasItem).visible = bool(_saved_visibility[instance_id])

	_sync_level_door_visual_state(player)
	_saved_visibility.clear()


func _sync_level_door_visual_state(player: CharacterBody2D) -> void:
	if player == null or player.get_tree() == null:
		return

	var current_scene: Node = player.get_tree().current_scene
	if current_scene == null:
		return

	var doors := current_scene.find_children("*", "LevelDoor", true, false)
	for door in doors:
		if door == null:
			continue
		var collision := door.get_node_or_null("CollisionShape2D") as CollisionShape2D
		var sprite := door.get_node_or_null("Sprite2D") as CanvasItem
		if collision == null or sprite == null:
			continue
		sprite.visible = not collision.disabled


func _set_node_visibility(node: Node, visible: bool) -> void:
	if node == null:
		return

	if node is CanvasItem:
		(node as CanvasItem).visible = visible

	for child in node.get_children():
		_set_node_visibility(child, visible)
