extends Node2D

const WORLD_SCENE := "res://scenes/World.tscn"
const UI_CLICK := preload("res://assets/audio/ui_click.wav")
const MAIN_MENU_BGM := preload("res://assets/audio/bgm_mainmenu.ogg")
const IDLE_FRAMES := [
	preload("res://assets/sprites/player/flying_fish/idle_0.png"),
	preload("res://assets/sprites/player/flying_fish/idle_1.png"),
	preload("res://assets/sprites/player/flying_fish/idle_2.png"),
	preload("res://assets/sprites/player/flying_fish/idle_3.png"),
]

@onready var parallax_background: ParallaxBackground = $ParallaxBackground
@onready var menu_panel: PanelContainer = $MenuLayer/Root/MenuPanel
@onready var start_button: Button = $MenuLayer/Root/MenuPanel/MarginContainer/VBoxContainer/StartButton
@onready var credits_button: Button = $MenuLayer/Root/MenuPanel/MarginContainer/VBoxContainer/CreditsButton
@onready var exit_button: Button = $MenuLayer/Root/MenuPanel/MarginContainer/VBoxContainer/ExitButton
@onready var credits_panel: PanelContainer = $MenuLayer/Root/CreditsPanel
@onready var credits_back_button: Button = $MenuLayer/Root/CreditsPanel/MarginContainer/VBoxContainer/BackButton

var drift_x := 0.0
var preview_fish: AnimatedSprite2D
var click_sfx: AudioStreamPlayer
var bgm: AudioStreamPlayer

func _ready() -> void:
	Engine.time_scale = 1.0
	_setup_preview_fish()
	_setup_click_sfx()
	_setup_bgm()
	start_button.pressed.connect(_on_start_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	credits_back_button.pressed.connect(_on_credits_back_pressed)
	credits_panel.hide()
	start_button.grab_focus()

func _process(delta: float) -> void:
	drift_x += delta * 18.0
	parallax_background.scroll_offset.x = -drift_x
	if preview_fish:
		var viewport_size := get_viewport_rect().size
		preview_fish.position = Vector2(viewport_size.x * 0.72, viewport_size.y * 0.55 + sin(Time.get_ticks_msec() * 0.002) * 8.0)

func _unhandled_input(event: InputEvent) -> void:
	if credits_panel.visible and event.is_action_pressed("ui_cancel"):
		_on_credits_back_pressed()
		get_viewport().set_input_as_handled()

func _on_start_pressed() -> void:
	_play_click()
	await get_tree().create_timer(0.25).timeout
	get_tree().change_scene_to_file(WORLD_SCENE)

func _on_credits_pressed() -> void:
	_play_click()
	menu_panel.hide()
	preview_fish.hide()
	credits_panel.show()
	credits_back_button.grab_focus()

func _on_credits_back_pressed() -> void:
	_play_click()
	credits_panel.hide()
	menu_panel.show()
	preview_fish.show()
	credits_button.grab_focus()

func _on_exit_pressed() -> void:
	_play_click()
	await get_tree().create_timer(0.25).timeout
	get_tree().quit()

func _setup_preview_fish() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", 4.0)
	for texture in IDLE_FRAMES:
		frames.add_frame(&"idle", texture)

	preview_fish = AnimatedSprite2D.new()
	preview_fish.sprite_frames = frames
	preview_fish.animation = &"idle"
	preview_fish.scale = Vector2(3.2, 3.2)
	preview_fish.play()
	$MenuLayer.add_child(preview_fish)

func _setup_click_sfx() -> void:
	click_sfx = AudioStreamPlayer.new()
	click_sfx.stream = UI_CLICK
	click_sfx.volume_db = -7.0
	add_child(click_sfx)

func _setup_bgm() -> void:
	bgm = AudioStreamPlayer.new()
	bgm.stream = MAIN_MENU_BGM
	bgm.volume_db = -10.0
	bgm.finished.connect(bgm.play)
	add_child(bgm)
	bgm.play()

func _play_click() -> void:
	if click_sfx:
		click_sfx.play()
