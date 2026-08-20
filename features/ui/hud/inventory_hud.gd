extends Control
class_name InventoryHUD

var player: PlayerController
var slot_labels: Array[Label] = []
var item_label: Label
var hp_value: Label
var battery_value: Label
var hp_bar: ProgressBar
var battery_bar: ProgressBar

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_to_group("hud")
	_build_ui()

func setup(player_ref: PlayerController) -> void:
	player = player_ref
	_refresh()

func _process(_delta: float) -> void:
	if player != null:
		_refresh()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(24.0, 22.0)
	panel.size = Vector2(330.0, 154.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	var hp_row := HBoxContainer.new()
	var hp_title := Label.new()
	hp_title.text = "HP"
	hp_title.custom_minimum_size.x = 42
	hp_title.add_theme_color_override("font_color", Color(0.72, 0.88, 0.96, 0.9))
	hp_row.add_child(hp_title)
	hp_bar = ProgressBar.new()
	hp_bar.max_value = 100.0
	hp_bar.value = 100.0
	hp_bar.show_percentage = false
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(hp_bar)
	hp_value = Label.new()
	hp_value.text = "100%"
	hp_value.custom_minimum_size.x = 52
	hp_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_row.add_child(hp_value)
	column.add_child(hp_row)

	var battery_row := HBoxContainer.new()
	var battery_title := Label.new()
	battery_title.text = "ФОНАРЬ"
	battery_title.custom_minimum_size.x = 42
	battery_title.add_theme_color_override("font_color", Color(0.72, 0.88, 0.96, 0.9))
	battery_row.add_child(battery_title)
	battery_bar = ProgressBar.new()
	battery_bar.max_value = 100.0
	battery_bar.value = 100.0
	battery_bar.show_percentage = false
	battery_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battery_row.add_child(battery_bar)
	battery_value = Label.new()
	battery_value.text = "100%"
	battery_value.custom_minimum_size.x = 52
	battery_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	battery_row.add_child(battery_value)
	column.add_child(battery_row)

	item_label = Label.new()
	item_label.text = "ПРЕДМЕТ: —"
	item_label.add_theme_font_size_override("font_size", 12)
	item_label.add_theme_color_override("font_color", Color(0.72, 0.88, 0.96, 0.9))
	column.add_child(item_label)

	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 6)
	column.add_child(slots)
	for i in range(1, 4):
		var label := Label.new()
		label.custom_minimum_size = Vector2(82.0, 30.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		slots.add_child(label)
		slot_labels.append(label)

func _refresh() -> void:
	if player == null or slot_labels.is_empty():
		return
	var hp_percent := 100.0 * player.hp / maxf(player.max_hp, 1.0)
	var battery_percent := 100.0 * player.flashlight_battery / maxf(player.max_flashlight_battery, 1.0)
	hp_bar.value = hp_percent
	battery_bar.value = battery_percent
	hp_value.text = "%d%%" % roundi(hp_percent)
	battery_value.text = "%d%%" % roundi(battery_percent)
	item_label.text = "ПРЕДМЕТ: %s" % (str(player.inventory_items.get(player.inventory_slot, "—")) if not str(player.inventory_items.get(player.inventory_slot, "")).is_empty() else "—")
	for i in range(3):
		var slot := i + 1
		var item_id := str(player.inventory_items.get(slot, ""))
		slot_labels[i].text = "%d  %s" % [slot, (item_id if not item_id.is_empty() else "—")]
		slot_labels[i].add_theme_color_override("font_color", Color(0.55, 0.82, 1.0, 1.0) if player.inventory_slot == slot else Color(0.55, 0.65, 0.70, 0.8))

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.035, 0.045, 0.70)
	style.border_color = Color(0.34, 0.68, 0.84, 0.30)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style
