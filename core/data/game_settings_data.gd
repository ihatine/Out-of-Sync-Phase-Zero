class_name GameSettingsData
extends Resource

const SAVE_PATH: String = "user://out_of_sync_settings.cfg"

@export var resolution: Vector2i = Vector2i(1920, 1080)
@export var fullscreen: bool = false
@export var brightness: float = 1.0
@export var contrast: float = 1.0
@export var gamma: float = 1.0
@export var hud_color: Color = Color(0.48, 0.78, 0.96, 1.0)
@export var hud_enabled: bool = true
@export var minimap_enabled: bool = true
@export var ammo_counter_enabled: bool = true
@export var mouse_sensitivity: float = 1.0
@export var master_volume: float = 1.0
@export var sfx_volume: float = 1.0
@export var ui_volume: float = 1.0
@export var vsync_enabled: bool = false
@export var motion_blur_enabled: bool = true
@export var film_grain: float = 0.25
@export_range(0, 2, 1) var quality_profile: int = 2

var key_bindings: Dictionary = {
	"move_forward": KEY_W,
	"move_backward": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"sprint": KEY_SHIFT,
	"jump": KEY_SPACE,
	"crouch": KEY_CTRL,
	"interact": KEY_E,
	"flashlight": KEY_F,
	"holster_item": KEY_Q,
	"drop_item": KEY_G,
	"slot_1": KEY_1,
	"slot_2": KEY_2,
	"slot_3": KEY_3,
}

static func load_saved() -> GameSettingsData:
	var result := GameSettingsData.new()
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		result._capture_current_display()
		return result
	result.resolution = Vector2i(int(config.get_value("display", "width", 1920)), int(config.get_value("display", "height", 1080)))
	result.fullscreen = bool(config.get_value("display", "fullscreen", false))
	result.vsync_enabled = bool(config.get_value("display", "vsync", false))
	result.motion_blur_enabled = bool(config.get_value("graphics", "motion_blur", true))
	result.film_grain = float(config.get_value("graphics", "film_grain", 0.25))
	result.brightness = float(config.get_value("graphics", "brightness", 1.0))
	result.contrast = float(config.get_value("graphics", "contrast", 1.0))
	result.gamma = float(config.get_value("graphics", "gamma", 1.0))
	result.quality_profile = int(config.get_value("graphics", "quality_profile", 2))
	result.hud_color = Color(str(config.get_value("interface", "hud_color", result.hud_color.to_html(true))))
	result.hud_enabled = bool(config.get_value("interface", "hud_enabled", true))
	result.minimap_enabled = bool(config.get_value("interface", "minimap_enabled", true))
	result.ammo_counter_enabled = bool(config.get_value("interface", "ammo_counter_enabled", true))
	result.mouse_sensitivity = float(config.get_value("controls", "mouse_sensitivity", 1.0))
	result.master_volume = float(config.get_value("audio", "master", 1.0))
	result.sfx_volume = float(config.get_value("audio", "sfx", 1.0))
	result.ui_volume = float(config.get_value("audio", "ui", 1.0))
	for action: String in result.key_bindings.keys():
		result.key_bindings[action] = int(config.get_value("keys", action, result.key_bindings[action]))
	result._clamp_values()
	return result

func save() -> void:
	_clamp_values()
	var config := ConfigFile.new()
	config.set_value("display", "width", resolution.x)
	config.set_value("display", "height", resolution.y)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "vsync", vsync_enabled)
	config.set_value("graphics", "brightness", brightness)
	config.set_value("graphics", "gamma", gamma)
	config.set_value("graphics", "quality_profile", quality_profile)
	config.set_value("graphics", "motion_blur", motion_blur_enabled)
	config.set_value("interface", "hud_color", hud_color.to_html(true))
	config.set_value("interface", "hud_enabled", hud_enabled)
	config.set_value("interface", "minimap_enabled", minimap_enabled)
	config.set_value("interface", "ammo_counter_enabled", ammo_counter_enabled)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("audio", "ui", ui_volume)
	for action: String in key_bindings.keys():
		config.set_value("keys", action, int(key_bindings[action]))
	config.save(SAVE_PATH)

func apply_all(viewport: Viewport = null) -> void:
	_clamp_values()
	apply_display()
	apply_audio()
	apply_input()
	apply_quality(viewport)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED)

func apply_display() -> void:
	# Never change the monitor's video mode. Only resize our game window or
	# switch the window mode. This avoids the fullscreen -> windowed jump.
	if fullscreen:
		# Use the real exclusive fullscreen mode on desktop. Setting the window
		# size first keeps the requested render size available to the viewport.
		DisplayServer.window_set_size(resolution)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)

func apply_audio() -> void:
	_ensure_audio_buses()
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("SFX", sfx_volume)
	_set_bus_volume("UI", ui_volume)

