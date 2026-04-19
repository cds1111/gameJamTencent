extends ShiftAbility
class_name AbilityEndCelebration


func _init() -> void:
	ability_name = "EndCelebration"
	hold_to_maintain = true


func execute(player: CharacterBody2D) -> void:
	if player == null:
		return

	emit_ability_used()

	var tree := player.get_tree()
	if tree == null or tree.current_scene == null:
		return

	var controller := tree.current_scene.get_node_or_null("CelebrationController")
	if controller != null and controller.has_method("trigger_random_celebration"):
		controller.trigger_random_celebration(player.global_position)


func cancel(_player: CharacterBody2D) -> void:
	pass
