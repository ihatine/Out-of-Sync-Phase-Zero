extends Control
class_name GlobalChat

const MAX_MESSAGES := 80
const MAX_LENGTH := 120

var _messages: Array[String] = []
var _panel: PanelContainer
var _log: RichTextLabel
var _input: LineEdit
var _hint: Label
var _open := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("global_chat")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	visible = multiplayer.has_multiplayer_peer()

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "ChatPanel"
	_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_panel.position = Vector2(-548.0, 28.0)
	_panel.size = Vector2(520.0, 250.0)
	_panel.visible = true
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)

	var title := Label.new()
	title.text = "ОБЩИЙ ЧАТ"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.74, 0.90, 0.98, 0.95))
	column.add_child(title)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.fit_content = false
	_log.scroll_active = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.custom_minimum_size.y = 150
	_log.add_theme_font_size_override("normal_font_size", 13)
	column.add_child(_log)

	_input = LineEdit.new()
	_input.placeholder_text = "Напишите сообщение..."
	_input.max_length = MAX_LENGTH
	_input.visible = false
	_input.focus_mode = Control.FOCUS_ALL
	_input.text_submitted.connect(_on_text_submitted)
	column.add_child(_input)

	_hint = Label.new()
	_hint.text = "T / ENTER — написать    ESC — закрыть ввод"
	_hint.add_theme_font_size_override("font_size", 10)
	_hint.add_theme_color_override("font_color", Color(0.45, 0.60, 0.67, 0.80))
	column.add_child(_hint)

func is_chat_open() -> bool:
	return _open

func _unhandled_input(event: InputEvent) -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return
		if key.keycode == KEY_ESCAPE and _open:
			_close_chat()
			get_viewport().set_input_as_handled()
			return
		if (key.keycode == KEY_ENTER or key.keycode == KEY_T) and not _open:
			_open_chat()
			get_viewport().set_input_as_handled()

func _open_chat() -> void:
	_open = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_panel.visible = true
	_input.visible = true
	_input.grab_focus()
	_hint.text = "ENTER — отправить    ESC — закрыть"
	get_viewport().set_input_as_handled()

func _close_chat() -> void:
	_open = false
	_input.clear()
	_input.visible = false
	_panel.visible = true
	_hint.text = "T / ENTER — написать    ESC — закрыть ввод"
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_text_submitted(text: String) -> void:
	var clean := text.strip_edges()
	if clean.is_empty():
		_close_chat()
		return
	clean = clean.replace("[", "(").replace("]", ")")
	if multiplayer.is_server():
		_broadcast_chat(multiplayer.get_unique_id(), clean)
	else:
		rpc_id(1, "_server_broadcast_chat", clean)
	_input.clear()
	_close_chat()

@rpc("any_peer", "reliable", "call_remote", 0)
func _server_broadcast_chat(text: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id <= 0:
		sender_id = multiplayer.get_unique_id()
	_broadcast_chat(sender_id, text)

func _broadcast_chat(sender_id: int, text: String) -> void:
	var clean := text.strip_edges()
	if clean.is_empty():
		return
	clean = clean.left(MAX_LENGTH).replace("[", "(").replace("]", ")")
	rpc("_client_receive_chat", sender_id, clean)

@rpc("authority", "reliable", "call_local", 0)
func _client_receive_chat(sender_id: int, text: String) -> void:
	var label := "ХОСТ" if sender_id == 1 else "ИГРОК %d" % sender_id
	_messages.append("[color=#9bd7f1][%s][/color] %s" % [label, text])
	if _messages.size() > MAX_MESSAGES:
		_messages.pop_front()
	if _log != null:
		_log.text = "\n".join(_messages)
		_log.scroll_to_line(_messages.size())

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.006, 0.018, 0.025, 0.94)
	style.border_color = Color(0.32, 0.64, 0.80, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style
