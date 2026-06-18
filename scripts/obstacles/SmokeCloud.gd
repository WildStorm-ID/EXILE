extends Area2D

signal smoke_entered(player: Node)
signal smoke_exited(player: Node)

@export var drift_speed := 105.0
@export var pulse_amplitude := 0.08

var world_speed := 1.0
var _time := 0.0

func _ready() -> void:
	add_to_group("air_obstacle")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	$AnimatedSprite2D.play("drift")

func _process(delta: float) -> void:
	_time += delta
	global_position.x -= drift_speed * world_speed * delta
	scale = Vector2.ONE * (1.0 + sin(_time * 1.6) * pulse_amplitude)

func set_world_speed(value: float) -> void:
	world_speed = max(value, 0.1)

func _on_body_entered(body: Node) -> void:
	if body.has_method("enter_smoke"):
		smoke_entered.emit(body)

func _on_body_exited(body: Node) -> void:
	if body.has_method("exit_smoke"):
		smoke_exited.emit(body)
