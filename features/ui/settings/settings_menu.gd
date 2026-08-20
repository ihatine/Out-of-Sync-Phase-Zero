class_name SettingsMenu
extends Control

signal closed

const GLASS_SHADER_PATH: String = "res://shaders/ui/glass_panel.gdshader"
const CYAN: Color = Color(0.48, 0.78, 0.96, 1.0)
const TEXT_PRIMARY: Color = Color(0.82, 0.91, 0.96, 1.0)
const TEXT_SECONDARY: Color = Color(0.46, 0.61, 0.68, 1.0)

var data: GameSettingsData = GameSettingsData.new()
var tabs: TabContainer
var _pages: Dictionary = {}
var _page_stack: VBoxContainer
var _sidebar: VBoxContainer
var _remap_buttons: Dictionary = {}
var _quality_selectors: Array[OptionButton] = []
var _quality_profile: OptionButton
var _sensitivity_value: Label
var _master_value: Label
var _sfx_value: Label
var _ui_value: Label
var _master_slider: HSlider
var _sfx_slider: HSlider
var _ui_slider: HSlider
var _hud_color_button: ColorPickerButton
var _hud_toggle: CheckButton
var _minimap_toggle: CheckButton
var _ammo_toggle: CheckButton
var _vsync_toggle: CheckButton
var close_button: Button
var remap_action: String = ""
var remap_button: Button = null
var _panel: Panel
var _resolution_option: OptionButton
var _fullscreen_toggle: CheckButton
var _brightness_slider: HSlider
var _gamma_slider: HSlider
var _sensitivity_slider: HSlider
var _motion_blur_toggle: CheckButton
var _current_page: String = "ГРАФИКА"

func _ready() -> void:
	data = GameSettingsData.load_saved()
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("settings_runtime")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_load_values()
	_sync_controls_from_data()
	_apply_layout()

func _unhandled_input(event: InputEvent) -> void:
	if remap_action.is_empty():
		return
	if not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var keycode: Key = key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
	if keycode == KEY_ESCAPE:
		_cancel_remap()
		get_viewport().set_input_as_handled()
		return

	_apply_key_binding(remap_action, keycode)
	get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var dimmer: ColorRect = ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.006, 0.010, 0.78)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	_panel = Panel.new()
	_panel.name = "SettingsPanel"
	add_child(_panel)
	_add_glass_surface(_panel)

	var content: MarginContainer = MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left", 28)
	content.add_theme_constant_override("margin_right", 28)
	content.add_theme_constant_override("margin_top", 22)
	content.add_theme_constant_override("margin_bottom", 22)
	_panel.add_child(content)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	content.add_child(root)

	var header: HBoxContainer = HBoxContainer.new()
	root.add_child(header)

	var title: Label = Label.new()
	title.text = "НАСТРОЙКИ"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", TEXT_PRIMARY)
	header.add_child(title)

	close_button = _create_glass_button("×", 44)
	close_button.custom_minimum_size.x = 44.0
	close_button.pressed.connect(_on_back_pressed)
	header.add_child(close_button)

	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	root.add_child(body)

	var side_panel: PanelContainer = PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(235.0, 0.0)
	side_panel.add_theme_stylebox_override("panel", _section_style(Color(0.015, 0.035, 0.045, 0.66), Color(0.24, 0.52, 0.65, 0.38), 12))
	body.add_child(side_panel)

	_sidebar = VBoxContainer.new()
	_sidebar.add_theme_constant_override("separation", 8)
	_sidebar.add_theme_constant_override("margin_left", 10)
	_sidebar.add_theme_constant_override("margin_right", 10)
	side_panel.add_child(_margin_wrap(_sidebar, 10, 10, 12, 10))

	var center_panel: PanelContainer = PanelContainer.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.add_theme_stylebox_override("panel", _section_style(Color(0.008, 0.020, 0.027, 0.74), Color(0.25, 0.54, 0.68, 0.32), 12))
	body.add_child(center_panel)

	_page_stack = VBoxContainer.new()
	_page_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_panel.add_child(_margin_wrap(_page_stack, 22, 22, 18, 18))

	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(345.0, 0.0)
	right_panel.add_theme_stylebox_override("panel", _section_style(Color(0.012, 0.028, 0.036, 0.68), Color(0.24, 0.52, 0.65, 0.34), 12))
	body.add_child(right_panel)
	right_panel.add_child(_build_quality_preview())

	_build_graphics_tab()
	_build_interface_tab()
	_build_controls_tab()
	_build_audio_tab()
	_select_page("ГРАФИКА")
	_refresh_remap_buttons()

	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)

	var defaults: Button = _create_glass_button("ПО УМОЛЧАНИЮ", 46)
	defaults.custom_minimum_size.x = 190.0
	defaults.pressed.connect(_on_defaults_pressed)
	footer.add_child(defaults)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var apply: Button = _create_glass_button("ПРИМЕНИТЬ", 46)
	apply.custom_minimum_size.x = 190.0
	apply.pressed.connect(_on_apply_pressed)
	footer.add_child(apply)

	var back: Button = _create_glass_button("НАЗАД", 46)
	back.custom_minimum_size.x = 150.0
	back.pressed.connect(_on_back_pressed)
	footer.add_child(back)

