extends Node2D

const WORLD_SCENE := "res://scenes/World.tscn"

@onready var parallax_background: ParallaxBackground = $ParallaxBackground
@onready var start_button: Button = $MenuLayer/Root/MenuPanel/MarginContainer/VBoxContainer/StartButton
@onready var exit_button: Button = $MenuLayer/Root/MenuPanel/MarginContainer/VBoxContainer/ExitButton

var drift_x := 0.0

func _ready() -> void:
	Engine.time_scale = 1.0
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	start_button.grab_focus()

func _process(delta: float) -> void:
	drift_x += delta * 18.0
	parallax_background.scroll_offset.x = -drift_x

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(WORLD_SCENE)

func _on_exit_pressed() -> void:
	get_tree().quit()
