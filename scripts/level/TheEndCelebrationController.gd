extends Node

const ENGLISH_FONT: FontFile = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const LATIN_FONT: FontFile = preload("res://assets/fonts/fusion-pixel-12px-proportional-latin.otf")
const CHINESE_FONT: FontFile = preload("res://assets/fonts/fusion-pixel-12px-proportional-zh_hans.otf")

const SFX_RETRO_NOTIFICATION: AudioStream = preload("res://assets/music/mixkit_retro_game_notification_212.mp3")
const SFX_UNLOCK_NOTIFICATION: AudioStream = preload("res://assets/music/mixkit_unlock_game_notification_253.mp3")
const SFX_QUICK_WIN: AudioStream = preload("res://assets/music/mixkit_quick_win_video_game_notification_269.mp3")
const SFX_ARCADE_COIN: AudioStream = preload("res://assets/music/mixkit_arcade_game_jump_coin_216.mp3")
const SFX_ARCADE_BONUS: AudioStream = preload("res://assets/music/mixkit_arcade_bonus_alert_767.mp3")
const SFX_QUICK_POSITIVE: AudioStream = preload("res://assets/music/mixkit_quick_positive_video_game_notification_interface_265.mp3")
const SFX_ARCADE_WIN: AudioStream = preload("res://assets/music/mixkit_arcade_video_game_win_212.wav")

const CELEBRATION_SOUNDS: Array[AudioStream] = [
	SFX_RETRO_NOTIFICATION,
	SFX_UNLOCK_NOTIFICATION,
	SFX_QUICK_WIN,
	SFX_ARCADE_COIN,
	SFX_ARCADE_BONUS,
	SFX_QUICK_POSITIVE,
	SFX_ARCADE_WIN,
]

const TEXT_VARIANTS: Array[Dictionary] = [
	{
		"text": "CONGRATULATIONS!",
		"font_key": "english",
		"font_size": 52,
		"color": Color(1.0, 0.96, 0.58, 1.0),
		"outline": Color(0.36, 0.16, 0.02, 1.0),
		"shadow": Color(0.18, 0.06, 0.14, 0.85),
		"accent": Color(1.0, 0.54, 0.18, 1.0),
	},
	{
		"text": "YOU DID THE THING!",
		"font_key": "latin",
		"font_size": 56,
		"color": Color(0.64, 0.96, 1.0, 1.0),
		"outline": Color(0.05, 0.22, 0.34, 1.0),
		"shadow": Color(0.02, 0.08, 0.15, 0.82),
		"accent": Color(0.2, 0.74, 1.0, 1.0),
	},
	{
		"text": "GG! STAGE CLEAR!",
		"font_key": "english",
		"font_size": 48,
		"color": Color(0.82, 1.0, 0.64, 1.0),
		"outline": Color(0.11, 0.28, 0.1, 1.0),
		"shadow": Color(0.03, 0.12, 0.05, 0.8),
		"accent": Color(0.42, 1.0, 0.5, 1.0),
	},
	{
		"text": "LEGENDARY!",
		"font_key": "english",
		"font_size": 50,
		"color": Color(1.0, 0.82, 0.56, 1.0),
		"outline": Color(0.35, 0.12, 0.01, 1.0),
		"shadow": Color(0.24, 0.08, 0.04, 0.84),
		"accent": Color(1.0, 0.4, 0.16, 1.0),
	},
	{
		"text": "AMAZING!",
		"font_key": "latin",
		"font_size": 56,
		"color": Color(0.7, 0.95, 1.0, 1.0),
		"outline": Color(0.06, 0.24, 0.34, 1.0),
		"shadow": Color(0.02, 0.08, 0.14, 0.84),
		"accent": Color(0.22, 0.76, 1.0, 1.0),
	},
	{
		"text": "\u606d\u559c\u901a\u5173\uff01",
		"font_key": "zh",
		"font_size": 62,
		"color": Color(1.0, 0.84, 0.48, 1.0),
		"outline": Color(0.43, 0.14, 0.02, 1.0),
		"shadow": Color(0.23, 0.05, 0.08, 0.86),
		"accent": Color(1.0, 0.43, 0.24, 1.0),
	},
	{
		"text": "\u592a\u5389\u5bb3\u4e86\uff01",
		"font_key": "zh",
		"font_size": 60,
		"color": Color(1.0, 0.76, 0.54, 1.0),
		"outline": Color(0.41, 0.16, 0.05, 1.0),
		"shadow": Color(0.21, 0.08, 0.03, 0.84),
		"accent": Color(1.0, 0.52, 0.2, 1.0),
	},
	{
		"text": "\u6f02\u4eae\uff01",
		"font_key": "zh",
		"font_size": 60,
		"color": Color(0.8, 0.92, 1.0, 1.0),
		"outline": Color(0.08, 0.16, 0.33, 1.0),
		"shadow": Color(0.04, 0.07, 0.16, 0.84),
		"accent": Color(0.34, 0.58, 1.0, 1.0),
	},
]