func _margin_wrap(child: Control, left: float, right: float, top: float, bottom: float) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	margin.add_child(child)
	return margin

func _section_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _build_quality_preview() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)

	var heading := Label.new()
	heading.text = "КАЧЕСТВО"
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", TEXT_PRIMARY)
	column.add_child(heading)

	for label_text in ["ТЕНИ", "ТЕКСТУРЫ", "ЭФФЕКТЫ", "ПОСТОБРАБОТКА", "ДИСТАНЦИЯ ПРОРИСОВКИ", "АНИЗОТРОПНАЯ ФИЛЬТРАЦИЯ"]:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 38.0
		var label := Label.new()
		label.text = label_text
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", TEXT_SECONDARY)
		row.add_child(label)
		var selector := OptionButton.new()
		selector.add_item("Низкое")
		selector.add_item("Среднее")
		selector.add_item("Высокое")
		selector.select(data.quality_profile)
		selector.custom_minimum_size = Vector2(128.0, 34.0)
		selector.disabled = true
		_quality_selectors.append(selector)
		row.add_child(selector)
		column.add_child(row)

	var preview := Panel.new()
	preview.custom_minimum_size.y = 210.0
	preview.add_theme_stylebox_override("panel", _section_style(Color(0.006, 0.015, 0.020, 0.94), Color(0.32, 0.63, 0.78, 0.38), 8))
	column.add_child(preview)

	var preview_title := Label.new()
	preview_title.text = "ПРЕДПРОСМОТР\n\n▰  ▰  ▰  ▰  ▰\n\n   ТЕСТОВАЯ СЦЕНА\n\n   качество изображения"
	preview_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_title.add_theme_font_size_override("font_size", 13)
	preview_title.add_theme_color_override("font_color", Color(0.56, 0.73, 0.80, 0.78))
	preview.add_child(preview_title)

	return _margin_wrap(column, 18, 18, 18, 18)

func _select_page(title: String) -> void:
	_current_page = title
	for key in _pages.keys():
		var page: Control = _pages[key]
		page.visible = key == title
	for key in _pages.keys():
		var button: Button = _pages[key].get_meta("sidebar_button") if _pages[key].has_meta("sidebar_button") else null
		if button != null:
			button.add_theme_stylebox_override("normal", _sidebar_button_style(key == title))

