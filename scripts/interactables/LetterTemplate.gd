extends StaticBody2D
class_name LetterTemplate

const LETTER_TOGGLE_ABILITIES := {
	"LetterToggle": true,
	"CaseToggle": true,
}

@export var character: String = "A"
@export var start_uppercase: bool = true
@export var uppercase_texture: Texture2D
@export var lowercase_texture: Texture2D
@export var uppercase_collision_size: Vector2 = Vector2(32.0, 32.0)
@export var lowercase_collision_size: Vector2 = Vector2(16.0, 16.0)
@export var uppercase_visual_scale: Vector2 = Vector2.ONE
@export var lowercase_visual_scale: Vector2 = Vector2(0.5, 0.5)

var _is_uppercase: bool = true

@onready var glyph_sprite: Sprite2D = get_node_or_null("GlyphSprite") as Sprite2D
@onready var glyph_label: Label = get_node_or_null("GlyphLabel") as Label
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var uppercase_collision: Node = get_node_or_null("Uppercase")
@onready var lowercase_collision: Node = get_node_or_null("Lowercase")


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
	if not LETTER_TOGGLE_ABILITIES.has(ability_name):
		return
	toggle_case()


func _apply_case_state() -> void:
	if not is_node_ready():
		return

	var display_text: String = _get_display_character()
	var current_texture: Texture2D = uppercase_texture if _is_uppercase else lowercase_texture
	var current_scale: Vector2 = uppercase_visual_scale if _is_uppercase else lowercase_visual_scale
	var collision_size: Vector2 = uppercase_collision_size if _is_uppercase else lowercase_collision_size

	if glyph_label != null:
		glyph_label.text = display_text
		glyph_label.visible = current_texture == null
		glyph_label.scale = current_scale

	if glyph_sprite != null:
		glyph_sprite.texture = current_texture
		glyph_sprite.visible = current_texture != null
		glyph_sprite.scale = current_scale

	_apply_single_collision_shape(collision_size)
	_apply_split_collision_state()


func _apply_single_collision_shape(collision_size: Vector2) -> void:
	if collision_shape == null:
		return

	var rectangle_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
	if rectangle_shape != null:
		rectangle_shape.size = collision_size


func _apply_split_collision_state() -> void:
	_set_collision_node_disabled(uppercase_collision, not _is_uppercase)
	_set_collision_node_disabled(lowercase_collision, _is_uppercase)


func _set_collision_node_disabled(node: Node, disabled: bool) -> void:
	if node == null:
		return
	if node is CollisionShape2D:
		(node as CollisionShape2D).disabled = disabled
	elif node is CollisionPolygon2D:
		(node as CollisionPolygon2D).disabled = disabled


func _get_display_character() -> String:
	var trimmed: String = character.strip_edges()
	if trimmed.is_empty():
		trimmed = "A"
	var first_char: String = trimmed.substr(0, 1)
	return first_char.to_upper() if _is_uppercase else first_char.to_lower()
