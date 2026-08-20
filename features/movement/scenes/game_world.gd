extends Node3D
class_name GameWorld

const MAIN_MENU_SCENE := "res://features/ui/main_menu/main_menu.tscn"
const SETTINGS_SCENE := "res://features/ui/settings/settings_menu.tscn"

var player: PlayerController
var pause_layer: CanvasLayer
var pause_panel: PanelContainer
var crosshair: Label
var fire_light: OmniLight3D
var fire_core: MeshInstance3D
var fire_time := 0.0
var _settings_instance: Control
var _networked: bool = false
var _network_players: Dictionary = {}
var _spawn_positions: Array[Vector3] = [Vector3(0.0, 0.08, 7.5), Vector3(2.2, 0.08, 7.5), Vector3(-2.2, 0.08, 7.5), Vector3(4.0, 0.08, 6.0)]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_networked = multiplayer.has_multiplayer_peer()
	var settings := GameSettingsData.load_saved()
	settings.apply_all(get_viewport())
	settings.apply_visual_settings()
	if _networked:
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_build_world()
	_spawn_player_for_peer(multiplayer.get_unique_id(), _spawn_position_for_peer(multiplayer.get_unique_id()))
	_build_hud()
	settings.apply_all(get_viewport())
	settings.apply_visual_settings()
	_build_mobile_controls()
	_build_global_chat()
	_build_pause_menu()
	if _networked and multiplayer.is_server():
		for peer_id in multiplayer.get_peers():
			_spawn_player_for_peer(peer_id, _spawn_position_for_peer(peer_id))
		for existing_id in _network_players.keys():
			rpc("_client_spawn_player", int(existing_id), (_network_players[existing_id] as Node3D).global_position)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _build_global_chat() -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	var chat_script := load("res://features/network/global_chat.gd") as Script
	if chat_script == null:
		return
	var chat := chat_script.new() as Control
	if chat == null:
		return
	chat.name = "GlobalChat"
	chat.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(chat)

func _process(delta: float) -> void:
	fire_time += delta
	if fire_light != null:
		fire_light.light_energy = 2.2 + sin(fire_time * 7.0) * 0.35 + sin(fire_time * 13.0) * 0.18
	if fire_core != null:
		fire_core.scale = Vector3.ONE * (1.0 + sin(fire_time * 8.0) * 0.07)
	# Flashlight input is handled by PlayerController.
	# Do not toggle it here as well, otherwise one key press would switch it twice.

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_toggle_pause()

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#03070a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#20313a")
	env.ambient_light_energy = 0.24
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color("#071016")
	env.fog_light_energy = 0.45
	env.fog_density = 0.012
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	environment.environment = env
	add_child(environment)
	environment.add_to_group("game_environment")

	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	moon.light_color = Color("#6e8da2")
	moon.light_energy = 0.22
	moon.shadow_enabled = true
	moon.add_to_group("quality_lights")
	add_child(moon)

	_make_floor()
	_make_street()
	_make_walls()
	_make_campfire(Vector3(-1.5, 0.0, 1.2))
	_make_door(Vector3(6.0, 0.0, -5.0))
	_make_table(Vector3(2.4, 0.0, 1.6))
	_make_sign(Vector3(2.4, 1.9, 0.7), "ТЕСТОВАЯ ЗОНА")

func _make_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "Ground"
	add_child(body)
	body.position = Vector3(0.0, -0.1, 0.0)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(30.0, 0.2, 24.0)
	mesh.mesh = box
	mesh.material_override = _mat(Color("#10171a"), 1.0)
	body.add_child(mesh)
	body.add_child(_box_collision(Vector3(30.0, 0.2, 24.0)))

