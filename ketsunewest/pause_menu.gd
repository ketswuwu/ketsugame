extends CanvasLayer

@export var main_menu_scene: String = "res://MainMenu.tscn"

@onready var panel: Control = $Panel
@onready var settings_panel: Control = $SettingsPanel

@onready var resume_btn: Button = $Panel/VBoxContainer/ResumeButton
@onready var settings_btn: Button = $Panel/VBoxContainer/SettingsButton
@onready var exit_btn: Button = $Panel/VBoxContainer/ExitButton
@onready var back_btn: Button = $SettingsPanel/BackButton

var _is_open := false

func _ready() -> void:
	visible = false
	panel.visible = true
	settings_panel.visible = false

	resume_btn.pressed.connect(_on_resume_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	back_btn.pressed.connect(_on_back_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		if _dialogue_is_active():
			return

		# ✅ don't open pause if inventory is open
		var inv := get_tree().get_first_node_in_group("inventory_menu")
		if inv and inv.has_method("is_open") and inv.is_open():
			return

		if _is_open:
			close_menu()
		else:
			open_menu()

func is_open() -> bool:
	return _is_open
	
func open_menu() -> void:
	_is_open = true
	visible = true
	panel.visible = true
	settings_panel.visible = false

	get_tree().paused = true

	# Optional: focus the Resume button for controller/keyboard
	resume_btn.grab_focus()

func close_menu() -> void:
	_is_open = false
	visible = false
	get_tree().paused = false

func _on_resume_pressed() -> void:
	close_menu()

func _on_settings_pressed() -> void:
	panel.visible = false
	settings_panel.visible = true
	back_btn.grab_focus()

func _on_back_pressed() -> void:
	settings_panel.visible = false
	panel.visible = true
	resume_btn.grab_focus()


func _dialogue_is_active() -> bool:
	# 1) If your project uses State.player_can_move = false during dialogue,
	# this will block pause during dialogue/cutscenes too.
	if "player_can_move" in State and State.player_can_move == false:
		return true

	# 2) Extra safety: if DialogueManager provides a method/flag (depends on plugin),
	# try it without crashing.
	if Engine.has_singleton("DialogueManager"):
		var dm = Engine.get_singleton("DialogueManager")
		if dm and dm.has_method("is_dialogue_active"):
			return dm.is_dialogue_active()

	return false


func _on_exit_button_pressed() -> void:
	get_tree().paused = false
	_is_open = false
	visible = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
