class_name Player
extends CharacterBody2D

signal hit_registered(hit_count: int)
signal status_changed(status_text: String, hit_count: int, in_smoke: bool)
signal zone_changed(in_water: bool)
signal splash_requested
signal flap_requested(in_water: bool)
signal healed(hit_count: int)
signal speed_boost_changed(active: bool)

@export var waterline_y := 300.0
@export var max_hits := 3
@export var swim_speed := 245.0
@export var swim_vertical_speed := 210.0
@export var air_horizontal_speed := 285.0
@export var air_control := 980.0
@export var water_acceleration := 840.0
@export var water_drag := 2.8
@export var buoyancy := 75.0
@export var gravity := 760.0
@export var flap_force := 345.0
@export var smoke_slow_factor := 0.55
@export var speed_boost_multiplier := 1.55
@export var speed_boost_duration := 3.0
@export var camera_left_margin := 44.0
@export var camera_forward_offset := 150.0
@export var vertical_margin := 42.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

var hit_count := 0
var speed_multiplier := 1.0
var controls_enabled := true
var invulnerable := false
var in_smoke := false
var freedom_mode := false
var stunned := false
var speed_boost_active := false

var _last_in_water := true
var _smoke_sources := 0
var _camera_center_x := 0.0
var _speed_boost_timer: SceneTreeTimer
var _powerup_animation_active := false
var _powerup_animation_token := 0

func _ready() -> void:
	_ensure_input_actions()
	_camera_center_x = global_position.x + camera_forward_offset
	_update_camera_anchor()
	_last_in_water = _is_in_water()
	sprite.play("idle")
	status_changed.emit(_status_text(), hit_count, in_smoke)
	zone_changed.emit(_last_in_water)

func _physics_process(delta: float) -> void:
	if stunned:
		_apply_stun_motion(delta)
		return

	if freedom_mode:
		velocity = Vector2.ZERO
		_update_camera_anchor()
		if sprite.animation != &"fly":
			sprite.play("fly")
		return

	if not controls_enabled:
		velocity = velocity.move_toward(Vector2.ZERO, 700.0 * delta)
		move_and_slide()
		_update_animation()
		return

	var in_water := _is_in_water()
	if in_water != _last_in_water:
		_last_in_water = in_water
		zone_changed.emit(in_water)
		if in_water:
			splash_requested.emit()

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.x < -0.1:
		sprite.flip_h = true
	elif input_vector.x > 0.1:
		sprite.flip_h = false

	var slow := smoke_slow_factor if in_smoke else 1.0
	var boost := speed_boost_multiplier if speed_boost_active else 1.0

	if in_water:
		_apply_water_motion(delta, input_vector, slow * boost)
	else:
		_apply_air_motion(delta, input_vector, slow * boost)

	if Input.is_action_just_pressed("flap"):
		if in_water:
			velocity.y = min(velocity.y - flap_force * 0.75, -flap_force * 0.55)
		else:
			velocity.y = -flap_force
		flap_requested.emit(in_water)

	move_and_slide()
	_update_camera_anchor()
	_clamp_to_camera_window()
	_update_camera_anchor()
	_update_animation()

func take_hit() -> bool:
	if invulnerable or hit_count >= max_hits or freedom_mode:
		return false

	hit_count += 1
	invulnerable = true
	_cancel_powerup_animation()
	if hit_count >= max_hits:
		sprite.play("stun")
	else:
		sprite.play("hurt_swim" if _is_in_water() else "hurt_fly")
	hit_registered.emit(hit_count)
	status_changed.emit(_status_text(), hit_count, in_smoke)
	get_tree().create_timer(1.0, true, false, true).timeout.connect(_clear_invulnerability)
	return true

func heal_one() -> bool:
	if stunned or freedom_mode:
		return false
	_play_powerup_animation()
	if hit_count > 0:
		hit_count -= 1
		status_changed.emit(_status_text(), hit_count, in_smoke)
		healed.emit(hit_count)
	else:
		status_changed.emit(_status_text(), hit_count, in_smoke)
	return true

func apply_speed_boost() -> void:
	_play_powerup_animation()
	speed_boost_active = true
	speed_boost_changed.emit(true)
	_speed_boost_timer = get_tree().create_timer(speed_boost_duration)
	var active_timer := _speed_boost_timer
	await active_timer.timeout
	if _speed_boost_timer != active_timer:
		return
	speed_boost_active = false
	speed_boost_changed.emit(false)

func set_speed_multiplier(value: float) -> void:
	speed_multiplier = max(value, 0.1)

func set_control_enabled(value: bool) -> void:
	controls_enabled = value

func enter_smoke() -> void:
	_smoke_sources += 1
	_set_smoke_active(_smoke_sources > 0)

func exit_smoke() -> void:
	_smoke_sources = max(_smoke_sources - 1, 0)
	_set_smoke_active(_smoke_sources > 0)

func enter_freedom_mode() -> void:
	freedom_mode = true
	stunned = false
	controls_enabled = false
	_cancel_powerup_animation()
	velocity = Vector2.ZERO
	in_smoke = false
	_smoke_sources = 0
	status_changed.emit("Freedom", hit_count, in_smoke)

func enter_stun_mode() -> void:
	stunned = true
	freedom_mode = false
	controls_enabled = false
	_cancel_powerup_animation()
	in_smoke = false
	_smoke_sources = 0
	velocity = Vector2(0.0, 260.0 if global_position.y < waterline_y else -90.0)
	sprite.play("stun")
	status_changed.emit(_status_text(), hit_count, in_smoke)

