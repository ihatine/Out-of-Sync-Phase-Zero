class_name PauseMenu
extends Control

const MAIN_MENU_SCENE: String = "res://features/ui/main_menu/main_menu.tscn"
const SETTINGS_SCENE: String = "res://features/ui/settings/settings_menu.tscn"

const CYAN: Color = Color(0.48, 0.78, 0.96, 1.0)
const TEXT_PRIMARY: Color = Color(0.84, 0.92, 0.97, 1.0)
const TEXT_SECONDARY: Color = Color(0.46, 0.62, 0.70, 1.0)

var _panel: Panel
var _settings: Control
var _resume_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or _settings != null and is_instance_valid(_settings) and _settings.visible:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			resume_game()
			get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	if visible:
		resume_game()
	else:
		pause_game()

func pause_game() -> void:
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	_resume_button.grab_focus()

func resume_game() -> void:
	if _settings != null and is_instance_valid(_settings):
		_settings.queue_free()
		_settings = null
	get_tree().paused = false
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _build_ui() -> void:
	var dimmer: ColorRect = ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.006, 0.012, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	var center: CenterContainer = CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = Panel.new()
	_panel.name = "PausePanel"
	_panel.custom_minimum_size = Vector2(620.0, 560.0)
	_panel.add_theme_stylebox_override("panel", _glass_style())
	center.add_child(_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 38)
	margin.add_theme_constant_override("margin_bottom", 38)
	_panel.add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var title: Label = Label.new()
	title.text = "ПАУЗА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", TEXT_PRIMARY)
	root.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "ИГРА ПРИОСТАНОВЛЕНА // FLINT PEAK 1994"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", TEXT_SECONDARY)
	root.add_child(subtitle)

	var line: HSeparator = HSeparator.new()
	line.add_theme_constant_override("separation", 12)
	root.add_child(line)

	var spacer_top: Control = Control.new()
	spacer_top.custom_minimum_size.y = 12.0
	root.add_child(spacer_top)

	_resume_button = _create_button("ПРОДОЛЖИТЬ")
	_resume_button.pressed.connect(resume_game)
	root.add_child(_resume_button)

	var settings: Button = _create_button("НАСТРОЙКИ")
	settings.pressed.connect(_open_settings)
	root.add_child(settings)

	var main_menu: Button = _create_button("В ГЛАВНОЕ МЕНЮ")
	main_menu.pressed.connect(_return_to_main_menu)
	root.add_child(main_menu)

	var quit: Button = _create_button("ВЫЙТИ ИЗ ИГРЫ")
	quit.pressed.connect(_quit_game)
	root.add_child(quit)

	var spacer_bottom: Control = Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer_bottom)

	var hint: Label = Label.new()
	hint.text = "ESC  //  ПРОДОЛЖИТЬ"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", TEXT_SECONDARY)
	root.add_child(hint)

func _create_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 66.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", Color(0.92, 0.97, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.035, 0.075, 0.095, 0.82), Color(0.24, 0.48, 0.60, 0.62)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.07, 0.16, 0.20, 0.94), Color(0.48, 0.78, 0.96, 0.90)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.10, 0.22, 0.27, 0.96), Color(0.60, 0.86, 1.0, 1.0)))
	button.add_theme_stylebox_override("focus", _button_style(Color(0.07, 0.16, 0.20, 0.94), CYAN))
	return button

func _glass_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.008, 0.025, 0.035, 0.90)
	style.border_color = Color(0.38, 0.72, 0.90, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.02, 0.34, 0.54, 0.42)
	style.shadow_size = 28
	style.shadow_offset = Vector2(0, 10)
	return style

func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.shadow_color = Color(0.03, 0.38, 0.58, 0.26)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	return style

func _open_settings() -> void:
	if _settings != null and is_instance_valid(_settings):
		return
	var scene: PackedScene = load(SETTINGS_SCENE) as PackedScene
	if scene == null:
		return
	_settings = scene.instantiate() as Control
	if _settings == null:
		return
	add_child(_settings)
	_settings.process_mode = Node.PROCESS_MODE_ALWAYS
	if _settings.has_signal("closed"):
		_settings.closed.connect(_on_settings_closed)

func _on_settings_closed() -> void:
	if _settings != null and is_instance_valid(_settings):
		_settings.queue_free()
		_settings = null
	show()
	_resume_button.grab_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _return_to_main_menu() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()
