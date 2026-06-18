extends Area2D

signal player_hit(player: Node)

@export var drift_speed := 125.0
@export var roll_speed := 1.4

var world_speed := 1.0

func _ready() -> void:
	add_to_group("water_obstacle")
	body_entered.connect(_on_body_entered)
	$AnimatedSprite2D.play("leak")
	$Bubbles.emitting = true

func _process(delta: float) -> void:
	global_position.x -= drift_speed * world_speed * delta
	rotation = sin(Time.get_ticks_msec() * 0.001 * roll_speed) * 0.08

func set_world_speed(value: float) -> void:
	world_speed = max(value, 0.1)

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_hit"):
		player_hit.emit(body)