func reset_status() -> void:
	hit_count = 0
	invulnerable = false
	in_smoke = false
	_smoke_sources = 0
	freedom_mode = false
	stunned = false
	speed_boost_active = false
	_cancel_powerup_animation()
	status_changed.emit(_status_text(), hit_count, in_smoke)

func reset_for_level(newposition: Vector2) -> void:
	reset_status()
	controls_enabled = true
	velocity = Vector2.ZERO
	global_position = newposition
	_camera_center_x = global_position.x + camera_forward_offset
	_update_camera_anchor()
	sprite.play("idle")

func _play_powerup_animation() -> void:
	if stunned or freedom_mode:
		return
	_powerup_animation_token += 1
	var token := _powerup_animation_token
	_powerup_animation_active = true
	sprite.play("powerup_swim" if _is_in_water() else "powerup_fly")
	await get_tree().create_timer(1.0).timeout
	if _powerup_animation_token != token:
		return
	_powerup_animation_active = false
	if String(sprite.animation).begins_with("powerup_"):
		_update_animation()

func _cancel_powerup_animation() -> void:
	_powerup_animation_token += 1
	_powerup_animation_active = false

func _apply_water_motion(delta: float, input_vector: Vector2, slow: float) -> void:
	var target_velocity := Vector2(
		input_vector.x * swim_speed * speed_multiplier * slow,
		input_vector.y * swim_vertical_speed * slow
	)
	if input_vector.x > 0.1:
		target_velocity.x += 90.0 * speed_multiplier * slow
	velocity = velocity.move_toward(target_velocity, water_acceleration * delta)
	velocity *= max(0.0, 1.0 - water_drag * delta)

func _apply_air_motion(delta: float, input_vector: Vector2, slow: float) -> void:
	var target_x := input_vector.x * air_horizontal_speed * speed_multiplier * slow
	if input_vector.x > 0.1:
		target_x += 115.0 * speed_multiplier * slow
	velocity.x = move_toward(velocity.x, target_x, air_control * delta)
	velocity.y += gravity * delta
	if input_vector.y < -0.1:
		velocity.y -= 170.0 * delta * slow
	elif input_vector.y > 0.1:
		velocity.y += 130.0 * delta

func _clamp_to_camera_window() -> void:
	var viewport_width := get_viewport_rect().size.x
	var viewport_height := get_viewport_rect().size.y
	var camera_left := _camera_center_x - viewport_width * 0.5 + camera_left_margin
	var top_edge := waterline_y - viewport_height * 0.5 + vertical_margin
	var bottom_edge := waterline_y + viewport_height * 0.5 - vertical_margin

	if global_position.x < camera_left:
		global_position.x = camera_left
		velocity.x = max(velocity.x, 0.0)
	if global_position.y < top_edge:
		global_position.y = top_edge
		velocity.y = max(velocity.y, 0.0)
	elif global_position.y > bottom_edge:
		global_position.y = bottom_edge
		velocity.y = min(velocity.y, 0.0)

func _update_camera_anchor() -> void:
	_camera_center_x = max(_camera_center_x, global_position.x + camera_forward_offset)
	camera.global_position = Vector2(_camera_center_x, waterline_y)

func _apply_stun_motion(delta: float) -> void:
	var surface_y := waterline_y + 8.0
	velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta)
	if global_position.y < surface_y:
		velocity.y = min(velocity.y + gravity * delta, 420.0)
	elif global_position.y > surface_y:
		velocity.y = max(velocity.y - water_acceleration * delta, -120.0)
	else:
		velocity.y = 0.0

	move_and_slide()
	if (velocity.y > 0.0 and global_position.y >= surface_y) or (velocity.y < 0.0 and global_position.y <= surface_y):
		global_position.y = surface_y
		velocity.y = 0.0
	_update_camera_anchor()
	if sprite.animation != &"stun":
		sprite.play("stun")

func _update_animation() -> void:
	if stunned:
		if sprite.animation != &"stun":
			sprite.play("stun")
		return
	if _powerup_animation_active and String(sprite.animation).begins_with("powerup_"):
		return
	if String(sprite.animation).begins_with("hurt_") and sprite.is_playing():
		return
	if _is_in_water():
		if abs(velocity.x) + abs(velocity.y) > 35.0:
			sprite.play("swim")
		else:
			sprite.play("idle")
	else:
		sprite.play("fly")

func _set_smoke_active(value: bool) -> void:
	if in_smoke == value:
		return
	in_smoke = value
	status_changed.emit(_status_text(), hit_count, in_smoke)

func _clear_invulnerability() -> void:
	invulnerable = false

func _is_in_water() -> bool:
	return global_position.y > waterline_y

func _status_text() -> String:
	if freedom_mode:
		return "Freedom"
	if in_smoke:
		return "Polluted"
	match hit_count:
		0:
			return "Stable"
		1:
			return "Warning"
		2:
			return "Critical"
		_:
			return "Lost"

func _ensure_input_actions() -> void:
	_bind_key("move_up", KEY_W)
	_bind_key("move_down", KEY_S)
	_bind_key("move_left", KEY_A)
	_bind_key("move_right", KEY_D)
	_bind_key("flap", KEY_SPACE)

func _bind_key(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.keycode == keycode:
			return

	var key := InputEventKey.new()
	key.keycode = keycode
	InputMap.action_add_event(action_name, key)
