extends Node
class_name LevelController

const ENGLISH_PIXEL_FONT: FontFile = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const CHINESE_PIXEL_FONT: FontFile = preload("res://assets/fonts/fusion-pixel-12px-proportional-zh_hans.otf")

@export var player_scene: PackedScene = preload("res://scenes/entities/Player.tscn")
@export var starting_ability: Resource
@export var next_level_id: int = 2
@export var level_title_text: String = "LEVEL"

@onready var _entities: Node2D = $"../Entities"
@onready var _player_spawn: Marker2D = $"../Entities/PlayerSpawn"
@onready var _goal: Area2D = $"../Entities/Goal"
@onready var _title_label: Label = $"../LevelUI/TopRightMargin/TitleBackground/TitleText"
@onready var _level_ui: CanvasLayer = $"../LevelUI"

var _player: CharacterBody2D
var _is_restarting: bool = false
var _is_level_completing: bool = false
var _settings_button: Button
var _settings_panel: PanelContainer
var _music_slider: HSlider
var _sfx_slider: HSlider
var _window_mode_option: OptionButton
var _transition_mode_option: OptionButton
var _back_button: Button
var _return_menu_button: Button

var _default_panel_style: StyleBoxFlat = StyleBoxFlat.new()
var _default_button_style: StyleBoxFlat = StyleBoxFlat.new()
var _hover_button_style: StyleBoxFlat = StyleBoxFlat.new()
var _pressed_button_style: StyleBoxFlat = StyleBoxFlat.new()
var _option_button_style: StyleBoxFlat = StyleBoxFlat.new()
var _option_button_popup_style: StyleBoxFlat = StyleBoxFlat.new()


func _ready() -> void:
	_apply_level_title()
	_spawn_player()
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_game_music()
	_configure_goal_detection()
	var signal_manager := get_node_or_null("/root/SignalManager")
	if signal_manager != null and not signal_manager.player_died.is_connected(_on_player_died):
		signal_manager.player_died.connect(_on_player_died)
	_setup_level_settings_ui()


func _apply_level_title() -> void:
	if is_instance_valid(_title_label):
		_title_label.text = level_title_text


func _process(_delta: float) -> void:
	if _is_level_completing:
		return
	if Input.is_action_just_pressed("restart_level"):
		if is_instance_valid(_player) and _player.has_method("die"):
			_player.die()
		else:
			_restart_level()


func _spawn_player() -> void:
	if player_scene == null or _entities == null or _player_spawn == null:
		return

	_player = _entities.get_node_or_null("Player") as CharacterBody2D
	if _player == null:
		_player = player_scene.instantiate() as CharacterBody2D
		if _player == null:
			return
		_entities.add_child(_player)

	_player.global_position = _player_spawn.global_position

	if starting_ability != null and _player.has_method("set_current_ability"):
		var ability := _build_ability_instance(starting_ability) as ShiftAbility
		if ability != null:
			_player.set_current_ability(ability)


func _build_ability_instance(source: Resource) -> Resource:
	if source == null:
		return null
	if source.resource_path.ends_with(".gd") and source is Script:
		return (source as Script).new()
	return source.duplicate(true)


func _configure_goal_detection() -> void:
	if not is_instance_valid(_goal):
		return

	_goal.monitoring = true
	_goal.monitorable = true

	if is_instance_valid(_player):
		_goal.collision_mask |= _player.collision_layer

	if not _goal.body_entered.is_connected(_on_goal_body_entered):
		_goal.body_entered.connect(_on_goal_body_entered)


func _on_goal_body_entered(body: Node) -> void:
	if body != null:
		print("[LevelController] Goal body_entered: ", body.name)
	if body != _player or _is_level_completing:
		return

	_is_level_completing = true
	if is_instance_valid(_goal):
		_goal.monitoring = false
	if is_instance_valid(_player) and _player.has_method("set_movement_locked"):
		_player.set_movement_locked(true)

	var signal_manager := get_node_or_null("/root/SignalManager")
	if signal_manager != null:
		print("[LevelController] emit level_completed -> ", next_level_id)
		signal_manager.level_completed.emit(next_level_id)


func _on_player_died() -> void:
	if _is_restarting or _is_level_completing:
		return
	print("[LevelController] player_died received -> restart current scene after 0.5s")
	call_deferred("_restart_level_with_delay")


func _restart_level() -> void:
	if _is_restarting or _is_level_completing:
		return
	_is_restarting = true
	print("[LevelController] reload_current_scene")
	var transition_manager: Node = get_node_or_null("/root/SceneTransitionManager")
	if transition_manager != null:
		transition_manager.reload_current_scene()
	else:
		get_tree().call_deferred("reload_current_scene")


