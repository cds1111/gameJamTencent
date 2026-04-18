extends CharacterBody2D
class_name Player

const MOVE_SPEED := 180.0
const JUMP_VELOCITY := -360.0
const GRAVITY := 980.0
const FLOOR_DECELERATION := 24.0
const LANDING_VELOCITY_THRESHOLD := 60.0

const ANIM_DEFAULT := "default"
const ANIM_WALK := "walk"
const ANIM_RUN := "run"
const ANIM_JUMP_UP := "jump_up"
const ANIM_JUMP_DOWN := "jump_down"
const ANIM_JUMP_END := "jump_end"
const ANIM_DIE := "die"

@export var base_speed: float = MOVE_SPEED
@export var jump_velocity: float = JUMP_VELOCITY
@export var death_y_threshold: float = 3000.0

var _speed_multiplier := 1.0
var _jump_multiplier := 1.0
var _wind_force_x := 0.0
var _gravity_flipped := false
var _is_dead := false
var _death_finalized := false
var _was_on_floor := false
var _is_jump_landing := false
var _pre_move_velocity_y := 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var movement_sfx: Node = $MovementSfx
@onready var shift_handler: PlayerShiftHandler = $ShiftHandler


func _ready() -> void:
	add_to_group("player")
	_ensure_core_input_actions()
	_was_on_floor = is_on_floor()
	_play_animation(ANIM_DEFAULT)
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	if shift_handler != null:
		shift_handler.process_input(self)

	var direction := Input.get_axis("move_left", "move_right")
	_handle_horizontal_movement(direction)
	_handle_jump()
	_apply_gravity(delta)
	_pre_move_velocity_y = velocity.y

	move_and_slide()

	_check_hazard_collisions()
	_check_death_fall()
	_update_animation_state(direction)


func set_current_ability(ability: ShiftAbility) -> void:
	if shift_handler == null:
		return
	shift_handler.set_current_ability(ability, self)


func set_shift_mode(mode: PlayerShiftHandler.ShiftMode) -> void:
	if shift_handler == null:
		return
	shift_handler.set_shift_mode(mode, self)


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
	animated_sprite.flip_v = _gravity_flipped


func die() -> void:
	if _is_dead:
		return

	print("[Player] die start name=%s pos=%s vel=%s anim=%s" % [name, global_position, velocity, animated_sprite.animation])
	_is_dead = true
	_is_jump_landing = false
	velocity = Vector2.ZERO
	if shift_handler != null:
		shift_handler.cancel_active(self)
	movement_sfx.stop_movement_loops()
	_play_animation(ANIM_DIE)

	if not _has_animation(ANIM_DIE):
		_finalize_death()


func _handle_horizontal_movement(direction: float) -> void:
	var target_speed := direction * base_speed * _speed_multiplier + _wind_force_x
	if absf(direction) > 0.01 or absf(_wind_force_x) > 0.01:
		velocity.x = target_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, FLOOR_DECELERATION)

	if absf(direction) > 0.01:
		var facing_left := direction < 0.0
		animated_sprite.flip_h = facing_left


func _handle_jump() -> void:
	if not Input.is_action_just_pressed("jump"):
		return
	if not is_on_floor():
		return

	var jump_sign := 1.0 if _gravity_flipped else -1.0
	velocity.y = absf(jump_velocity) * jump_sign * _jump_multiplier
	_is_jump_landing = false
	movement_sfx.stop_movement_loops()
	movement_sfx.play_jump()
	_play_animation(ANIM_JUMP_UP)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	var gravity_sign := -1.0 if _gravity_flipped else 1.0
	velocity.y += GRAVITY * gravity_sign * delta


func _check_death_fall() -> void:
	if not _gravity_flipped and global_position.y <= death_y_threshold:
		return
	if _gravity_flipped and global_position.y >= -death_y_threshold:
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


func _update_animation_state(direction: float) -> void:
	var landed_this_frame := is_on_floor() \
		and not _was_on_floor \
		and absf(_pre_move_velocity_y) >= LANDING_VELOCITY_THRESHOLD

	if landed_this_frame:
		movement_sfx.play_land()
		_start_jump_end_if_needed()

	if _is_jump_landing:
		_was_on_floor = is_on_floor()
		return

	if not is_on_floor():
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


func _start_jump_end_if_needed() -> void:
	if _has_animation(ANIM_JUMP_END):
		_is_jump_landing = true
		movement_sfx.stop_movement_loops()
		_play_animation(ANIM_JUMP_END)
	else:
		_is_jump_landing = false


func _on_animation_finished() -> void:
	match animated_sprite.animation:
		ANIM_JUMP_END:
			_is_jump_landing = false
			_play_animation(ANIM_DEFAULT)
		ANIM_DIE:
			print("[Player] die animation finished -> finalize_death")
			_finalize_death()


func _finalize_death() -> void:
	if _death_finalized:
		return
	_death_finalized = true
	print("[Player] finalize_death emit player_died name=%s pos=%s" % [name, global_position])
	var signal_manager := get_node_or_null("/root/SignalManager")
	if signal_manager != null:
		signal_manager.player_died.emit()


func _has_animation(name: String) -> bool:
	return animated_sprite.sprite_frames != null \
		and animated_sprite.sprite_frames.has_animation(name) \
		and animated_sprite.sprite_frames.get_frame_count(name) > 0


func _play_animation(name: String) -> void:
	if _has_animation(name):
		if animated_sprite.animation != name:
			animated_sprite.play(name)


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
