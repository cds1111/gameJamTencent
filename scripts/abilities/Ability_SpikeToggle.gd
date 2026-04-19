extends "res://scripts/abilities/ShiftAbility.gd"
class_name AbilitySpikeToggle

var _state_one_active: bool = true


func _init() -> void:
	ability_name = "SpikeToggle"
	hold_to_maintain = false


func on_equipped(player: CharacterBody2D) -> void:
	_state_one_active = true
	_apply_state(player)


func execute(player: CharacterBody2D) -> void:
	_toggle_state(player)


func cancel(player: CharacterBody2D) -> void:
	_toggle_state(player)


func _toggle_state(player: CharacterBody2D) -> void:
	_state_one_active = not _state_one_active
	_apply_state(player)
	emit_ability_used()


func _apply_state(player: CharacterBody2D) -> void:
	if player == null or player.get_tree() == null:
		return
	var scene_root := player.get_tree().current_scene
	if scene_root == null:
		return

	var spike_group_1 := scene_root.get_node_or_null("Spike1")
	var spike_group_2 := scene_root.get_node_or_null("Spike2")
	if spike_group_1 == null or spike_group_2 == null:
		push_warning("[AbilitySpikeToggle] Missing Spike1 or Spike2 root node in current scene.")
		return

	_set_spike_group_enabled(spike_group_1, _state_one_active)
	_set_spike_group_enabled(spike_group_2, not _state_one_active)


func _set_spike_group_enabled(root: Node, enabled: bool) -> void:
	if root is CanvasItem:
		(root as CanvasItem).visible = enabled

	if root is Area2D:
		var area := root as Area2D
		area.monitoring = enabled
		area.monitorable = enabled

	if root is CollisionShape2D:
		(root as CollisionShape2D).set_deferred("disabled", not enabled)

	for child in root.get_children():
		_set_spike_group_enabled(child, enabled)