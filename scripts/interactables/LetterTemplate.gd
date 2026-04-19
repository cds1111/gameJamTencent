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
@export var uppercase_visual_scale: Vector2 = Vector2.ONE
@export var lowercase_visual_scale: Vector2 = Vector2(0.5, 0.5)

var _is_uppercase := true

@onready var uppercase_root: CanvasItem = get_node_or_null("Uppercase") as CanvasItem
@onready var lowercase_root: CanvasItem = get_node_or_null("Lowercase") as CanvasItem

@onready var uppercase_sprite: Sprite2D = get_node_or_null("Uppercase/GlyphSprite") as Sprite2D
@onready var lowercase_sprite: Sprite2D = get_node_or_null("Lowercase/GlyphSprite") as Sprite2D
@onready var uppercase_label: Label = get_node_or_null("Uppercase/GlyphLabel") as Label
@onready var lowercase_label: Label = get_node_or_null("Lowercase/GlyphLabel") as Label

@onready var uppercase_collision: CollisionPolygon2D = get_node_or_null("Uppercase/CollisionPolygon2D") as CollisionPolygon2D
@onready var lowercase_collision: CollisionPolygon2D = get_node_or_null("Lowercase/CollisionPolygon2D") as CollisionPolygon2D


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

	_apply_variant_visuals(
		uppercase_sprite,
		uppercase_label,
		_get_uppercase_character(),
		uppercase_texture,
		uppercase_visual_scale
	)
	_apply_variant_visuals(
		lowercase_sprite,
		lowercase_label,
		_get_lowercase_character(),
		lowercase_texture,
		lowercase_visual_scale
	)

	_set_variant_active(uppercase_root, uppercase_collision, _is_uppercase)
	_set_variant_active(lowercase_root, lowercase_collision, not _is_uppercase)


func _apply_variant_visuals(
	sprite: Sprite2D,
	label: Label,
	display_text: String,
	texture: Texture2D,
	visual_scale: Vector2
) -> void:
	if label != null:
		label.text = display_text
		label.visible = texture == null
		label.scale = visual_scale

	if sprite != null:
		sprite.texture = texture
		sprite.visible = texture != null
		sprite.scale = visual_scale


func _set_variant_active(root: CanvasItem, collision: CollisionPolygon2D, active: bool) -> void:
	if root != null:
		root.visible = active
	if collision != null:
		collision.disabled = not active


func _get_uppercase_character() -> String:
	return _get_base_character().to_upper()


func _get_lowercase_character() -> String:
	return _get_base_character().to_lower()


func _get_base_character() -> String:
	var trimmed := character.strip_edges()
	if trimmed.is_empty():
		return "A"
	return trimmed.substr(0, 1)