func _build_graphics_tab() -> void:
	var page: VBoxContainer = _create_tab("ГРАФИКА")

	var resolution := OptionButton.new()
	_resolution_option = resolution
	resolution.add_item("1280 × 720 (16:9)")
	resolution.add_item("1600 × 900 (16:9)")
	resolution.add_item("1920 × 1080 (16:9)")
	resolution.add_item("2560 × 1440 (16:9)")
	resolution.item_selected.connect(_on_resolution_selected)
	_add_labeled_control(page, "РАЗРЕШЕНИЕ", resolution)

	var fullscreen := CheckButton.new()
	_fullscreen_toggle = fullscreen
	fullscreen.text = "Полноэкранный режим"
	fullscreen.toggled.connect(_on_fullscreen_toggled)
	_add_labeled_control(page, "РЕЖИМ ДИСПЛЕЯ", fullscreen)

	var quality := OptionButton.new()
	quality.add_item("Низкое")
	quality.add_item("Среднее")
	quality.add_item("Высокое")
	quality.select(data.quality_profile)
	quality.item_selected.connect(_on_quality_selected)
	_quality_profile = quality
	_add_labeled_control(page, "ПРОФИЛЬ ГРАФИКИ", quality)

	var brightness := _create_slider(0.50, 1.50, 0.01)
	_brightness_slider = brightness
	brightness.value_changed.connect(_on_brightness_changed)
	_add_labeled_control(page, "ЯРКОСТЬ", brightness)

	var vsync := CheckButton.new()
	vsync.text = "Включить VSync"
	vsync.button_pressed = data.vsync_enabled
	_vsync_toggle = vsync
	vsync.toggled.connect(_on_vsync_toggled)
	_add_labeled_control(page, "VSYNC", vsync)

	var gamma := _create_slider(0.50, 2.00, 0.01)
	_gamma_slider = gamma
	gamma.value_changed.connect(_on_gamma_changed)
	_add_labeled_control(page, "ГАММА", gamma)

	var motion_blur := CheckButton.new()
	_motion_blur_toggle = motion_blur
	motion_blur.text = "Вкл."
	motion_blur.button_pressed = data.motion_blur_enabled
	motion_blur.toggled.connect(func(enabled: bool): data.motion_blur_enabled = enabled)
	_add_labeled_control(page, "РАЗМЫТИЕ В ДВИЖЕНИИ", motion_blur)


func _build_interface_tab() -> void:
	var page := _create_tab("ИНТЕРФЕЙС")
	var hud_color := ColorPickerButton.new()
	hud_color.color = data.hud_color
	hud_color.custom_minimum_size = Vector2(170.0, 38.0)
	_hud_color_button = hud_color
	hud_color.color_changed.connect(_on_hud_color_changed)
	_add_labeled_control(page, "ЦВЕТ HUD", hud_color)

	var hud := CheckButton.new()
	hud.text = "Показывать HUD"
	hud.button_pressed = data.hud_enabled
	_hud_toggle = hud
	hud.toggled.connect(_on_hud_toggled)
	_add_labeled_control(page, "ОБЩИЙ HUD", hud)

	var minimap := CheckButton.new()
	minimap.text = "Мини-карта"
	minimap.button_pressed = data.minimap_enabled
	_minimap_toggle = minimap
	minimap.toggled.connect(_on_minimap_toggled)
	_add_labeled_control(page, "МИНИ-КАРТА", minimap)

	var ammo := CheckButton.new()
	ammo.text = "Счётчик патронов"
	ammo.button_pressed = data.ammo_counter_enabled
	_ammo_toggle = ammo
	ammo.toggled.connect(_on_ammo_toggled)
	_add_labeled_control(page, "ИНФОРМАЦИЯ", ammo)

func _build_controls_tab() -> void:
	var page := _create_tab("УПРАВЛЕНИЕ")
	var sensitivity := _create_slider(0.10, 5.00, 0.05)
	_sensitivity_slider = sensitivity
	sensitivity.value = data.mouse_sensitivity
	sensitivity.value_changed.connect(_on_sensitivity_changed)
	var sensitivity_row := _value_row(sensitivity, _format_percent(data.mouse_sensitivity / 5.0))
	_sensitivity_value = sensitivity_row.get_node("Value") as Label
	_add_labeled_control(page, "ЧУВСТВИТЕЛЬНОСТЬ МЫШИ", sensitivity_row)

	var heading := Label.new()
	heading.text = "ПЕРЕНАЗНАЧЕНИЕ КЛАВИШ"
	heading.add_theme_font_size_override("font_size", 14)
	heading.add_theme_color_override("font_color", TEXT_PRIMARY)
	page.add_child(heading)

	var actions := [
		["move_forward", "ДВИЖЕНИЕ ВПЕРЁД"], ["move_backward", "ДВИЖЕНИЕ НАЗАД"],
		["move_left", "ДВИЖЕНИЕ ВЛЕВО"], ["move_right", "ДВИЖЕНИЕ ВПРАВО"],
		["sprint", "БЕГ"], ["crouch", "ПРИСЕСТЬ"], ["jump", "ПРЫЖОК"],
		["interact", "ВЗАИМОДЕЙСТВИЕ"], ["flashlight", "ФОНАРЬ"], ["holster_item", "УБРАТЬ ПРЕДМЕТ"], ["drop_item", "ВЫБРОСИТЬ ПРЕДМЕТ"]
	]
	for item in actions:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 43.0
		var label := Label.new()
		label.text = item[1]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", TEXT_SECONDARY)
		row.add_child(label)
		var bind_button := _create_glass_button(_key_name(item[0]), 38)
		bind_button.custom_minimum_size.x = 135.0
		bind_button.pressed.connect(_begin_remap.bind(item[0], bind_button))
		_remap_buttons[item[0]] = bind_button
		row.add_child(bind_button)
		page.add_child(row)

