extends Node2D
@export var room_id: StringName = &"room_02"
@onready var camerapoint: Marker2D = $camerapoint

# -----------------------------------------
# ENEMIES (mixed waves)
# -----------------------------------------
@export var enemy_scene: PackedScene  # fallback if a wave has no scenes
@export var waves: Array[WaveConfig] = []  # Wave 1, Wave 2, Wave 3...

# "cycle" = use the order in WaveConfig.scenes
# "random" = pick random scene from WaveConfig.scenes
@export var wave_pick_mode: String = "cycle"

@export var max_enemies: int = 9
@export var wave_size: int = 3
@export var wave_delay: float = 0.6
@export var spawn_stagger_delay: float = 0.18

# -----------------------------------------
@onready var gate_sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var playerdetector: Area2D = $playerdetector

@onready var gate1: StaticBody2D = $nobackwall
@onready var gate2: StaticBody2D = $nobackwall2

@onready var gate1_anim: AnimatedSprite2D = $nobackwall/AnimatedSprite2D
@onready var gate2_anim: AnimatedSprite2D = $nobackwall2/AnimatedSprite2D

@onready var spawnpoint1: Marker2D = $spawn1
@onready var spawnpoint2: Marker2D = $spawn2
@onready var spawnpoint3: Marker2D = $spawn3

var started: bool = false
var total_spawned: int = 0
var alive_in_wave: int = 0
var spawning_next_wave: bool = false
var finished: bool = false
var spawned_enemies: Array[Node] = []

# For cycling through the scenes list inside the current wave
var wave_spawn_index: int = 0


func _ready() -> void:
	_set_gate_layer(gate1, 0)
	_set_gate_layer(gate2, 0)

	playerdetector.body_entered.connect(_on_playerdetector_body_entered)

	if Respawn.is_room_completed(room_id):
		finished = true
		started = true
		playerdetector.monitoring = false

func _on_playerdetector_body_entered(body: Node) -> void:
	if finished or started:
		return
	if not body.is_in_group("player"):
		return

	started = true
	Respawn.enter_room(self, room_id)
	# Lock camera to this room
	var cam := _get_camera(body)
	if cam and cam.has_method("lock_to_room"):
		cam.lock_to_room(camerapoint.global_position)
		cam.apply_shake(10.0, 0.18)

	_close_gates()
	_spawn_wave()


func _get_camera(from_body: Node) -> Camera2D:
	if from_body and from_body.has_node("Camera2D"):
		var cam := from_body.get_node("Camera2D")
		if cam is Camera2D:
			return cam

	var scene := get_tree().current_scene
	if scene == null:
		return null

	var cam_node := scene.find_child("Camera2D", true, false)
	if cam_node is Camera2D:
		return cam_node

	return null


func _close_gates() -> void:
	_set_gate_layer(gate1, 1)
	_set_gate_layer(gate2, 1)

	if is_instance_valid(gate_sfx):
		gate_sfx.play()

	if is_instance_valid(gate1_anim):
		gate1_anim.play("gate_up")
	if is_instance_valid(gate2_anim):
		gate2_anim.play("gate_up")


func _open_gates() -> void:
	if is_instance_valid(gate_sfx):
		gate_sfx.play()

	if is_instance_valid(gate1_anim):
		gate1_anim.play("gate_down")
	if is_instance_valid(gate2_anim):
		gate2_anim.play("gate_down")

	if is_instance_valid(gate1_anim):
		await gate1_anim.animation_finished
	if is_instance_valid(gate2_anim):
		await gate2_anim.animation_finished

	_set_gate_layer(gate1, 0)
	_set_gate_layer(gate2, 0)


func _set_gate_layer(g: StaticBody2D, layer: int) -> void:
	if not is_instance_valid(g):
		return

	g.collision_layer = layer

	var shapes := g.find_children("*", "CollisionShape2D", true, false)
	for s in shapes:
		(s as CollisionShape2D).disabled = false


# -----------------------------------------
# Mixed-wave helpers
# -----------------------------------------

func _get_current_wave_index() -> int:
	if wave_size <= 0:
		return 0
	return int(total_spawned / wave_size)

