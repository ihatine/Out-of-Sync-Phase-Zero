class_name InteractionPrompt
extends CanvasLayer

var _panel: PanelContainer
var _label: Label

func _ready() -> void:
	layer = 40
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.position = Vector2(-190.0, -92.0)
	_panel.size = Vector2(380.0, 62.0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(_panel)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	_panel.add_child(row)

	var key := Label.new()
	key.text = "E"
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key.custom_minimum_size = Vector2(32.0, 32.0)
	key.add_theme_font_size_override("font_size", 18)
	key.add_theme_color_override("font_color", Color(0.58, 0.84, 1.0, 1.0))
	key.add_theme_stylebox_override("normal", _key_style())
	row.add_child(key)

	_label = Label.new()
	_label.text = "Взаимодействовать"
	_label.add_theme_font_size_override("font_size", 17)
	_label.add_theme_color_override("font_color", Color(0.82, 0.91, 0.97, 1.0))
	row.add_child(_label)
	hide_prompt()

func show_prompt(text: String) -> void:
	_label.text = text
	_panel.visible = true

func hide_prompt() -> void:
	if _panel != null:
		_panel.visible = false

func _panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.025, 0.07, 0.095, 0.82)
	s.border_color = Color(0.35, 0.72, 0.95, 0.58)
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	s.shadow_color = Color(0.08, 0.48, 0.75, 0.25)
	s.shadow_size = 12
	s.content_margin_left = 16.0
	s.content_margin_right = 16.0
	return s

func _key_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.12, 0.16, 0.95)
	s.border_color = Color(0.42, 0.8, 1.0, 0.7)
	s.set_border_width_all(1)
	s.set_corner_radius_all(5)
	return s
