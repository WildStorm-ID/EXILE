class_name HurtEffect
extends CanvasLayer

@export var hit_alpha := 0.35
@export var smoke_alpha := 0.18
@export var slow_time_scale := 0.6
@export var fade_seconds := 2.0

@onready var damage_overlay: ColorRect = $DamageOverlay
@onready var vignette_rect: ColorRect = $Vignette
@onready var brightness_overlay: ColorRect = $BrightnessOverlay

var _hit_token := 0
var _smoke_active := false
var _overlay_tween: Tween
var _brightness_tween: Tween

func _ready() -> void:
	damage_overlay.modulate.a = 0.0
	brightness_overlay.modulate.a = 0.0
	vignette_rect.modulate.a = 1.0

func play_hit_effect() -> void:
	_hit_token += 1
	var token := _hit_token
	Engine.time_scale = slow_time_scale
	_tween_damage_alpha(hit_alpha, 0.12)

	await get_tree().create_timer(fade_seconds, true, false, true).timeout
	if token != _hit_token:
		return

	Engine.time_scale = 1.0
	_tween_damage_alpha(smoke_alpha if _smoke_active else 0.0, 0.35)

func set_smoke_active(value: bool) -> void:
	_smoke_active = value
	if _hit_token > 0 and damage_overlay.modulate.a >= hit_alpha * 0.9:
		return
	_tween_damage_alpha(smoke_alpha if _smoke_active else 0.0, 0.25)

func play_brighten() -> void:
	if _brightness_tween:
		_brightness_tween.kill()
	_brightness_tween = create_tween()
	_brightness_tween.tween_property(brightness_overlay, "modulate:a", 0.58, 2.4)

func fade_to_clear() -> void:
	Engine.time_scale = 1.0
	_smoke_active = false
	_hit_token += 1
	_tween_damage_alpha(0.0, 0.3)

func _tween_damage_alpha(target_alpha: float, duration: float) -> void:
	if _overlay_tween:
		_overlay_tween.kill()
	_overlay_tween = create_tween()
	_overlay_tween.tween_property(damage_overlay, "modulate:a", target_alpha, duration)
