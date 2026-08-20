class_name MainMenu
extends Control

const GAME_WORLD_SCENE: String = "res://features/movement/scenes/game_world.tscn"
const SETTINGS_SCENE: String = "res://features/ui/settings/settings_menu.tscn"
const PATCH_DIR: String = "res://features/ui/patch_notes"
const DEFAULT_PORT: int = 1766

var menu_panel: PanelContainer
var buttons_container: VBoxContainer
var singleplayer_button: Button
var network_button: Button
var settings_button: Button
var exit_button: Button
var settings_menu: SettingsMenu = null
var network_panel: PanelContainer = null
var transition_locked: bool = false
var background: ColorRect
var news_panel: PanelContainer
var news_scroll: ScrollContainer
var news_column: VBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var settings := GameSettingsData.load_saved()
	settings.apply_all(get_viewport())
	settings.apply_visual_settings()
	_build_ui()
	_connect_buttons()

func _build_ui() -> void:
	background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background_shader: Shader = load("res://shaders/ui/menu_ambient.gdshader") as Shader
	if background_shader != null:
		var material := ShaderMaterial.new()
		material.shader = background_shader
		background.material = material
	else:
		background.color = Color("#030507")
	add_child(background)
	move_child(background, 0)

	var haze := ColorRect.new()
	haze.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var haze_shader: Shader = load("res://shaders/ui/glass_haze.gdshader") as Shader
	if haze_shader != null:
		var haze_material := ShaderMaterial.new()
		haze_material.shader = haze_shader
		haze.material = haze_material
	add_child(haze)
	move_child(haze, 1)

	_build_menu_panel()
	_build_news_panel()

func _build_menu_panel() -> void:
	menu_panel = PanelContainer.new()
	menu_panel.name = "MenuPanel"
	menu_panel.anchor_left = 0.07
	menu_panel.anchor_top = 0.17
	menu_panel.anchor_right = 0.34
	menu_panel.anchor_bottom = 0.78
	menu_panel.custom_minimum_size = Vector2(440.0, 520.0)
	menu_panel.add_theme_stylebox_override("panel", _panel_style(0.018, 0.026, 0.032, 0.82, 0.34))
	add_child(menu_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	menu_panel.add_child(margin)

	buttons_container = VBoxContainer.new()
	buttons_container.add_theme_constant_override("separation", 10)
	margin.add_child(buttons_container)

	var title := Label.new()
	title.text = "OUT OF SYNC"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.90, 0.96, 1.0, 0.98))
	buttons_container.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "PHASE ZERO // FLINT PEAK 1994"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.52, 0.65, 0.72, 0.82))
	buttons_container.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 16
	buttons_container.add_child(spacer)

	singleplayer_button = _create_button("ОДИНОЧНАЯ ИГРА", "player.svg")
	network_button = _create_button("КО-ОП // СЕТЕВАЯ ИГРА", "network.svg")
	settings_button = _create_button("НАСТРОЙКИ", "settings.svg")
	exit_button = _create_button("ВЫЙТИ ИЗ ИГРЫ", "power.svg")

func _build_news_panel() -> void:
	news_panel = PanelContainer.new()
	news_panel.name = "PatchNews"
	news_panel.anchor_left = 0.62
	news_panel.anchor_top = 0.17
	news_panel.anchor_right = 0.945
	news_panel.anchor_bottom = 0.79
	news_panel.custom_minimum_size = Vector2(560.0, 520.0)
	news_panel.add_theme_stylebox_override("panel", _panel_style(0.008, 0.014, 0.020, 0.62, 0.24))
	add_child(news_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	news_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var heading := Label.new()
	heading.text = "НОВОСТИ // БАГ-ФИКСЫ"
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color(0.82, 0.91, 0.96, 0.94))
	root.add_child(heading)

	var hint := Label.new()
	hint.text = "Выберите патч, чтобы раскрыть полное описание."
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.40, 0.55, 0.62, 0.8))
	root.add_child(hint)

	news_scroll = ScrollContainer.new()
	news_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	news_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(news_scroll)

	news_column = VBoxContainer.new()
	news_column.add_theme_constant_override("separation", 8)
	news_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	news_scroll.add_child(news_column)
	_load_patch_notes()

	var footer := Label.new()
	footer.text = "FLINT PEAK // BUILD CHANNEL: DEV // CO-OP PORT 1766"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_theme_font_size_override("font_size", 10)
	footer.add_theme_color_override("font_color", Color(0.38, 0.47, 0.52, 0.7))
	root.add_child(footer)

