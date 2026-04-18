extends CanvasLayer

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "transition"
const SETTINGS_KEY_STYLE := "style"
const DEFAULT_STYLE := "default"
const FAST_STYLE := "fast"
const MAIN_MENU_SCENE := "res://main.tscn"
const FALLBACK_LEVEL_SCENE := "res://scenes/levels/BaseLevel.tscn"
const LEVEL_SCENE_MAP := {
	2: "res://scenes/levels/Level_01_Sprint.tscn",
	5: "res://scenes/levels/Level_05_Swap.tscn",
}
const DEFAULT_COVER_TIME := 0.28
const DEFAULT_REVEAL_TIME := 0.24
const FAST_COVER_TIME := 0.09
const FAST_REVEAL_TIME := 0.08

var _overlay: ColorRect
var _dissolve_material: ShaderMaterial
var _fast_material: ShaderMaterial
var _is_transitioning: bool = false
var _transition_style: String = DEFAULT_STYLE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_overlay()
	_load_settings()
	_connect_signals()


func get_transition_style() -> String:
	return _transition_style


func set_transition_style(style_name: String) -> void:
	var normalized: String = style_name.to_lower()
	if normalized != FAST_STYLE:
		normalized = DEFAULT_STYLE
	_transition_style = normalized
	_save_settings()


func change_scene_to_file(scene_path: String) -> void:
	if _is_transitioning or scene_path.is_empty():
		return

	_is_transitioning = true
	await _play_cover()
	var error: Error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_warning("Scene transition failed for: %s" % scene_path)
	await get_tree().process_frame
	await _play_reveal()
	_is_transitioning = false


func reload_current_scene() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return
	change_scene_to_file(current_scene.scene_file_path)


func change_to_level(level_id: int) -> void:
	var scene_path: String = str(LEVEL_SCENE_MAP.get(level_id, ""))
	if scene_path.is_empty():
		scene_path = FALLBACK_LEVEL_SCENE
	change_scene_to_file(scene_path)


func return_to_menu() -> void:
	change_scene_to_file(MAIN_MENU_SCENE)


func _connect_signals() -> void:
	var signal_manager: Node = get_node_or_null("/root/SignalManager")
	if signal_manager == null:
		return
	if not signal_manager.level_completed.is_connected(_on_level_completed):
		signal_manager.level_completed.connect(_on_level_completed)


func _build_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.name = "SceneTransitionOverlay"
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color.BLACK
	_overlay.visible = false
	add_child(_overlay)

	_dissolve_material = ShaderMaterial.new()
	_dissolve_material.shader = Shader.new()
	_dissolve_material.shader.code = """
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float cell_size = 16.0;
uniform float softness : hint_range(0.001, 0.2) = 0.055;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 cell = floor(UV * screen_size / cell_size);
	float noise_value = hash(cell);
	float alpha = smoothstep(noise_value - softness, noise_value + softness, progress);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
"""

	_fast_material = ShaderMaterial.new()
	_fast_material.shader = Shader.new()
	_fast_material.shader.code = """
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.001, 0.2) = 0.03;
uniform float slant = 0.34;

void fragment() {
	float diagonal = UV.x + (1.0 - UV.y) * slant;
	float edge = progress * (1.0 + slant) - slant * 0.5;
	float alpha = smoothstep(diagonal - softness, diagonal + softness, edge);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
"""


func _play_cover() -> void:
	_overlay.visible = true
	if _transition_style == FAST_STYLE:
		_overlay.material = _fast_material
		_fast_material.set_shader_parameter("progress", 0.0)
		await _tween_shader_progress(_fast_material, 0.0, 1.0, FAST_COVER_TIME)
	else:
		_overlay.material = _dissolve_material
		_dissolve_material.set_shader_parameter("progress", 0.0)
		await _tween_shader_progress(_dissolve_material, 0.0, 1.0, DEFAULT_COVER_TIME)


func _play_reveal() -> void:
	if _transition_style == FAST_STYLE:
		_overlay.material = _fast_material
		_fast_material.set_shader_parameter("progress", 1.0)
		await _tween_shader_progress(_fast_material, 1.0, 0.0, FAST_REVEAL_TIME)
	else:
		_overlay.material = _dissolve_material
		_dissolve_material.set_shader_parameter("progress", 1.0)
		await _tween_shader_progress(_dissolve_material, 1.0, 0.0, DEFAULT_REVEAL_TIME)
	_overlay.visible = false


func _tween_shader_progress(material: ShaderMaterial, from_value: float, to_value: float, duration: float) -> void:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	material.set_shader_parameter("progress", from_value)
	tween.tween_method(
		func(value: float) -> void:
			material.set_shader_parameter("progress", value),
		from_value,
		to_value,
		duration
	)
	await tween.finished


func _load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		_transition_style = DEFAULT_STYLE
		return
	_transition_style = str(config.get_value(SETTINGS_SECTION, SETTINGS_KEY_STYLE, DEFAULT_STYLE))
	if _transition_style != FAST_STYLE:
		_transition_style = DEFAULT_STYLE


func _save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, SETTINGS_KEY_STYLE, _transition_style)
	config.save(SETTINGS_PATH)


func _on_level_completed(next_level_id: int) -> void:
	change_to_level(next_level_id)
