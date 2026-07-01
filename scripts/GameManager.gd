class_name GameManager
extends Node2D

signal score_changed(score_meters: int)
signal speed_changed(speed_multiplier: float)
signal game_over(final_score: int)
signal freedom_reached(final_score: int)

@export var pixels_per_meter := 10.0
@export var speed_step_distance := 500
@export var level_start_distance := 1000
@export var level_distance_step := 1000
@export var freedom_distance := 5000
@export var waterline_y := 300.0
@export var bgm_fade_duration := 1.0

@onready var player: Node = $Player
@onready var spawner: Node = $ObstacleSpawner
@onready var hud: Node = $HUD
@onready var hurt_effect: Node = $HurtEffect
@onready var bgm: AudioStreamPlayer = $BGM
@onready var splash_sfx: AudioStreamPlayer = $SFX/Splash
@onready var flap_sfx: AudioStreamPlayer = $SFX/Flap
@onready var hurt_sfx: AudioStreamPlayer = $SFX/Hurt
@onready var win_sfx: AudioStreamPlayer = $SFX/Win
@onready var powerup_sfx: AudioStreamPlayer = $SFX/Powerup

var start_x := 0.0
var best_x := 0.0
var score_meters := 0
var speed_multiplier := 1.0
var game_active := true
var ending_started := false
var game_paused := false
var current_level := 1
var current_target_distance := 1000
var _bgm_base_volume_db := 0.0
var _bgm_fade_tween: Tween

func _ready() -> void:
	Engine.time_scale = 1.0
	_bgm_base_volume_db = bgm.volume_db
	start_x = player.global_position.x
	best_x = start_x

	player.waterline_y = waterline_y
	spawner.waterline_y = waterline_y

	player.hit_registered.connect(_on_player_hit_registered)
	player.status_changed.connect(hud.set_status)
	#player.zone_changed.connect(hud.set_zone)
	player.splash_requested.connect(_play_splash)
	player.flap_requested.connect(_on_player_flap)
	spawner.hazard_hit.connect(_on_hazard_hit)
	spawner.item_collected.connect(_on_item_collected)
	score_changed.connect(hud.set_score)
	#speed_changed.connect(hud.set_speed)
	game_over.connect(hud.show_game_over)
	freedom_reached.connect(hud.show_freedom)
	hud.next_level_requested.connect(_on_next_level_requested)
	hud.pause_requested.connect(_pause_game)
	hud.resume_requested.connect(_resume_game)

	bgm.finished.connect(bgm.play)
	_restore_bgm_volume()
	bgm.play()

	current_target_distance = level_start_distance
	spawner.set_level(current_level - 1)
	score_changed.emit(score_meters)
	speed_changed.emit(speed_multiplier)

func _process(_delta: float) -> void:
	if not game_active:
		return

	best_x = max(best_x, player.global_position.x)
	var new_score := int(max(0.0, (best_x - start_x) / pixels_per_meter))
	if new_score != score_meters:
		score_meters = new_score
		score_changed.emit(score_meters)
		_update_speed_for_score()

	if score_meters >= current_target_distance and not ending_started:
		_trigger_freedom()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not ending_started and player.hit_count < player.max_hits:
		hud.play_click_feedback()
		if game_paused:
			_resume_game()
		elif game_active:
			_pause_game()
		get_viewport().set_input_as_handled()

func _on_hazard_hit(hit_player: Node) -> void:
	if not game_active or hit_player != player:
		return
	player.take_hit()

func _on_item_collected(item_type: StringName, hit_player: Node) -> void:
	if not game_active or hit_player != player:
		return
	match item_type:
		&"hp":
			if player.heal_one():
				powerup_sfx.play()
		&"speed":
			player.apply_speed_boost()
			powerup_sfx.play()

func _on_player_hit_registered(hit_count: int) -> void:
	hurt_sfx.play()
	hurt_effect.play_hit_effect()
	if hit_count >= player.max_hits:
		_trigger_game_over()