const ANIMATION_STYLES: Array[StringName] = [
	&"rise",
	&"spin",
	&"sweep",
	&"echo",
]

const EFFECT_STYLES: Array[StringName] = [
	&"sparkle_storm",
	&"pixel_blast",
	&"fireworks",
	&"jackpot",
	&"party_rain",
]

const CELEBRATION_COLORS: Array[Color] = [
	Color(1.0, 0.95, 0.45, 1.0),
	Color(1.0, 0.48, 0.36, 1.0),
	Color(0.48, 0.95, 1.0, 1.0),
	Color(0.58, 1.0, 0.46, 1.0),
	Color(1.0, 0.52, 0.88, 1.0),
	Color(0.95, 0.76, 1.0, 1.0),
]

const TRIGGER_COOLDOWN := 0.12

var _rng := RandomNumberGenerator.new()
var _overlay_layer: CanvasLayer
var _ui_root: Control
var _flash_rect: ColorRect
var _particle_root: Node2D
var _audio_players: Array[AudioStreamPlayer] = []
var _next_audio_player: int = 0
var _last_trigger_time: float = -10.0
var _confetti_texture: Texture2D
var _pixel_burst_texture: Texture2D
var _sparkle_texture: Texture2D
var _streamer_texture: Texture2D
var _ring_texture: Texture2D
var _prompt_node2d: Node2D
var _prompt_control: Control
var _prompt_scale: Vector2 = Vector2.ONE
var _prompt_modulate: Color = Color.WHITE


func _ready() -> void:
	_rng.randomize()
	_build_overlay()
	_build_audio_players()
	_cache_shift_prompt()


func trigger_random_celebration(world_position: Vector2 = Vector2.ZERO) -> void:
	var now: float = Time.get_ticks_msec() * 0.001
	if now - _last_trigger_time < TRIGGER_COOLDOWN:
		return
	_last_trigger_time = now

	var variant: Dictionary = TEXT_VARIANTS[_rng.randi_range(0, TEXT_VARIANTS.size() - 1)]
	var accent: Color = variant.get("accent", Color.WHITE)
	var screen_position := _random_text_anchor()
	var animation_style: StringName = ANIMATION_STYLES[_rng.randi_range(0, ANIMATION_STYLES.size() - 1)]
	var effect_style: StringName = EFFECT_STYLES[_rng.randi_range(0, EFFECT_STYLES.size() - 1)]

	_play_effect_sound(effect_style)
	_pulse_shift_prompt(accent)
	_play_screen_flash(accent)
	_spawn_local_celebration_effect(screen_position, accent, effect_style)

	match animation_style:
		&"spin":
			_spawn_spin_banner(variant, screen_position)
		&"sweep":
			_spawn_sweep_banner(variant, screen_position)
		&"echo":
			_spawn_echo_banner(variant, screen_position)
		_:
			_spawn_rise_banner(variant, screen_position)


func _build_overlay() -> void:
	_confetti_texture = _create_confetti_texture()
	_pixel_burst_texture = _create_pixel_burst_texture()
	_sparkle_texture = _create_sparkle_texture()
	_streamer_texture = _create_streamer_texture()
	_ring_texture = _create_ring_texture()

	_overlay_layer = CanvasLayer.new()
	_overlay_layer.name = "CelebrationOverlay"
	_overlay_layer.layer = 25
	add_child(_overlay_layer)

	_ui_root = Control.new()
	_ui_root.name = "CelebrationUI"
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_layer.add_child(_ui_root)

	_flash_rect = ColorRect.new()
	_flash_rect.name = "FlashRect"
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_ui_root.add_child(_flash_rect)

	_particle_root = Node2D.new()
	_particle_root.name = "CelebrationParticles"
	_overlay_layer.add_child(_particle_root)


