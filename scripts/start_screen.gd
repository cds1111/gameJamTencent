extends Control

const FG := Color(0.22, 0.13, 0.07, 1.0)
const ENGLISH_PIXEL_FONT: FontFile = preload("res://assets/fonts/press_start_2p/PressStart2P-Regular.ttf")
const CHINESE_PIXEL_FONT: FontFile = preload("res://assets/fonts/fusion_pixel_font/fusion-pixel-12px-proportional-zh_hans.otf")
const MENU_MUSIC: AudioStream = preload("res://assets/music/menu.mp3")
const HOVER_SOUND: AudioStream = preload("res://assets/music/kenney_interface-sounds/Audio/select_006.ogg")
const CLICK_SOUND: AudioStream = preload("res://assets/music/kenney_interface-sounds/Audio/confirmation_002.ogg")
const BACKGROUND_SCROLL_SPEED := 18.0
const FIRST_LEVEL_SCENE := "res://scenes/levels/Level_01_Swap.tscn"
const TEST_SCENE := "res://scenes/test.tscn"

var default_panel_style: StyleBoxFlat = StyleBoxFlat.new()
var default_button_style: StyleBoxFlat = StyleBoxFlat.new()
var hover_button_style: StyleBoxFlat = StyleBoxFlat.new()
var pressed_button_style: StyleBoxFlat = StyleBoxFlat.new()
var background_width := 0.0
var option_button_style: StyleBoxFlat = StyleBoxFlat.new()
var option_button_popup_style: StyleBoxFlat = StyleBoxFlat.new()
var is_initializing_settings: bool = false
var _is_entering_level: bool = false

@onready var background_a: TextureRect = $BackgroundA
@onready var background_b: TextureRect = $BackgroundB
@onready var title: Label = $Title
@onready var subtitle: Label = $Subtitle
@onready var panel: PanelContainer = $MenuPanel
@onready var prompt: Label = $MenuPanel/MenuMargin/MenuVBox/Prompt
@onready var start_button: Button = $MenuPanel/MenuMargin/MenuVBox/StartButton
@onready var option_button: Button = $MenuPanel/MenuMargin/MenuVBox/OptionButton
@onready var quit_button: Button = $MenuPanel/MenuMargin/MenuVBox/QuitButton
@onready var hint: Label = $Hint
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var music_slider: HSlider = $SettingsPanel/SettingsMargin/SettingsScroll/SettingsVBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $SettingsPanel/SettingsMargin/SettingsScroll/SettingsVBox/SfxRow/SfxSlider
@onready var window_mode_option: OptionButton = $SettingsPanel/SettingsMargin/SettingsScroll/SettingsVBox/WindowRow/WindowModeOption
@onready var transition_mode_option: OptionButton = $SettingsPanel/SettingsMargin/SettingsScroll/SettingsVBox/TransitionRow/TransitionModeOption
@onready var test_scene_button: Button = $SettingsPanel/SettingsMargin/SettingsScroll/SettingsVBox/TestSceneButton
@onready var back_button: Button = $SettingsPanel/SettingsMargin/SettingsScroll/SettingsVBox/BackButton
@onready var settings_title: Label = $SettingsPanel/SettingsMargin/SettingsScroll/SettingsVBox/SettingsTitle
@onready var settings_hint: Label = $SettingsPanel/SettingsMargin/SettingsScroll/SettingsVBox/SettingsHint
@onready var music_label: Label = $SettingsPanel/SettingsMargin/SettingsScroll/SettingsVBox/MusicRow/MusicLabel
@onready var sfx_label: Label = $SettingsPanel/SettingsMargin/SettingsScroll/SettingsVBox/SfxRow/SfxLabel
@onready var window_label: Label = $SettingsPanel/SettingsMargin/SettingsScroll/SettingsVBox/WindowRow/WindowLabel
@onready var transition_label: Label = $SettingsPanel/SettingsMargin/SettingsScroll/SettingsVBox/TransitionRow/TransitionLabel
@onready var menu_music_player: AudioStreamPlayer = $MenuMusicPlayer
@onready var hover_sfx_player: AudioStreamPlayer = $HoverSfxPlayer
@onready var click_sfx_player: AudioStreamPlayer = $ClickSfxPlayer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_process(true)
	resized.connect(_layout_scrolling_backgrounds)
	_layout_scrolling_backgrounds()
	_apply_pixel_font()
	_configure_styles()
	_setup_audio()
	_setup_settings_ui()
	_wire_menu_button(start_button, "_on_start_pressed")
	_wire_menu_button(option_button, "_on_option_pressed")
	_wire_menu_button(quit_button, "_on_quit_pressed")
	_wire_menu_button(test_scene_button, "_on_test_scene_pressed")
	_wire_menu_button(back_button, "_on_back_pressed")
	queue_redraw()