func _build_audio_tab() -> void:
	var page := _create_tab("ЗВУК")
	var master := _create_slider(0.0, 1.0, 0.01)
	_master_slider = master
	master.value = data.master_volume
	master.value_changed.connect(_on_master_volume_changed)
	var master_row := _value_row(master, _format_percent(data.master_volume))
	_master_value = master_row.get_node("Value") as Label
	_add_labeled_control(page, "ОБЩАЯ ГРОМКОСТЬ", master_row)
	var sfx := _create_slider(0.0, 1.0, 0.01)
	_sfx_slider = sfx
	sfx.value = data.sfx_volume
	sfx.value_changed.connect(_on_sfx_volume_changed)
	var sfx_row := _value_row(sfx, _format_percent(data.sfx_volume))
	_sfx_value = sfx_row.get_node("Value") as Label
	_add_labeled_control(page, "ЗВУКИ ИГРЫ", sfx_row)
	var ui := _create_slider(0.0, 1.0, 0.01)
	_ui_slider = ui
	ui.value = data.ui_volume
	ui.value_changed.connect(_on_ui_volume_changed)
	var ui_row := _value_row(ui, _format_percent(data.ui_volume))
	_ui_value = ui_row.get_node("Value") as Label
	_add_labeled_control(page, "ИНТЕРФЕЙС", ui_row)

func _create_tab(title: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = title
	page.add_theme_constant_override("separation", 10)
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.visible = _pages.is_empty()
	_page_stack.add_child(page)
	_pages[title] = page

	var button := _create_sidebar_button(title)
	button.pressed.connect(_select_page.bind(title))
	page.set_meta("sidebar_button", button)
	_sidebar.add_child(button)
	return page

func _create_sidebar_button(title: String) -> Button:
	var icons := {
		"ГРАФИКА": "graphics.svg",
		"ИНТЕРФЕЙС": "interface.svg",
		"УПРАВЛЕНИЕ": "controls.svg",
		"ЗВУК": "sound.svg"
	}
	var button := Button.new()
	button.text = title
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.expand_icon = true
	button.custom_minimum_size = Vector2(0.0, 64.0)
	button.add_theme_constant_override("h_separation", 14)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var icon_path := "res://features/ui/main_menu/assets/icons/%s" % str(icons.get(title, ""))
	if ResourceLoader.exists(icon_path):
		button.icon = load(icon_path) as Texture2D
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _sidebar_button_style(false))
	button.add_theme_stylebox_override("hover", _sidebar_button_style(true))
	return button

func _sidebar_button_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.13, 0.17, 0.78) if active else Color(0.015, 0.045, 0.060, 0.52)
	style.border_color = Color(0.58, 0.84, 1.0, 0.86) if active else Color(0.28, 0.52, 0.65, 0.38)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style

func _format_percent(value: float) -> String:
	return "%d%%" % int(round(clampf(value, 0.0, 1.0) * 100.0))

func _value_row(control: Control, value_text: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "ValueRow"
	row.add_theme_constant_override("separation", 12)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	var value: Label = Label.new()
	value.name = "Value"
	value.text = value_text
	value.custom_minimum_size = Vector2(62.0, 38.0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 13)
	value.add_theme_color_override("font_color", TEXT_PRIMARY)
	row.add_child(value)
	return row

func _add_labeled_control(parent: VBoxContainer, label_text: String, control: Control) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 58.0)
	row.add_theme_constant_override("separation", 24)
	parent.add_child(row)

	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(310.0, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", TEXT_SECONDARY)
	row.add_child(label)

	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)

