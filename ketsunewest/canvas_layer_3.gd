extends CanvasLayer

@onready var panel := $TextureRect
@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"
var is_transitioning := false

func _ready():
	panel.modulate.a = 0.0

func _process(_delta):
	if is_transitioning:
		return

	if State.boss == "dead" and not visible:
		open_boss_death()
	elif State.boss != "dead" and visible:
		close_boss_death()


func open_boss_death() -> void:
	is_transitioning = true

	# 1. Fade world to black
	await Fade.fade_out(0.4)

	# 2. Show boss-death panel but invisible
	visible = true
	panel.modulate.a = 0.0

	# 3. Fade panel in
	var t := create_tween()
	t.tween_property(panel, "modulate:a", 1.0, 0.25)
	await t.finished

	# 4. Fade world back in
	await Fade.fade_in(0.4)

	# 5. Show DialogueManager for boss death dialogue
	# Make sure you have a DialogueResource for the boss death lines
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)

	is_transitioning = false

func close_boss_death() -> void:
	is_transitioning = true

	# 1. Fade world to black
	await Fade.fade_out(0.4)

	# 2. Fade shop out while black
	var t := create_tween()
	t.tween_property(panel, "modulate:a", 0.0, 0.2)
	await t.finished

	visible = false

	# 3. Fade world back in
	await Fade.fade_in(0.4)

	is_transitioning = false
	