func apply_quality(viewport: Viewport = null) -> void:
	if viewport == null:
		return

	# These are real runtime rendering profiles rather than a cosmetic label:
	# they change 3D render resolution, anti-aliasing and the frame-rate cap.
	# UI remains at native canvas resolution, so text/buttons stay sharp.
	var scale := 1.0
	var fps := 144
	var msaa := Viewport.MSAA_2X
	match quality_profile:
		0: # LOW / weak PC and phones
			scale = 0.65
			fps = 60
			msaa = Viewport.MSAA_DISABLED
		1: # MEDIUM
			scale = 0.82
			fps = 90
			msaa = Viewport.MSAA_2X
		2: # HIGH
			scale = 1.0
			fps = 144
			msaa = Viewport.MSAA_2X

	if OS.has_feature("mobile"):
		scale = minf(scale, 0.82 if quality_profile < 2 else 0.92)
		fps = min(fps, 60)

	viewport.scaling_3d_scale = scale
	viewport.msaa_3d = msaa
	Engine.max_fps = fps
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		for node: Node in tree.get_nodes_in_group("game_environment"):
			if node is WorldEnvironment and (node as WorldEnvironment).environment != null:
				var env := (node as WorldEnvironment).environment
				env.glow_enabled = quality_profile >= 1
				env.fog_enabled = quality_profile >= 1
		for node: Node in tree.get_nodes_in_group("quality_lights"):
			if node is Light3D:
				(node as Light3D).shadow_enabled = quality_profile >= 1

func apply_visual_settings() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	# Apply actual scene-wide visual controls. These are read by the active world
	# through the game_environment group, so changing settings in the menu does
	# not accidentally modify the menu itself.
	for node: Node in tree.get_nodes_in_group("game_environment"):
		if node is WorldEnvironment:
			var world_env := node as WorldEnvironment
			if world_env.environment == null:
				continue
			world_env.environment.adjustment_enabled = true
			world_env.environment.adjustment_brightness = clampf(brightness * gamma, 0.5, 2.0)

	for node: Node in tree.get_nodes_in_group("motion_blur_controller"):
		if node.has_method("set_motion_blur_enabled"):
			node.call("set_motion_blur_enabled", motion_blur_enabled)

	for node: Node in tree.get_nodes_in_group("hud"):
		if node is CanvasItem:
			(node as CanvasItem).visible = hud_enabled

	for node: Node in tree.get_nodes_in_group("minimap"):
		if node is CanvasItem:
			(node as CanvasItem).visible = minimap_enabled and hud_enabled

	for node: Node in tree.get_nodes_in_group("hud_info"):
		if node is CanvasItem:
			(node as CanvasItem).visible = ammo_counter_enabled and hud_enabled

func apply_input() -> void:
	for action: String in key_bindings.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var wanted: Key = int(key_bindings[action]) as Key
		if wanted == KEY_NONE:
			continue
		InputMap.action_erase_events(action)
		var event := InputEventKey.new()
		event.physical_keycode = wanted
		InputMap.action_add_event(action, event)

func set_key_binding(action: String, keycode: Key) -> void:
	# Staged setting: the caller decides when to apply it. This prevents a
	# key from becoming active before the player presses «ПРИМЕНИТЬ».
	key_bindings[action] = int(keycode)

func get_key_binding(action: String) -> Key:
	return int(key_bindings.get(action, KEY_NONE)) as Key

func reset_to_defaults() -> void:
	resolution = Vector2i(1920, 1080)
	fullscreen = false
	brightness = 1.0
	contrast = 1.0
	gamma = 1.0
	hud_color = Color(0.48, 0.78, 0.96, 1.0)
	hud_enabled = true
	minimap_enabled = true
	ammo_counter_enabled = true
	mouse_sensitivity = 1.0
	master_volume = 1.0
	sfx_volume = 1.0
	ui_volume = 1.0
	vsync_enabled = false
	motion_blur_enabled = true
	film_grain = 0.25
	quality_profile = 2
	key_bindings = {
		"move_forward": KEY_W,
		"move_backward": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"sprint": KEY_SHIFT,
		"jump": KEY_SPACE,
		"crouch": KEY_CTRL,
		"interact": KEY_E,
		"flashlight": KEY_F,
		"holster_item": KEY_Q,
		"drop_item": KEY_G,
		"slot_1": KEY_1,
		"slot_2": KEY_2,
		"slot_3": KEY_3,
	}

func _capture_current_display() -> void:
	resolution = DisplayServer.window_get_size()
	fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	vsync_enabled = false

func _clamp_values() -> void:
	brightness = clampf(brightness, 0.50, 1.50)
	contrast = clampf(contrast, 0.50, 1.50)
	gamma = clampf(gamma, 0.50, 2.20)
	mouse_sensitivity = clampf(mouse_sensitivity, 0.10, 5.00)
	master_volume = clampf(master_volume, 0.0, 1.0)
	sfx_volume = clampf(sfx_volume, 0.0, 1.0)
	ui_volume = clampf(ui_volume, 0.0, 1.0)
	film_grain = clampf(film_grain, 0.0, 1.0)
	quality_profile = clampi(quality_profile, 0, 2)

func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
	if AudioServer.get_bus_index("UI") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "UI")

func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear_value, 0.0001)))