func _create_slider(min_value: float, max_value: float, step_value: float) -> HSlider:
	var slider: HSlider = HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(360.0, 38.0)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.07, 0.15, 0.19, 0.90)
	track.corner_radius_top_left = 4
	track.corner_radius_top_right = 4
	track.corner_radius_bottom_left = 4
	track.corner_radius_bottom_right = 4
	track.content_margin_top = 3.0
	track.content_margin_bottom = 3.0
	slider.add_theme_stylebox_override("slider", track)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = CYAN
	grabber.set_corner_radius_all(8)
	grabber.shadow_color = Color(0.20, 0.65, 0.95, 0.45)
	grabber.shadow_size = 8
	slider.add_theme_stylebox_override("grabber_area", grabber)
	return slider

func _create_glass_button(text_value: String, height: float) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0.0, height)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", CYAN)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var normal: StyleBoxFlat = _button_style(Color(0.025, 0.055, 0.070, 0.62), Color(0.40, 0.66, 0.78, 0.45), 10)
	var hover: StyleBoxFlat = _button_style(Color(0.065, 0.125, 0.16, 0.76), Color(0.56, 0.82, 0.96, 0.82), 16)
	var pressed_style: StyleBoxFlat = _button_style(Color(0.025, 0.055, 0.070, 0.86), Color(0.68, 0.90, 1.0, 1.0), 8)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover)
	return button

func _tab_style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style

func _button_style(background: Color, border: Color, shadow_size: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(CYAN.r, CYAN.g, CYAN.b, 0.22)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0.0, 4.0)
	return style

func _add_glass_surface(parent: Control) -> void:
	var surface: ColorRect = ColorRect.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader: Shader = load(GLASS_SHADER_PATH) as Shader
	if shader != null:
		var shader_material: ShaderMaterial = ShaderMaterial.new()
		shader_material.shader = shader
		shader_material.set_shader_parameter("tint", Color(0.02, 0.05, 0.065, 0.78))
		shader_material.set_shader_parameter("rim", CYAN)
		surface.material = shader_material
	parent.add_child(surface)
	parent.move_child(surface, 0)

	var border: StyleBoxFlat = StyleBoxFlat.new()
	border.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	border.border_color = Color(0.55, 0.78, 0.90, 0.60)
	border.set_border_width_all(1)
	border.corner_radius_top_left = 20
	border.corner_radius_top_right = 20
	border.corner_radius_bottom_left = 20
	border.corner_radius_bottom_right = 20
	border.shadow_color = Color(0.03, 0.36, 0.54, 0.34)
	border.shadow_size = 26
	border.shadow_offset = Vector2(0.0, 10.0)
	parent.add_theme_stylebox_override("panel", border)

func _apply_layout() -> void:
	# Панель масштабируется от reference 1920x1080, но никогда не
	# выходит за безопасные поля текущего окна.
	if not is_instance_valid(_panel):
		return

	var viewport: Vector2 = size
	if viewport.x <= 1.0 or viewport.y <= 1.0:
		return

	var scale_factor: float = clampf(minf(viewport.x / 1920.0, viewport.y / 1080.0), 0.70, 1.15)
	var width: float = minf(1760.0 * scale_factor, viewport.x - 56.0)
	var height: float = minf(820.0 * scale_factor, viewport.y - 68.0)
	width = maxf(width, 720.0)
	height = maxf(height, 520.0)

	_panel.size = Vector2(width, height)
	_panel.position = (viewport - _panel.size) * 0.5

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_layout()

func _load_values() -> void:
	# Все изменения в этом окне являются отложенными до «ПРИМЕНИТЬ».
	# Здесь ничего не меняем в активной игре.
	pass