func _build_audio_players() -> void:
	for index in range(3):
		var player := AudioStreamPlayer.new()
		player.name = "CelebrationAudioPlayer%d" % index
		player.bus = &"Master"
		add_child(player)
		_audio_players.append(player)


func _cache_shift_prompt() -> void:
	var prompt_node := get_parent().get_node_or_null("BigShift")
	_prompt_node2d = prompt_node as Node2D
	_prompt_control = prompt_node as Control

	if _prompt_node2d != null:
		_prompt_scale = _prompt_node2d.scale
		_prompt_modulate = _prompt_node2d.modulate
	elif _prompt_control != null:
		_prompt_scale = _prompt_control.scale
		_prompt_modulate = _prompt_control.modulate


func _play_random_sound() -> void:
	if _audio_players.is_empty() or CELEBRATION_SOUNDS.is_empty():
		return

	var audio_manager := get_node_or_null("/root/AudioManager")
	var sfx_volume_db := -7.0
	if audio_manager != null and audio_manager.has_method("get_sfx_volume_db"):
		sfx_volume_db = float(audio_manager.get_sfx_volume_db())

	var player := _audio_players[_next_audio_player % _audio_players.size()]
	_next_audio_player += 1
	player.stop()
	player.volume_db = sfx_volume_db + 2.6
	player.pitch_scale = _rng.randf_range(0.96, 1.05)
	player.stream = CELEBRATION_SOUNDS[_rng.randi_range(0, CELEBRATION_SOUNDS.size() - 1)]
	player.play()


func _play_effect_sound(effect_style: StringName) -> void:
	match effect_style:
		&"sparkle_storm":
			_play_sound_from_pool([SFX_RETRO_NOTIFICATION, SFX_QUICK_POSITIVE, SFX_QUICK_WIN], 2.3, 0.98, 1.08)
			_schedule_sound_from_pool([SFX_ARCADE_COIN, SFX_UNLOCK_NOTIFICATION], 0.08, 0.9, 1.06, 1.4)
		&"pixel_blast":
			_play_sound_from_pool([SFX_ARCADE_BONUS, SFX_ARCADE_WIN, SFX_QUICK_WIN], 3.0, 0.94, 1.03)
		&"fireworks":
			_play_sound_from_pool([SFX_ARCADE_BONUS, SFX_QUICK_POSITIVE, SFX_ARCADE_WIN], 3.1, 0.95, 1.04)
			_schedule_sound_from_pool([SFX_QUICK_WIN, SFX_ARCADE_COIN], 0.06, 0.94, 1.08, 1.6)
		&"party_rain":
			_play_sound_from_pool([SFX_UNLOCK_NOTIFICATION, SFX_QUICK_POSITIVE, SFX_RETRO_NOTIFICATION], 2.2, 0.99, 1.08)
			_schedule_sound_from_pool([SFX_ARCADE_COIN, SFX_QUICK_WIN], 0.11, 0.94, 1.1, 1.2)
		_:
			_play_sound_from_pool([SFX_ARCADE_WIN, SFX_ARCADE_BONUS, SFX_QUICK_POSITIVE], 3.2, 0.94, 1.04)
			_schedule_sound_from_pool([SFX_ARCADE_COIN, SFX_UNLOCK_NOTIFICATION, SFX_QUICK_WIN], 0.08, 0.92, 1.08, 1.7)


func _play_sound_from_pool(pool: Array, volume_offset: float, pitch_min: float, pitch_max: float) -> void:
	if pool.is_empty():
		_play_random_sound()
		return

	var audio_manager := get_node_or_null("/root/AudioManager")
	var sfx_volume_db := -7.0
	if audio_manager != null and audio_manager.has_method("get_sfx_volume_db"):
		sfx_volume_db = float(audio_manager.get_sfx_volume_db())

	var player := _audio_players[_next_audio_player % _audio_players.size()]
	_next_audio_player += 1
	player.stop()
	player.volume_db = sfx_volume_db + volume_offset
	player.pitch_scale = _rng.randf_range(pitch_min, pitch_max)
	player.stream = pool[_rng.randi_range(0, pool.size() - 1)] as AudioStream
	player.play()