func _restart_level_with_delay() -> void:
	if _is_restarting or _is_level_completing:
		return
	await get_tree().create_timer(0.5).timeout
	_restart_level()


func _setup_level_settings_ui() -> void:
	if not is_instance_valid(_level_ui):
		return

	_settings_button = Button.new()
	_settings_button.name = "SettingsGearButton"
	_settings_button.text = "⚙"
	_settings_button.custom_minimum_size = Vector2(40.0, 40.0)
	_settings_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_settings_button.offset_left = -56.0
	_settings_button.offset_top = 16.0
	_settings_button.offset_right = -16.0
	_settings_button.offset_bottom = 56.0
	_settings_button.focus_mode = Control.FOCUS_NONE
	_settings_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_settings_button.add_theme_font_size_override("font_size", 22)
	_settings_button.pressed.connect(_on_settings_button_pressed)
	_level_ui.add_child(_settings_button)


func _on_settings_button_pressed() -> void:
	if not _ensure_settings_panel():
		return
	_settings_panel.visible = not _settings_panel.visible


func _ensure_settings_panel() -> bool:
	if is_instance_valid(_settings_panel):
		return true
	_settings_panel = PanelContainer.new()
	_settings_panel.name = "InLevelSettingsPanel"
	_settings_panel.visible = false
	_settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	_settings_panel.offset_left = -240.0
	_settings_panel.offset_top = -150.0
	_settings_panel.offset_right = 240.0
	_settings_panel.offset_bottom = 150.0
	_level_ui.add_child(_settings_panel)

	var margin := MarginContainer.new()
	margin.name = "SettingsMargin"
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	_settings_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "SettingsVBox"
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	var music_row := HBoxContainer.new()
	vbox.add_child(music_row)
	var music_label := Label.new()
	music_label.custom_minimum_size = Vector2(150, 0)
	music_label.text = "MUSIC"
	music_row.add_child(music_label)
	_music_slider = HSlider.new()
	_music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_music_slider.min_value = -20.0
	_music_slider.max_value = 2.0
	music_row.add_child(_music_slider)

	var sfx_row := HBoxContainer.new()
	vbox.add_child(sfx_row)
	var sfx_label := Label.new()
	sfx_label.custom_minimum_size = Vector2(150, 0)
	sfx_label.text = "SFX"
	sfx_row.add_child(sfx_label)
	_sfx_slider = HSlider.new()
	_sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sfx_slider.min_value = -20.0
	_sfx_slider.max_value = 4.0
	sfx_row.add_child(_sfx_slider)

	var window_row := HBoxContainer.new()
	vbox.add_child(window_row)
	var window_label := Label.new()
	window_label.custom_minimum_size = Vector2(150, 0)
	window_label.text = "WINDOW"
	window_row.add_child(window_label)
	_window_mode_option = OptionButton.new()
	_window_mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_window_mode_option.add_item("WINDOWED", 0)
	_window_mode_option.add_item("FULLSCREEN", 1)
	window_row.add_child(_window_mode_option)

	var transition_row := HBoxContainer.new()
	vbox.add_child(transition_row)
	var transition_label := Label.new()
	transition_label.custom_minimum_size = Vector2(150, 0)
	transition_label.text = "TRANSITION"
	transition_row.add_child(transition_label)
	_transition_mode_option = OptionButton.new()
	_transition_mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_transition_mode_option.add_item("DEFAULT", 0)
	_transition_mode_option.add_item("FAST", 1)
	transition_row.add_child(_transition_mode_option)

	_return_menu_button = Button.new()
	_return_menu_button.text = "RETURN TO MENU"
	_return_menu_button.custom_minimum_size = Vector2(0, 44)
	vbox.add_child(_return_menu_button)

	_back_button = Button.new()
	_back_button.text = "BACK"
	_back_button.custom_minimum_size = Vector2(0, 44)
	vbox.add_child(_back_button)

	if is_instance_valid(_music_slider) and not _music_slider.value_changed.is_connected(_on_music_volume_changed):
		_music_slider.value_changed.connect(_on_music_volume_changed)
	if is_instance_valid(_sfx_slider) and not _sfx_slider.value_changed.is_connected(_on_sfx_volume_changed):
		_sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	if is_instance_valid(_window_mode_option) and not _window_mode_option.item_selected.is_connected(_on_window_mode_selected):
		_window_mode_option.item_selected.connect(_on_window_mode_selected)
	if is_instance_valid(_transition_mode_option) and not _transition_mode_option.item_selected.is_connected(_on_transition_mode_selected):
		_transition_mode_option.item_selected.connect(_on_transition_mode_selected)
	if is_instance_valid(_back_button) and not _back_button.pressed.is_connected(_on_settings_back_pressed):
		_back_button.pressed.connect(_on_settings_back_pressed)
	if is_instance_valid(_return_menu_button) and not _return_menu_button.pressed.is_connected(_on_return_to_menu_pressed):
		_return_menu_button.pressed.connect(_on_return_to_menu_pressed)

	_apply_settings_panel_style(title, music_label, sfx_label, window_label, transition_label)
	_refresh_settings_panel_values()
	return true