func _sync_controls_from_data() -> void:
	if _resolution_option != null:
		var resolutions: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
		var closest: int = 2
		var best_distance: int = 2147483647
		for i: int in resolutions.size():
			var distance: int = abs(resolutions[i].x - data.resolution.x) + abs(resolutions[i].y - data.resolution.y)
			if distance < best_distance:
				best_distance = distance
				closest = i
		_resolution_option.select(closest)
	if _fullscreen_toggle != null:
		_fullscreen_toggle.button_pressed = data.fullscreen
	if _brightness_slider != null:
		_brightness_slider.value = data.brightness
	if _gamma_slider != null:
		_gamma_slider.value = data.gamma


func _on_resolution_selected(index: int) -> void:
	var sizes: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
	if index >= 0 and index < sizes.size():
		data.resolution = sizes[index]

func _on_fullscreen_toggled(enabled: bool) -> void:
	data.fullscreen = enabled

func _on_brightness_changed(value: float) -> void:
	data.brightness = value

func _on_gamma_changed(value: float) -> void:
	data.gamma = value

func _on_vsync_toggled(enabled: bool) -> void:
	data.vsync_enabled = enabled

func _on_hud_color_changed(color: Color) -> void:
	data.hud_color = color

func _apply_hud_color() -> void:
	for node: Node in get_tree().get_nodes_in_group("hud"):
		if node is CanvasItem:
			(node as CanvasItem).modulate = data.hud_color

func _on_hud_toggled(enabled: bool) -> void:
	data.hud_enabled = enabled

func _on_minimap_toggled(enabled: bool) -> void:
	data.minimap_enabled = enabled

func _on_ammo_toggled(enabled: bool) -> void:
	data.ammo_counter_enabled = enabled

func _set_group_visibility(group_name: String, visible: bool) -> void:
	for node: Node in get_tree().get_nodes_in_group(group_name):
		if node is CanvasItem:
			(node as CanvasItem).visible = visible

func _on_sensitivity_changed(value: float) -> void:
	data.mouse_sensitivity = value
	if _sensitivity_value != null:
		_sensitivity_value.text = _format_percent(value / 5.0)

func _apply_player_settings() -> void:
	for node: Node in get_tree().get_nodes_in_group("player_controller"):
		if node.has_method("apply_settings"):
			node.call("apply_settings", data)

func _on_master_volume_changed(value: float) -> void:
	data.master_volume = value
	if _master_value != null:
		_master_value.text = _format_percent(value)

func _on_sfx_volume_changed(value: float) -> void:
	data.sfx_volume = value
	if _sfx_value != null:
		_sfx_value.text = _format_percent(value)

func _on_ui_volume_changed(value: float) -> void:
	data.ui_volume = value
	if _ui_value != null:
		_ui_value.text = _format_percent(value)

func _on_quality_selected(index: int) -> void:
	data.quality_profile = clampi(index, 0, 2)
	for selector: OptionButton in _quality_selectors:
		selector.select(data.quality_profile)

func _begin_remap(action: String, button: Button) -> void:
	_cancel_remap()
	remap_action = action
	remap_button = button
	remap_button.text = "НАЖМИТЕ КЛАВИШУ..."
	remap_button.grab_focus()

func _cancel_remap() -> void:
	remap_button = null
	remap_action = ""
	_refresh_remap_buttons()

func _apply_key_binding(action: String, keycode: Key) -> void:
	# Key changes are staged locally and become active only after «ПРИМЕНИТЬ».
	# This also makes Space and other physical keys behave consistently.
	data.key_bindings[action] = int(keycode)
	_cancel_remap()
	_refresh_remap_buttons()

func _key_name(action: String) -> String:
	var stored: Key = data.get_key_binding(action)
	if stored == KEY_NONE:
		return "—"
	return OS.get_keycode_string(stored)

func _refresh_remap_buttons() -> void:
	var owners: Dictionary = {}
	for action in data.key_bindings.keys():
		var keycode := int(data.key_bindings[action])
		if keycode == KEY_NONE:
			continue
		if not owners.has(keycode):
			owners[keycode] = []
		owners[keycode].append(action)

	for action in _remap_buttons.keys():
		var button: Button = _remap_buttons[action]
		button.text = "НАЖМИТЕ КЛАВИШУ..." if action == remap_action else _key_name(action)
		var duplicate: bool = owners.has(int(data.key_bindings.get(action, KEY_NONE))) and owners[int(data.key_bindings.get(action, KEY_NONE))].size() > 1
		button.add_theme_color_override("font_color", Color(1.0, 0.32, 0.32, 1.0) if duplicate else TEXT_PRIMARY)
		button.add_theme_color_override("font_hover_color", Color(1.0, 0.50, 0.50, 1.0) if duplicate else Color.WHITE)
		button.tooltip_text = "Клавиша используется несколькими действиями" if duplicate else "Нажмите, чтобы переназначить"

