extends Camera2D

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_decay: float = 10.0

@export var look_ahead_distance := 90.0
@export var look_ahead_speed := 6.0
@export var follow_speed := 1.0
@export var target: Node2D

# --- ROOM LOCK / CINEMATIC ---
var is_room_locked := false
var room_lock_position := Vector2.ZERO

var default_zoom := Vector2.ONE
var lock_zoom := Vector2(0.86, 0.86)  # cinematic zoom in (smaller = more zoom)
var lock_smooth := 0.12               # smaller = snappier, bigger = smoother
var zoom_in_time := 0.45
var zoom_out_time := 0.55

var _cam_tween: Tween


# --- SCREEN SHAKE ---
func apply_shake(intensity: float = 20.0, duration: float = 0.2):
	shake_intensity = max(shake_intensity, intensity)
	shake_duration = max(shake_duration, duration)


func lock_to_room(pos: Vector2) -> void:
	is_room_locked = true
	room_lock_position = pos

	_kill_cam_tween()
	_cam_tween = create_tween()
	_cam_tween.tween_property(self, "zoom", lock_zoom, zoom_in_time)


func unlock_room() -> void:
	is_room_locked = false

	_kill_cam_tween()
	_cam_tween = create_tween()
	_cam_tween.tween_property(self, "zoom", default_zoom, zoom_out_time)


# A small cinematic pan (used when last enemy dies)
func victory_pan(pan_offset := Vector2(60, -20), pan_time := 0.35, return_time := 0.45) -> void:
	if not is_room_locked:
		return

	_kill_cam_tween()
	_cam_tween = create_tween()

	var a := room_lock_position + pan_offset
	var b := room_lock_position

	# We pan by temporarily changing the lock position
	_cam_tween.tween_method(func(v): room_lock_position = v, room_lock_position, a, pan_time)
	_cam_tween.tween_method(func(v): room_lock_position = v, room_lock_position, b, return_time)
	await _cam_tween.finished


func _kill_cam_tween() -> void:
	if _cam_tween and _cam_tween.is_valid():
		_cam_tween.kill()
	_cam_tween = null


func _process(delta):
	var player := get_parent()
	if player == null:
		return

	# --- FOLLOW TARGET OR ROOM LOCK ---
	if is_room_locked:
		# smooth follow to the room lock point
		global_position = global_position.lerp(room_lock_position, 1.0 - pow(lock_smooth, delta * 60.0))
	else:
		if target:
			global_position = global_position.lerp(
				target.global_position,
				delta * follow_speed
			)

	# --- LOOK AHEAD (disable while locked so it stays centered) ---
	if not is_room_locked:
		var dir: Vector2 = player.last_move_dir.normalized()
		if dir.length() < 0.1:
			dir = Vector2.ZERO

		var target_offset = dir * look_ahead_distance
		position = position.lerp(target_offset, delta * look_ahead_speed)
	else:
		# ease offset back to center
		position = position.lerp(Vector2.ZERO, delta * 10.0)

	# --- SCREEN SHAKE ---
	var shake_offset := Vector2.ZERO
	if shake_duration > 0.0:
		shake_duration -= delta

		shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)

		shake_intensity = lerp(
			shake_intensity,
			0.0,
			delta * shake_decay
		)

	position += shake_offset
