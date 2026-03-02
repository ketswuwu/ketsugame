extends Node2D

@export var enemy_scene: PackedScene
@export var wave_delay: float = 0.6
@export var spawn_stagger_delay: float = 0.12

@onready var camerapoint: Marker2D = $camerapoint
@onready var playerdetector: Area2D = $playerdetector

@onready var spawn1: Marker2D = $spawn1
@onready var spawn2: Marker2D = $spawn2
@onready var spawn3: Marker2D = $spawn3

var started: bool = false
var wave_index: int = 0
var alive_in_wave: int = 0
var spawning_next_wave: bool = false


func _ready() -> void:
	playerdetector.body_entered.connect(_on_playerdetector_body_entered)


func _on_playerdetector_body_entered(body: Node) -> void:
	if started:
		return
	if not body.is_in_group("player"):
		return

	started = true
	playerdetector.monitoring = false

	# Lock camera to this room (smooth if your Camera script supports it)
	var cam := _get_camera(body)
	if cam and cam.has_method("lock_to_room"):
		cam.lock_to_room(camerapoint.global_position)

	# Start tutorial waves
	await _start_next_wave()


func _start_next_wave() -> void:
	# Wave 0 => spawn 1 enemy at spawn1
	# Wave 1 => spawn 3 enemies at spawn1, spawn2, spawn3
	if enemy_scene == null:
		push_error("enemy_scene is not set on the tutorial room!")
		return

	spawning_next_wave = false
	alive_in_wave = 0

	var points: Array[Marker2D] = []

	if wave_index == 0:
		points = [spawn1]
	elif wave_index == 1:
		points = [spawn1, spawn2, spawn3]
	else:
		# all done
		await _finish_tutorial()
		return

	# Spawn enemies (optionally staggered)
	for i in range(points.size()):
		var sp: Marker2D = points[i]

		var enemy := enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = sp.global_position

		alive_in_wave += 1

		# Listen for death
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died)
		else:
			push_warning("Enemy scene has no 'died' signal. The tutorial waves won't progress!")

		# small delay between spawns (looks cleaner)
		if i < points.size() - 1:
			await get_tree().create_timer(spawn_stagger_delay).timeout


func _on_enemy_died(_enemy) -> void:
	alive_in_wave = max(0, alive_in_wave - 1)

	if alive_in_wave == 0:
		if spawning_next_wave:
			return
		spawning_next_wave = true

		wave_index += 1
		await get_tree().create_timer(wave_delay).timeout
		await _start_next_wave()


func _finish_tutorial() -> void:
	# Unlock camera back to normal
	var player := get_tree().current_scene.find_child("Player", true, false)
	var cam := _get_camera(player)
	if cam and cam.has_method("unlock_room"):
		cam.unlock_room()


func _get_camera(from_body: Node) -> Camera2D:
	# Best case: camera is a child of the player
	if from_body and from_body.has_node("Camera2D"):
		var cam := from_body.get_node("Camera2D")
		if cam is Camera2D:
			return cam

	# Fallback: search whole current scene
	var scene := get_tree().current_scene
	if scene == null:
		return null

	var cam_node := scene.find_child("Camera2D", true, false)
	if cam_node is Camera2D:
		return cam_node

	return null
