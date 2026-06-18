extends Area2D

signal player_hit(player: Node)

@export var drift_speed := 150.0
@export var bob_amplitude := 18.0
@export var bob_frequency := 2.2

var world_speed := 1.0
var _base_y := 0.0
var _time := 0.0

func _ready() -> void:
	add_to_group("water_obstacle")
	_base_y = global_position.y
	body_entered.connect(_on_body_entered)
	$AnimatedSprite2D.play("float")

func _process(delta: float) -> void:
	_time += delta
	global_position.x -= drift_speed * world_speed * delta
	global_position.y = _base_y + sin(_time * bob_frequency) * bob_amplitude

func set_world_speed(value: float) -> void:
	world_speed = max(value, 0.1)

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_hit"):
		player_hit.emit(body)