func _on_player_flap(in_water: bool) -> void:
	if in_water:
		splash_sfx.play()
	else:
		flap_sfx.play()

func _play_splash() -> void:
	splash_sfx.play()

func _update_speed_for_score() -> void:
	var next_multiplier := 1.0 + floori(float(score_meters) / float(speed_step_distance)) * 0.08
	if not is_equal_approx(next_multiplier, speed_multiplier):
		speed_multiplier = next_multiplier
		player.set_speed_multiplier(speed_multiplier)
		spawner.set_world_speed(speed_multiplier)
		speed_changed.emit(speed_multiplier)

func _trigger_game_over() -> void:
	if not game_active:
		return
	game_paused = false
	game_active = false
	Engine.time_scale = 1.0
	player.enter_stun_mode()
	spawner.set_spawning_enabled(false)
	hurt_effect.fade_to_clear()
	_fade_bgm_to_silence()
	await get_tree().create_timer(0.75).timeout
	game_over.emit(score_meters)

func _trigger_freedom() -> void:
	if ending_started:
		return
	game_paused = false
	ending_started = true
	game_active = false
	spawner.set_spawning_enabled(false)
	spawner.clear_obstacles()
	player.enter_freedom_mode()
	hurt_effect.fade_to_clear()
	hurt_effect.play_brighten()
	if current_target_distance >= freedom_distance:
		_fade_bgm_to_silence()
	win_sfx.play()
	freedom_reached.emit(score_meters)

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", player.global_position + Vector2(760.0, -80.0), 3.0)
	await tween.finished
	hud.show_win_screen(score_meters, current_level, current_target_distance, current_target_distance < freedom_distance)

func _on_next_level_requested() -> void:
	if current_target_distance >= freedom_distance:
		get_tree().reload_current_scene()
		return

	current_level += 1
	current_target_distance = mini(freedom_distance, level_start_distance + (current_level - 1) * level_distance_step)
	ending_started = false
	game_active = true
	game_paused = false
	speed_multiplier = 1.0
	var next_start_x := start_x + float(score_meters) * pixels_per_meter
	player.reset_for_level(Vector2(next_start_x, 360.0))
	player.set_speed_multiplier(speed_multiplier)
	spawner.clear_obstacles()
	spawner.set_world_speed(speed_multiplier)
	spawner.set_level(current_level - 1)
	spawner.set_spawning_enabled(true)
	spawner.set_movement_paused(false)
	hurt_effect.fade_to_clear()
	hud.hide_result()
	_restore_bgm_volume()
	bgm.stream_paused = false
	if not bgm.playing:
		bgm.play()
	score_changed.emit(score_meters)
	speed_changed.emit(speed_multiplier)

func _pause_game() -> void:
	if game_paused or not game_active or ending_started:
		return
	game_paused = true
	game_active = false
	player.set_control_enabled(false)
	spawner.set_spawning_enabled(false)
	spawner.set_movement_paused(true)
	bgm.stream_paused = true
	hud.show_pause_screen()

func _resume_game() -> void:
	if not game_paused:
		return
	game_paused = false
	game_active = true
	player.set_control_enabled(true)
	spawner.set_movement_paused(false)
	spawner.set_spawning_enabled(true)
	bgm.stream_paused = false
	hud.hide_pause_screen()

func _fade_bgm_to_silence() -> void:
	if _bgm_fade_tween:
		_bgm_fade_tween.kill()
	var start_volume := db_to_linear(bgm.volume_db)
	_bgm_fade_tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	_bgm_fade_tween.tween_method(_set_bgm_linear_volume, start_volume, 0.0, bgm_fade_duration)
	_bgm_fade_tween.tween_callback(Callable(bgm, "stop"))

func _restore_bgm_volume() -> void:
	if _bgm_fade_tween:
		_bgm_fade_tween.kill()
		_bgm_fade_tween = null
	bgm.volume_db = _bgm_base_volume_db

func _set_bgm_linear_volume(value: float) -> void:
	bgm.volume_db = linear_to_db(maxf(value, 0.001))
