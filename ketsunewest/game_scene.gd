extends Node2D

@onready var respawn_point: Marker2D = $Respawn1


func _ready():
	Respawn.set_respawn(respawn_point.global_position)
	Combatmusicmanager.set_combat_music(
		preload("res://audio/music.mp3")
	)

	ShopMusic.set_shop_music(
		preload("res://audio/Shoplifting.mp3")
	)
	MainMusic.set_main_music(
		preload("res://audio/Dead Cells - Prisoner's Awakening (Official Soundtrack).mp3")
	)
	


func _process(delta: float) -> void:
	pass
