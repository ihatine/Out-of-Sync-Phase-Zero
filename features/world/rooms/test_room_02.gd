extends Node3D
class_name TestRoom02

const PLAYER_SCENE: String = "res://features/movement/scenes/player.tscn"
const DOOR_SCRIPT: String = "res://features/interaction/door.gd"
const RETURN_SCENE: String = "res://features/movement/scenes/game_world.tscn"

var player: PlayerController
var pulse_time: float = 0.0
var _networked: bool = false
var _players: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_networked = multiplayer.has_multiplayer_peer()
	var settings := GameSettingsData.load_saved()
	settings.apply_all(get_viewport())
	settings.apply_visual_settings()
	if _networked:
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_build_environment()
	_build_room()
	_spawn_player_for_peer(multiplayer.get_unique_id(), Vector3(0.0, 0.08, 3.8))
	_build_hud()
	settings.apply_all(get_viewport())
	settings.apply_visual_settings()
	_build_mobile_controls()
	_build_global_chat()
	if _networked and multiplayer.is_server():
		for peer_id in multiplayer.get_peers():
			var spawn := Vector3(float(peer_id % 2) * 1.8 - 0.9, 0.08, 3.8)
			_spawn_player_for_peer(peer_id, spawn)
			rpc("_client_spawn_player", peer_id, spawn)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _build_hud() -> void:
	# HUD lives on a CanvasLayer so it remains fixed to the screen in Room 02.
	# The same HUD is rebuilt after every scene transition.
	var layer := CanvasLayer.new()
	layer.name = "HUDLayer"
	layer.layer = 20
	add_child(layer)

	var crosshair := Label.new()
	crosshair.name = "Crosshair"
	crosshair.text = "+"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8.0, -18.0)
	crosshair.add_theme_font_size_override("font_size", 24)
	crosshair.add_theme_color_override("font_color", Color(0.72, 0.9, 1.0, 0.78))
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

	var hud_path := "res://features/ui/hud/inventory_hud.gd"
	if ResourceLoader.exists(hud_path):
		var hud_script := load(hud_path) as Script
		if hud_script != null:
			var hud_instance := hud_script.new() as Control
			if hud_instance != null:
				layer.add_child(hud_instance)
				if hud_instance.has_method("setup") and player != null:
					hud_instance.setup(player)

	var minimap_script := load("res://features/ui/hud/minimap_hud.gd") as Script
	if minimap_script != null and player != null:
		var minimap := minimap_script.new() as Control
		if minimap != null:
			layer.add_child(minimap)
			minimap.setup(player)
			if minimap.has_method("configure_room"):
				minimap.configure_room("room02")

	var blur_script := load("res://features/ui/hud/motion_blur_controller.gd") as Script
	if blur_script != null and player != null:
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
	pulse_time += delta
	var emergency := get_node_or_null("EmergencyLight") as OmniLight3D
	if emergency != null:
		emergency.light_energy = 0.65 + sin(pulse_time * 2.0) * 0.08

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			if multiplayer.multiplayer_peer != null:
				multiplayer.multiplayer_peer = null
			get_tree().change_scene_to_file("res://features/ui/main_menu/main_menu.tscn")

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#020508")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#28333b")
	environment.ambient_light_energy = 0.18
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("#081015")
	environment.fog_light_energy = 0.35
	environment.fog_density = 0.018
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.0
	world_environment.environment = environment
	add_child(world_environment)
	world_environment.add_to_group("game_environment")

func _build_room() -> void:
	_make_floor()
	_make_wall(Vector3(0.0, 1.5, -6.0), Vector3(5.0, 3.0, 0.3))
	_make_wall(Vector3(0.0, 1.5, 6.0), Vector3(5.0, 3.0, 0.3))
	_make_wall(Vector3(-6.0, 1.5, 0.0), Vector3(0.3, 3.0, 12.0))
	_make_wall(Vector3(6.0, 1.5, 0.0), Vector3(0.3, 3.0, 12.0))

	_make_door(Vector3(0.0, 0.0, -5.72), RETURN_SCENE, "ВЫХОД")
	_make_door(Vector3(0.0, 0.0, 5.72), RETURN_SCENE, "НАЗАД")

	_make_light(Vector3(0.0, 2.7, 0.0), Color("#9ac8df"), 1.2, 8.0)
	_make_emergency_light(Vector3(-4.8, 2.0, -2.0))
	_make_test_table(Vector3(2.0, 0.0, 0.5))
	_make_test_item(Vector3(1.55, 1.28, 0.5), "stick", "res://features/interaction/test_stick.gd", Color("#6d4a32"), 0.85, 0.07)
	_make_test_item(Vector3(2.45, 1.28, 0.5), "wrench", "res://features/interaction/test_wrench.gd", Color("#71808a"), 0.58, 0.075)
	_make_test_item(Vector3(2.95, 1.28, 0.5), "sword", "res://features/interaction/test_item.gd", Color("#aab7c0"), 1.05, 0.045)
	_make_sign(Vector3(0.0, 2.5, 0.0), "ROOM 02 // TEST LAB")

