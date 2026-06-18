class_name GameManager
extends Node2D

signal score_changed(score_meters: int)
signal speed_changed(speed_multiplier: float)
signal game_over(final_score: int)
signal freedom_reached(final_score: int)

@export var pixels_per_meter := 10.0
@export var speed_step_distance := 500
@export var freedom_distance := 1000
@export var waterline_y := 300.0

@onready var player: Node = $Player
@onready var spawner: Node = $ObstacleSpawner
@onready var hud: Node = $HUD
@onready var hurt_effect: Node = $HurtEffect
@onready var bgm: AudioStreamPlayer = $BGM
@onready var splash_sfx: AudioStreamPlayer = $SFX/Splash
@onready var flap_sfx: AudioStreamPlayer = $SFX/Flap
@onready var hurt_sfx: AudioStreamPlayer = $SFX/Hurt
@onready var win_sfx: AudioStreamPlayer = $SFX/Win

var start_x := 0.0
var best_x := 0.0
var score_meters := 0
var speed_multiplier := 1.0
var game_active := true
var ending_started := false

func _ready() -> void:
	Engine.time_scale = 1.0
	start_x = player.global_position.x
	best_x = start_x

	player.waterline_y = waterline_y
	spawner.waterline_y = waterline_y

	player.hit_registered.connect(_on_player_hit_registered)
	player.status_changed.connect(hud.set_status)
	player.zone_changed.connect(hud.set_zone)
	player.splash_requested.connect(_play_splash)
	player.flap_requested.connect(_on_player_flap)
	spawner.obstacle_spawned.connect(_on_obstacle_spawned)
	score_changed.connect(hud.set_score)
	speed_changed.connect(hud.set_speed)
	game_over.connect(hud.show_game_over)
	freedom_reached.connect(hud.show_freedom)

	bgm.finished.connect(bgm.play)
	bgm.play()

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

	if score_meters >= freedom_distance and not ending_started:
		_trigger_freedom()

func _on_obstacle_spawned(obstacle: Node) -> void:
	if obstacle.has_signal("player_hit"):
		obstacle.player_hit.connect(_on_obstacle_player_hit)
	if obstacle.has_signal("smoke_entered"):
		obstacle.smoke_entered.connect(_on_smoke_entered)
	if obstacle.has_signal("smoke_exited"):
		obstacle.smoke_exited.connect(_on_smoke_exited)

func _on_obstacle_player_hit(hit_player: Node) -> void:
	if not game_active or hit_player != player:
		return
	player.take_hit()

func _on_smoke_entered(hit_player: Node) -> void:
	if not game_active or hit_player != player:
		return
	player.enter_smoke()
	player.take_hit()
	hurt_effect.set_smoke_active(true)

func _on_smoke_exited(hit_player: Node) -> void:
	if hit_player != player:
		return
	player.exit_smoke()
	hurt_effect.set_smoke_active(player.in_smoke)

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
	game_active = false
	Engine.time_scale = 1.0
	player.set_control_enabled(false)
	spawner.set_spawning_enabled(false)
	hurt_effect.fade_to_clear()
	game_over.emit(score_meters)

func _trigger_freedom() -> void:
	if ending_started:
		return
	ending_started = true
	game_active = false
	spawner.set_spawning_enabled(false)
	spawner.clear_obstacles()
	player.enter_freedom_mode()
	hurt_effect.fade_to_clear()
	hurt_effect.play_brighten()
	bgm.stop()
	win_sfx.play()
	freedom_reached.emit(score_meters)

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", player.global_position + Vector2(760.0, -80.0), 3.0)
	await tween.finished
	hud.show_win_screen(score_meters)