func _process(delta: float) -> void:
	if background_width <= 0.0:
		return

	background_a.position.x -= BACKGROUND_SCROLL_SPEED * delta
	background_b.position.x -= BACKGROUND_SCROLL_SPEED * delta

	if background_a.position.x + background_width <= 0.0:
		background_a.position.x = background_b.position.x + background_width
	if background_b.position.x + background_width <= 0.0:
		background_b.position.x = background_a.position.x + background_width


func _draw() -> void:
	pass


func _apply_pixel_font() -> void:
	for control in [title, subtitle, prompt, hint, start_button, option_button, quit_button, settings_title, settings_hint, music_label, sfx_label, window_label, transition_label, test_scene_button, back_button]:
		_apply_font_by_text(control, control.text)

	title.add_theme_font_size_override("font_size", 30)
	subtitle.add_theme_font_size_override("font_size", 12)
	prompt.add_theme_font_size_override("font_size", 12)
	hint.add_theme_font_size_override("font_size", 10)
	settings_title.add_theme_font_size_override("font_size", 16)
	settings_hint.add_theme_font_size_override("font_size", 10)
	music_label.add_theme_font_size_override("font_size", 10)
	sfx_label.add_theme_font_size_override("font_size", 10)
	window_label.add_theme_font_size_override("font_size", 10)
	transition_label.add_theme_font_size_override("font_size", 10)


