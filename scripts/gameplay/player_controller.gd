extends CharacterBody2D

const MOVE_SPEED := 180.0
const RUN_SPEED := 290.0
const JUMP_VELOCITY := -360.0
const GRAVITY := 980.0

const ANIM_DEFAULT := "default"
const ANIM_WALK := "walk"
const ANIM_RUN := "run"
const ANIM_JUMP_UP := "jump_up"
const ANIM_JUMP_DOWN := "jump_down"
const ANIM_JUMP_END := "jump_end"
const ANIM_DIE := "die"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fallback_sprite: Sprite2D = $FallbackSprite
@onready var movement_sfx: Node = $MovementSfx

var was_on_floor := false
var is_jump_landing := false
var is_dead := false

func _ready() -> void:
	was_on_floor = is_on_floor()
	_play_animation(ANIM_DEFAULT)
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = 0.0
		move_and_slide()
		return

	var direction := Input.get_axis("move_left", "move_right")
	var shift_multiplier := _get_shift_speed_multiplier()
	var max_move_speed := MOVE_SPEED * shift_multiplier

	if direction != 0.0:
		velocity.x = direction * max_move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 24.0)

	if direction != 0.0:
		var facing_left := direction < 0.0
		animated_sprite.flip_h = facing_left
		fallback_sprite.flip_h = facing_left

	if Input.is_action_just_pressed("jump") and is_on_floor():
		_jump_immediately()

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	move_and_slide()
	_update_animation_state(direction)


func _jump_immediately() -> void:
	velocity.y = JUMP_VELOCITY
	is_jump_landing = false
	movement_sfx.stop_movement_loops()
	movement_sfx.play_jump()
	_play_animation(ANIM_JUMP_UP)


func _update_animation_state(direction: float) -> void:
	if is_on_floor() and not was_on_floor:
		movement_sfx.play_land()
		_start_jump_end_if_needed()

	if is_jump_landing:
		was_on_floor = is_on_floor()
		return

	if not is_on_floor():
		movement_sfx.stop_movement_loops()
		if velocity.y < 0.0:
			_play_animation(ANIM_JUMP_UP)
		else:
			_play_animation(ANIM_JUMP_DOWN)
	elif absf(velocity.x) > MOVE_SPEED:
		movement_sfx.play_run_loop()
		_play_animation(ANIM_RUN)
	elif absf(direction) > 0.01:
		movement_sfx.play_walk_loop()
		_play_animation(ANIM_WALK)
	else:
		movement_sfx.stop_movement_loops()
		_play_animation(ANIM_DEFAULT)

	was_on_floor = is_on_floor()


func _start_jump_end_if_needed() -> void:
	if _has_animation(ANIM_JUMP_END):
		is_jump_landing = true
		movement_sfx.stop_movement_loops()
		_play_animation(ANIM_JUMP_END)
	else:
		is_jump_landing = false


func _on_animation_finished() -> void:
	match animated_sprite.animation:
		ANIM_JUMP_END:
			is_jump_landing = false
			_play_animation(ANIM_DEFAULT)
		ANIM_DIE:
			_play_animation(ANIM_DIE)


func _get_shift_speed_multiplier() -> float:
	# 预留 Shift 接口，默认不启用加速。
	if Input.is_action_pressed("run"):
		return 1.0
	return 1.0


func _has_animation(name: String) -> bool:
	return animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(name) and animated_sprite.sprite_frames.get_frame_count(name) > 0


func _play_animation(name: String) -> void:
	if _has_animation(name):
		animated_sprite.visible = true
		fallback_sprite.visible = false
		if animated_sprite.animation != name:
			animated_sprite.play(name)
	else:
		_show_fallback_frame(name)


func _show_fallback_frame(name: String) -> void:
	animated_sprite.visible = false
	fallback_sprite.visible = true
	match name:
		ANIM_DEFAULT:
			fallback_sprite.frame = 0
		ANIM_WALK:
			fallback_sprite.frame = 1
		ANIM_RUN:
			fallback_sprite.frame = 2
		ANIM_JUMP_UP, ANIM_JUMP_DOWN, ANIM_JUMP_END:
			fallback_sprite.frame = 3
		ANIM_DIE:
			fallback_sprite.frame = 4


func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_jump_landing = false
	velocity = Vector2.ZERO
	movement_sfx.stop_movement_loops()
	_play_animation(ANIM_DIE)
