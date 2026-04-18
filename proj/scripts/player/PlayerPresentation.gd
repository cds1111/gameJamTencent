extends Node

const ANIM_DEFAULT := "default"
const ANIM_WALK := "walk"
const ANIM_RUN := "run"
const ANIM_JUMP_UP := "jump_up"
const ANIM_JUMP_DOWN := "jump_down"
const ANIM_JUMP_END := "jump_end"
const ANIM_DIE := "die"

@onready var _player: CharacterBody2D = get_parent() as CharacterBody2D
@onready var _animated_sprite: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var _fallback_sprite: Sprite2D = $"../FallbackSprite"
@onready var _movement_sfx: Node = $"../MovementSfx"

var _was_on_floor := false
var _is_jump_landing := false


func _ready() -> void:
	_was_on_floor = _player.is_on_floor()
	if _animated_sprite != null and not _animated_sprite.animation_finished.is_connected(_on_animation_finished):
		_animated_sprite.animation_finished.connect(_on_animation_finished)
	_play_animation(ANIM_DEFAULT)


func _physics_process(_delta: float) -> void:
	if _player == null:
		return

	var direction := signf(_player.velocity.x)
	var gravity_flipped := _is_gravity_flipped()

	if direction != 0.0:
		var facing_left := direction < 0.0
		_animated_sprite.flip_h = facing_left
		_fallback_sprite.flip_h = facing_left

	_animated_sprite.flip_v = gravity_flipped
	_fallback_sprite.flip_v = gravity_flipped

	if _is_dead():
		_is_jump_landing = false
		_movement_sfx.stop_movement_loops()
		_play_animation(ANIM_DIE)
		return

	if _player.is_on_floor() and not _was_on_floor:
		_movement_sfx.play_land()
		_start_jump_end_if_needed()

	if _is_jump_landing:
		_was_on_floor = _player.is_on_floor()
		return

	if not _player.is_on_floor():
		_movement_sfx.stop_movement_loops()
		if _is_moving_against_gravity(gravity_flipped):
			_play_animation(ANIM_JUMP_UP)
		else:
			_play_animation(ANIM_JUMP_DOWN)
	elif absf(_player.velocity.x) > _get_run_threshold():
		_movement_sfx.play_run_loop()
		_play_animation(ANIM_RUN)
	elif absf(_player.velocity.x) > 0.01:
		_movement_sfx.play_walk_loop()
		_play_animation(ANIM_WALK)
	else:
		_movement_sfx.stop_movement_loops()
		_play_animation(ANIM_DEFAULT)

	_was_on_floor = _player.is_on_floor()


func play_jump_feedback() -> void:
	_is_jump_landing = false
	_movement_sfx.stop_movement_loops()
	_movement_sfx.play_jump()
	_play_animation(ANIM_JUMP_UP)


func refresh_state() -> void:
	_is_jump_landing = false


func _on_animation_finished() -> void:
	match _animated_sprite.animation:
		ANIM_JUMP_END:
			_is_jump_landing = false
			_play_animation(ANIM_DEFAULT)
		ANIM_DIE:
			_play_animation(ANIM_DIE)


func _start_jump_end_if_needed() -> void:
	if _has_animation(ANIM_JUMP_END):
		_is_jump_landing = true
		_movement_sfx.stop_movement_loops()
		_play_animation(ANIM_JUMP_END)
	else:
		_is_jump_landing = false


func _has_animation(name: String) -> bool:
	return _animated_sprite.sprite_frames and _animated_sprite.sprite_frames.has_animation(name) and _animated_sprite.sprite_frames.get_frame_count(name) > 0


func _play_animation(name: String) -> void:
	if _has_animation(name):
		_animated_sprite.visible = true
		_fallback_sprite.visible = false
		if _animated_sprite.animation != name:
			_animated_sprite.play(name)
	else:
		_show_fallback_frame(name)


func _show_fallback_frame(name: String) -> void:
	_animated_sprite.visible = false
	_fallback_sprite.visible = true
	match name:
		ANIM_DEFAULT:
			_fallback_sprite.frame = 0
		ANIM_WALK:
			_fallback_sprite.frame = 1
		ANIM_RUN:
			_fallback_sprite.frame = 2
		ANIM_JUMP_UP, ANIM_JUMP_DOWN, ANIM_JUMP_END:
			_fallback_sprite.frame = 3
		ANIM_DIE:
			_fallback_sprite.frame = 4


func _is_moving_against_gravity(gravity_flipped: bool) -> bool:
	return _player.velocity.y > 0.0 if gravity_flipped else _player.velocity.y < 0.0


func _get_run_threshold() -> float:
	if _player.has_method("get_base_speed"):
		return _player.get_base_speed() + 5.0
	return 225.0


func _is_dead() -> bool:
	return _player.has_method("is_dead") and _player.is_dead()


func _is_gravity_flipped() -> bool:
	return _player.has_method("is_gravity_flipped") and _player.is_gravity_flipped()