func _configure_styles() -> void:
	default_panel_style.bg_color = Color(0.97, 0.89, 0.72, 0.92)
	default_panel_style.border_color = Color(0.34, 0.18, 0.08, 1.0)
	default_panel_style.set_border_width_all(4)
	default_panel_style.shadow_color = Color(0, 0, 0, 0.18)
	default_panel_style.shadow_size = 8
	default_panel_style.shadow_offset = Vector2(4, 5)
	default_panel_style.corner_radius_top_left = 4
	default_panel_style.corner_radius_top_right = 4
	default_panel_style.corner_radius_bottom_right = 4
	default_panel_style.corner_radius_bottom_left = 4
	panel.add_theme_stylebox_override("panel", default_panel_style)
	settings_panel.add_theme_stylebox_override("panel", default_panel_style)

	default_button_style.bg_color = Color(0.9, 0.63, 0.31, 1.0)
	default_button_style.border_color = Color(0.35, 0.18, 0.07, 1.0)
	default_button_style.set_border_width_all(3)
	default_button_style.corner_radius_top_left = 2
	default_button_style.corner_radius_top_right = 2
	default_button_style.corner_radius_bottom_right = 2
	default_button_style.corner_radius_bottom_left = 2
	default_button_style.shadow_color = Color(0.21, 0.1, 0.04, 0.22)
	default_button_style.shadow_size = 4
	default_button_style.shadow_offset = Vector2(2, 3)

	hover_button_style.bg_color = Color(0.97, 0.74, 0.39, 1.0)
	hover_button_style.border_color = Color(0.35, 0.18, 0.07, 1.0)
	hover_button_style.set_border_width_all(3)
	hover_button_style.corner_radius_top_left = 2
	hover_button_style.corner_radius_top_right = 2
	hover_button_style.corner_radius_bottom_right = 2
	hover_button_style.corner_radius_bottom_left = 2
	hover_button_style.shadow_color = Color(0.21, 0.1, 0.04, 0.28)
	hover_button_style.shadow_size = 5
	hover_button_style.shadow_offset = Vector2(3, 4)

	pressed_button_style.bg_color = Color(0.8, 0.52, 0.24, 1.0)
	pressed_button_style.border_color = Color(0.35, 0.18, 0.07, 1.0)
	pressed_button_style.set_border_width_all(3)
	pressed_button_style.corner_radius_top_left = 2
	pressed_button_style.corner_radius_top_right = 2
	pressed_button_style.corner_radius_bottom_right = 2
	pressed_button_style.corner_radius_bottom_left = 2
	pressed_button_style.shadow_color = Color(0, 0, 0, 0)
	pressed_button_style.shadow_size = 0
	pressed_button_style.shadow_offset = Vector2.ZERO

	for button in [start_button, option_button, quit_button, test_scene_button, back_button]:
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", Color(0.2, 0.1, 0.04, 1.0))
		button.add_theme_color_override("font_hover_color", Color(0.2, 0.1, 0.04, 1.0))
		button.add_theme_color_override("font_pressed_color", Color(0.16, 0.08, 0.03, 1.0))
		button.add_theme_constant_override("h_separation", 0)
		button.add_theme_constant_override("outline_size", 1)
		button.add_theme_color_override("font_outline_color", Color(1, 0.95, 0.8, 0.35))
		button.add_theme_stylebox_override("normal", default_button_style)
		button.add_theme_stylebox_override("hover", hover_button_style)
		button.add_theme_stylebox_override("pressed", pressed_button_style)
		button.add_theme_stylebox_override("focus", hover_button_style)

	option_button_style.bg_color = Color(0.94, 0.79, 0.53, 1.0)
	option_button_style.border_color = Color(0.35, 0.18, 0.07, 1.0)
	option_button_style.set_border_width_all(3)
	option_button_style.corner_radius_top_left = 2
	option_button_style.corner_radius_top_right = 2
	option_button_style.corner_radius_bottom_right = 2
	option_button_style.corner_radius_bottom_left = 2

	option_button_popup_style.bg_color = Color(0.98, 0.9, 0.73, 1.0)
	option_button_popup_style.border_color = Color(0.35, 0.18, 0.07, 1.0)
	option_button_popup_style.set_border_width_all(3)
	option_button_popup_style.corner_radius_top_left = 2
	option_button_popup_style.corner_radius_top_right = 2
	option_button_popup_style.corner_radius_bottom_right = 2
	option_button_popup_style.corner_radius_bottom_left = 2

	for option in [window_mode_option, transition_mode_option]:
		option.add_theme_stylebox_override("normal", option_button_style)
		option.add_theme_stylebox_override("hover", hover_button_style)
		option.add_theme_stylebox_override("pressed", pressed_button_style)
		option.add_theme_stylebox_override("focus", hover_button_style)
		option.add_theme_color_override("font_color", Color(0.2, 0.1, 0.04, 1.0))
		option.add_theme_color_override("font_hover_color", Color(0.2, 0.1, 0.04, 1.0))
		option.add_theme_color_override("font_pressed_color", Color(0.16, 0.08, 0.03, 1.0))
		option.add_theme_color_override("font_outline_color", Color(1, 0.95, 0.8, 0.35))
		option.add_theme_constant_override("outline_size", 1)
		option.add_theme_font_override("font", ENGLISH_PIXEL_FONT)
		option.add_theme_font_size_override("font_size", 10)

		var popup: PopupMenu = option.get_popup()
		popup.add_theme_stylebox_override("panel", option_button_popup_style)
		popup.add_theme_color_override("font_color", Color(0.2, 0.1, 0.04, 1.0))
		popup.add_theme_color_override("font_hover_color", Color(0.2, 0.1, 0.04, 1.0))
		popup.add_theme_font_override("font", ENGLISH_PIXEL_FONT)
		popup.add_theme_font_size_override("font_size", 10)


