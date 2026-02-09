extends Node2D


func _ready():
	Combatmusicmanager.set_combat_music(
		preload("res://audio/music.mp3")
	)

	ShopMusic.set_shop_music(
		preload("res://audio/Shoplifting.mp3")
	)


func _process(delta: float) -> void:
	pass
