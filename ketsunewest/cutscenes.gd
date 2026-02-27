extends Node2D

@export var dialogue_resource: DialogueResource
@onready var anim: AnimatedSprite2D = $CanvasLayer/AnimatedSprite2D


func _ready():

	# React every time a line is shown
	if not DialogueManager.got_dialogue.is_connected(_on_got_dialogue):
		DialogueManager.got_dialogue.connect(_on_got_dialogue)

	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
		
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")


func _on_got_dialogue(_line: DialogueLine) -> void:
	_cutscene()


func _cutscene():

	match State.intro:
		"cutscene1":
			anim.play("cutscene1")
		"cutscene2":
			anim.play("cutscene2")
		"cutscene3":
			anim.play("cutscene3")   # ← small bug fixed here
		"cutscene4":
			anim.play("cutscene4")
			

func _on_dialogue_ended(_resource):
	get_tree().change_scene_to_file("res://game_scene.tscn")
