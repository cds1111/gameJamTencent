extends Node

const MENU_SCENE := "res://scenes/ui/StartMenu.tscn"
const DEFAULT_LEVEL_ID := 5
const LEVEL_SCENES := {
	5: "res://scenes/levels/Level_05_Swap.tscn",
}

var _is_transitioning := false

@onready var _signal_manager: Node = get_node_or_null("/root/SignalManager")
@onready var _overlay_scene: PackedScene = preload("res://scenes/ui/TransitionOverlay.tscn")

var _overlay: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _signal_manager == null:
		_signal_manager = get_node_or_null("/root/SignalManager")
	if _signal_manager != null and not _signal_manager.level_completed.is_connected(_on_level_completed):
		_signal_manager.level_completed.connect(_on_level_completed)
	call_deferred("_ensure_overlay")


func start_game() -> void:
	go_to_level(DEFAULT_LEVEL_ID, "ENTERING TEST ROOM")


func go_to_menu(message: String = "RETURNING TO MENU") -> void:
	go_to_scene(MENU_SCENE, message)


func go_to_level(level_id: int, message: String = "SHIFTING IN") -> void:
	var scene_path: String = LEVEL_SCENES.get(level_id, "")
	if scene_path.is_empty():
		go_to_menu("RETURNING TO MENU")
		return
	go_to_scene(scene_path, message)


func go_to_scene(scene_path: String, message: String = "SHIFTING") -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	_ensure_overlay()
	if _overlay != null and _overlay.has_method("play_transition"):
		_overlay.play_transition(message)
		await get_tree().create_timer(0.38).timeout

	var result := get_tree().change_scene_to_file(scene_path)
	if result != OK:
		push_error("Failed to change scene to %s (error %s)" % [scene_path, result])
		if _overlay != null and _overlay.has_method("play_fade_out"):
			_overlay.play_fade_out()
		_is_transitioning = false
		return

	await get_tree().process_frame
	await get_tree().process_frame
	if _overlay != null and _overlay.has_method("play_fade_out"):
		_overlay.play_fade_out()
	_is_transitioning = false


func _ensure_overlay() -> void:
	if is_instance_valid(_overlay):
		return
	if _overlay_scene == null:
		return
	_overlay = _overlay_scene.instantiate() as CanvasLayer
	if _overlay == null:
		return
	get_tree().root.add_child(_overlay)


func _on_level_completed(next_level_id: int) -> void:
	go_to_level(next_level_id, "STAGE CLEAR")