func _spawn_player_for_peer(peer_id: int, spawn_position: Vector3) -> void:
	var node_name := "Player_%d" % peer_id
	if get_node_or_null(node_name) != null:
		return
	var packed_player := load(PLAYER_SCENE) as PackedScene
	if packed_player == null:
		return
	var new_player := packed_player.instantiate() as PlayerController
	if new_player == null:
		return
	new_player.name = node_name
	new_player.position = spawn_position
	new_player.set_multiplayer_authority(peer_id)
	add_child(new_player)
	var interaction := InteractionController.new()
	interaction.name = "InteractionController"
	new_player.add_child(interaction)
	interaction.setup(new_player, new_player.camera)
	_players[peer_id] = new_player
	if peer_id == multiplayer.get_unique_id():
		player = new_player

func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var spawn := Vector3(float(peer_id % 2) * 1.8 - 0.9, 0.08, 3.8)
	_spawn_player_for_peer(peer_id, spawn)
	rpc("_client_spawn_player", peer_id, spawn)

func _on_peer_disconnected(peer_id: int) -> void:
	var node := _players.get(peer_id, null) as Node
	if node != null and is_instance_valid(node):
		node.queue_free()
	_players.erase(peer_id)

@rpc("authority", "reliable", "call_remote", 0)
func _client_spawn_player(peer_id: int, spawn: Vector3) -> void:
	_spawn_player_for_peer(peer_id, spawn)

func _make_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "Floor"
	add_child(body)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(12.0, 0.2, 12.0)
	mesh.mesh = box
	mesh.material_override = _material(Color("#11181c"))
	body.add_child(mesh)
	body.add_child(_collision(Vector3(12.0, 0.2, 12.0)))

func _make_wall(position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = position
	add_child(body)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(Color("#0a1014"))
	body.add_child(mesh)
	body.add_child(_collision(size))

func _make_door(position: Vector3, target: String, title: String) -> void:
	var door := AnimatableBody3D.new()
	door.name = "TransitionDoor"
	door.position = position
	door.set_script(load(DOOR_SCRIPT))
	door.target_scene = target
	door.open_sound = load("res://assets/audio/door_open.wav") as AudioStream
	door.close_sound = load("res://assets/audio/door_close.wav") as AudioStream
	add_child(door)

	var frame := MeshInstance3D.new()
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(1.8, 2.8, 0.22)
	frame.mesh = frame_mesh
	frame.position.y = 1.4
	frame.material_override = _material(Color("#263941"))
	door.add_child(frame)

	var panel := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(1.35, 2.35, 0.12)
	panel.mesh = panel_mesh
	panel.position = Vector3(0.0, 1.25, -0.13)
	panel.material_override = _material(Color("#40515a"))
	door.add_child(panel)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.35, 2.35, 0.16)
	collision.shape = shape
	collision.position = Vector3(0.0, 1.25, -0.13)
	door.add_child(collision)

	var label := Label3D.new()
	label.text = "E // %s" % title
	label.font_size = 32
	label.modulate = Color("#9bd7f1")
	label.position = Vector3(0.0, 2.65, -0.25)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	door.add_child(label)

func _make_light(position: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = true
	light.add_to_group("quality_lights")
	add_child(light)

func _make_emergency_light(position: Vector3) -> void:
	var light := OmniLight3D.new()
	light.name = "EmergencyLight"
	light.position = position
	light.light_color = Color("#b33142")
	light.light_energy = 0.65
	light.omni_range = 5.0
	light.shadow_enabled = true
	light.add_to_group("quality_lights")
	add_child(light)

func _make_test_table(position: Vector3) -> void:
	var table := StaticBody3D.new()
	table.position = position
	add_child(table)

	var top := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(2.2, 0.18, 1.0)
	top.mesh = top_mesh
	top.position.y = 1.0
	top.material_override = _material(Color("#3b2a22"))
	table.add_child(top)
	table.add_child(_collision(Vector3(2.2, 0.18, 1.0), Vector3(0.0, 1.0, 0.0)))

	for x in [-0.85, 0.85]:
		for z in [-0.35, 0.35]:
			var leg := MeshInstance3D.new()
			var leg_mesh := BoxMesh.new()
			leg_mesh.size = Vector3(0.12, 1.0, 0.12)
			leg.mesh = leg_mesh
			leg.position = Vector3(x, 0.5, z)
			leg.material_override = _material(Color("#241b17"))
			table.add_child(leg)

	var label := Label3D.new()
	label.text = "TEST TABLE\nITEMS"
	label.font_size = 28
	label.modulate = Color("#8ab7c9")
	label.position = Vector3(0.0, 1.8, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	table.add_child(label)

func _make_test_item(position: Vector3, item_id: String, script_path: String, color: Color, length: float, radius: float) -> void:
	var item := RigidBody3D.new()
	item.name = "TestItem_%s" % item_id
	item.position = position
	item.set_script(load(script_path))
	add_child(item)
	item.freeze = true

	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius * 0.8
	cylinder.bottom_radius = radius
	cylinder.height = length
	mesh.mesh = cylinder
	mesh.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	mesh.material_override = _material(color)
	item.add_child(mesh)

	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = length
	collision.shape = shape
	collision.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	item.add_child(collision)

func _make_sign(position: Vector3, text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 40
	label.modulate = Color("#6f98a8")
	label.position = position
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	return material

func _collision(size: Vector3, position: Vector3 = Vector3.ZERO) -> CollisionShape3D:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = position
	return collision