func _make_street() -> void:
	var road := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(7.5, 0.025, 24.0)
	road.mesh = box
	road.position = Vector3(-0.8, 0.015, 0.0)
	road.material_override = _mat(Color("#151b1e"), 0.95)
	add_child(road)

	for z in [-8.0, -2.0, 4.0, 10.0]:
		var lamp := MeshInstance3D.new()
		var pole := CylinderMesh.new()
		pole.top_radius = 0.045
		pole.bottom_radius = 0.07
		pole.height = 2.8
		lamp.mesh = pole
		lamp.position = Vector3(-5.0, 1.4, z)
		lamp.material_override = _mat(Color("#1c2529"), 0.9)
		add_child(lamp)
		var light := OmniLight3D.new()
		light.position = lamp.position + Vector3(0.0, 1.25, 0.0)
		light.light_color = Color("#8cb7ca")
		light.light_energy = 0.55
		light.omni_range = 5.0
		add_child(light)

func _make_walls() -> void:
	_make_wall(Vector3(0.0, 1.5, -11.5), Vector3(30.0, 3.0, 0.35))
	_make_wall(Vector3(0.0, 1.5, 11.5), Vector3(30.0, 3.0, 0.35))
	_make_wall(Vector3(-14.8, 1.5, 0.0), Vector3(0.35, 3.0, 24.0))
	_make_wall(Vector3(14.8, 1.5, 0.0), Vector3(0.35, 3.0, 24.0))
	# A broken low wall makes the area read as an outdoor test street rather than a box.
	_make_wall(Vector3(9.0, 0.65, -1.8), Vector3(5.0, 1.3, 0.3))
	_make_wall(Vector3(-8.0, 0.65, 5.5), Vector3(4.5, 1.3, 0.3))

