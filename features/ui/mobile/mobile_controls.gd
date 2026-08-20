class_name MobileControls
extends Control

var player: PlayerController
var dpad: Dictionary = {}
var look_origin := Vector2.ZERO
var looking := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	visible = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()

func setup(player_ref: PlayerController) -> void:
	player = player_ref

func _build_ui() -> void:
	var pad := Control.new()
	pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pad.position = Vector2(26, -218)
	pad.size = Vector2(210, 190)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pad)
	_make_hold_button(pad, "▲", Vector2(72, 0), "move_forward")
	_make_hold_button(pad, "▼", Vector2(72, 118), "move_backward")
	_make_hold_button(pad, "◀", Vector2(0, 59), "move_left")
	_make_hold_button(pad, "▶", Vector2(144, 59), "move_right")

	var interact := _make_action_button("E", "interact", Vector2(-190, -170), Vector2(70, 70), Control.PRESET_BOTTOM_RIGHT)
	add_child(interact)
	var flashlight := _make_action_button("F", "flashlight", Vector2(-112, -170), Vector2(70, 70), Control.PRESET_BOTTOM_RIGHT)
	add_child(flashlight)
	var attack := _make_action_button("⚔", "attack_virtual", Vector2(-190, -92), Vector2(70, 70), Control.PRESET_BOTTOM_RIGHT)
	add_child(attack)

	for i in range(1, 4):
		var slot := _make_action_button(str(i), "slot_%d" % i, Vector2(-270 + (i - 1) * 76, -18), Vector2(64, 52), Control.PRESET_BOTTOM_RIGHT)
		add_child(slot)

	var hint := Label.new()
	hint.text = "Свайп справа — осмотр"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position = Vector2(-250, -55)
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.65, 0.78, 0.84, 0.65))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

func _make_hold_button(parent: Control, text_value: String, pos: Vector2, action: String) -> void:
	var button := Button.new()
	button.text = text_value
	button.position = pos
	button.size = Vector2(66, 54)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	_style(button)
	button.button_down.connect(func(): Input.action_press(action))
	button.button_up.connect(func(): Input.action_release(action))
	parent.add_child(button)
	dpad[action] = button

func _make_action_button(text_value: String, action: String, pos: Vector2, button_size: Vector2, preset: int) -> Button:
	var button := Button.new()
	button.text = text_value
	button.set_anchors_preset(preset)
	button.position = pos
	button.size = button_size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	_style(button)
	button.pressed.connect(func():
		if action == "attack_virtual":
			if player != null and player.has_method("attack_virtual"):
				player.call("attack_virtual")
			return
		if action.begins_with("slot_"):
			if player != null:
				player.select_inventory_slot(int(action.trim_prefix("slot_")))
			return
		Input.action_press(action)
		call_deferred("_release_action", action)
	)
	return button

func _release_action(action: String) -> void:
	Input.action_release(action)

func _style(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 20)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.02, 0.07, 0.09, 0.72)
	normal.border_color = Color(0.42, 0.72, 0.86, 0.38)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(12)
	button.add_theme_stylebox_override("normal", normal)

func _gui_input(event: InputEvent) -> void:
	if not visible or player == null:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.position.x < size.x * 0.52:
			return
		looking = touch.pressed
		look_origin = touch.position
		accept_event()
	elif event is InputEventScreenDrag and looking:
		var drag := event as InputEventScreenDrag
		player.apply_touch_look(drag.relative)
		accept_event()