func _wire_menu_button(button: Button, pressed_method: String) -> void:
	button.mouse_entered.connect(func() -> void:
		_play_hover_sfx()
	)
	button.focus_entered.connect(func() -> void:
		_play_hover_sfx()
	)
	button.pressed.connect(Callable(self , pressed_method))


func _setup_audio() -> void:
	menu_music_player.stop()

	hover_sfx_player.stream = HOVER_SOUND
	hover_sfx_player.bus = &"Master"

	click_sfx_player.stream = CLICK_SOUND
	click_sfx_player.bus = &"Master"

	var audio_manager: Node = _get_audio_manager()
	if audio_manager != null:
		audio_manager.play_menu_music()


func _setup_settings_ui() -> void:
	is_initializing_settings = true
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	window_mode_option.item_selected.connect(_on_window_mode_selected)
	transition_mode_option.item_selected.connect(_on_transition_mode_selected)
	_wire_slider_control(music_slider)
	_wire_slider_control(sfx_slider)
	_wire_option_control(window_mode_option)
	_wire_option_control(transition_mode_option)

	window_mode_option.clear()
	window_mode_option.add_item("WINDOWED", 0)
	window_mode_option.add_item("FULLSCREEN", 1)
	transition_mode_option.clear()
	transition_mode_option.add_item("DEFAULT", 0)
	transition_mode_option.add_item("FAST", 1)

	var audio_manager: Node = _get_audio_manager()
	if audio_manager != null:
		music_slider.value = audio_manager.get_music_volume_db()
		sfx_slider.value = audio_manager.get_sfx_volume_db()
	else:
		music_slider.value = menu_music_player.volume_db
		sfx_slider.value = (hover_sfx_player.volume_db + click_sfx_player.volume_db) * 0.5

	_apply_sfx_volume(sfx_slider.value)

	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		window_mode_option.select(1)
	else:
		window_mode_option.select(0)

	var transition_manager = _get_transition_manager()
	if transition_manager != null and transition_manager.get_transition_style() == "fast":
		transition_mode_option.select(1)
	else:
		transition_mode_option.select(0)
	is_initializing_settings = false


func _wire_slider_control(slider: HSlider) -> void:
	slider.mouse_entered.connect(func() -> void:
		_play_hover_sfx()
	)
	slider.focus_entered.connect(func() -> void:
		_play_hover_sfx()
	)
	slider.drag_started.connect(func() -> void:
		_play_hover_sfx()
	)
	slider.drag_ended.connect(func(value_changed: bool) -> void:
		if value_changed:
			_play_click_sfx()
	)


func _wire_option_control(option: OptionButton) -> void:
	option.mouse_entered.connect(func() -> void:
		_play_hover_sfx()
	)
	option.focus_entered.connect(func() -> void:
		_play_hover_sfx()
	)
	option.pressed.connect(func() -> void:
		_play_hover_sfx()
	)


func _layout_scrolling_backgrounds() -> void:
	var texture_size: Vector2 = background_a.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var scale_factor := size.y / texture_size.y
	background_width = texture_size.x * scale_factor

	for background in [background_a, background_b]:
		background.set_anchors_preset(Control.PRESET_TOP_LEFT)
		background.custom_minimum_size = Vector2(background_width, size.y)
		background.set_deferred("size", Vector2(background_width, size.y))

	background_a.position = Vector2(0, 0)
	background_b.position = Vector2(background_width, 0)


