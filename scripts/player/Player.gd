extends CharacterBody2D
class_name Player

const MOVE_SPEED := 125.0 # 玩家基础水平移动速度。
const JUMP_VELOCITY := -250.0 # 玩家起跳时施加的初始竖直速度。
const GRAVITY := 980.0 # 玩家在空中时每帧受到的重力加速度。
const FLOOR_DECELERATION := 24.0 # 松开移动键后在地面上的减速速度。
const LANDING_VELOCITY_THRESHOLD := 60.0 # 触发落地表现所需的最小下落速度。
const SPRINT_SPEED := 640.0 # 冲刺平移时的水平移动速度。

const ANIM_DEFAULT := "default" # 待机动画。
const ANIM_WALK := "walk" # 普通地面移动动画。
const ANIM_RUN := "run" # 快速移动动画。
const ANIM_SPRINT := "sprint" # 冲刺动画。
const ANIM_JUMP_UP := "jump_up" # 跳跃上升阶段动画。
const ANIM_JUMP_DOWN := "jump_down" # 跳跃下落阶段动画。
const ANIM_JUMP_END := "jump_end" # 落地过渡动画。
const ANIM_DIE := "die" # 死亡动画。

@export var base_speed: float = MOVE_SPEED
@export var jump_velocity: float = JUMP_VELOCITY
@export var death_y_threshold: float = 3000.0

var _jump_multiplier: float = 1.0
var _wind_force_x: float = 0.0
var _gravity_flipped: bool = false
var _is_dead: bool = false
var _death_finalized: bool = false
var _sprint_consumed: bool = false
var _sprint_reset_timer: float = 0.0
var _last_sprint_velocity_y: float = 0.0
var _is_sprinting: bool = false
var _sprint_direction: float = 0.0
var _sprint_distance_remaining: float = 0.0
var _was_on_floor: bool = false
var _is_jump_landing: bool = false
var _pre_move_velocity_y: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var movement_sfx: Node = $MovementSfx
@onready var shift_handler: PlayerShiftHandler = $ShiftHandler


# 初始化玩家输入、动画和分组状态。
func _ready() -> void:
	add_to_group("player")
	_ensure_core_input_actions()
	_was_on_floor = is_on_floor()
	_play_animation(ANIM_DEFAULT)
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)


# 每帧处理玩家移动、能力输入、碰撞和动画状态。
func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	if shift_handler != null:
		shift_handler.process_input(self)

	var direction: float = Input.get_axis("move_left", "move_right")
	if _is_sprinting:
		_handle_sprint_motion(delta)
	else:
		_handle_horizontal_movement(direction)
		_handle_jump()
		_apply_gravity(delta)

	_pre_move_velocity_y = velocity.y
	move_and_slide()

	_check_hazard_collisions()
	_check_death_fall()
	_update_sprint_reset(delta)
	_update_animation_state(direction)


# 设置玩家当前可用的切换能力。
func set_current_ability(ability: ShiftAbility) -> void:
	if shift_handler == null:
		return
	shift_handler.set_current_ability(ability, self)


# 设置玩家当前的能力模式。
func set_shift_mode(mode: PlayerShiftHandler.ShiftMode) -> void:
	if shift_handler == null:
		return
	shift_handler.set_shift_mode(mode, self)


# 设置跳跃倍率，供能力系统动态修改跳跃强度。
func set_jump_multiplier(value: float) -> void:
	_jump_multiplier = maxf(value, 0.1)


# 设置额外水平风力。
func set_wind_force(value: float) -> void:
	_wind_force_x = value


# 触发一次水平冲刺，地面和空中都可使用，落地后重置次数。
func try_sprint(distance: float) -> bool:
	if _is_sprinting or _sprint_consumed:
		return false

	var dash_direction: float = Input.get_axis("move_left", "move_right")
	if absf(dash_direction) <= 0.01:
		dash_direction = -1.0 if animated_sprite.flip_h else 1.0
	else:
		animated_sprite.flip_h = dash_direction < 0.0

	var allowed_motion: float = _get_allowed_sprint_motion(signf(dash_direction) * distance)
	if is_zero_approx(allowed_motion):
		return false

	_is_sprinting = true
	_sprint_consumed = true
	_sprint_reset_timer = 0.0
	_last_sprint_velocity_y = velocity.y
	_is_jump_landing = false
	_sprint_direction = signf(allowed_motion)
	_sprint_distance_remaining = absf(allowed_motion)
	velocity = Vector2.ZERO
	movement_sfx.stop_movement_loops()
	_play_animation(ANIM_SPRINT)
	return true


