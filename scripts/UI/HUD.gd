class_name HUD
extends CanvasLayer

const MAX_STATUS_HITS := 3
const MAIN_MENU_SCENE := "res://scenes/UI/MainMenu.tscn"

@onready var score_label: Label = $Root/TopBar/ScoreBox/ScoreLabel
@onready var health_fill: ColorRect = $Root/TopBar/HealthBar/Fill
@onready var health_shine: ColorRect = $Root/TopBar/HealthBar/Shine
@onready var status_label: Label = $Root/TopBar/StatusLabel
@onready var zone_label: Label = $Root/TopBar/ZoneLabel
@onready var speed_label: Label = $Root/TopBar/SpeedLabel
@onready var freedom_banner: TextureRect = $Root/Center/FreedomBanner
@onready var result_panel: PanelContainer = $Root/Center/ResultPanel
@onready var result_title: Label = $Root/Center/ResultPanel/MarginContainer/VBoxContainer/ResultTitle
@onready var result_score: Label = $Root/Center/ResultPanel/MarginContainer/VBoxContainer/ResultScore
@onready var restart_button: Button = $Root/Center/ResultPanel/MarginContainer/VBoxContainer/ButtonRow/RestartButton
@onready var menu_button: Button = $Root/Center/ResultPanel/MarginContainer/VBoxContainer/ButtonRow/MenuButton

func _ready() -> void:
	freedom_banner.modulate.a = 0.0
	result_panel.hide()
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	_update_health_bar(0)

func set_score(score_meters: int) -> void:
	score_label.text = "%05d m" % score_meters

func set_speed(speed_multiplier: float) -> void:
	speed_label.text = "Speed x%.2f" % speed_multiplier

func set_status(status_text: String, hit_count: int, in_smoke: bool) -> void:
	var markers := ""
	for index in range(MAX_STATUS_HITS):
		markers += "X" if index < hit_count else "-"
	status_label.text = "Status %s  Hits [%s]" % [status_text, markers]
	_update_health_bar(hit_count)
	if in_smoke:
		status_label.add_theme_color_override("font_color", Color(0.75, 0.92, 0.55))
	elif hit_count >= 2:
		status_label.add_theme_color_override("font_color", Color(1.0, 0.44, 0.35))
	else:
		status_label.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))

func set_zone(in_water: bool) -> void:
	zone_label.text = "Water" if in_water else "Air"

func show_freedom(final_score: int) -> void:
	set_score(final_score)
	var tween := create_tween()
	tween.tween_property(freedom_banner, "modulate:a", 1.0, 1.0)

func show_win_screen(final_score: int) -> void:
	result_title.text = "AIR BEBAS"
	result_score.text = "Jarak pelarian: %d m" % final_score
	freedom_banner.hide()
	result_panel.show()
	restart_button.grab_focus()

func show_game_over(final_score: int) -> void:
	result_title.text = "TEWAS MENGENASKAN"
	result_score.text = "Bertahan sejauh: %d m" % final_score
	freedom_banner.hide()
	result_panel.show()
	restart_button.grab_focus()

func _update_health_bar(hit_count: int) -> void:
	var remaining := clampi(MAX_STATUS_HITS - hit_count, 0, MAX_STATUS_HITS)
	var ratio := float(remaining) / float(MAX_STATUS_HITS)
	health_fill.scale.x = ratio
	health_shine.scale.x = ratio

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