func _apply_settings_panel_style(title: Label, music_label: Label, sfx_label: Label, window_label: Label, transition_label: Label) -> void:
	_default_panel_style.bg_color = Color(0.97, 0.89, 0.72, 0.92)
	_default_panel_style.border_color = Color(0.34, 0.18, 0.08, 1.0)
	_default_panel_style.set_border_width_all(4)
	_default_panel_style.shadow_color = Color(0, 0, 0, 0.18)
	_default_panel_style.shadow_size = 8
	_default_panel_style.shadow_offset = Vector2(4, 5)
	_default_panel_style.corner_radius_top_left = 4
	_default_panel_style.corner_radius_top_right = 4
	_default_panel_style.corner_radius_bottom_right = 4
	_default_panel_style.corner_radius_bottom_left = 4
	_settings_panel.add_theme_stylebox_override("panel", _default_panel_style)

	_default_button_style.bg_color = Color(0.9, 0.63, 0.31, 1.0)
	_default_button_style.border_color = Color(0.35, 0.18, 0.07, 1.0)
	_default_button_style.set_border_width_all(3)
	_default_button_style.corner_radius_top_left = 2
	_default_button_style.corner_radius_top_right = 2
	_default_button_style.corner_radius_bottom_right = 2
	_default_button_style.corner_radius_bottom_left = 2
	_default_button_style.shadow_color = Color(0.21, 0.1, 0.04, 0.22)
	_default_button_style.shadow_size = 4
	_default_button_style.shadow_offset = Vector2(2, 3)

	_hover_button_style.bg_color = Color(0.97, 0.74, 0.39, 1.0)
	_hover_button_style.border_color = Color(0.35, 0.18, 0.07, 1.0)
	_hover_button_style.set_border_width_all(3)
	_hover_button_style.corner_radius_top_left = 2
	_hover_button_style.corner_radius_top_right = 2
	_hover_button_style.corner_radius_bottom_right = 2
	_hover_button_style.corner_radius_bottom_left = 2
	_hover_button_style.shadow_color = Color(0.21, 0.1, 0.04, 0.28)
	_hover_button_style.shadow_size = 5
	_hover_button_style.shadow_offset = Vector2(3, 4)

	_pressed_button_style.bg_color = Color(0.8, 0.52, 0.24, 1.0)
	_pressed_button_style.border_color = Color(0.35, 0.18, 0.07, 1.0)
	_pressed_button_style.set_border_width_all(3)
	_pressed_button_style.corner_radius_top_left = 2
	_pressed_button_style.corner_radius_top_right = 2
	_pressed_button_style.corner_radius_bottom_right = 2
	_pressed_button_style.corner_radius_bottom_left = 2

	_option_button_style.bg_color = Color(0.94, 0.79, 0.53, 1.0)
	_option_button_style.border_color = Color(0.35, 0.18, 0.07, 1.0)
	_option_button_style.set_border_width_all(3)
	_option_button_style.corner_radius_top_left = 2
	_option_button_style.corner_radius_top_right = 2
	_option_button_style.corner_radius_bottom_right = 2
	_option_button_style.corner_radius_bottom_left = 2

	_option_button_popup_style.bg_color = Color(0.98, 0.9, 0.73, 1.0)
	_option_button_popup_style.border_color = Color(0.35, 0.18, 0.07, 1.0)
	_option_button_popup_style.set_border_width_all(3)
	_option_button_popup_style.corner_radius_top_left = 2
	_option_button_popup_style.corner_radius_top_right = 2
	_option_button_popup_style.corner_radius_bottom_right = 2
	_option_button_popup_style.corner_radius_bottom_left = 2

	for label in [title, music_label, sfx_label, window_label, transition_label]:
		if label == null:
			continue
		label.add_theme_font_override("font", _pick_font(label.text))
		label.add_theme_color_override("font_color", Color(0.31, 0.16, 0.08, 1.0))

	title.add_theme_font_size_override("font_size", 16)
	for label in [music_label, sfx_label, window_label, transition_label]:
		if label != null:
			label.add_theme_font_size_override("font_size", 10)

	for button in [_return_menu_button, _back_button]:
		if button == null:
			continue
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_override("font", ENGLISH_PIXEL_FONT)
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", Color(0.2, 0.1, 0.04, 1.0))
		button.add_theme_color_override("font_hover_color", Color(0.2, 0.1, 0.04, 1.0))
		button.add_theme_color_override("font_pressed_color", Color(0.16, 0.08, 0.03, 1.0))
		button.add_theme_stylebox_override("normal", _default_button_style)
		button.add_theme_stylebox_override("hover", _hover_button_style)
		button.add_theme_stylebox_override("pressed", _pressed_button_style)
		button.add_theme_stylebox_override("focus", _hover_button_style)

	for option in [_window_mode_option, _transition_mode_option]:
		if option == null:
			continue
		option.focus_mode = Control.FOCUS_NONE
		option.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		option.add_theme_stylebox_override("normal", _option_button_style)
		option.add_theme_stylebox_override("hover", _hover_button_style)
		option.add_theme_stylebox_override("pressed", _pressed_button_style)
		option.add_theme_stylebox_override("focus", _hover_button_style)
		option.add_theme_color_override("font_color", Color(0.2, 0.1, 0.04, 1.0))
		option.add_theme_color_override("font_hover_color", Color(0.2, 0.1, 0.04, 1.0))
		option.add_theme_color_override("font_pressed_color", Color(0.16, 0.08, 0.03, 1.0))
		option.add_theme_font_override("font", ENGLISH_PIXEL_FONT)
		option.add_theme_font_size_override("font_size", 10)

		var popup: PopupMenu = option.get_popup()
		popup.add_theme_stylebox_override("panel", _option_button_popup_style)
		popup.add_theme_color_override("font_color", Color(0.2, 0.1, 0.04, 1.0))
		popup.add_theme_color_override("font_hover_color", Color(0.2, 0.1, 0.04, 1.0))
		popup.add_theme_font_override("font", ENGLISH_PIXEL_FONT)
		popup.add_theme_font_size_override("font_size", 10)


