extends CanvasLayer

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "transition"
const SETTINGS_KEY_STYLE := "style"
const DEFAULT_STYLE := "default"
const FAST_STYLE := "fast"
const MAIN_MENU_SCENE := "res://main.tscn"
const FALLBACK_LEVEL_SCENE := "res://scenes/levels/BaseLevel.tscn"
const LEVEL_SCENE_MAP := {
	1: "res://scenes/levels/Level_01_Sprint.tscn",
	2: "res://scenes/levels/Level_02.tscn",
	3: "res://scenes/levels/Level_03_Swap.tscn",
	4: "res://scenes/levels/Level_04_GravityFlip.tscn",
	5: "res://scenes/levels/Level_05_ViewSwap.tscn",
	6: "res://scenes/levels/Level_06_GoalControl.tscn",
	7: "res://scenes/levels/Level_07_Wind.tscn",
	8: "res://scenes/levels/Level_08_PhantomBlink.tscn",
	9: "res://scenes/levels/Level_09_TOGETOGE.tscn",
	10: "res://scenes/the_end.tscn",
}
const DEFAULT_COVER_TIME := 0.28
const DEFAULT_REVEAL_TIME := 0.24
const FAST_COVER_TIME := 0.09
const FAST_REVEAL_TIME := 0.08
const CELEBRATION_TEXT := "congratulations!"
const CELEBRATION_FONT := preload("res://assets/fonts/PressStart2P-Regular.ttf")
const CELEBRATION_SFX: AudioStream = preload("res://assets/music/mixkit_arcade_video_game_win_212.wav")
const CELEBRATION_EXTRA_TIME := 0.4
const CONFETTI_COLORS := [
	Color(1.0, 0.96, 0.45, 1.0),
	Color(1.0, 0.55, 0.38, 1.0),
	Color(0.45, 0.9, 1.0, 1.0),
	Color(0.62, 1.0, 0.55, 1.0),
	Color(1.0, 0.62, 0.88, 1.0),
]

var _overlay: ColorRect
var _dissolve_material: ShaderMaterial
var _fast_material: ShaderMaterial
var _is_transitioning: bool = false
var _transition_style: String = DEFAULT_STYLE
var _celebration_layer: Control
var _celebration_banner: Control
var _celebration_label: Label
var _celebration_particles: Array[CPUParticles2D] = []
var _confetti_texture: Texture2D
var _celebration_sfx_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_celebration_audio()
	_build_celebration_ui()
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
	await _run_scene_change(scene_path)
	_is_transitioning = false


func reload_current_scene() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return
	change_scene_to_file(current_scene.scene_file_path)


func change_to_level(level_id: int) -> void:
	var scene_path: String = _get_level_scene_path(level_id)
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


func _build_celebration_ui() -> void:
	_confetti_texture = _create_confetti_texture()

	_celebration_layer = Control.new()
	_celebration_layer.name = "LevelCompleteCelebration"
	_celebration_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_celebration_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_celebration_layer.visible = false
	add_child(_celebration_layer)

	_celebration_banner = Control.new()
	_celebration_banner.name = "CelebrationBanner"
	_celebration_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_celebration_banner.custom_minimum_size = Vector2(1080.0, 116.0)
	_celebration_layer.add_child(_celebration_banner)

	_celebration_label = Label.new()
	_celebration_label.name = "CelebrationLabel"
	_celebration_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_celebration_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_celebration_label.text = CELEBRATION_TEXT
	_celebration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_celebration_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_celebration_label.add_theme_font_override("font", CELEBRATION_FONT)
	_celebration_label.add_theme_font_size_override("font_size", 36)
	_celebration_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.62, 1.0))
	_celebration_label.add_theme_color_override("font_outline_color", Color(0.35, 0.15, 0.02, 1.0))
	_celebration_label.add_theme_constant_override("outline_size", 10)
	_celebration_banner.add_child(_celebration_label)

	for index in range(CONFETTI_COLORS.size()):
		var particles := CPUParticles2D.new()
		particles.name = "CelebrationParticles%d" % index
		particles.one_shot = true
		particles.explosiveness = 1.0
		particles.amount = 52
		particles.lifetime = 1.3
		particles.randomness = 0.55
		particles.texture = _confetti_texture
		particles.direction = Vector2.UP
		particles.spread = 145.0
		particles.gravity = Vector2(0.0, 560.0)
		particles.initial_velocity_min = 220.0
		particles.initial_velocity_max = 360.0
		particles.angular_velocity_min = -720.0
		particles.angular_velocity_max = 720.0
		particles.scale_amount_min = 0.85
		particles.scale_amount_max = 1.55
		particles.color = CONFETTI_COLORS[index]
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = Vector2(96.0, 16.0)
		particles.emitting = false
		_celebration_layer.add_child(particles)
		_celebration_particles.append(particles)


