extends Node2D

@onready var trigger: Area2D = $trigger
@onready var camera_point: Marker2D = $camerapoint

var triggered := false

func _ready() -> void:
	trigger.body_entered.connect(_on_trigger_body_entered)

func _on_trigger_body_entered(body: Node) -> void:
	if triggered:
		return
	if not body.is_in_group("player"):
		return

	triggered = true
	trigger.monitoring = false

	var cam := _get_camera(body)
	if cam and cam.has_method("lock_to_room"):
		cam.lock_to_room(camera_point.global_position)

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
