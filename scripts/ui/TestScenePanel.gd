extends CanvasLayer

const ABILITY_DISABLED := -1
const ABILITY_SPRINT := preload("res://scripts/abilities/Ability_Sprint.gd")
const ABILITY_GRAVITY_FLIP := preload("res://scripts/abilities/Ability_GravityFlip.gd")
const ABILITY_SWAP := preload("res://scripts/abilities/Ability_Swap.gd")
const ABILITY_WIND := preload("res://scripts/abilities/Ability_Wind.gd")
const ABILITY_GIANT := preload("res://scripts/abilities/Ability_Giant.gd")
const ABILITY_VIEW_SWAP := preload("res://scripts/abilities/Ability_ViewSwap.gd")
const ABILITY_CASE_TOGGLE := preload("res://scripts/abilities/Ability_CaseToggle.gd")

@onready var ability_option: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/AbilityOption


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_options()
	ability_option.focus_mode = Control.FOCUS_NONE
	if not ability_option.item_selected.is_connected(_on_ability_selected):
		ability_option.item_selected.connect(_on_ability_selected)


func _setup_options() -> void:
	ability_option.clear()
	ability_option.add_item("DISABLED", ABILITY_DISABLED)
	ability_option.add_item("SPRINT", 0)
	ability_option.add_item("GRAVITY FLIP", 1)
	ability_option.add_item("SWAP", 2)
	ability_option.add_item("WIND", 3)
	ability_option.add_item("GIANT", 4)
	ability_option.add_item("VIEW SWAP", 5)
	ability_option.add_item("CASE TOGGLE", 6)
	ability_option.select(0)


func _on_ability_selected(index: int) -> void:
	var item_id: int = ability_option.get_item_id(index)
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	if item_id == ABILITY_DISABLED:
		if player.has_method("set_shift_mode"):
			player.set_shift_mode(PlayerShiftHandler.ShiftMode.DISABLED)
		return

	var ability: ShiftAbility = _build_ability(item_id)
	if ability == null:
		return
	if player.has_method("set_current_ability"):
		player.set_current_ability(ability)


func _build_ability(item_id: int) -> ShiftAbility:
	match item_id:
		0:
			return ABILITY_SPRINT.new()
		1:
			return ABILITY_GRAVITY_FLIP.new()
		2:
			return ABILITY_SWAP.new()
		3:
			return ABILITY_WIND.new()
		4:
			return ABILITY_GIANT.new()
		5:
			return ABILITY_VIEW_SWAP.new()
		6:
			return ABILITY_CASE_TOGGLE.new()
		_:
			return null
