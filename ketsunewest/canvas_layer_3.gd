extends CanvasLayer

@onready var panel1: TextureRect = $TextureRect
@onready var panel2: TextureRect = $TextureRect2
@onready var panel3: TextureRect = $TextureRect3
@onready var panel4: TextureRect = $TextureRect4
@onready var panel5: TextureRect = $TextureRect5

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"
@export var end_scene_path: String = "res://scenes/endscreen.tscn"
@export var panel_fade_time: float = 0.25

var is_transitioning := false
var boss_dialogue_running := false
var _current_panel: TextureRect = null
var _panel_tween: Tween
var _panel_switching := false


func _ready() -> void:
	visible = false

	_hide_all_panels()
	_set_all_panel_alpha(0.0)

	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _process(_delta: float) -> void:
	if is_transitioning:
		return

	if ("boss" in State) and State.boss == "dead" and not boss_dialogue_running and not visible:
		open_boss_death()
		return

	if boss_dialogue_running:
		_update_end_panel()


func open_boss_death() -> void:
	is_transitioning = true

	await Fade.fade_out(0.6)

	visible = true
	await _switch_to_panel(_get_panel_for_state(), 0.35)

	await Fade.fade_in(0.6)

	boss_dialogue_running = true
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)

	is_transitioning = false


func _update_end_panel() -> void:
	var next_panel := _get_panel_for_state()

	if next_panel == _current_panel:
		return
	if _panel_switching:
		return

	_switch_to_panel(next_panel, panel_fade_time)


func _switch_to_panel(next_panel: TextureRect, fade_time: float) -> void:
	if next_panel == null:
		return

	_panel_switching = true
	_kill_panel_tween()

	# first panel shown
	if _current_panel == null:
		_current_panel = next_panel
		_current_panel.visible = true
		_current_panel.modulate.a = 0.0

		_panel_tween = create_tween()
		_panel_tween.tween_property(_current_panel, "modulate:a", 1.0, fade_time)
		await _panel_tween.finished

		_panel_switching = false
		return

	# normal crossfade
	var old_panel := _current_panel
	_current_panel = next_panel

	_current_panel.visible = true
	_current_panel.modulate.a = 0.0

	_panel_tween = create_tween()
	_panel_tween.parallel().tween_property(old_panel, "modulate:a", 0.0, fade_time)
	_panel_tween.parallel().tween_property(_current_panel, "modulate:a", 1.0, fade_time)
	await _panel_tween.finished

	if old_panel and old_panel != _current_panel:
		old_panel.visible = false

	_panel_switching = false


func _kill_panel_tween() -> void:
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()
	_panel_tween = null


func _get_panel_for_state() -> TextureRect:
	if not ("end" in State):
		return panel1

	match State.end:
		"cutscene1":
			return panel1
		"cutscene2":
			return panel2
		"cutscene3":
			return panel3
		"cutscene4":
			return panel4
		"cutscene5":
			return panel5
		_:
			return panel1


func _hide_all_panels() -> void:
	panel1.visible = false
	panel2.visible = false
	panel3.visible = false
	panel4.visible = false
	panel5.visible = false


func _set_all_panel_alpha(alpha: float) -> void:
	panel1.modulate.a = alpha
	panel2.modulate.a = alpha
	panel3.modulate.a = alpha
	panel4.modulate.a = alpha
	panel5.modulate.a = alpha


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	if not boss_dialogue_running:
		return

	if _resource != dialogue_resource:
		return

	boss_dialogue_running = false
	_go_to_endscreen()


func _go_to_endscreen() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	await Fade.fade_out(0.8)

	get_tree().change_scene_to_file(end_scene_path)

	await Fade.fade_in(0.8)

	is_transitioning = false