func _load_patch_notes() -> void:
	for child in news_column.get_children():
		child.queue_free()
	var dir := DirAccess.open(PATCH_DIR)
	if dir == null:
		_add_patch_entry("20.08.2026", "PATCH NOTES", "Папка патчей не найдена.", "Создайте features/ui/patch_notes и положите туда markdown-файлы.")
		return
	var files: Array[String] = []
	dir.list_dir_begin()
	while true:
		var file := dir.get_next()
		if file.is_empty():
			break
		if not dir.current_is_dir() and file.to_lower().ends_with(".md"):
			files.append(file)
	dir.list_dir_end()
	files.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) > 0)
	for file in files:
		var text := FileAccess.get_file_as_string(PATCH_DIR.path_join(file))
		_add_patch_from_markdown(file, text)

func _add_patch_from_markdown(file_name: String, text: String) -> void:
	var lines := text.split("\n")
	var title := file_name.get_basename().replace("_", " ")
	var body := text.strip_edges()
	for line in lines:
		var trimmed := line.strip_edges()
		if trimmed.begins_with("# "):
			title = trimmed.trim_prefix("# ").strip_edges()
			break
	var date := "PATCH"
	var date_regex := RegEx.new()
	date_regex.compile("(20\\d{2}[.-]\\d{2}[.-]\\d{2})")
	var match := date_regex.search(text)
	if match != null:
		date = match.get_string(1).replace("-", ".")
	_add_patch_entry(date, title, body, "Источник: %s" % file_name)

func _add_patch_entry(date_text: String, patch_name: String, description: String, source: String) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(0.035, 0.055, 0.065, 0.58, 0.10))
	news_column.add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)
	var head := Button.new()
	head.text = "%s   //   %s" % [date_text, patch_name]
	head.alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.flat = true
	head.focus_mode = Control.FOCUS_NONE
	head.add_theme_font_size_override("font_size", 14)
	head.add_theme_color_override("font_color", Color(0.78, 0.90, 0.96, 0.95))
	box.add_child(head)
	var detail := Label.new()
	detail.text = description
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 11)
	detail.add_theme_color_override("font_color", Color(0.58, 0.68, 0.73, 0.86))
	detail.visible = false
	box.add_child(detail)
	var source_label := Label.new()
	source_label.text = source
	source_label.add_theme_font_size_override("font_size", 9)
	source_label.add_theme_color_override("font_color", Color(0.35, 0.45, 0.50, 0.68))
	source_label.visible = false
	box.add_child(source_label)
	head.pressed.connect(func():
		detail.visible = not detail.visible
		source_label.visible = detail.visible
	)

func _create_button(text_value: String, icon_file: String) -> Button:
	var button: GlassButton = GlassButton.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0.0, 58.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	var texture := load("res://features/ui/main_menu/assets/icons/%s" % icon_file) as Texture2D
	if texture != null:
		button.icon = texture
	buttons_container.add_child(button)
	return button