func _get_wave_scenes(wave_index: int) -> Array[PackedScene]:
	if waves.size() == 0:
		return []
	var idx :int = clamp(wave_index, 0, waves.size() - 1)
	var wc := waves[idx]
	if wc == null:
		return []
	return wc.scenes

func _pick_scene_for_spawn(wave_scenes: Array[PackedScene]) -> PackedScene:
	# If wave has no scenes, fallback
	if wave_scenes.size() == 0:
		return enemy_scene

	# Remove nulls safely (in case you left empty slots)
	var usable: Array[PackedScene] = []
	for s in wave_scenes:
		if s != null:
			usable.append(s)

	if usable.size() == 0:
		return enemy_scene

	if wave_pick_mode == "random":
		return usable[randi_range(0, usable.size() - 1)]

	# default: cycle
	var picked := usable[wave_spawn_index % usable.size()]
	wave_spawn_index += 1
	return picked


func _spawn_wave() -> void:
	spawning_next_wave = false
	alive_in_wave = 0
	wave_spawn_index = 0

	var spawn_points: Array[Marker2D] = [spawnpoint1, spawnpoint2, spawnpoint3]
	var to_spawn: int = min(wave_size, max_enemies - total_spawned)

	var wave_index := _get_current_wave_index()
	var wave_scenes := _get_wave_scenes(wave_index)

	for i in range(to_spawn):
		var sp: Marker2D = spawn_points[i % spawn_points.size()]

		var scene_to_spawn := _pick_scene_for_spawn(wave_scenes)
		if scene_to_spawn == null:
			push_error("No enemy scene available for wave %d. Set enemy_scene or add scenes to the wave." % wave_index)
			return

		var enemy := scene_to_spawn.instantiate()
		add_child(enemy)
		enemy.global_position = sp.global_position
		
		spawned_enemies.append(enemy)
		enemy.add_to_group("room_enemy")

		# tiny camera shake per spawn
		var player := get_tree().current_scene.find_child("Player", true, false)
		var cam := _get_camera(player)
		if cam:
			cam.apply_shake(10.0, 0.08)

		alive_in_wave += 1
		total_spawned += 1

		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died)
		else:
			push_warning("Spawned enemy has no 'died' signal. Room won't progress on kill.")

		if i < to_spawn - 1:
			await get_tree().create_timer(spawn_stagger_delay).timeout

	if to_spawn <= 0:
		_finish_room()


func _on_enemy_died(_enemy) -> void:
	alive_in_wave = max(0, alive_in_wave - 1)

	if alive_in_wave == 0:
		if total_spawned < max_enemies:
			if spawning_next_wave:
				return
			spawning_next_wave = true
			await get_tree().create_timer(wave_delay).timeout
			_spawn_wave()
		else:
			await _finish_room()


func _finish_room() -> void:
	finished = true
	Respawn.mark_room_completed(room_id)
	playerdetector.monitoring = false

	var player := get_tree().current_scene.find_child("Player", true, false)
	var cam := _get_camera(player)
	if cam and cam.has_method("victory_pan"):
		await cam.victory_pan(Vector2(70, -25), 0.30, 0.45)

	await _open_gates()

	if cam and cam.has_method("unlock_room"):
		cam.unlock_room()
		

func reset_room() -> void:
	# ✅ unlock camera because death respawn should return camera to player
	var player := get_tree().current_scene.find_child("Player", true, false)
	var cam := _get_camera(player)
	if cam and cam.has_method("unlock_room"):
		cam.unlock_room()

	# (optional) also snap the lock point back just in case
	if cam and "room_lock_position" in cam:
		cam.room_lock_position = Vector2.ZERO

	for e in spawned_enemies:
		if is_instance_valid(e):
			e.queue_free()
	spawned_enemies.clear()

	# Reset counters
	started = false
	finished = false
	total_spawned = 0
	alive_in_wave = 0
	spawning_next_wave = false
	wave_spawn_index = 0

	# Reopen gates visually + physically
	_set_gate_layer(gate1, 0)
	_set_gate_layer(gate2, 0)

	if is_instance_valid(gate1_anim):
		gate1_anim.play("gate_down")
	if is_instance_valid(gate2_anim):
		gate2_anim.play("gate_down")

	playerdetector.monitoring = true