func _schedule_sound_from_pool(pool: Array, delay: float, pitch_min: float, pitch_max: float, volume_offset: float) -> void:
	if pool.is_empty():
		return

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		_play_sound_from_pool(pool, volume_offset, pitch_min, pitch_max)
	)


func _play_screen_flash(accent: Color) -> void:
	var flash_color := accent.lerp(Color.WHITE, 0.35)
	flash_color.a = 1.0
	_flash_rect.color = flash_color
	_flash_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_flash_rect, "modulate", Color(1.0, 1.0, 1.0, 0.2), 0.05)
	tween.tween_property(_flash_rect, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.22)


func _spawn_burst_ring(center: Vector2, accent: Color) -> void:
	for offset_scale in [0.0, 24.0]:
		var ring := Sprite2D.new()
		ring.texture = _ring_texture
		ring.centered = true
		ring.position = center + Vector2(_rng.randf_range(-18.0, 18.0), _rng.randf_range(-22.0, 14.0))
		ring.modulate = accent.lerp(Color.WHITE, 0.2)
		ring.scale = Vector2.ONE * (0.25 + offset_scale * 0.002)
		_particle_root.add_child(ring)

		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		tween.tween_property(ring, "scale", Vector2.ONE * (2.4 + offset_scale * 0.01), 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(ring, "modulate", Color(ring.modulate.r, ring.modulate.g, ring.modulate.b, 0.0), 0.36)
		tween.set_parallel(false)
		tween.tween_callback(ring.queue_free)


func _spawn_pixel_explosion(center: Vector2, accent: Color) -> void:
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 72
	particles.lifetime = 0.82
	particles.randomness = 0.4
	particles.texture = _pixel_burst_texture
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2(0.0, 420.0)
	particles.initial_velocity_min = 180.0
	particles.initial_velocity_max = 340.0
	particles.angular_velocity_min = -920.0
	particles.angular_velocity_max = 920.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.2
	particles.color = accent.lerp(_random_palette_color(), 0.38)
	particles.position = center
	particles.emitting = false
	_particle_root.add_child(particles)
	_play_one_shot_particles(particles, 1.0)


func _spawn_star_flash(center: Vector2, accent: Color) -> void:
	var star := Sprite2D.new()
	star.texture = _sparkle_texture
	star.centered = true
	star.position = center
	star.scale = Vector2(0.15, 0.15)
	star.modulate = accent.lerp(Color.WHITE, 0.45)
	_particle_root.add_child(star)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(star, "scale", Vector2(2.8, 2.8), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(star, "rotation", _rng.randf_range(-0.7, 0.7), 0.18)
	tween.tween_property(star, "modulate", Color(star.modulate.r, star.modulate.g, star.modulate.b, 0.0), 0.24)
	tween.set_parallel(false)
	tween.tween_callback(star.queue_free)


func _spawn_local_celebration_effect(center: Vector2, accent: Color, effect_style: StringName) -> void:
	_spawn_burst_ring(center, accent)
	match effect_style:
		&"sparkle_storm":
			_spawn_sparkle_halo(center, accent)
			_spawn_star_fountain(center, accent)
		&"pixel_blast":
			_spawn_pixel_bloom(center, accent)
			_spawn_orbit_flashes(center, accent)
		&"fireworks":
			_spawn_firework_cluster(center, accent)
			_spawn_orbit_flashes(center, accent)
		&"party_rain":
			_spawn_ribbon_swirl(center, accent)
			_spawn_streamer_fan(center, accent)
		_:
			_spawn_jackpot_burst(center, accent)
			_spawn_sparkle_halo(center, accent)


func _spawn_sparkle_halo(center: Vector2, accent: Color) -> void:
	for offset in [
		Vector2(0.0, -72.0),
		Vector2(-92.0, -18.0),
		Vector2(92.0, -18.0),
		Vector2(-54.0, 46.0),
		Vector2(54.0, 46.0),
	]:
		var color := _random_accent_variant(accent)
		_spawn_star_flash(center + offset, color)
		_spawn_sparkles(center + offset * 0.65, color)


func _spawn_pixel_bloom(center: Vector2, accent: Color) -> void:
	_spawn_pixel_explosion(center, accent)
	for offset in [
		Vector2(-86.0, -34.0),
		Vector2(88.0, -28.0),
		Vector2(-54.0, 58.0),
		Vector2(58.0, 62.0),
	]:
		_spawn_pixel_explosion(center + offset, _random_accent_variant(accent))


func _spawn_firework_cluster(center: Vector2, accent: Color) -> void:
	for offset in [
		Vector2(0.0, -92.0),
		Vector2(-110.0, 8.0),
		Vector2(110.0, 6.0),
	]:
		var color := _random_accent_variant(accent)
		_spawn_confetti(center + offset, color)
		_spawn_burst_ring(center + offset, color)
		_spawn_star_flash(center + offset, color)


func _spawn_streamer_fan(center: Vector2, accent: Color) -> void:
	_spawn_streamers(center, accent)
	_spawn_streamers(center + Vector2(-82.0, -24.0), _random_accent_variant(accent))
	_spawn_streamers(center + Vector2(82.0, -24.0), _random_accent_variant(accent))


func _spawn_ribbon_swirl(center: Vector2, accent: Color) -> void:
	for offset in [
		Vector2(-118.0, -42.0),
		Vector2(118.0, -42.0),
		Vector2(-68.0, 56.0),
		Vector2(68.0, 56.0),
	]:
		var color := _random_accent_variant(accent)
		_spawn_streamers(center + offset, color)
		if _rng.randf() < 0.8:
			_spawn_star_flash(center + offset * 0.7, color)


func _spawn_star_fountain(center: Vector2, accent: Color) -> void:
	for offset in [
		Vector2(-32.0, 42.0),
		Vector2(0.0, 28.0),
		Vector2(32.0, 42.0),
	]:
		_spawn_sparkles(center + offset, _random_accent_variant(accent))
	_spawn_star_flash(center + Vector2(0.0, -88.0), accent)


func _spawn_orbit_flashes(center: Vector2, accent: Color) -> void:
	for offset in [
		Vector2(-128.0, -12.0),
		Vector2(-74.0, -86.0),
		Vector2(74.0, -86.0),
		Vector2(128.0, -12.0),
		Vector2(0.0, 84.0),
	]:
		_spawn_star_flash(center + offset, _random_accent_variant(accent))


func _spawn_jackpot_burst(center: Vector2, accent: Color) -> void:
	_spawn_firework_cluster(center, accent)
	_spawn_pixel_bloom(center, accent)
	_spawn_streamer_fan(center + Vector2(0.0, 22.0), accent)
	_spawn_star_fountain(center, accent)


func _spawn_confetti(center: Vector2, accent: Color) -> void:
	var offsets := [
		Vector2(0.0, 12.0),
		Vector2(-170.0, -8.0),
		Vector2(170.0, -8.0),
	]

	for index in range(offsets.size()):
		var particles := CPUParticles2D.new()
		particles.one_shot = true
		particles.explosiveness = 1.0
		particles.amount = 54
		particles.lifetime = 1.25
		particles.randomness = 0.58
		particles.texture = _confetti_texture
		particles.direction = Vector2.UP
		particles.spread = 155.0
		particles.gravity = Vector2(0.0, 620.0)
		particles.initial_velocity_min = 220.0
		particles.initial_velocity_max = 370.0
		particles.angular_velocity_min = -720.0
		particles.angular_velocity_max = 720.0
		particles.scale_amount_min = 0.9
		particles.scale_amount_max = 1.65
		particles.color = _random_accent_variant(accent).lerp(CELEBRATION_COLORS[index % CELEBRATION_COLORS.size()], 0.35)
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = Vector2(84.0, 14.0)
		particles.position = center + offsets[index]
		particles.emitting = false
		_particle_root.add_child(particles)
		_play_one_shot_particles(particles, 1.6)


func _spawn_sparkles(center: Vector2, accent: Color) -> void:
	for offset in [Vector2(-56.0, -44.0), Vector2(0.0, -76.0), Vector2(62.0, -40.0)]:
		var particles := CPUParticles2D.new()
		particles.one_shot = true
		particles.explosiveness = 1.0
		particles.amount = 24
		particles.lifetime = 0.95
		particles.randomness = 0.42
		particles.texture = _sparkle_texture
		particles.direction = Vector2.UP
		particles.spread = 180.0
		particles.gravity = Vector2(0.0, 120.0)
		particles.initial_velocity_min = 110.0
		particles.initial_velocity_max = 220.0
		particles.scale_amount_min = 0.7
		particles.scale_amount_max = 1.45
		particles.color = _random_accent_variant(accent).lerp(Color.WHITE, 0.55)
		particles.position = center + offset
		particles.emitting = false
		_particle_root.add_child(particles)
		_play_one_shot_particles(particles, 1.2)


func _spawn_streamers(center: Vector2, accent: Color) -> void:
	for offset in [Vector2(-120.0, -28.0), Vector2(120.0, -28.0)]:
		var particles := CPUParticles2D.new()
		particles.one_shot = true
		particles.explosiveness = 1.0
		particles.amount = 18
		particles.lifetime = 1.1
		particles.randomness = 0.4
		particles.texture = _streamer_texture
		particles.direction = Vector2.UP
		particles.spread = 48.0
		particles.gravity = Vector2(0.0, 300.0)
		particles.initial_velocity_min = 160.0
		particles.initial_velocity_max = 240.0
		particles.angular_velocity_min = -360.0
		particles.angular_velocity_max = 360.0
		particles.scale_amount_min = 1.6
		particles.scale_amount_max = 2.5
		particles.color = _random_accent_variant(accent).lerp(Color.WHITE, 0.22)
		particles.position = center + offset
		particles.emitting = false
		_particle_root.add_child(particles)
		_play_one_shot_particles(particles, 1.4)


func _play_one_shot_particles(particles: CPUParticles2D, cleanup_delay: float) -> void:
	particles.restart()
	particles.emitting = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(cleanup_delay)
	tween.tween_callback(particles.queue_free)


func _spawn_rise_banner(variant: Dictionary, anchor: Vector2) -> void:
	var banner := _create_banner(variant, Vector2(1080.0, 170.0))
	var final_center := _clamp_banner_center(anchor + Vector2(0.0, -112.0), banner.size)
	var start_center := final_center + Vector2(0.0, 132.0)
	_set_banner_center(banner, start_center)
	banner.scale = Vector2(0.52, 0.52)
	banner.rotation = _rng.randf_range(-0.08, 0.08)
	banner.modulate = Color(1.0, 1.0, 1.0, 0.0)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(banner, "position", final_center - banner.size * 0.5, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "scale", Vector2(1.04, 1.04), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "modulate", Color.WHITE, 0.18)
	tween.tween_property(banner, "rotation", 0.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_interval(0.48)
	tween.tween_property(banner, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.24)
	tween.tween_callback(banner.queue_free)


func _spawn_spin_banner(variant: Dictionary, anchor: Vector2) -> void:
	var banner := _create_banner(variant, Vector2(980.0, 160.0))
	var final_center := _clamp_banner_center(anchor + Vector2(_rng.randf_range(-24.0, 24.0), -88.0), banner.size)
	_set_banner_center(banner, final_center)
	banner.scale = Vector2(0.15, 0.15)
	banner.rotation = _rng.randf_range(-0.75, 0.75)
	banner.modulate = Color(1.0, 1.0, 1.0, 0.0)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(banner, "scale", Vector2(1.18, 1.18), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "rotation", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "modulate", Color.WHITE, 0.12)
	tween.set_parallel(false)
	tween.tween_property(banner, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.42)
	tween.tween_property(banner, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.2)
	tween.tween_callback(banner.queue_free)


func _spawn_sweep_banner(variant: Dictionary, anchor: Vector2) -> void:
	var sweep_from_left: bool = _rng.randf() < 0.5
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var main_banner := _create_banner(variant, Vector2(1040.0, 150.0))
	var echo_a := _create_banner(variant, Vector2(1040.0, 150.0), Color(1.0, 1.0, 1.0, 0.22))
	var echo_b := _create_banner(variant, Vector2(1040.0, 150.0), Color(1.0, 1.0, 1.0, 0.14))
	var final_center := _clamp_banner_center(anchor + Vector2(0.0, -84.0), main_banner.size)
	var start_x: float = -main_banner.size.x if sweep_from_left else viewport_size.x + main_banner.size.x
	var echo_a_start_x: float = start_x - 42.0 if sweep_from_left else start_x + 42.0
	var echo_b_start_x: float = start_x - 84.0 if sweep_from_left else start_x + 84.0

	_set_banner_center(main_banner, Vector2(start_x, final_center.y))
	_set_banner_center(echo_a, Vector2(echo_a_start_x, final_center.y + 18.0))
	_set_banner_center(echo_b, Vector2(echo_b_start_x, final_center.y + 34.0))

	for banner in [echo_b, echo_a, main_banner]:
		banner.modulate = Color(banner.modulate.r, banner.modulate.g, banner.modulate.b, 0.0)

	_sweep_banner_to(echo_b, final_center + Vector2(10.0, 24.0), 0.22, 0.38, 0.18, 0.18)
	_sweep_banner_to(echo_a, final_center + Vector2(4.0, 12.0), 0.15, 0.42, 0.2, 0.34)
	_sweep_banner_to(main_banner, final_center, 0.08, 0.46, 0.22, 1.0)


func _sweep_banner_to(banner: Control, final_center: Vector2, delay: float, hold_time: float, fade_time: float, target_alpha: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.set_parallel(true)
	tween.tween_property(banner, "position", final_center - banner.size * 0.5, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "modulate", Color(banner.modulate.r, banner.modulate.g, banner.modulate.b, target_alpha), 0.12)
	tween.set_parallel(false)
	tween.tween_interval(hold_time)
	tween.tween_property(banner, "modulate", Color(banner.modulate.r, banner.modulate.g, banner.modulate.b, 0.0), fade_time)
	tween.tween_callback(banner.queue_free)


func _spawn_echo_banner(variant: Dictionary, anchor: Vector2) -> void:
	var centers := [
		anchor + Vector2(-18.0, -120.0),
		anchor + Vector2(18.0, -86.0),
		anchor + Vector2(0.0, -52.0),
	]
	var alpha_values := [0.2, 0.42, 1.0]

	for index in range(centers.size()):
		var banner := _create_banner(variant, Vector2(1000.0, 146.0))
		var final_center := _clamp_banner_center(centers[index], banner.size)
		var start_center := final_center + Vector2(_rng.randf_range(-180.0, 180.0), 84.0 + index * 14.0)
		_set_banner_center(banner, start_center)
		banner.scale = Vector2(0.62, 0.62)
		banner.modulate = Color(1.0, 1.0, 1.0, 0.0)

		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_interval(index * 0.05)
		tween.set_parallel(true)
		tween.tween_property(banner, "position", final_center - banner.size * 0.5, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(banner, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(banner, "modulate", Color(1.0, 1.0, 1.0, alpha_values[index]), 0.14)
		tween.set_parallel(false)
		tween.tween_interval(0.36 - index * 0.06)
		tween.tween_property(banner, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.22)
		tween.tween_callback(banner.queue_free)


func _create_banner(variant: Dictionary, size: Vector2, tint: Color = Color.WHITE) -> Control:
	var banner := Control.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.size = size
	banner.pivot_offset = size * 0.5
	_ui_root.add_child(banner)

	var shadow := Label.new()
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shadow.position = Vector2(8.0, 8.0)
	shadow.text = str(variant.get("text", "CONGRATULATIONS!"))
	shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shadow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shadow.add_theme_font_override("font", _font_for_key(str(variant.get("font_key", "english"))))
	shadow.add_theme_font_size_override("font_size", int(variant.get("font_size", 56)))
	shadow.add_theme_color_override("font_color", variant.get("shadow", Color(0.1, 0.1, 0.1, 0.8)))
	banner.add_child(shadow)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = str(variant.get("text", "CONGRATULATIONS!"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", _font_for_key(str(variant.get("font_key", "english"))))
	label.add_theme_font_size_override("font_size", int(variant.get("font_size", 56)))
	label.add_theme_color_override("font_color", variant.get("color", Color.WHITE))
	label.add_theme_color_override("font_outline_color", variant.get("outline", Color.BLACK))
	label.add_theme_constant_override("outline_size", 10)
	banner.add_child(label)

	banner.modulate = tint
	return banner


func _font_for_key(font_key: String) -> FontFile:
	match font_key:
		"latin":
			return LATIN_FONT
		"zh":
			return CHINESE_FONT
		_:
			return ENGLISH_FONT


func _set_banner_center(banner: Control, center: Vector2) -> void:
	banner.position = center - banner.size * 0.5


func _clamp_banner_center(center: Vector2, banner_size: Vector2) -> Vector2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	return Vector2(
		clampf(center.x, banner_size.x * 0.5 + 24.0, viewport_size.x - banner_size.x * 0.5 - 24.0),
		clampf(center.y, banner_size.y * 0.5 + 24.0, viewport_size.y - banner_size.y * 0.5 - 24.0)
	)


func _pulse_shift_prompt(accent: Color) -> void:
	if _prompt_node2d == null and _prompt_control == null:
		return

	var target_tint := accent.lerp(Color.WHITE, 0.28)

	if _prompt_node2d != null:
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		tween.tween_property(_prompt_node2d, "scale", _prompt_scale * 1.16, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(_prompt_node2d, "modulate", target_tint, 0.08)
		tween.set_parallel(false)
		tween.tween_property(_prompt_node2d, "scale", _prompt_scale, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.set_parallel(true)
		tween.tween_property(_prompt_node2d, "modulate", _prompt_modulate, 0.18)
	elif _prompt_control != null:
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		tween.tween_property(_prompt_control, "scale", _prompt_scale * 1.16, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(_prompt_control, "modulate", target_tint, 0.08)
		tween.set_parallel(false)
		tween.tween_property(_prompt_control, "scale", _prompt_scale, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.set_parallel(true)
		tween.tween_property(_prompt_control, "modulate", _prompt_modulate, 0.18)


func _world_to_screen(world_position: Vector2) -> Vector2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var screen_position: Vector2 = get_viewport().get_canvas_transform() * world_position
	if screen_position == Vector2.ZERO:
		return viewport_size * Vector2(0.5, 0.46)
	return Vector2(
		clampf(screen_position.x, viewport_size.x * 0.22, viewport_size.x * 0.78),
		clampf(screen_position.y, viewport_size.y * 0.22, viewport_size.y * 0.7)
	)


func _random_text_anchor() -> Vector2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	return Vector2(
		_rng.randf_range(220.0, maxf(220.0, viewport_size.x - 220.0)),
		_rng.randf_range(120.0, maxf(120.0, viewport_size.y - 140.0))
	)


func _random_palette_color() -> Color:
	return CELEBRATION_COLORS[_rng.randi_range(0, CELEBRATION_COLORS.size() - 1)]


func _random_accent_variant(accent: Color) -> Color:
	return accent.lerp(_random_palette_color(), _rng.randf_range(0.25, 0.58))


func _create_confetti_texture() -> Texture2D:
	var image := Image.create(4, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)


func _create_pixel_burst_texture() -> Texture2D:
	var image := Image.create(6, 6, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			if x >= 1 and x <= 4 and y >= 1 and y <= 4:
				image.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(image)


func _create_streamer_texture() -> Texture2D:
	var image := Image.create(14, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			image.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(image)


func _create_sparkle_texture() -> Texture2D:
	var image := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var dx := absf(float(x) - 4.5)
			var dy := absf(float(y) - 4.5)
			if dx + dy <= 3.5 or dx <= 0.5 or dy <= 0.5:
				image.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(image)


func _create_ring_texture() -> Texture2D:
	var size := 96
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var center := Vector2(size * 0.5, size * 0.5)
	for x in range(size):
		for y in range(size):
			var distance := Vector2(float(x), float(y)).distance_to(center)
			if distance >= 28.0 and distance <= 38.0:
				image.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(image)