func _apply_font_by_text(control: Control, text: String) -> void:
	var font_to_use: FontFile = ENGLISH_PIXEL_FONT
	if _contains_cjk(text):
		font_to_use = CHINESE_PIXEL_FONT
	control.add_theme_font_override("font", font_to_use)


func _contains_cjk(text: String) -> bool:
	for i in range(text.length()):
		var codepoint: int = text.unicode_at(i)
		if codepoint >= 0x2E80 and codepoint <= 0x9FFF:
			return true
		if codepoint >= 0xF900 and codepoint <= 0xFAFF:
			return true
		if codepoint >= 0x20000 and codepoint <= 0x2FA1F:
			return true
	return false


func _set_hint_text(text: String) -> void:
	hint.text = text
	_apply_font_by_text(hint, text)


func _play_hover_sfx() -> void:
	if hover_sfx_player.playing:
		hover_sfx_player.stop()
	hover_sfx_player.play()


func _play_click_sfx() -> void:
	if click_sfx_player.playing:
		click_sfx_player.stop()
	click_sfx_player.play()


func _show_main_menu() -> void:
	panel.visible = true
	settings_panel.visible = false
	_set_hint_text("tips: There're no tips!")


func _show_settings() -> void:
	panel.visible = false
	settings_panel.visible = true
	_set_hint_text("Tune the menu vibe here.")


func _on_music_volume_changed(value: float) -> void:
	var audio_manager: Node = _get_audio_manager()
	if audio_manager != null:
		audio_manager.set_music_volume_db(value)
	if not is_initializing_settings:
		_play_hover_sfx()


func _on_sfx_volume_changed(value: float) -> void:
	_apply_sfx_volume(value)
	var audio_manager: Node = _get_audio_manager()
	if audio_manager != null:
		audio_manager.set_sfx_volume_db(value)
	if not is_initializing_settings:
		_play_hover_sfx()


func _on_window_mode_selected(index: int) -> void:
	if not is_initializing_settings:
		_play_click_sfx()
	if index == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_transition_mode_selected(index: int) -> void:
	if not is_initializing_settings:
		_play_click_sfx()
	var transition_manager = _get_transition_manager()
	if transition_manager == null:
		return
	if index == 1:
		transition_manager.set_transition_style("fast")
	else:
		transition_manager.set_transition_style("default")


func _on_start_pressed() -> void:
	_play_click_sfx()
	_enter_base_level()


func _enter_base_level() -> void:
	if _is_entering_level:
		return
	_is_entering_level = true
	_set_hint_text("Signal locked. Entering base level...")
	await get_tree().create_timer(0.12).timeout
	var transition_manager = _get_transition_manager()
	if transition_manager != null:
		transition_manager.change_scene_to_file(FIRST_LEVEL_SCENE)
	else:
		get_tree().change_scene_to_file(FIRST_LEVEL_SCENE)


func _on_option_pressed() -> void:
	_play_click_sfx()
	_show_settings()


func _on_back_pressed() -> void:
	_play_click_sfx()
	_show_main_menu()


func _on_test_scene_pressed() -> void:
	_play_click_sfx()
	_enter_scene(TEST_SCENE, "Entering test scene...")


func _on_quit_pressed() -> void:
	_play_click_sfx()
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()


func _get_transition_manager() -> Node:
	return get_node_or_null("/root/SceneTransitionManager")


func _get_audio_manager() -> Node:
	return get_node_or_null("/root/AudioManager")


func _apply_sfx_volume(value: float) -> void:
	hover_sfx_player.volume_db = value - 1.0
	click_sfx_player.volume_db = value + 1.0


func _enter_scene(scene_path: String, hint_text: String) -> void:
	if _is_entering_level:
		return
	_is_entering_level = true
	_set_hint_text(hint_text)
	await get_tree().create_timer(0.12).timeout
	var transition_manager = _get_transition_manager()
	if transition_manager != null:
		transition_manager.change_scene_to_file(scene_path)
	else:
		get_tree().change_scene_to_file(scene_path)
