extends Node2D

const WORLD_SCENE := "res://scenes/World.tscn"

@onready var parallax_background: ParallaxBackground = $ParallaxBackground
@onready var menu_panel: PanelContainer = $MenuLayer/Root/MenuPanel
@onready var start_button: Button = $MenuLayer/Root/MenuPanel/MarginContainer/VBoxContainer/StartButton
@onready var credits_button: Button = $MenuLayer/Root/MenuPanel/MarginContainer/VBoxContainer/CreditsButton
@onready var exit_button: Button = $MenuLayer/Root/MenuPanel/MarginContainer/VBoxContainer/ExitButton
@onready var credits_panel: PanelContainer = $MenuLayer/Root/CreditsPanel
@onready var credits_back_button: Button = $MenuLayer/Root/CreditsPanel/MarginContainer/VBoxContainer/BackButton

var drift_x := 0.0

func _ready() -> void:
	Engine.time_scale = 1.0
	start_button.pressed.connect(_on_start_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	credits_back_button.pressed.connect(_on_credits_back_pressed)
	credits_panel.hide()
	start_button.grab_focus()

func _process(delta: float) -> void:
	drift_x += delta * 18.0
	parallax_background.scroll_offset.x = -drift_x

func _unhandled_input(event: InputEvent) -> void:
	if credits_panel.visible and event.is_action_pressed("ui_cancel"):
		_on_credits_back_pressed()
		get_viewport().set_input_as_handled()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(WORLD_SCENE)

func _on_credits_pressed() -> void:
	menu_panel.hide()
	credits_panel.show()
	credits_back_button.grab_focus()

func _on_credits_back_pressed() -> void:
	credits_panel.hide()
	menu_panel.show()
	credits_button.grab_focus()

func _on_exit_pressed() -> void:
	get_tree().quit()
