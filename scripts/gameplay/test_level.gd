extends Node2D

const MENU_SCENE := "res://main.tscn"
const CHINESE_PIXEL_FONT: FontFile = preload("res://assets/fonts/fusion_pixel_font/fusion-pixel-12px-proportional-zh_hans.otf")

@onready var exit_area: Area2D = $ExitArea
@onready var player: CharacterBody2D = $Player
@onready var transition_overlay: CanvasLayer = $TransitionOverlay
@onready var prompt_title: Label = $PromptTitle
@onready var prompt_text: Label = $PromptText

var exiting := false

func _ready() -> void:
	_apply_fonts()
	exit_area.body_entered.connect(_on_exit_body_entered)


func _apply_fonts() -> void:
	for label in [prompt_title, prompt_text]:
		label.add_theme_font_override("font", CHINESE_PIXEL_FONT)


func _on_exit_body_entered(body: Node) -> void:
	if exiting or body != player:
		return

	exiting = true
	player.set_physics_process(false)
	transition_overlay.play_to_menu("BACK TO MENU")
	await get_tree().create_timer(0.65).timeout
	get_tree().change_scene_to_file(MENU_SCENE)
