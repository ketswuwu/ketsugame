extends DialogueManagerExampleBalloon

@onready var talk_sound: AudioStreamPlayer = $Talksoundfinal
@onready var talksprite: Panel = $EmotesPanel
@onready var dimmer: ColorRect = $CanvasLayer/Dimmer

@export var dim_alpha: float = 0.55
@export var dim_fade_in_time: float = 0.25
@export var dim_fade_out_time: float = 0.25

@export var emote_fade_time := 0.1

var _dim_tween: Tween
var _emote_tween: Tween


func _ready() -> void:
	# Hide main UI while in dialogue
	var ui := get_tree().get_current_scene().get_node_or_null("UI")
	if ui:
		ui.visible = false

	# start fully transparent
	if dimmer:
		dimmer.color = Color(0, 0, 0, 0)
		dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# start emotes invisible
	if talksprite:
		talksprite.modulate.a = 0.0

	_fade_dim_in()
	_fade_emotes_in()


func _process(_delta: float) -> void:
	# Fade out during cutscenes
	if State.in_cutscene:
		_fade_emotes_out()
	else:
		_fade_emotes_in()


func _on_dialogue_label_spoke(letter: String, letter_index: int, speed: float) -> void:
	if not letter in [".", " "]:
		talk_sound.pitch_scale = randf_range(0.9, 1.1)
		talk_sound.volume_db = -12
		talk_sound.play()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_fade_dim_out_instant_safe()

		if talksprite:
			talksprite.modulate.a = 0.0

		# Restore UI
		var ui := get_tree().get_current_scene().get_node_or_null("UI")
		if ui:
			ui.visible = true

func _kill_dim_tween() -> void:
	if _dim_tween and _dim_tween.is_valid():
		_dim_tween.kill()
	_dim_tween = null


func _fade_dim_in() -> void:
	if not dimmer:
		return

	_kill_dim_tween()
	_dim_tween = create_tween()
	_dim_tween.tween_property(dimmer, "color", Color(0, 0, 0, dim_alpha), dim_fade_in_time)


func _fade_dim_out() -> void:
	if not dimmer:
		return

	_kill_dim_tween()
	_dim_tween = create_tween()
	_dim_tween.tween_property(dimmer, "color", Color(0, 0, 0, 0), dim_fade_out_time)


func _fade_dim_out_instant_safe() -> void:
	if not dimmer:
		return
	_kill_dim_tween()
	dimmer.color = Color(0, 0, 0, 0)


# -------------------------
# Emotes panel fade
# -------------------------

func _kill_emote_tween() -> void:
	if _emote_tween and _emote_tween.is_valid():
		_emote_tween.kill()
	_emote_tween = null


func _fade_emotes_in() -> void:
	if not talksprite:
		return

	if talksprite.modulate.a >= 0.99:
		return

	_kill_emote_tween()
	_emote_tween = create_tween()
	_emote_tween.tween_property(talksprite, "modulate:a", 1.0, emote_fade_time)


func _fade_emotes_out() -> void:
	if not talksprite:
		return

	if talksprite.modulate.a <= 0.01:
		return

	_kill_emote_tween()
	_emote_tween = create_tween()
	_emote_tween.tween_property(talksprite, "modulate:a", 0.0, emote_fade_time)
