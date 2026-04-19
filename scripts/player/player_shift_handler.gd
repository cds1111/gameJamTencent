extends Node
class_name PlayerShiftHandler

enum ShiftMode {
	DISABLED,
	SPRINT,
	GRAVITY_FLIP,
	SWAP,
	WIND,
	GIANT,
	VIEW_SWAP,
	CUSTOM,
	CASE_TOGGLE,
	GOAL_CONTROL,
	LETTER_TOGGLE,
}

enum ShiftInputMode {
	AUTO,
	HOLD,
	TOGGLE,
}

const ABILITY_SPRINT := preload("res://scripts/abilities/Ability_Sprint.gd")
const ABILITY_GRAVITY_FLIP := preload("res://scripts/abilities/Ability_GravityFlip.gd")
const ABILITY_SWAP := preload("res://scripts/abilities/Ability_Swap.gd")
const ABILITY_WIND := preload("res://scripts/abilities/Ability_Wind.gd")
const ABILITY_GIANT := preload("res://scripts/abilities/Ability_Giant.gd")
const ABILITY_VIEW_SWAP := preload("res://scripts/abilities/Ability_ViewSwap.gd")
const ABILITY_CASE_TOGGLE := preload("res://scripts/abilities/Ability_CaseToggle.gd")
const ABILITY_GOAL_CONTROL := preload("res://scripts/abilities/Ability_GoalControl.gd")
const ABILITY_LETTER_TOGGLE := preload("res://scripts/abilities/Ability_LetterToggle.gd")

@export var shift_mode: ShiftMode = ShiftMode.DISABLED
@export var input_mode: ShiftInputMode = ShiftInputMode.AUTO
@export var custom_ability: Resource

var _current_ability: ShiftAbility
var _ability_active := false


func _ready() -> void:
	_current_ability = _build_ability_for_mode()
	_equip_current_ability(get_parent() as CharacterBody2D)


func process_input(player: CharacterBody2D) -> void:
	if player == null or _current_ability == null:
		_ability_active = false
		return

	match _resolve_input_mode():
		ShiftInputMode.HOLD:
			if Input.is_action_pressed("shift"):
				if not _ability_active:
					_current_ability.execute(player)
					_ability_active = true
			elif _ability_active:
				_current_ability.cancel(player)
				_ability_active = false
		ShiftInputMode.TOGGLE:
			if not Input.is_action_just_pressed("shift"):
				return
			if _ability_active:
				_current_ability.cancel(player)
				_ability_active = false
			else:
				_current_ability.execute(player)
				_ability_active = true
		_:
			_ability_active = false


func process_active_ability(player: CharacterBody2D, delta: float) -> void:
	if not _ability_active or _current_ability == null or player == null:
		return
	_current_ability.physics_process(player, delta)


func set_shift_mode(value: ShiftMode, player: CharacterBody2D = null) -> void:
	shift_mode = value
	_rebuild_ability(player)


func set_current_ability(ability: ShiftAbility, player: CharacterBody2D = null) -> void:
	custom_ability = ability
	shift_mode = ShiftMode.CUSTOM
	_rebuild_ability(player)


func cancel_active(player: CharacterBody2D) -> void:
	if _ability_active and _current_ability != null and player != null:
		_current_ability.cancel(player)
	_ability_active = false


func _resolve_input_mode() -> ShiftInputMode:
	if input_mode != ShiftInputMode.AUTO:
		return input_mode
	if _current_ability != null and _current_ability.hold_to_maintain:
		return ShiftInputMode.HOLD
	return ShiftInputMode.TOGGLE


func _build_ability_for_mode() -> ShiftAbility:
	match shift_mode:
		ShiftMode.SPRINT:
			return ABILITY_SPRINT.new()
		ShiftMode.GRAVITY_FLIP:
			return ABILITY_GRAVITY_FLIP.new()
		ShiftMode.SWAP:
			return ABILITY_SWAP.new()
		ShiftMode.WIND:
			return ABILITY_WIND.new()
		ShiftMode.GIANT:
			return ABILITY_GIANT.new()
		ShiftMode.VIEW_SWAP:
			return ABILITY_VIEW_SWAP.new()
		ShiftMode.CUSTOM:
			return _clone_custom_ability()
		ShiftMode.CASE_TOGGLE:
			return ABILITY_CASE_TOGGLE.new()
		ShiftMode.GOAL_CONTROL:
			return ABILITY_GOAL_CONTROL.new()
		ShiftMode.LETTER_TOGGLE:
			return ABILITY_LETTER_TOGGLE.new()
		_:
			return null


func _clone_custom_ability() -> ShiftAbility:
	if custom_ability == null:
		return null
	if custom_ability is Script:
		return (custom_ability as Script).new()
	if custom_ability is ShiftAbility:
		return (custom_ability as ShiftAbility).duplicate(true)
	return null


func _rebuild_ability(player: CharacterBody2D) -> void:
	cancel_active(player)
	_unequip_current_ability(player)
	_current_ability = _build_ability_for_mode()
	_ability_active = false
	_equip_current_ability(player)


func _equip_current_ability(player: CharacterBody2D) -> void:
	if _current_ability == null or player == null:
		return
	_current_ability.on_equipped(player)


func _unequip_current_ability(player: CharacterBody2D) -> void:
	if _current_ability == null or player == null:
		return
	_current_ability.on_unequipped(player)
