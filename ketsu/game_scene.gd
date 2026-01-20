extends Node2D


# Called when the node enters the scene tree for the first time.

func _ready():
	Combatmusicmanager.set_combat_music(
		preload("res://audio/music.mp3")
	)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
