extends StaticBody2D
class_name LetterTemplate

const CASE_TOGGLE_ABILITY := "CaseToggle"

@export var character: String = "A"
@export var start_uppercase: bool = true
@export var uppercase_texture: Texture2D
@export var lowercase_texture: Texture2D
@export var uppercase_collision_size: Vector2 = Vector2(32.0, 32.0)
@export var lowercase_collision_size: Vector2 = Vector2(16.0, 16.0)
@export var uppercase_visual_scale: Vector2 = Vector2.ONE
@export var lowercase_visual_scale: Vector2 = Vector2(0.5, 0.5)

var _is_uppercase: bool = true

@onready var glyph_sprite: Sprite2D = $GlyphSprite
@onready var glyph_label: Label = $GlyphLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_is_uppercase = start_uppercase
	_connect_signal_manager()
	_apply_case_state()


func set_character(value: String) -> void:
	character = value
	_apply_case_state()


func set_uppercase(value: bool) -> void:
	_is_uppercase = value
	_apply_case_state()


func toggle_case() -> void:
	_is_uppercase = not _is_uppercase
	_apply_case_state()


func _connect_signal_manager() -> void:
	var signal_manager: Node = get_node_or_null("/root/SignalManager")
	if signal_manager == null:
		return
	if not signal_manager.shift_ability_used.is_connected(_on_shift_ability_used):
		signal_manager.shift_ability_used.connect(_on_shift_ability_used)


func _on_shift_ability_used(ability_name: String) -> void:
	if ability_name != CASE_TOGGLE_ABILITY:
		return
	toggle_case()


func _apply_case_state() -> void:
	if not is_node_ready():
		return

	var display_text: String = _get_display_character()
	var current_texture: Texture2D = uppercase_texture if _is_uppercase else lowercase_texture
	var current_scale: Vector2 = uppercase_visual_scale if _is_uppercase else lowercase_visual_scale
	var collision_size: Vector2 = uppercase_collision_size if _is_uppercase else lowercase_collision_size

	glyph_label.text = display_text
	glyph_label.visible = current_texture == null
	glyph_label.scale = current_scale
	glyph_sprite.texture = current_texture
	glyph_sprite.visible = current_texture != null
	glyph_sprite.scale = current_scale

	var rectangle_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
	if rectangle_shape != null:
		rectangle_shape.size = collision_size


func _get_display_character() -> String:
	var trimmed: String = character.strip_edges()
	if trimmed.is_empty():
		trimmed = "A"
	var first_char: String = trimmed.substr(0, 1)
	return first_char.to_upper() if _is_uppercase else first_char.to_lower()
