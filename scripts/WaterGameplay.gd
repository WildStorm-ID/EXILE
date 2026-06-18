class_name WaterGameplay
extends Node2D

@export var waterline_y := 300.0
@export var tint_color := Color(0.02, 0.35, 0.62, 0.34)
@export var depth_color := Color(0.0, 0.13, 0.24, 0.18)
@export var surface_color := Color(0.62, 0.93, 1.0, 0.82)
@export var foam_color := Color(0.92, 1.0, 1.0, 0.72)
@export var bubble_count := 36

var _time := 0.0
var _rng := RandomNumberGenerator.new()
var _bubbles: Array[Dictionary] = []

func _ready() -> void:
	_rng.randomize()
	_rebuild_bubbles()

func _process(delta: float) -> void:
	_time += delta
	var size := get_viewport_rect().size

	for bubble in _bubbles:
		var bubble_position: Vector2 = bubble["position"]
		var speed: float = bubble["speed"]
		var sway: float = bubble["sway"]
		var sway_speed: float = bubble["sway_speed"]
		var phase: float = bubble["phase"]
		bubble_position.y -= speed * delta
		bubble_position.x += sin(_time * sway_speed + phase) * sway * delta
		bubble["position"] = bubble_position
		if bubble_position.y < waterline_y + 8.0:
			_reset_bubble(bubble, size, true)

	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	if _bubbles.size() != bubble_count:
		_rebuild_bubbles()

	var water_height: float = size.y - waterline_y
	if water_height < 0.0:
		water_height = 0.0

	var depth_height: float = water_height - 120.0
	if depth_height < 0.0:
		depth_height = 0.0

	draw_rect(Rect2(0.0, waterline_y, size.x, water_height), tint_color, true)
	draw_rect(Rect2(0.0, waterline_y + 120.0, size.x, depth_height), depth_color, true)
	_draw_surface(size.x)
	_draw_bubbles()

func _draw_surface(width: float) -> void:
	var points := PackedVector2Array()
	var step := 24.0
	var x := 0.0
	while x <= width + step:
		var y := waterline_y + sin((x * 0.035) + _time * 2.4) * 3.0
		points.append(Vector2(x, y))
		x += step

	draw_polyline(points, Color(0.01, 0.18, 0.31, 0.95), 5.0, false)
	draw_polyline(points, surface_color, 2.0, false)

	for start_x in range(0, int(width) + 48, 48):
		var crest_y := waterline_y + sin((float(start_x) * 0.035) + _time * 2.4) * 3.0
		draw_rect(Rect2(start_x + 12.0, crest_y - 3.0, 18.0, 2.0), foam_color, true)

func _draw_bubbles() -> void:
	for bubble in _bubbles:
		var radius: float = bubble["radius"]
		var bubble_position: Vector2 = bubble["position"]
		draw_circle(bubble_position, radius + 1.0, Color(0.02, 0.18, 0.24, 0.22))
		draw_arc(bubble_position, radius, 0.2, TAU * 0.88, 8, Color(0.76, 1.0, 0.96, 0.42), 1.0, false)
		draw_circle(bubble_position + Vector2(-radius * 0.25, -radius * 0.25), max(1.0, radius * 0.22), Color(0.94, 1.0, 1.0, 0.56))

func _rebuild_bubbles() -> void:
	_bubbles.clear()
	var size := get_viewport_rect().size
	for _index in range(bubble_count):
		var bubble := {
			"position": Vector2.ZERO,
			"radius": 1.0,
			"speed": 20.0,
			"sway": 12.0,
			"sway_speed": 1.0,
			"phase": 0.0,
		}
		_reset_bubble(bubble, size, false)
		_bubbles.append(bubble)

func _reset_bubble(bubble: Dictionary, size: Vector2, from_bottom: bool) -> void:
	var water_height: float = size.y - waterline_y
	if water_height < 16.0:
		water_height = 16.0

	var max_x: float = size.x - 16.0
	if max_x < 16.0:
		max_x = 16.0

	bubble["position"] = Vector2(
		_rng.randf_range(16.0, max_x),
		_rng.randf_range(size.y + 8.0, size.y + water_height * 0.75) if from_bottom else _rng.randf_range(waterline_y + 18.0, size.y - 8.0)
	)
	bubble["radius"] = _rng.randf_range(1.5, 4.0)
	bubble["speed"] = _rng.randf_range(16.0, 42.0)
	bubble["sway"] = _rng.randf_range(5.0, 18.0)
	bubble["sway_speed"] = _rng.randf_range(0.8, 2.2)
	bubble["phase"] = _rng.randf_range(0.0, TAU)
