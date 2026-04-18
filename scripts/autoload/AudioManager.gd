extends Node

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "audio"
const SETTINGS_KEY_MUSIC := "music_volume_db"
const SETTINGS_KEY_SFX := "sfx_volume_db"
const DEFAULT_MUSIC_VOLUME_DB := -7.0
const DEFAULT_SFX_VOLUME_DB := -7.0
const MENU_MUSIC: AudioStream = preload("res://assets/music/menu.mp3")
const GAME_MUSIC: AudioStream = preload("res://assets/music/game.ogg")

var _music_volume_db: float = DEFAULT_MUSIC_VOLUME_DB
var _sfx_volume_db: float = DEFAULT_SFX_VOLUME_DB
var _menu_player: AudioStreamPlayer
var _game_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	_build_players()
	_apply_music_volume()


func play_menu_music() -> void:
	if _menu_player == null or MENU_MUSIC == null:
		return
	if _game_player != null and _game_player.playing:
		_game_player.stop()
	_menu_player.stream = MENU_MUSIC
	if not _menu_player.playing:
		_menu_player.play()


func play_game_music() -> void:
	if _game_player == null or GAME_MUSIC == null:
		return
	if _menu_player != null and _menu_player.playing:
		_menu_player.stop()
	_game_player.stream = GAME_MUSIC
	if not _game_player.playing:
		_game_player.play()


func stop_all_music() -> void:
	if _menu_player != null:
		_menu_player.stop()
	if _game_player != null:
		_game_player.stop()


func set_music_volume_db(value: float) -> void:
	_music_volume_db = value
	_apply_music_volume()
	_save_settings()


func get_music_volume_db() -> float:
	return _music_volume_db


func set_sfx_volume_db(value: float) -> void:
	_sfx_volume_db = value
	_save_settings()


func get_sfx_volume_db() -> float:
	return _sfx_volume_db


func _build_players() -> void:
	_menu_player = AudioStreamPlayer.new()
	_menu_player.name = "MenuMusicPlayer"
	_menu_player.bus = &"Master"
	_menu_player.finished.connect(_on_menu_music_finished)
	add_child(_menu_player)

	_game_player = AudioStreamPlayer.new()
	_game_player.name = "GameMusicPlayer"
	_game_player.bus = &"Master"
	_game_player.finished.connect(_on_game_music_finished)
	add_child(_game_player)


func _apply_music_volume() -> void:
	if _menu_player != null:
		_menu_player.volume_db = _music_volume_db
	if _game_player != null:
		_game_player.volume_db = _music_volume_db


func _load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		_music_volume_db = DEFAULT_MUSIC_VOLUME_DB
		_sfx_volume_db = DEFAULT_SFX_VOLUME_DB
		return
	_music_volume_db = float(config.get_value(SETTINGS_SECTION, SETTINGS_KEY_MUSIC, DEFAULT_MUSIC_VOLUME_DB))
	_sfx_volume_db = float(config.get_value(SETTINGS_SECTION, SETTINGS_KEY_SFX, DEFAULT_SFX_VOLUME_DB))


func _save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, SETTINGS_KEY_MUSIC, _music_volume_db)
	config.set_value(SETTINGS_SECTION, SETTINGS_KEY_SFX, _sfx_volume_db)
	config.save(SETTINGS_PATH)


func _on_menu_music_finished() -> void:
	if _menu_player != null and _menu_player.stream == MENU_MUSIC:
		_menu_player.play()


func _on_game_music_finished() -> void:
	if _game_player != null and _game_player.stream == GAME_MUSIC:
		_game_player.play()