# 切换重力方向。
func toggle_gravity_flip() -> void:
	set_gravity_flipped(not _gravity_flipped)


# 直接设置当前重力方向并同步角色朝向。
func set_gravity_flipped(value: bool) -> void:
	_gravity_flipped = value
	up_direction = Vector2.DOWN if _gravity_flipped else Vector2.UP
	animated_sprite.flip_v = _gravity_flipped


# 被弹簧等外力发射时更新速度和表现。
func launch_from_spring(force: float, horizontal_force: float = 0.0) -> void:
	if _is_dead:
		return

	var launch_force: float = absf(force)
	velocity.y = launch_force if _gravity_flipped else -launch_force
	velocity.x = horizontal_force
	_is_sprinting = false
	_sprint_distance_remaining = 0.0
	_is_jump_landing = false
	_was_on_floor = false
	movement_sfx.stop_movement_loops()
	movement_sfx.play_jump()
	_play_animation(ANIM_JUMP_UP)


# 触发死亡流程并播放死亡动画。
func die() -> void:
	if _is_dead:
		return

	print("[Player] die start name=%s pos=%s vel=%s anim=%s" % [name, global_position, velocity, animated_sprite.animation])
	_is_dead = true
	_is_sprinting = false
	_is_jump_landing = false
	velocity = Vector2.ZERO
	if shift_handler != null:
		shift_handler.cancel_active(self)
	movement_sfx.stop_movement_loops()
	_play_animation(ANIM_DIE)

	if not _has_animation(ANIM_DIE):
		_finalize_death()


# 根据输入和环境力更新水平速度。
func _handle_horizontal_movement(direction: float) -> void:
	var target_speed: float = direction * base_speed + _wind_force_x
	if absf(direction) > 0.01 or absf(_wind_force_x) > 0.01:
		velocity.x = target_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, FLOOR_DECELERATION)

	if absf(direction) > 0.01:
		animated_sprite.flip_h = direction < 0.0


# 按剩余距离推进冲刺，使用平移动画而不是闪现。
func _handle_sprint_motion(delta: float) -> void:
	var step_distance: float = minf(SPRINT_SPEED * delta, _sprint_distance_remaining)
	var allowed_motion: float = _get_allowed_sprint_motion(_sprint_direction * step_distance)

	if is_zero_approx(allowed_motion):
		_finish_sprint()
		return

	velocity.x = allowed_motion / delta
	velocity.y = 0.0
	_sprint_distance_remaining -= absf(allowed_motion)

	if _sprint_distance_remaining <= 0.001:
		_finish_sprint()


# 在允许起跳时施加跳跃初速度并切换表现。
func _handle_jump() -> void:
	if not Input.is_action_just_pressed("jump"):
		return
	if not is_on_floor():
		return

	var jump_sign: float = 1.0 if _gravity_flipped else -1.0
	velocity.y = absf(jump_velocity) * jump_sign * _jump_multiplier
	_is_jump_landing = false
	movement_sfx.stop_movement_loops()
	movement_sfx.play_jump()
	_play_animation(ANIM_JUMP_UP)


# 在空中持续施加重力。
func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	var gravity_sign: float = -1.0 if _gravity_flipped else 1.0
	velocity.y += GRAVITY * gravity_sign * delta


# 结束冲刺并恢复正常物理更新。
func _finish_sprint() -> void:
	_is_sprinting = false
	_sprint_distance_remaining = 0.0
	velocity.x = 0.0


# 按“落地”或“0.3 秒内竖直速度无变化”规则恢复冲刺次数。
func _update_sprint_reset(delta: float) -> void:
	if not _sprint_consumed:
		return

	if is_on_floor():
		_sprint_consumed = false
		_sprint_reset_timer = 0.0
		return

	var vertical_velocity_changed: bool = not is_equal_approx(velocity.y, _last_sprint_velocity_y)
	if vertical_velocity_changed:
		_last_sprint_velocity_y = velocity.y
		_sprint_reset_timer = 0.0
		return

	_sprint_reset_timer += delta
	if _sprint_reset_timer >= 0.3:
		_sprint_consumed = false
		_sprint_reset_timer = 0.0