func _pick_font(text: String) -> FontFile:
	for i in range(text.length()):
		var codepoint: int = text.unicode_at(i)
		if (codepoint >= 0x2E80 and codepoint <= 0x9FFF) \
			or (codepoint >= 0xF900 and codepoint <= 0xFAFF) \
			or (codepoint >= 0x20000 and codepoint <= 0x2FA1F):
			return CHINESE_PIXEL_FONT
	return ENGLISH_PIXEL_FONT


func _refresh_settings_panel_values() -> void:
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		if is_instance_valid(_music_slider):
			_music_slider.value = audio_manager.get_music_volume_db()
		if is_instance_valid(_sfx_slider):
			_sfx_slider.value = audio_manager.get_sfx_volume_db()

	if is_instance_valid(_window_mode_option):
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			_window_mode_option.select(1)
		else:
			_window_mode_option.select(0)

	if is_instance_valid(_transition_mode_option):
		var transition_manager := get_node_or_null("/root/SceneTransitionManager")
		if transition_manager != null and transition_manager.get_transition_style() == "fast":
			_transition_mode_option.select(1)
		else:
			_transition_mode_option.select(0)


func _on_settings_back_pressed() -> void:
	if is_instance_valid(_settings_panel):
		_settings_panel.visible = false


func _on_return_to_menu_pressed() -> void:
	var transition_manager := get_node_or_null("/root/SceneTransitionManager")
	if transition_manager != null and transition_manager.has_method("return_to_menu"):
		transition_manager.return_to_menu()
		return
	get_tree().change_scene_to_file("res://main.tscn")


func _on_music_volume_changed(value: float) -> void:
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.set_music_volume_db(value)


func _on_sfx_volume_changed(value: float) -> void:
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.set_sfx_volume_db(value)


func _on_window_mode_selected(index: int) -> void:
	if index == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_transition_mode_selected(index: int) -> void:
	var transition_manager := get_node_or_null("/root/SceneTransitionManager")
	if transition_manager == null:
		return
	if index == 1:
		transition_manager.set_transition_style("fast")
	else:
		transition_manager.set_transition_style("default")
