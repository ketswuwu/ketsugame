extends Node2D

@export var room_id: StringName = &"boss_room"

@export var boss_name: String = "Boss"
@export var boss_path: NodePath

@export var respawn_marker_name: StringName = &"Respawn2" # in MAIN GAME scene

# Gate settings (edit if your layers differ)
@export var gate_closed_layer: int = 1
@export var gate_open_layer: int = 0

@onready var trigger: Area2D = $trigger
@onready var camera_point: Marker2D = $camerapoint

# ✅ Direct gate reference (your node is named "gagte")
@onready var gate: StaticBody2D = $gagte
@onready var gate_shape: CollisionShape2D = $gagte/CollisionShape2D

var started := false

func _ready() -> void:
	trigger.body_entered.connect(_on_trigger_body_entered)

	# ✅ Safety: when the room scene loads, keep gate OPEN by default
	_open_gate()


func _on_trigger_body_entered(body: Node) -> void:
	if started:
		return
	if not body.is_in_group("player"):
		return

	Respawn.in_boss_room = true

	started = true
	trigger.monitoring = false

	Respawn.enter_room(self, room_id)

	# ✅ Update respawn to Respawn2 in MAIN GAME scene
	var rp := get_tree().current_scene.find_child(String(respawn_marker_name), true, false)
	if rp and rp is Node2D:
		Respawn.set_respawn((rp as Node2D).global_position)
	else:
		push_warning("BossRoom: couldn't find respawn marker '%s' in main scene." % respawn_marker_name)

	# ✅ Lock camera
	var cam := _get_camera(body)
	if cam and cam.has_method("lock_to_room"):
		cam.lock_to_room(camera_point.global_position)

	# ✅ Close gate behind player (DIRECT)
	_close_gate()

	# ✅ Show boss UI
	_show_boss_ui()


# -----------------------
# Gate control (DIRECT)
# -----------------------
func _close_gate() -> void:
	if not is_instance_valid(gate):
		push_warning("BossRoom: gate node 'gagte' not found.")
		return

	gate.collision_layer = gate_closed_layer



func _open_gate() -> void:
	if not is_instance_valid(gate):
		return

	gate.collision_layer = gate_open_layer



# -----------------------
# Boss UI
# -----------------------
func _show_boss_ui() -> void:
	var boss_ui := get_tree().get_first_node_in_group("boss_ui")
	if boss_ui == null:
		push_warning("BossRoom: no node in group 'boss_ui' found.")
		return

	var boss := get_node_or_null(boss_path)
	if boss == null:
		boss = get_tree().get_first_node_in_group("boss")

	if boss == null:
		push_warning("BossRoom: boss not found (set boss_path or put boss in group 'boss').")
		return

	if boss_ui.has_method("show_for_boss"):
		boss_ui.show_for_boss(boss, boss_name)
	elif boss_ui is CanvasItem:
		(boss_ui as CanvasItem).visible = true


func _hide_boss_ui() -> void:
	var boss_ui := get_tree().get_first_node_in_group("boss_ui")
	if boss_ui == null:
		return

	if boss_ui.has_method("hide_boss"):
		boss_ui.hide_boss()
	elif boss_ui is CanvasItem:
		(boss_ui as CanvasItem).visible = false


# -----------------------
# Respawn hook
# -----------------------
func reset_room() -> void:
	# Called by Respawn when player dies in this room

	Respawn.in_boss_room = false

	# ✅ Open gate so player can re-enter
	_open_gate()

	# ✅ Hide UI on death
	_hide_boss_ui()

	# ✅ Allow the trigger to fire again on re-entry
	started = false
	trigger.monitoring = true

	# ✅ Boss reset (Respawn also calls reset_on_respawn via group "respawn_reset",
	# but keeping this is fine as redundancy)
	var boss := get_node_or_null(boss_path)
	if boss == null:
		boss = get_tree().get_first_node_in_group("boss")

	if boss and boss.has_method("reset_on_respawn"):
		boss.reset_on_respawn()


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