func _on_defaults_pressed() -> void:
	match _current_page:
		"ГРАФИКА":
			data.resolution = Vector2i(1920, 1080)
			data.fullscreen = false
			data.brightness = 1.0
			data.gamma = 1.0
			data.vsync_enabled = false
			data.motion_blur_enabled = true
			data.quality_profile = 2
		"ИНТЕРФЕЙС":
			data.hud_color = Color(0.48, 0.78, 0.96, 1.0)
			data.hud_enabled = true
			data.minimap_enabled = true
			data.ammo_counter_enabled = true
		"УПРАВЛЕНИЕ":
			data.mouse_sensitivity = 1.0
			data.key_bindings = {
				"move_forward": KEY_W, "move_backward": KEY_S,
				"move_left": KEY_A, "move_right": KEY_D,
				"sprint": KEY_SHIFT, "crouch": KEY_CTRL, "jump": KEY_SPACE,
				"interact": KEY_E, "flashlight": KEY_F, "holster_item": KEY_Q,
				"drop_item": KEY_G, "slot_1": KEY_1, "slot_2": KEY_2, "slot_3": KEY_3
			}
		"ЗВУК":
			data.master_volume = 1.0
			data.sfx_volume = 1.0
			data.ui_volume = 1.0
	_build_defaults_refresh()

func _build_defaults_refresh() -> void:
	match _current_page:
		"ГРАФИКА":
			if _resolution_option != null: _resolution_option.select(2)
			if _fullscreen_toggle != null: _fullscreen_toggle.button_pressed = data.fullscreen
			if _quality_profile != null: _quality_profile.select(data.quality_profile)
			for selector: OptionButton in _quality_selectors: selector.select(data.quality_profile)
			if _brightness_slider != null: _brightness_slider.value = data.brightness
			if _gamma_slider != null: _gamma_slider.value = data.gamma
			if _motion_blur_toggle != null: _motion_blur_toggle.button_pressed = data.motion_blur_enabled
			if _vsync_toggle != null: _vsync_toggle.button_pressed = data.vsync_enabled
		"ИНТЕРФЕЙС":
			if _hud_color_button != null: _hud_color_button.color = data.hud_color
			if _hud_toggle != null: _hud_toggle.button_pressed = data.hud_enabled
			if _minimap_toggle != null: _minimap_toggle.button_pressed = data.minimap_enabled
			if _ammo_toggle != null: _ammo_toggle.button_pressed = data.ammo_counter_enabled
		"УПРАВЛЕНИЕ":
			if _sensitivity_slider != null: _sensitivity_slider.value = data.mouse_sensitivity
			if _sensitivity_value != null: _sensitivity_value.text = _format_percent(data.mouse_sensitivity / 5.0)
			_refresh_remap_buttons()
		"ЗВУК":
			if _master_slider != null: _master_slider.value = data.master_volume
			if _sfx_slider != null: _sfx_slider.value = data.sfx_volume
			if _ui_slider != null: _ui_slider.value = data.ui_volume
			if _master_value != null: _master_value.text = _format_percent(data.master_volume)
			if _sfx_value != null: _sfx_value.text = _format_percent(data.sfx_volume)
			if _ui_value != null: _ui_value.text = _format_percent(data.ui_volume)

func _on_apply_pressed() -> void:
	_cancel_remap()
	data.apply_all(get_viewport())
	_apply_hud_color()
	data.apply_visual_settings()
	data.save()
	_apply_player_settings()

func _on_back_pressed() -> void:
	_cancel_remap()
	# Discard all staged changes when leaving without applying.
	data = GameSettingsData.load_saved()
	data.apply_all(get_viewport())
	_sync_controls_from_data()
	_build_defaults_refresh()
	closed.emit()
