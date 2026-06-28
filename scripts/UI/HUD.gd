class_name HUD
extends CanvasLayer

signal next_level_requested

const MAX_STATUS_HITS := 3
const MAIN_MENU_SCENE := "res://scenes/UI/MainMenu.tscn"

@onready var score_label: Label = $Root/TopBar/ScoreBox/ScoreLabel
@onready var health_fill: ColorRect = $Root/TopBar/HealthBar/Fill
@onready var health_shine: ColorRect = $Root/TopBar/HealthBar/Shine
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

#func set_speed(speed_multiplier: float) -> void:
	#pass

func set_status(_status_text: String, hit_count: int, _in_smoke: bool) -> void:
	_update_health_bar(hit_count)

#func set_zone(in_water: bool) -> void:
	#pass

func show_freedom(final_score: int) -> void:
	set_score(final_score)
	var tween := create_tween()
	tween.tween_property(freedom_banner, "modulate:a", 1.0, 1.0)

func show_win_screen(final_score: int, level: int = 1, target_distance: int = 0, has_next_level: bool = false) -> void:
	result_title.text = "AIR BEBAS"
	result_score.text = "Level %d selesai: %d m" % [level, target_distance if target_distance > 0 else final_score]
	restart_button.text = "Next Level" if has_next_level else "Coba Lagi"
	freedom_banner.hide()
	result_panel.show()
	restart_button.grab_focus()

func show_game_over(final_score: int) -> void:
	result_title.text = "TEWAS MENGENASKAN"
	result_score.text = "Bertahan sejauh: %d m" % final_score
	restart_button.text = "Coba Lagi"
	freedom_banner.hide()
	result_panel.show()
	restart_button.grab_focus()

func hide_result() -> void:
	result_panel.hide()
	freedom_banner.show()
	freedom_banner.modulate.a = 0.0

func _update_health_bar(hit_count: int) -> void:
	var remaining := clampi(MAX_STATUS_HITS - hit_count, 0, MAX_STATUS_HITS)
	var ratio := float(remaining) / float(MAX_STATUS_HITS)
	health_fill.scale.x = ratio
	health_shine.scale.x = ratio

func _on_restart_pressed() -> void:
	if restart_button.text == "Next Level":
		next_level_requested.emit()
	else:
		get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