func _make_wall(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _mat(Color("#0c1114"), 1.0)
	body.add_child(mesh)
	body.add_child(_box_collision(size))

func _make_campfire(pos: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Campfire"
	root.position = pos
	add_child(root)

	for angle in [0.0, 1.05, 2.1]:
		var log := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.12
		cylinder.bottom_radius = 0.15
		cylinder.height = 1.1
		log.mesh = cylinder
		log.rotation_degrees = Vector3(0.0, rad_to_deg(angle), 90.0)
		log.material_override = _mat(Color("#4c3020"), 0.95)
		root.add_child(log)

	fire_core = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.34
	sphere.height = 0.7
	fire_core.mesh = sphere
	fire_core.position = Vector3(0.0, 0.48, 0.0)
	fire_core.material_override = _emissive_mat(Color("#ff7a28"), 5.0)
	root.add_child(fire_core)

	var inner := MeshInstance3D.new()
	var inner_sphere := SphereMesh.new()
	inner_sphere.radius = 0.2
	inner_sphere.height = 0.4
	inner.mesh = inner_sphere
	inner.position = Vector3(0.0, 0.62, 0.0)
	inner.material_override = _emissive_mat(Color("#ffd36a"), 7.0)
	root.add_child(inner)

	fire_light = OmniLight3D.new()
	fire_light.position = Vector3(0.0, 1.2, 0.0)
	fire_light.light_color = Color("#ff9a52")
	fire_light.light_energy = 2.2
	fire_light.omni_range = 8.5
	fire_light.shadow_enabled = true
	fire_light.add_to_group("quality_lights")
	root.add_child(fire_light)

	var marker := Label3D.new()
	marker.text = "КОСТЁР // SAFE LIGHT"
	marker.font_size = 32
	marker.modulate = Color("#8cc9e8")
	marker.position = Vector3(0.0, 2.3, 0.0)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(marker)

func _make_door(pos: Vector3) -> void:
	var door := AnimatableBody3D.new()
	door.name = "TestDoor"
	door.position = pos
	door.set_script(load("res://features/interaction/door.gd"))
	door.target_scene = "res://features/world/rooms/test_room_02.tscn"
	door.open_sound = load("res://assets/audio/door_open.wav") as AudioStream
	door.close_sound = load("res://assets/audio/door_close.wav") as AudioStream
	add_child(door)

	var frame := MeshInstance3D.new()
	var frame_box := BoxMesh.new()
	frame_box.size = Vector3(1.7, 2.7, 0.22)
	frame.mesh = frame_box
	frame.position = Vector3(0.0, 1.35, 0.0)
	frame.material_override = _mat(Color("#18252b"), 0.85)
	door.add_child(frame)

	var panel := MeshInstance3D.new()
	var panel_box := BoxMesh.new()
	panel_box.size = Vector3(1.25, 2.25, 0.12)
	panel.mesh = panel_box
	panel.position = Vector3(0.0, 1.28, -0.14)
	panel.material_override = _mat(Color("#34434a"), 0.78)
	door.add_child(panel)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.25, 2.25, 0.14)
	collision.shape = shape
	collision.position = Vector3(0.0, 1.28, -0.14)
	door.add_child(collision)

	var label := Label3D.new()
	label.text = "E  //  ДВЕРЬ"
	label.font_size = 38
	label.modulate = Color("#9bd7f1")
	label.position = Vector3(0.0, 2.55, -0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	door.add_child(label)

func _make_table(pos: Vector3) -> void:
	var root := StaticBody3D.new()
	root.name = "TestTable"
	root.position = pos
	add_child(root)
	var top := MeshInstance3D.new()
	var top_box := BoxMesh.new()
	top_box.size = Vector3(2.4, 0.18, 1.2)
	top.mesh = top_box
	top.position.y = 1.05
	top.material_override = _mat(Color("#3b2a22"), 0.95)
	root.add_child(top)
	root.add_child(_box_collision(Vector3(2.4, 0.18, 1.2), Vector3(0.0, 1.05, 0.0)))

	for x in [-0.95, 0.95]:
		for z in [-0.43, 0.43]:
			var leg := MeshInstance3D.new()
			var leg_box := BoxMesh.new()
			leg_box.size = Vector3(0.14, 1.0, 0.14)
			leg.mesh = leg_box
			leg.position = Vector3(x, 0.5, z)
			leg.material_override = _mat(Color("#29201b"), 1.0)
			root.add_child(leg)

	var stick := RigidBody3D.new()
	stick.name = "TestStick"
	stick.position = Vector3(0.0, 1.35, 0.0)
	stick.set_script(load("res://features/interaction/test_stick.gd"))
	root.add_child(stick)
	stick.freeze = true
	var stick_mesh := MeshInstance3D.new()
	var stick_cylinder := CylinderMesh.new()
	stick_cylinder.top_radius = 0.05
	stick_cylinder.bottom_radius = 0.07
	stick_cylinder.height = 0.85
	stick_mesh.mesh = stick_cylinder
	stick_mesh.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	stick_mesh.material_override = _mat(Color("#6d4a32"), 0.95)
	stick.add_child(stick_mesh)
	var stick_collision := CollisionShape3D.new()
	var stick_shape := CylinderShape3D.new()
	stick_shape.radius = 0.07
	stick_shape.height = 0.85
	stick_collision.shape = stick_shape
	stick_collision.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	stick.add_child(stick_collision)

	var sword := RigidBody3D.new()
	sword.name = "TestSword"
	sword.position = Vector3(0.72, 1.35, 0.0)
	sword.set_script(load("res://features/interaction/test_item.gd"))
	sword.set("item_id", "sword")
	sword.set("display_name", "меч")
	sword.set("mesh_color", Color("#aab7c0"))
	sword.set("mesh_length", 1.05)
	sword.set("mesh_radius", 0.045)
	root.add_child(sword)
	sword.freeze = true
	var sword_mesh := MeshInstance3D.new()
	var sword_cylinder := CylinderMesh.new()
	sword_cylinder.top_radius = 0.035
	sword_cylinder.bottom_radius = 0.045
	sword_cylinder.height = 1.05
	sword_mesh.mesh = sword_cylinder
	sword_mesh.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	sword_mesh.material_override = _mat(Color("#aab7c0"), 0.55)
	sword.add_child(sword_mesh)
	var sword_collision := CollisionShape3D.new()
	var sword_shape := CylinderShape3D.new()
	sword_shape.radius = 0.045
	sword_shape.height = 1.05
	sword_collision.shape = sword_shape
	sword_collision.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	sword.add_child(sword_collision)

	var label := Label3D.new()
	label.text = "ТЕСТОВЫЕ ПРЕДМЕТЫ\nE — взять"
	label.font_size = 30
	label.modulate = Color("#91cbe4")
	label.position = Vector3(0.0, 2.0, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)

func _make_sign(pos: Vector3, text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 42
	label.modulate = Color("#63889a")
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _spawn_position_for_peer(peer_id: int) -> Vector3:
	var index := maxi(0, peer_id - 1) % _spawn_positions.size()
	return _spawn_positions[index]

func _spawn_player_for_peer(peer_id: int, spawn_position: Vector3) -> void:
	var node_name := "Player_%d" % peer_id
	if get_node_or_null(node_name) != null:
		return
	var packed_player := load("res://features/movement/scenes/player.tscn") as PackedScene
	if packed_player == null:
		push_error("[GameWorld] Player scene failed to load.")
		return
	var new_player := packed_player.instantiate() as PlayerController
	if new_player == null:
		push_error("[GameWorld] Player scene root must use PlayerController.")
		return
	new_player.name = node_name
	new_player.position = spawn_position
	new_player.set_multiplayer_authority(peer_id)
	add_child(new_player)
	var interaction := InteractionController.new()
	interaction.name = "InteractionController"
	new_player.add_child(interaction)
	interaction.setup(new_player, new_player.camera)
	_network_players[peer_id] = new_player
	if peer_id == multiplayer.get_unique_id():
		player = new_player

func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var spawn := _spawn_position_for_peer(peer_id)
	_spawn_player_for_peer(peer_id, spawn)
	var ids: Array[int] = []
	var positions: Array[Vector3] = []
	for existing_id in _network_players.keys():
		ids.append(int(existing_id))
		var existing := _network_players[existing_id] as Node3D
		positions.append(existing.global_position if existing != null else _spawn_position_for_peer(int(existing_id)))
	rpc_id(peer_id, "_client_sync_players", ids, positions)
	rpc("_client_spawn_player", peer_id, spawn)

func _on_peer_disconnected(peer_id: int) -> void:
	var node := _network_players.get(peer_id, null) as Node
	if node != null and is_instance_valid(node):
		node.queue_free()
	_network_players.erase(peer_id)

@rpc("authority", "reliable", "call_remote", 0)
func _client_spawn_player(peer_id: int, spawn: Vector3) -> void:
	_spawn_player_for_peer(peer_id, spawn)

@rpc("authority", "reliable", "call_remote", 0)
func _client_sync_players(ids: Array, positions: Array) -> void:
	for i in range(mini(ids.size(), positions.size())):
		_spawn_player_for_peer(int(ids[i]), positions[i] as Vector3)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-7.0, -12.0)
	crosshair.add_theme_font_size_override("font_size", 20)
	crosshair.add_theme_color_override("font_color", Color(0.72, 0.9, 1.0, 0.75))
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(crosshair)

	var info := Label.new()
	info.text = "WASD  движение     SHIFT  бег     CTRL  присесть     SPACE  прыжок     F  фонарь     E  взаимодействие     Q  убрать     G  выбросить     LMB  удар"
	info.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	info.position = Vector2(-430.0, -45.0)
	info.add_theme_font_size_override("font_size", 13)
	info.add_theme_color_override("font_color", Color(0.52, 0.68, 0.75, 0.72))
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_to_group("hud_info")
	layer.add_child(info)

	# Inventory HUD is optional. Load it at runtime and instantiate the script
	# directly; never call set_script() on a possibly-null reference.
	var hud_path := "res://features/ui/hud/inventory_hud.gd"
	if ResourceLoader.exists(hud_path):
		var hud_script := load(hud_path) as Script
		if hud_script != null:
			var hud_instance := hud_script.new() as Control
			if hud_instance != null:
				layer.add_child(hud_instance)
				if hud_instance.has_method("setup") and player != null:
					hud_instance.setup(player)
			else:
				push_warning("GameWorld: Inventory HUD script did not create a Control instance.")
		else:
			push_warning("GameWorld: Inventory HUD script could not be loaded.")

	var minimap_path := "res://features/ui/hud/minimap_hud.gd"
	if ResourceLoader.exists(minimap_path) and player != null:
		var minimap_script := load(minimap_path) as Script
		if minimap_script != null:
			var minimap := minimap_script.new() as Control
			if minimap != null:
				layer.add_child(minimap)
				minimap.setup(player)

	var blur_path := "res://features/ui/hud/motion_blur_controller.gd"
	if ResourceLoader.exists(blur_path) and player != null:
		var blur_script := load(blur_path) as Script
		if blur_script != null:
			var blur := blur_script.new() as Control
			if blur != null:
				layer.add_child(blur)
				blur.setup(player)

func _build_mobile_controls() -> void:
	var script_path := "res://features/ui/mobile/mobile_controls.gd"
	if not ResourceLoader.exists(script_path) or player == null:
		return
	var script := load(script_path) as Script
	if script == null:
		return
	var controls := script.new() as Control
	if controls == null:
		return
	controls.name = "MobileControls"
	controls.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(controls)
	if controls.has_method("setup"):
		controls.setup(player)

func _build_pause_menu() -> void:
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 100
	add_child(pause_layer)

	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.015, 0.02, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_layer.add_child(shade)

	pause_panel = PanelContainer.new()
	pause_panel.name = "PausePanel"
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.position = Vector2(-250.0, -220.0)
	pause_panel.size = Vector2(500.0, 440.0)
	pause_panel.add_theme_stylebox_override("panel", _glass_panel())
	pause_layer.add_child(pause_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	pause_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var title := Label.new()
	title.text = "ПАУЗА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#bfe5f6"))
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "OUT OF SYNC // PHASE ZERO"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("#6f91a0"))
	column.add_child(subtitle)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 20
	column.add_child(spacer)

	var continue_button := _pause_button("ПРОДОЛЖИТЬ")
	continue_button.pressed.connect(_toggle_pause)
	column.add_child(continue_button)

	var settings_button := _pause_button("НАСТРОЙКИ")
	settings_button.pressed.connect(_open_settings)
	column.add_child(settings_button)

	var menu_button := _pause_button("В ГЛАВНОЕ МЕНЮ")
	menu_button.pressed.connect(_return_to_menu)
	column.add_child(menu_button)

	pause_layer.visible = false

