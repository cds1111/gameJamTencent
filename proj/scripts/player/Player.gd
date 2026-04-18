extends CharacterBody2D
class_name Player

@export var base_speed: float = 220.0
@export var jump_velocity: float = -360.0
@export var death_y_threshold: float = 3000.0

var current_ability: ShiftAbility

var _speed_multiplier: float = 1.0
var _jump_multiplier: float = 1.0
var _wind_force_x: float = 0.0
var _gravity_flipped: bool = false
var _ability_active: bool = false
var _is_dead: bool = false

@onready var _presentation: Node = $PlayerPresentation


func _ready() -> void:
	add_to_group("player")
	_ensure_core_input_actions()


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_process_shift_input()
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement()
	move_and_slide()
	
	# 保留基于物理碰撞体的检测 (用于移动的锯齿等 StaticBody)
	# 删除了极度消耗性能的 Area2D 每帧轮询，Area2D (尖刺) 将交由信号自己处理
	_check_hazard_collisions() 
	_check_death_fall()


func _process_shift_input() -> void:
	if current_ability == null:
		_ability_active = false
		return

	# 模式1：长按维持 (例如：疾跑)
	if current_ability.hold_to_maintain:
		if Input.is_action_pressed("shift"):
			if not _ability_active:
				current_ability.execute(self)
				_ability_active = true
				_refresh_presentation()
		elif _ability_active:
			current_ability.cancel(self)
			_ability_active = false
			_refresh_presentation()
		return

	# 模式2：按下切换/一次性触发 (例如：换位、重力反转)
	if Input.is_action_just_pressed("shift"):
		if not _ability_active:
			current_ability.execute(self)
			# 如果你的技能需要再按一次取消，它应该设置 _ability_active
			_ability_active = true
			_refresh_presentation()
		else:
			current_ability.cancel(self)
			_ability_active = false
			_refresh_presentation()

func set_current_ability(ability: ShiftAbility) -> void:
	if current_ability != null:
		current_ability.cancel(self )
	current_ability = ability
	_ability_active = false


func set_speed_multiplier(value: float) -> void:
	_speed_multiplier = maxf(value, 0.1)


func set_jump_multiplier(value: float) -> void:
	_jump_multiplier = maxf(value, 0.1)


func set_wind_force(value: float) -> void:
	_wind_force_x = value


func toggle_gravity_flip() -> void:
	set_gravity_flipped(not _gravity_flipped)


func set_gravity_flipped(value: bool) -> void:
	_gravity_flipped = value
	up_direction = Vector2.DOWN if _gravity_flipped else Vector2.UP


func _apply_gravity(delta: float) -> void:
	var gravity := ProjectSettings.get_setting("physics/2d/default_gravity") as float
	var gravity_sign := -1.0 if _gravity_flipped else 1.0
	velocity.y += gravity * gravity_sign * delta


func _handle_jump() -> void:
	if not Input.is_action_just_pressed("jump"):
		return
	if not is_on_floor():
		return

	var jump_sign := 1.0 if _gravity_flipped else -1.0
	velocity.y = absf(jump_velocity) * jump_sign * _jump_multiplier
	if _presentation != null and _presentation.has_method("play_jump_feedback"):
		_presentation.play_jump_feedback()


func _handle_movement() -> void:
	var input_axis := Input.get_axis("move_left", "move_right")
	velocity.x = input_axis * base_speed * _speed_multiplier + _wind_force_x


func _check_death_fall() -> void:
	if global_position.y <= death_y_threshold and not _gravity_flipped:
		return
	if global_position.y >= -death_y_threshold and _gravity_flipped:
		return
	die()


func _check_hazard_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		if collision == null:
			continue
		var collider := collision.get_collider() as Node
		if collider != null and collider.is_in_group("hazard"):
			die()
			return


func _check_hazard_area_overlaps() -> void:
	var hazards := get_tree().get_nodes_in_group("hazard")
	for hazard in hazards:
		if not (hazard is Area2D):
			continue
		if (hazard as Area2D).overlaps_body(self ):
			die()
			return


func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	var signal_manager := get_node_or_null("/root/SignalManager")
	if signal_manager != null:
		signal_manager.player_died.emit()


func is_dead() -> bool:
	return _is_dead


func is_gravity_flipped() -> bool:
	return _gravity_flipped


func get_base_speed() -> float:
	return base_speed


func _refresh_presentation() -> void:
	if _presentation != null and _presentation.has_method("refresh_state"):
		_presentation.refresh_state()


func _ensure_core_input_actions() -> void:
	_ensure_action_key("move_left", KEY_A)
	_ensure_action_key("move_right", KEY_D)
	_ensure_action_key("jump", KEY_SPACE)
	_ensure_action_key("shift", KEY_SHIFT)
	_ensure_action_key("restart_level", KEY_R)


func _ensure_action_key(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and (event as InputEventKey).keycode == keycode:
			return

	var key_event := InputEventKey.new()
	key_event.keycode = keycode
	InputMap.action_add_event(action_name, key_event)