func _connect_buttons() -> void:
	singleplayer_button.pressed.connect(_on_singleplayer_pressed)
	network_button.pressed.connect(_on_network_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_singleplayer_pressed() -> void:
	if transition_locked:
		return
	_close_network_panel()
	_start_game_world()

func _on_network_pressed() -> void:
	if transition_locked:
		return
	if network_panel != null and is_instance_valid(network_panel):
		network_panel.visible = not network_panel.visible
		return
	_build_network_panel()

func _build_network_panel() -> void:
	network_panel = PanelContainer.new()
	network_panel.name = "NetworkPanel"
	network_panel.set_anchors_preset(Control.PRESET_CENTER)
	network_panel.position = Vector2(-260.0, -190.0)
	network_panel.size = Vector2(520.0, 380.0)
	network_panel.add_theme_stylebox_override("panel", _panel_style(0.012, 0.022, 0.030, 0.96, 0.40))
	add_child(network_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	network_panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)
	var title := Label.new()
	title.text = "КО-ОП // СЕТЕВАЯ ИГРА"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.82, 0.92, 0.98, 0.96))
	col.add_child(title)
	var hint := Label.new()
	hint.text = "LAN / Radmin VPN / проброс порта. По умолчанию :1766"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.48, 0.62, 0.69, 0.82))
	col.add_child(hint)
	var ip := LineEdit.new()
	ip.placeholder_text = "IP хоста, например 26.x.x.x"
	ip.text = "127.0.0.1"
	ip.name = "IpInput"
	col.add_child(ip)
	var port := LineEdit.new()
	port.placeholder_text = "Порт"
	port.text = str(DEFAULT_PORT)
	port.name = "PortInput"
	port.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	col.add_child(port)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	var host := _create_dialog_button("СОЗДАТЬ ЛОББИ")
	row.add_child(host)
	var join := _create_dialog_button("ПОДКЛЮЧИТЬСЯ")
	row.add_child(join)
	var close := _create_dialog_button("ЗАКРЫТЬ")
	col.add_child(close)
	host.pressed.connect(func():
		var p := _parse_port(port.text)
		var peer := ENetMultiplayerPeer.new()
		var err := peer.create_server(p, 4)
		if err != OK:
			_hint_network(col, "Не удалось создать сервер: %s" % error_string(err))
			return
		multiplayer.multiplayer_peer = peer
		_start_game_world()
	)
	join.pressed.connect(func():
		var p := _parse_port(port.text)
		var address := ip.text.strip_edges()
		if address.is_empty():
			address = "127.0.0.1"
		var peer := ENetMultiplayerPeer.new()
		var err := peer.create_client(address, p)
		if err != OK:
			_hint_network(col, "Не удалось подключиться: %s" % error_string(err))
			return
		multiplayer.multiplayer_peer = peer
		_start_game_world()
	)
	close.pressed.connect(_close_network_panel)

func _create_dialog_button(text_value: String) -> Button:
	var b := _create_button_style(Button.new(), text_value)
	b.custom_minimum_size = Vector2(0.0, 48.0)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b

func _create_button_style(button: Button, text_value: String) -> Button:
	button.text = text_value
	button.add_theme_font_size_override("font_size", 13)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.11, 0.15, 0.92)
	s.border_color = Color(0.32, 0.66, 0.86, 0.40)
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", s)
	return button

func _hint_network(parent: VBoxContainer, text_value: String) -> void:
	var old := parent.get_node_or_null("NetworkHint")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "NetworkHint"
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.38, 0.9))
	parent.add_child(label)

func _parse_port(value: String) -> int:
	return clampi(int(value), 1, 65535)

func _close_network_panel() -> void:
	if network_panel != null and is_instance_valid(network_panel):
		network_panel.queue_free()
		network_panel = null

func _on_settings_pressed() -> void:
	if transition_locked:
		return
	_open_settings()

func _on_exit_pressed() -> void:
	get_tree().quit()

func _start_game_world() -> void:
	if not ResourceLoader.exists(GAME_WORLD_SCENE):
		push_error("[MainMenu] GameWorld not found: " + GAME_WORLD_SCENE)
		return
	transition_locked = true
	var result := get_tree().change_scene_to_file(GAME_WORLD_SCENE)
	if result != OK:
		transition_locked = false
		push_error("[MainMenu] GameWorld transition failed: " + error_string(result))

func _open_settings() -> void:
	menu_panel.visible = false
	news_panel.visible = false
	_close_network_panel()
	if settings_menu != null and is_instance_valid(settings_menu):
		settings_menu.visible = true
		return
	var packed_scene := load(SETTINGS_SCENE) as PackedScene
	if packed_scene == null:
		menu_panel.visible = true
		news_panel.visible = true
		return
	settings_menu = packed_scene.instantiate() as SettingsMenu
	if settings_menu == null:
		menu_panel.visible = true
		news_panel.visible = true
		return
	add_child(settings_menu)
	settings_menu.closed.connect(_on_settings_closed)

func _on_settings_closed() -> void:
	if settings_menu != null:
		settings_menu.visible = false
	menu_panel.visible = true
	news_panel.visible = true
	transition_locked = false

func _panel_style(r: float, g: float, b: float, alpha: float, shadow: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(r, g, b, alpha)
	s.border_color = Color(0.48, 0.70, 0.82, 0.18)
	s.set_border_width_all(1)
	s.set_corner_radius_all(16)
	s.shadow_color = Color(0.0, 0.0, 0.0, shadow)
	s.shadow_size = 22
	s.shadow_offset = Vector2(0.0, 8.0)
	return s
