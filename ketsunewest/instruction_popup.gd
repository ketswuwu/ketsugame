extends CanvasLayer

@onready var dimmer: ColorRect = $Dimmer
@onready var instruction_image: TextureRect = $TextureRect
@onready var open_sound: AudioStreamPlayer = $Opensound
@onready var close_sound: AudioStreamPlayer = $CloseSound
@export var dim_alpha: float = 0.55
@export var fade_time: float = 0.2

var _tween: Tween
var _is_open := false
var _is_closing := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	if dimmer:
		dimmer.color = Color(0, 0, 0, 0)
		dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if instruction_image:
		instruction_image.modulate.a = 0.0
		instruction_image.mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_instruction(texture: Texture2D) -> void:
	if instruction_image == null:
		push_warning("InstructionPopup: TextureRect not found.")
		return

	if texture == null:
		push_warning("InstructionPopup: show_instruction() got a null texture.")
		return

	instruction_image.texture = texture
	await show_popup()


func show_popup() -> void:
	if _is_open:
		return

	_is_open = true
	_is_closing = false
	visible = true
	if open_sound:
		open_sound.play(.40)
	# let the popup become visible for one frame BEFORE pausing
	await get_tree().process_frame

	get_tree().paused = true

	_kill_tween()
	_tween = create_tween()
	_tween.parallel().tween_property(dimmer, "color", Color(0, 0, 0, dim_alpha), fade_time)
	_tween.parallel().tween_property(instruction_image, "modulate:a", 1.0, fade_time)

	await _tween.finished

	# wait here until player closes it
	while _is_open:
		await get_tree().process_frame


func hide_popup() -> void:
	if not _is_open or _is_closing:
		return

	_is_closing = true
	if close_sound:
		close_sound.play(.65)
	_kill_tween()
	_tween = create_tween()
	_tween.parallel().tween_property(dimmer, "color", Color(0, 0, 0, 0), fade_time)
	_tween.parallel().tween_property(instruction_image, "modulate:a", 0.0, fade_time)

	await _tween.finished

	visible = false
	get_tree().paused = false
	_is_open = false
	_is_closing = false


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		hide_popup()
		get_viewport().set_input_as_handled()


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