func _pause_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0.0, 58.0)
	b.add_theme_font_size_override("font_size", 16)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.035, 0.11, 0.15, 0.84)
	normal.border_color = Color(0.35, 0.72, 0.95, 0.42)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(9)
	b.add_theme_stylebox_override("normal", normal)
	return b

func _glass_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.018, 0.055, 0.07, 0.88)
	s.border_color = Color(0.38, 0.72, 0.92, 0.52)
	s.set_border_width_all(1)
	s.set_corner_radius_all(16)
	s.shadow_color = Color(0.0, 0.35, 0.6, 0.35)
	s.shadow_size = 26
	s.shadow_offset = Vector2(0.0, 10.0)
	return s

func _toggle_pause() -> void:
	if _settings_instance != null:
		return
	var paused := not get_tree().paused
	get_tree().paused = paused
	pause_layer.visible = paused
	if paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _open_settings() -> void:
	if _settings_instance != null:
		return
	_settings_instance = load(SETTINGS_SCENE).instantiate()
	add_child(_settings_instance)
	_settings_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	_settings_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _settings_instance.has_signal("closed"):
		_settings_instance.closed.connect(_close_settings)
	pause_layer.visible = false

func _close_settings() -> void:
	if _settings_instance != null:
		_settings_instance.queue_free()
		_settings_instance = null
	pause_layer.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _return_to_menu() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _box_collision(size: Vector3, offset: Vector3 = Vector3.ZERO) -> CollisionShape3D:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = offset
	return collision

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

func _emissive_mat(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.roughness = 0.5
	return m