func _build_celebration_audio() -> void:
	_celebration_sfx_player = AudioStreamPlayer.new()
	_celebration_sfx_player.name = "CelebrationSfxPlayer"
	_celebration_sfx_player.bus = &"Master"
	add_child(_celebration_sfx_player)


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
	if _is_transitioning:
		return

	_is_transitioning = true
	await _play_level_complete_celebration()
	await _run_scene_change(_get_level_scene_path(next_level_id))
	_is_transitioning = false


func _run_scene_change(scene_path: String) -> void:
	await _play_cover()
	if _celebration_layer != null:
		_celebration_layer.visible = false
	var error: Error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_warning("Scene transition failed for: %s" % scene_path)
	await get_tree().process_frame
	await _play_reveal()


func _get_level_scene_path(level_id: int) -> String:
	if level_id <= 0:
		return MAIN_MENU_SCENE

	var scene_path: String = str(LEVEL_SCENE_MAP.get(level_id, ""))
	if scene_path.is_empty():
		scene_path = FALLBACK_LEVEL_SCENE
	return scene_path


func _play_level_complete_celebration() -> void:
	var celebration_duration := _get_celebration_duration()
	_layout_celebration_ui()
	_restart_celebration_particles()
	_play_celebration_sfx()
	_celebration_layer.visible = true
	_celebration_banner.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_celebration_banner.scale = Vector2(0.68, 0.68)

	var final_position := _get_celebration_banner_position()
	var display_scale := Vector2(1.1, 1.1)
	_celebration_banner.position = final_position + Vector2(0.0, 96.0)

	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(_celebration_banner, "position", final_position, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_celebration_banner, "scale", display_scale, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_celebration_banner, "modulate", Color.WHITE, 0.18)
	tween.set_parallel(false)
	tween.tween_interval(0.32)
	tween.tween_callback(_restart_celebration_particles)
	tween.tween_interval(maxf(celebration_duration - 0.60, 0.0))
	await tween.finished


func _layout_celebration_ui() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_celebration_layer.size = viewport_size

	var banner_size := Vector2(minf(viewport_size.x - 48.0, 1080.0), 116.0)
	_celebration_banner.size = banner_size
	_celebration_label.add_theme_font_size_override(
		"font_size",
		int(clampf(viewport_size.x * 0.045, 30.0, 42.0))
	)

	var base_position := _get_celebration_banner_position()
	var particle_y: float = base_position.y + banner_size.y * 0.52
	var emitter_count: int = _celebration_particles.size()
	var emitter_span: float = banner_size.x * 0.78

	for index in range(emitter_count):
		var t := 0.5 if emitter_count <= 1 else float(index) / float(emitter_count - 1)
		_celebration_particles[index].position = Vector2(
			base_position.x + lerpf(banner_size.x * 0.5 - emitter_span * 0.5, banner_size.x * 0.5 + emitter_span * 0.5, t),
			particle_y
		)


func _get_celebration_banner_position() -> Vector2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	return Vector2(
		(viewport_size.x - _celebration_banner.size.x) * 0.5,
		viewport_size.y * 0.33
	)


func _restart_celebration_particles() -> void:
	for particles in _celebration_particles:
		particles.emitting = false
		particles.restart()
		particles.emitting = true


func _play_celebration_sfx() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	var sfx_volume_db := -7.0
	if audio_manager != null and audio_manager.has_method("get_sfx_volume_db"):
		sfx_volume_db = float(audio_manager.get_sfx_volume_db())

	if _celebration_sfx_player != null:
		_celebration_sfx_player.volume_db = sfx_volume_db + 3.5
		_celebration_sfx_player.pitch_scale = 1.0
		_celebration_sfx_player.stream = CELEBRATION_SFX
		_celebration_sfx_player.play()


func _get_celebration_duration() -> float:
	if CELEBRATION_SFX != null:
		return CELEBRATION_SFX.get_length() + CELEBRATION_EXTRA_TIME
	return CELEBRATION_EXTRA_TIME + 1.0


func _create_confetti_texture() -> Texture2D:
	var image := Image.create(4, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)
