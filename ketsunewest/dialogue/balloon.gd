extends DialogueManagerExampleBalloon
@onready var talk_sound: AudioStreamPlayer = $Talksoundfinal
@onready var talksprite: Panel = $EmotesPanel
func _emote() -> void:
	if not State.in_cutscene:
		talksprite.visible = false
	else:
		talksprite.visible = true
func _on_dialogue_label_spoke(letter: String, letter_index: int, speed: float) -> void:
	if not letter in ["."," "]:
		talk_sound.pitch_scale = randf_range(0.9, 1.1)
		talk_sound.volume_db = -12
		talk_sound.play()