# 检查是否超出死亡边界。
func _check_death_fall() -> void:
	if not _gravity_flipped and global_position.y <= death_y_threshold:
		return
	if _gravity_flipped and global_position.y >= -death_y_threshold:
		return
	die()


# 检查角色是否撞到带 hazard 分组的危险物。
func _check_hazard_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		if collision == null:
			continue
		var collider: Node = collision.get_collider() as Node
		if collider != null and collider.is_in_group("hazard"):
			die()
			return


# 根据移动和落地状态更新动画与音效。
func _update_animation_state(direction: float) -> void:
	var landed_this_frame: bool = is_on_floor() \
		and not _was_on_floor \
		and absf(_pre_move_velocity_y) >= LANDING_VELOCITY_THRESHOLD

	if landed_this_frame:
		movement_sfx.play_land()
		_start_jump_end_if_needed()

	if _is_jump_landing:
		_was_on_floor = is_on_floor()
		return

	if _is_sprinting:
		movement_sfx.play_run_loop()
		_play_animation(ANIM_SPRINT)
	elif not is_on_floor():
		movement_sfx.stop_movement_loops()
		if (_gravity_flipped and velocity.y > 0.0) or (not _gravity_flipped and velocity.y < 0.0):
			_play_animation(ANIM_JUMP_UP)
		else:
			_play_animation(ANIM_JUMP_DOWN)
	elif absf(velocity.x) > base_speed * 1.2:
		movement_sfx.play_run_loop()
		_play_animation(ANIM_RUN)
	elif absf(direction) > 0.01:
		movement_sfx.play_walk_loop()
		_play_animation(ANIM_WALK)
	else:
		movement_sfx.stop_movement_loops()
		_play_animation(ANIM_DEFAULT)

	_was_on_floor = is_on_floor()


# 如果存在落地动画，则进入落地过渡状态。
func _start_jump_end_if_needed() -> void:
	if _has_animation(ANIM_JUMP_END):
		_is_jump_landing = true
		movement_sfx.stop_movement_loops()
		_play_animation(ANIM_JUMP_END)
	else:
		_is_jump_landing = false


# 动画播完后处理落地收尾和死亡收尾。
func _on_animation_finished() -> void:
	match animated_sprite.animation:
		ANIM_JUMP_END:
			_is_jump_landing = false
			_play_animation(ANIM_DEFAULT)
		ANIM_DIE:
			print("[Player] die animation finished -> finalize_death")
			_finalize_death()


# 广播玩家死亡事件，避免重复发送。
func _finalize_death() -> void:
	if _death_finalized:
		return
	_death_finalized = true
	print("[Player] finalize_death emit player_died name=%s pos=%s" % [name, global_position])
	var signal_manager: Node = get_node_or_null("/root/SignalManager")
	if signal_manager != null:
		signal_manager.player_died.emit()


# 判断指定动画是否存在且至少有一帧。
func _has_animation(name: String) -> bool:
	return animated_sprite.sprite_frames != null \
		and animated_sprite.sprite_frames.has_animation(name) \
		and animated_sprite.sprite_frames.get_frame_count(name) > 0


# 安全播放动画，避免切到不存在或重复的动画。
func _play_animation(name: String) -> void:
	if _has_animation(name) and animated_sprite.animation != name:
		animated_sprite.play(name)


# 逐像素测试可执行的冲刺位移，避免冲进墙体。
func _get_allowed_sprint_motion(target_distance: float) -> float:
	var test_transform: Transform2D = global_transform
	var step: float = 1.0 if target_distance > 0.0 else -1.0
	var allowed_distance: float = 0.0

	for _i in range(int(absf(target_distance))):
		var motion := Vector2(step, 0.0)
		if test_move(test_transform, motion):
			break
		test_transform.origin += motion
		allowed_distance += step

	return allowed_distance


# 确保项目运行时具备玩家核心输入映射。
func _ensure_core_input_actions() -> void:
	_ensure_action_key("move_left", KEY_A)
	_ensure_action_key("move_right", KEY_D)
	_ensure_action_key("jump", KEY_SPACE)
	_ensure_action_key("shift", KEY_SHIFT)
	_ensure_action_key("restart_level", KEY_R)


# 若输入映射中缺少指定按键，则自动补上。
func _ensure_action_key(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and (event as InputEventKey).keycode == keycode:
			return

	var key_event: InputEventKey = InputEventKey.new()
	key_event.keycode = keycode
	InputMap.action_add_event(action_name, key_event)
