extends Control

const BG := Color(0.97, 0.97, 0.95, 1.0)
const FG := Color(0.06, 0.06, 0.06, 1.0)
const DIM := Color(0.0, 0.0, 0.0, 0.18)
const SOFT := Color(0.0, 0.0, 0.0, 0.08)
const PIXEL := 16.0
const ENGLISH_PIXEL_FONT: FontFile = preload("res://assets/fonts/press_start_2p/PressStart2P-Regular.ttf")
const CHINESE_PIXEL_FONT: FontFile = preload("res://assets/fonts/fusion_pixel_font/fusion-pixel-12px-proportional-zh_hans.otf")
const MENU_MUSIC: AudioStream = preload("res://assets/music/menu.mp3")
const HOVER_SOUND: AudioStream = preload("res://assets/music/kenney_interface-sounds/Audio/select_006.ogg")
const CLICK_SOUND: AudioStream = preload("res://assets/music/kenney_interface-sounds/Audio/confirmation_002.ogg")

var default_panel_style := StyleBoxFlat.new()
var default_button_style := StyleBoxFlat.new()
var hover_button_style := StyleBoxFlat.new()

@onready var title: Label = $Title
@onready var subtitle: Label = $Subtitle
@onready var panel: PanelContainer = $MenuPanel
@onready var prompt: Label = $MenuPanel/MenuMargin/MenuVBox/Prompt
@onready var start_button: Button = $MenuPanel/MenuMargin/MenuVBox/StartButton
@onready var option_button: Button = $MenuPanel/MenuMargin/MenuVBox/OptionButton
@onready var quit_button: Button = $MenuPanel/MenuMargin/MenuVBox/QuitButton
@onready var hint: Label = $Hint
@onready var menu_music_player: AudioStreamPlayer = $MenuMusicPlayer
@onready var hover_sfx_player: AudioStreamPlayer = $HoverSfxPlayer
@onready var click_sfx_player: AudioStreamPlayer = $ClickSfxPlayer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_apply_pixel_font()
	_configure_styles()
	_setup_audio()
	_wire_button(start_button, "_on_start_pressed")
	_wire_button(option_button, "_on_option_pressed")
	_wire_button(quit_button, "_on_quit_pressed")
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	_draw_pixel_grid()
	_draw_corner_frame()


func _draw_pixel_grid() -> void:
	var columns := int(ceil(size.x / PIXEL)) + 1
	var rows := int(ceil(size.y / PIXEL)) + 1

	for x in range(columns):
		var xpos: float = x * PIXEL
		draw_line(Vector2(xpos, 0), Vector2(xpos, size.y), SOFT, 1.0)

	for y in range(rows):
		var ypos: float = y * PIXEL
		draw_line(Vector2(0, ypos), Vector2(size.x, ypos), SOFT, 1.0)

	for x in range(columns):
		for y in range(rows):
			if (x + y) % 5 == 0:
				draw_rect(
					Rect2(Vector2(x * PIXEL + 4.0, y * PIXEL + 4.0), Vector2(2, 2)),
					Color(0, 0, 0, 0.08),
					true
				)


func _draw_corner_frame() -> void:
	var margin: float = 30.0
	var corner_len: float = 72.0
	var thickness: float = 3.0

	draw_line(Vector2(margin, margin), Vector2(margin + corner_len, margin), FG, thickness)
	draw_line(Vector2(margin, margin), Vector2(margin, margin + corner_len), FG, thickness)

	draw_line(Vector2(size.x - margin, margin), Vector2(size.x - margin - corner_len, margin), FG, thickness)
	draw_line(Vector2(size.x - margin, margin), Vector2(size.x - margin, margin + corner_len), FG, thickness)

	draw_line(Vector2(margin, size.y - margin), Vector2(margin + corner_len, size.y - margin), FG, thickness)
	draw_line(Vector2(margin, size.y - margin), Vector2(margin, size.y - margin - corner_len), FG, thickness)

	draw_line(Vector2(size.x - margin, size.y - margin), Vector2(size.x - margin - corner_len, size.y - margin), FG, thickness)
	draw_line(Vector2(size.x - margin, size.y - margin), Vector2(size.x - margin, size.y - margin - corner_len), FG, thickness)


func _apply_pixel_font() -> void:
	for control in [title, subtitle, prompt, hint, start_button, option_button, quit_button]:
		_apply_font_by_text(control, control.text)

	title.add_theme_font_size_override("font_size", 30)
	subtitle.add_theme_font_size_override("font_size", 12)
	prompt.add_theme_font_size_override("font_size", 12)
	hint.add_theme_font_size_override("font_size", 10)


func _configure_styles() -> void:
	default_panel_style.bg_color = Color(1, 1, 1, 0.9)
	default_panel_style.border_color = FG
	default_panel_style.set_border_width_all(3)
	default_panel_style.corner_radius_top_left = 4
	default_panel_style.corner_radius_top_right = 4
	default_panel_style.corner_radius_bottom_right = 4
	default_panel_style.corner_radius_bottom_left = 4
	panel.add_theme_stylebox_override("panel", default_panel_style)

	default_button_style.bg_color = Color(1, 1, 1, 0)
	default_button_style.border_color = FG
	default_button_style.set_border_width_all(2)
	default_button_style.corner_radius_top_left = 2
	default_button_style.corner_radius_top_right = 2
	default_button_style.corner_radius_bottom_right = 2
	default_button_style.corner_radius_bottom_left = 2

	hover_button_style.bg_color = FG
	hover_button_style.border_color = FG
	hover_button_style.set_border_width_all(2)
	hover_button_style.shadow_color = Color(0, 0, 0, 0.22)
	hover_button_style.shadow_size = 6
	hover_button_style.shadow_offset = Vector2(4, 4)
	hover_button_style.corner_radius_top_left = 2
	hover_button_style.corner_radius_top_right = 2
	hover_button_style.corner_radius_bottom_right = 2
	hover_button_style.corner_radius_bottom_left = 2

	for button in [start_button, option_button, quit_button]:
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", FG)
		button.add_theme_color_override("font_hover_color", BG)
		button.add_theme_color_override("font_pressed_color", BG)
		button.add_theme_stylebox_override("normal", default_button_style)
		button.add_theme_stylebox_override("hover", hover_button_style)
		button.add_theme_stylebox_override("pressed", hover_button_style)
		button.add_theme_stylebox_override("focus", hover_button_style)


func _wire_button(button: Button, pressed_method: String) -> void:
	button.mouse_entered.connect(func() -> void:
		_play_hover_sfx()
	)
	button.focus_entered.connect(func() -> void:
		_play_hover_sfx()
	)
	button.pressed.connect(Callable(self, pressed_method))


func _setup_audio() -> void:
	menu_music_player.stream = MENU_MUSIC
	menu_music_player.bus = &"Master"
	menu_music_player.stream_paused = false
	menu_music_player.finished.connect(func() -> void:
		menu_music_player.play()
	)
	if not menu_music_player.playing:
		menu_music_player.play()

	hover_sfx_player.stream = HOVER_SOUND
	hover_sfx_player.bus = &"Master"

	click_sfx_player.stream = CLICK_SOUND
	click_sfx_player.bus = &"Master"


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


func _on_start_pressed() -> void:
	_play_click_sfx()
	_set_hint_text("Signal locked. Entering the sketch world...")


func _on_option_pressed() -> void:
	_play_click_sfx()
	_set_hint_text("Notebook open. More menu branches can grow from here.")


func _on_quit_pressed() -> void:
	_play_click_sfx()
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()
