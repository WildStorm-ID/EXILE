class_name ObstacleSpawner
extends Node2D

signal hazard_hit(player: Node)
signal item_collected(item_type: StringName, player: Node)

const HAZARDS := [
	{
		"name": &"bottle",
		"frames": [
			preload("res://assets/sprites/objects/hazards/bottle_0.png"),
			preload("res://assets/sprites/objects/hazards/bottle_1.png"),
		],
		"size": Vector2(30, 34),
	},
	{
		"name": &"papercup",
		"frames": [
			preload("res://assets/sprites/objects/hazards/papercup_0.png"),
			preload("res://assets/sprites/objects/hazards/papercup_1.png"),
		],
		"size": Vector2(28, 30),
	},
	{
		"name": &"straw",
		"frames": [
			preload("res://assets/sprites/objects/hazards/straw_0.png"),
			preload("res://assets/sprites/objects/hazards/straw_1.png"),
		],
		"size": Vector2(36, 18),
	},
	{
		"name": &"trashbag",
		"frames": [
			preload("res://assets/sprites/objects/hazards/trashbag_0.png"),
			preload("res://assets/sprites/objects/hazards/trashbag_1.png"),
		],
		"size": Vector2(34, 34),
	},
]

const ITEMS := [
	{
		"name": &"hp",
		"frames": [
			preload("res://assets/sprites/objects/items/hp_0.png"),
			preload("res://assets/sprites/objects/items/hp_1.png"),
		],
		"size": Vector2(28, 28),
	},
	{
		"name": &"speed",
		"frames": [
			preload("res://assets/sprites/objects/items/speed_0.png"),
			preload("res://assets/sprites/objects/items/speed_1.png"),
		],
		"size": Vector2(28, 28),
	},
]

@export var waterline_y := 300.0
@export var min_interval := 1.4
@export var max_interval := 3.0
@export var item_spawn_chance := 0.14
@export var spawn_distance := 1080.0
@export var cleanup_distance := 360.0
@export var drift_speed := 135.0

var camera: Camera2D
var enabled := true
var world_speed := 1.0
var level_index := 0

@onready var timer: Timer = $SpawnTimer

func _ready() -> void:
	randomize()
	timer.timeout.connect(_on_spawn_timer_timeout)
	_schedule_next_spawn()

func _process(delta: float) -> void:
	if camera == null:
		camera = get_viewport().get_camera_2d()
	if camera == null:
		return

	var left_limit := camera.global_position.x - get_viewport_rect().size.x * 0.5 - cleanup_distance
	for child in get_children():
		if child is Timer:
			continue
		if child is Node2D:
			var speed := float(child.get_meta("drift_speed", drift_speed))
			child.global_position.x -= speed * world_speed * delta
			child.rotation += float(child.get_meta("spin_speed", 0.0)) * delta
			if child.global_position.x < left_limit:
				child.queue_free()

func set_world_speed(value: float) -> void:
	world_speed = max(value, 0.1)

func set_level(value: int) -> void:
	level_index = max(value, 0)
	var difficulty := float(level_index)
	min_interval = max(0.55, 1.35 - difficulty * 0.12)
	max_interval = max(min_interval + 0.2, 2.75 - difficulty * 0.22)
	item_spawn_chance = clampf(0.18 - difficulty * 0.015, 0.08, 0.18)

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

	_spawn_random_object()
	_schedule_next_spawn()

func _schedule_next_spawn() -> void:
	if not is_inside_tree() or timer == null:
		return
	timer.wait_time = randf_range(min_interval, max_interval)
	timer.start()

func _spawn_random_object() -> void:
	if camera == null:
		camera = get_viewport().get_camera_2d()
	if camera == null:
		return

	var is_item := randf() < item_spawn_chance
	var data: Dictionary = (ITEMS if is_item else HAZARDS).pick_random()
	var object := _build_object(data, is_item)
	add_child(object)
	object.global_position = _spawn_position_for(is_item)

func _build_object(data: Dictionary, is_item: bool) -> Area2D:
	var object := Area2D.new()
	object.collision_layer = 2
	object.collision_mask = 1
	object.set_meta("object_type", &"item" if is_item else &"hazard")
	object.set_meta("item_type", data["name"] if is_item else &"")
	object.set_meta("drift_speed", drift_speed + randf_range(-16.0, 22.0))
	object.set_meta("spin_speed", randf_range(-0.6, 0.6))
	object.body_entered.connect(_on_object_body_entered.bind(object))

	var sprite := AnimatedSprite2D.new()
	sprite.scale = Vector2(1.5, 1.5)
	sprite.sprite_frames = _sprite_frames(data["frames"], "idle")
	sprite.animation = &"idle"
	sprite.play()
	object.add_child(sprite)

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = data["size"]
	shape.shape = rectangle
	object.add_child(shape)

	return object

func _sprite_frames(textures: Array, animation_name: StringName) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, 5.0)
	for texture in textures:
		frames.add_frame(animation_name, texture)
	return frames

func _spawn_position_for(is_item: bool) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var spawn_x := camera.global_position.x + viewport_size.x * 0.5 + spawn_distance
	var top_y := camera.global_position.y - viewport_size.y * 0.5
	var bottom_y := camera.global_position.y + viewport_size.y * 0.5
	var padding := 52.0 if is_item else 42.0
	return Vector2(spawn_x, randf_range(top_y + padding, bottom_y - padding))

func _on_object_body_entered(body: Node, object: Area2D) -> void:
	if object.get_meta("object_type") == &"item":
		item_collected.emit(object.get_meta("item_type"), body)
	else:
		hazard_hit.emit(body)
	object.queue_free()
