extends Resource
class_name ShiftAbility

@export var ability_name: String = "ShiftAbility"
@export var hold_to_maintain: bool = true


func on_equipped(_player: CharacterBody2D) -> void:
	pass


func on_unequipped(_player: CharacterBody2D) -> void:
	pass


func execute(player: CharacterBody2D) -> void:
	push_warning("%s.execute() should be overridden." % ability_name)


func cancel(player: CharacterBody2D) -> void:
	push_warning("%s.cancel() should be overridden." % ability_name)


func physics_process(_player: CharacterBody2D, _delta: float) -> void:
	pass


func emit_ability_used() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	if not tree.root.has_node("SignalManager"):
		return
	var signal_manager := tree.root.get_node("SignalManager")
	signal_manager.shift_ability_used.emit(ability_name)
