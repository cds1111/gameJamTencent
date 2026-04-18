extends CanvasLayer

@onready var fade_rect: ColorRect = $FadeRect
@onready var label: Label = $TransitionLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	fade_rect.color.a = 1.0
	label.modulate.a = 1.0
	play_fade_out()


func play_transition(text: String = "SHIFTING") -> void:
	label.text = text
	animation_player.play("fade_in")


func play_fade_out() -> void:
	animation_player.play("fade_out")
