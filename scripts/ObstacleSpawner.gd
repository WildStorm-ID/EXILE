class_name ObstacleSpawner
extends Node2D

signal obstacle_spawned(obstacle: Node)

@export var sea_mine_scene: PackedScene
@export var waste_barrel_scene: PackedScene
@export var smoke_cloud_scene: PackedScene
@export var waterline_y := 300.0
@export var min_interval := 1.5
@export var max_interval := 4.0
@export var spawn_distance := 1080.0
@export var cleanup_distance := 360.0

var camera: Camera2D
var enabled := true
var world_speed := 1.0

@onready var timer: Timer = $SpawnTimer

func _ready() -> void:
	randomize()
	timer.timeout.connect(_on_spawn_timer_timeout)
	_schedule_next_spawn()

func _process(_delta: float) -> void:
	if camera == null:
		camera = get_viewport().get_camera_2d()
	if camera == null:
		return

	var left_limit := camera.global_position.x - get_viewport_rect().size.x * 0.5 - cleanup_distance
	for child in get_children():
		if child is Timer:
			continue
		if child is Node2D and child.global_position.x < left_limit:
			child.queue_free()

func set_world_speed(value: float) -> void:
	world_speed = max(value, 0.1)
	for child in get_children():
		if child.has_method("set_world_speed"):
			child.set_world_speed(world_speed)

func set_spawning_enabled(value: bool) -> void:
	enabled = value
	if enabled:
		_schedule_next_spawn()
	else:
		timer.stop()

func clear_obstacles() -> void:
	for child in get_children():
		if child is Timer:
			continue
		child.queue_free()

func _on_spawn_timer_timeout() -> void:
	if not enabled:
		return

	_spawn_random_obstacle()
	_schedule_next_spawn()

func _schedule_next_spawn() -> void:
	if not is_inside_tree() or timer == null:
		return
	timer.wait_time = randf_range(min_interval, max_interval)
	timer.start()

func _spawn_random_obstacle() -> void:
	if camera == null:
		camera = get_viewport().get_camera_2d()
	if camera == null:
		return

	var packed_scene := _pick_scene()
	if packed_scene == null:
		return

	var obstacle := packed_scene.instantiate()
	add_child(obstacle)
	obstacle.global_position = _spawn_position_for(obstacle)
	if obstacle.has_method("set_world_speed"):
		obstacle.set_world_speed(world_speed)
	obstacle_spawned.emit(obstacle)

func _pick_scene() -> PackedScene:
	var roll := randf()
	if roll < 0.36:
		return sea_mine_scene
	if roll < 0.68:
		return waste_barrel_scene
	return smoke_cloud_scene

func _spawn_position_for(obstacle: Node) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var spawn_x := camera.global_position.x + viewport_size.x * 0.5 + spawn_distance
	var top_y := camera.global_position.y - viewport_size.y * 0.5
	var bottom_y := camera.global_position.y + viewport_size.y * 0.5

	if obstacle.is_in_group("air_obstacle"):
		return Vector2(spawn_x, randf_range(top_y + 82.0, waterline_y - 58.0))

	return Vector2(spawn_x, randf_range(waterline_y + 52.0, bottom_y - 62.0))
