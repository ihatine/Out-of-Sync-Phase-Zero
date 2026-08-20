extends CharacterBody3D
class_name PlayerController

@export var walk_speed: float = 3.2
@export var sprint_speed: float = 5.4
@export var crouch_speed: float = 1.7
@export var acceleration: float = 18.0
@export var air_acceleration: float = 8.0
@export var jump_velocity: float = 4.2
@export var mouse_sensitivity: float = 0.0025
@export var standing_height: float = 1.8
@export var crouching_height: float = 1.15
@export var standing_camera_height: float = 1.58
@export var crouching_camera_height: float = 1.02
@export var sprint_fov: float = 78.0
@export var normal_fov: float = 74.0
@export var max_hp: float = 100.0
@export var max_flashlight_battery: float = 100.0
@export var flashlight_drain_rate: float = 4.0
@export var flashlight_charge_rate: float = 7.0

@onready var camera: Camera3D = $Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var flashlight: SpotLight3D = $Camera3D/ViewModel/Flashlight
@onready var flashlight_left: SpotLight3D = $Camera3D/LeftViewModel/Flashlight
@onready var right_view: Node3D = $Camera3D/ViewModel
@onready var left_view: Node3D = $Camera3D/LeftViewModel

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
var pitch: float = 0.0
var is_crouching: bool = false
var is_sprinting: bool = false
var flashlight_enabled: bool = true
var hp: float = 100.0
var flashlight_battery: float = 100.0
var _network_send_timer: float = 0.0
var _remote_target_position: Vector3 = Vector3.ZERO
var _remote_target_yaw: float = 0.0
var _remote_target_pitch: float = 0.0
var _remote_flashlight: bool = true
var _standing_shape: CapsuleShape3D
var _crouching_shape: CapsuleShape3D
var _weapon: Node3D
var _attack_cooldown: float = 0.0
var _item_holstered: bool = false
var _inventory_item: String = ""
var _item_anim_tween: Tween
var _view_velocity: Vector2 = Vector2.ZERO
var _bob_time: float = 0.0
var inventory_slot: int = 1
var inventory_items: Dictionary = {}
var _item_definitions: Dictionary = {}
var _current_item_data: ItemData = null
var _audio_manager: GameAudioManager
var _footstep_timer: float = 0.0


func _ready() -> void:
	_ensure_input_actions()
	hp = max_hp
	flashlight_battery = max_flashlight_battery
	if is_multiplayer_authority():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		camera.current = false
		right_view.visible = false
		left_view.visible = false
		_build_remote_body()
	Input.set_use_accumulated_input(false)
	_build_collision_shapes()
	_audio_manager = GameAudioManager.new()
	_audio_manager.name = "AudioManager"
	add_child(_audio_manager)
	_apply_settings_if_available()
	add_to_group("player_controller")
	_register_default_items()
	_sync_hand_layout()

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if _chat_is_open():
		return
	if event is InputEventScreenDrag:
		apply_touch_look((event as InputEventScreenDrag).relative)
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not get_tree().paused:
		var motion := event as InputEventMouseMotion
		_view_velocity = _view_velocity.lerp(motion.relative, 1.0 - exp(-24.0 * get_process_delta_time()))
		rotate_y(-motion.relative.x * mouse_sensitivity)
		pitch = clampf(pitch - motion.relative.y * mouse_sensitivity, deg_to_rad(-88.0), deg_to_rad(88.0))
		camera.rotation.x = pitch
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not get_tree().paused:
		_attack()

func _chat_is_open() -> bool:
	var chat := get_tree().get_first_node_in_group("global_chat")
	return chat != null and chat.has_method("is_chat_open") and chat.is_chat_open()

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	if not is_multiplayer_authority():
		_remote_target_position = _remote_target_position if _remote_target_position != Vector3.ZERO else global_position
		global_position = global_position.lerp(_remote_target_position, 1.0 - exp(-14.0 * delta))
		rotation.y = lerp_angle(rotation.y, _remote_target_yaw, 1.0 - exp(-14.0 * delta))
		var remote_body := get_node_or_null("RemoteBody") as Node3D
		if remote_body != null:
			remote_body.rotation.x = lerpf(remote_body.rotation.x, _remote_target_pitch * 0.18, 1.0 - exp(-10.0 * delta))
		return
	if _chat_is_open():
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		if is_on_floor():
			velocity.y = -0.2
		else:
			velocity.y -= gravity * delta
		move_and_slide()
		is_sprinting = false
		return
	_update_stance(delta)
	_update_movement(delta)
	move_and_slide()
	_update_footsteps(delta)
	_update_camera(delta)
	_update_weapon(delta)
	_update_viewmodel(delta)
	_update_item_animation(delta)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_update_flashlight_battery(delta)
	_network_send_timer -= delta
	if multiplayer.has_multiplayer_peer() and _network_send_timer <= 0.0:
		_network_send_timer = 0.05
		rpc("_receive_network_transform", global_position, rotation.y, pitch)
	if Input.is_action_just_pressed("flashlight"):
		toggle_flashlight()
	if Input.is_action_just_pressed("holster_item"):
		holster_item()
	if Input.is_action_just_pressed("drop_item"):
		drop_item()
	if Input.is_action_just_pressed("slot_1"):
		select_inventory_slot(1)
	if Input.is_action_just_pressed("slot_2"):
		select_inventory_slot(2)
	if Input.is_action_just_pressed("slot_3"):
		select_inventory_slot(3)

func _update_movement(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching and direction.length_squared() > 0.01
	var target_speed := crouch_speed if is_crouching else (sprint_speed if is_sprinting else walk_speed)
	var target_velocity := direction * target_speed
	var blend := acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, blend * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, blend * delta)

	if is_on_floor():
		if Input.is_action_just_pressed("jump") and not is_crouching:
			velocity.y = jump_velocity
		elif velocity.y < 0.0:
			velocity.y = -0.2
	else:
		velocity.y -= gravity * delta

func _update_stance(delta: float) -> void:
	var wants_crouch := Input.is_action_pressed("crouch")
	if wants_crouch:
		is_crouching = true
	elif _can_stand():
		is_crouching = false

	var target_height := crouching_height if is_crouching else standing_height
	var target_camera_y := crouching_camera_height if is_crouching else standing_camera_height
	var current_height := float(collision_shape.shape.height)
	var new_height := move_toward(current_height, target_height, 10.0 * delta)
	collision_shape.shape.height = new_height
	collision_shape.position.y = new_height * 0.5
	camera.position.y = move_toward(camera.position.y, target_camera_y, 10.0 * delta)

func _can_stand() -> bool:
	if not is_crouching:
		return true
	var space_state := get_world_3d().direct_space_state
	var from := global_position + Vector3.UP * crouching_height
	var to := global_position + Vector3.UP * standing_height
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	return space_state.intersect_ray(query).is_empty()

func _update_camera(delta: float) -> void:
	var target_fov := sprint_fov if is_sprinting else normal_fov
	camera.fov = lerpf(camera.fov, target_fov, minf(delta * 8.0, 1.0))

func _build_collision_shapes() -> void:
	_standing_shape = CapsuleShape3D.new()
	_standing_shape.radius = 0.32
	_standing_shape.height = standing_height
	_crouching_shape = CapsuleShape3D.new()
	_crouching_shape.radius = 0.32
	_crouching_shape.height = crouching_height
	collision_shape.shape = _standing_shape
	collision_shape.position.y = standing_height * 0.5

func _apply_settings_if_available() -> void:
	var settings := GameSettingsData.load_saved()
	settings.apply_input()
	apply_settings(settings)

func apply_settings(settings: GameSettingsData) -> void:
	if settings == null:
		return
	apply_mouse_sensitivity(settings.mouse_sensitivity)

func apply_mouse_sensitivity(value: float) -> void:
	# Settings stores a human-friendly 0.10..5.00 value.
	# Convert it to radians-per-pixel here so the full slider range is useful.
	mouse_sensitivity = clampf(value * 0.0025, 0.00025, 0.0125)

func toggle_flashlight() -> void:
	if not flashlight_enabled and flashlight_battery <= 0.5:
		return
	flashlight_enabled = not flashlight_enabled
	if _audio_manager != null:
		_audio_manager.play("flashlight")
	_sync_hand_layout()

func apply_settings_data(settings: GameSettingsData) -> void:
	apply_settings(settings)

func has_weapon() -> bool:
	return _weapon != null and _weapon.visible and not _item_holstered

func _register_default_items() -> void:
	var stick := ItemData.new()
	stick.item_id = "stick"
	stick.display_name = "Палка"
	stick.equip_time = 0.20
	stick.holster_time = 0.16
	stick.attack_time = 0.28
	stick.grip_position = Vector3(0.20, -0.22, -0.58)
	stick.grip_rotation = Vector3(-0.9, 0.0, 0.35)
	stick.mesh_color = Color("#6d4a32")
	stick.mesh_length = 0.72
	stick.mesh_radius = 0.055
	_item_definitions[stick.item_id] = stick

	var wrench := ItemData.new()
	wrench.item_id = "wrench"
	wrench.display_name = "Гаечный ключ"
	wrench.equip_time = 0.28
	wrench.holster_time = 0.20
	wrench.attack_time = 0.38
	wrench.grip_position = Vector3(0.22, -0.24, -0.60)
	wrench.grip_rotation = Vector3(-0.75, 0.08, 0.42)
	wrench.attack_rotation = Vector3(0.85, -0.18, -0.55)
	wrench.mesh_color = Color("#71808a")
	wrench.mesh_length = 0.58
	wrench.mesh_radius = 0.075
	_item_definitions[wrench.item_id] = wrench

	var sword := ItemData.new()
	sword.item_id = "sword"
	sword.display_name = "Меч"
	sword.equip_time = 0.34
	sword.holster_time = 0.24
	sword.attack_time = 0.52
	sword.grip_position = Vector3(0.22, -0.18, -0.68)
	sword.grip_rotation = Vector3(-0.92, -0.10, 0.22)
	sword.attack_rotation = Vector3(1.15, -0.35, -1.15)
	sword.mesh_color = Color("#aab7c0")
	sword.mesh_length = 1.05
	sword.mesh_radius = 0.045
	_item_definitions[sword.item_id] = sword

func get_item_data(item_id: String) -> ItemData:
	return _item_definitions.get(item_id, null) as ItemData

func get_pickup_target() -> Node3D:
	var hand := right_view.get_node_or_null("Hand") as Node3D
	return hand if hand != null else right_view

func equip_stick() -> bool:
	return equip_item("stick")

func equip_item(item_id: String, target_slot_override: int = 0) -> bool:
	var data := get_item_data(item_id)
	if data == null:
		return false

	# Never overwrite an occupied inventory slot during pickup. If the
	# currently selected slot is occupied, use the first free slot. When all
	# three slots are full, reject the pickup so the world item remains.
	var target_slot := inventory_slot if target_slot_override <= 0 else target_slot_override
	if target_slot < 1 or target_slot > 3:
		return false
	if target_slot_override <= 0 and not str(inventory_items.get(target_slot, "")).is_empty():
		target_slot = _find_empty_inventory_slot()
		if target_slot == 0:
			return false

	if _item_anim_tween != null and _item_anim_tween.is_valid():
		_item_anim_tween.kill()
		_item_anim_tween = null

	inventory_items[target_slot] = item_id
	inventory_slot = target_slot
	_inventory_item = item_id
	_current_item_data = data
	_item_holstered = false

	if _weapon != null and is_instance_valid(_weapon):
		_weapon.queue_free()
		_weapon = null
	_create_held_item(data)
	_attach_item_to_hand()
	_play_item_transition(true)
	_sync_hand_layout()
	if _audio_manager != null:
		_audio_manager.play("pickup" if target_slot_override <= 0 else "switch_item")
	return true

func _find_empty_inventory_slot() -> int:
	for slot in [1, 2, 3]:
		if str(inventory_items.get(slot, "")).is_empty():
			return slot
	return 0

func select_inventory_slot(slot: int) -> void:
	if slot < 1 or slot > 3:
		return
	inventory_slot = slot
	if _audio_manager != null:
		_audio_manager.play("switch_item")
	var item_id: String = str(inventory_items.get(slot, ""))
	if item_id.is_empty():
		holster_item()
		return
	equip_item(item_id, slot)

func holster_item() -> void:
	if _inventory_item.is_empty() or _weapon == null:
		return
	_item_holstered = true
	_play_item_transition(false)
	_sync_hand_layout()

func drop_item() -> void:
	if _inventory_item.is_empty() or _weapon == null:
		return

	var item_id := _inventory_item
	var data := get_item_data(item_id)
	if data == null:
		return

	var dropped := RigidBody3D.new()
	dropped.name = "Dropped_%s" % item_id.capitalize()
	dropped.set_script(load("res://features/interaction/test_item.gd"))
	dropped.set("item_id", item_id)
	dropped.set("display_name", data.display_name)
	dropped.set("mesh_color", data.mesh_color)
	dropped.set("mesh_length", data.mesh_length)
	dropped.set("mesh_radius", data.mesh_radius)
	get_tree().current_scene.add_child(dropped)

	# Только после add_child() читаем/назначаем global_position.
	dropped.global_position = global_position + (-global_transform.basis.z * 0.9) + Vector3.UP * 0.9

	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = data.mesh_radius * 0.8
	cylinder.bottom_radius = data.mesh_radius
	cylinder.height = data.mesh_length
	mesh.mesh = cylinder
	mesh.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = data.mesh_color
	material.roughness = 0.95
	mesh.material_override = material
	dropped.add_child(mesh)

	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = data.mesh_radius
	shape.height = data.mesh_length
	collision.shape = shape
	collision.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	dropped.add_child(collision)

	dropped.linear_velocity = -global_transform.basis.z * 1.5 + Vector3.UP * 0.8

	inventory_items.erase(inventory_slot)
	_inventory_item = ""
	_current_item_data = null
	_item_holstered = false
	if _audio_manager != null:
		_audio_manager.play("drop")
	_weapon.visible = false
	_sync_hand_layout()

func _create_held_item(data: ItemData) -> void:
	if _weapon != null:
		_weapon.queue_free()
		_weapon = null

	_weapon = Node3D.new()
	_weapon.name = "HeldItem_%s" % data.item_id
	right_view.add_child(_weapon)
	_weapon.position = data.grip_position
	_weapon.rotation = data.grip_rotation

	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = data.mesh_radius * 0.8
	cylinder.bottom_radius = data.mesh_radius
	cylinder.height = data.mesh_length
	mesh.mesh = cylinder
	mesh.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = data.mesh_color
	material.roughness = 0.92
	mesh.material_override = material
	_weapon.add_child(mesh)
	_weapon.visible = false

func _attach_item_to_hand() -> void:
	if _weapon == null or _current_item_data == null:
		return
	if _weapon.get_parent() != right_view:
		_weapon.reparent(right_view, true)
	_weapon.position = _current_item_data.grip_position
	_weapon.rotation = _current_item_data.grip_rotation

func _play_item_transition(equipping: bool) -> void:
	if _weapon == null or _current_item_data == null:
		return
	if _item_anim_tween != null and _item_anim_tween.is_valid():
		_item_anim_tween.kill()

	# Capture the exact weapon instance. Otherwise a delayed holster callback
	# can hide the NEW item after the player switches slots/items quickly.
	var weapon_instance: Node3D = _weapon
	var item_data: ItemData = _current_item_data

	_item_anim_tween = create_tween()
	_item_anim_tween.set_trans(Tween.TRANS_QUAD)
	_item_anim_tween.set_ease(Tween.EASE_OUT)

	var grip := item_data.grip_position
	var grip_rot := item_data.grip_rotation
	if equipping:
		weapon_instance.visible = true
		weapon_instance.position = grip + Vector3(0.08, -0.20, 0.18)
		weapon_instance.rotation = grip_rot + Vector3(-0.35, 0.18, 0.25)
		_item_anim_tween.tween_property(weapon_instance, "position", grip, item_data.equip_time)
		_item_anim_tween.parallel().tween_property(weapon_instance, "rotation", grip_rot, item_data.equip_time)
	else:
		_item_anim_tween.tween_property(weapon_instance, "position", grip + Vector3(0.12, -0.16, 0.16), item_data.holster_time)
		_item_anim_tween.parallel().tween_property(weapon_instance, "rotation", grip_rot + Vector3(-0.25, 0.12, 0.18), item_data.holster_time)
		_item_anim_tween.tween_callback(func():
			if is_instance_valid(weapon_instance):
				weapon_instance.visible = false
		)

func _update_item_animation(delta: float) -> void:
	if _weapon == null or not _weapon.visible or _attack_cooldown > 0.0 or _current_item_data == null:
		return
	var sway := Vector3(-_view_velocity.y, -_view_velocity.x, 0.0) * 0.00035
	var target := _current_item_data.grip_position + sway
	_weapon.position = _weapon.position.lerp(target, 1.0 - exp(-14.0 * delta))

func apply_touch_look(relative: Vector2) -> void:
	if not is_multiplayer_authority():
		return
	rotate_y(-relative.x * mouse_sensitivity * 0.75)
	pitch = clampf(pitch - relative.y * mouse_sensitivity * 0.75, deg_to_rad(-88.0), deg_to_rad(88.0))
	camera.rotation.x = pitch

func attack_virtual() -> void:
	_attack()

func _build_remote_body() -> void:
	if get_node_or_null("RemoteBody") != null:
		return
	var root := Node3D.new()
	root.name = "RemoteBody"
	add_child(root)

	# A simple low-poly humanoid made from proper body parts instead of the
	# old capsule placeholder. It is intentionally neutral so every player
	# has the same default body in co-op.
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("#a56d4a")
	skin.roughness = 0.82
	var skin_dark := StandardMaterial3D.new()
	skin_dark.albedo_color = Color("#70452f")
	skin_dark.roughness = 0.88
	var jacket := StandardMaterial3D.new()
	jacket.albedo_color = Color("#11181c")
	jacket.roughness = 0.92
	var jacket2 := StandardMaterial3D.new()
	jacket2.albedo_color = Color("#1b252a")
	jacket2.roughness = 0.86
	var pants := StandardMaterial3D.new()
	pants.albedo_color = Color("#0b1013")
	pants.roughness = 0.94
	var boots := StandardMaterial3D.new()
	boots.albedo_color = Color("#090b0c")
	boots.roughness = 0.82
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("#20282c")
	metal.metallic = 0.72
	metal.roughness = 0.30
	var lens_mat := StandardMaterial3D.new()
	lens_mat.albedo_color = Color("#8fdcff")
	lens_mat.emission_enabled = true
	lens_mat.emission = Color("#4fc5ff")
	lens_mat.emission_energy_multiplier = 3.0

	# Hips / torso
	var hips := MeshInstance3D.new()
	var hips_mesh := BoxMesh.new()
	hips_mesh.size = Vector3(0.62, 0.30, 0.36)
	hips.mesh = hips_mesh
	hips.material_override = pants
	hips.position = Vector3(0.0, 0.72, 0.0)
	root.add_child(hips)

	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.31
	torso_mesh.height = 0.88
	torso.mesh = torso_mesh
	torso.material_override = jacket
	torso.position = Vector3(0.0, 1.18, 0.0)
	root.add_child(torso)

	# Collar
	var collar := MeshInstance3D.new()
	var collar_mesh := CylinderMesh.new()
	collar_mesh.top_radius = 0.18
	collar_mesh.bottom_radius = 0.22
	collar_mesh.height = 0.16
	collar.mesh = collar_mesh
	collar.material_override = jacket2
	collar.position = Vector3(0.0, 1.65, 0.0)
	root.add_child(collar)

	# Head + neck
	var neck := MeshInstance3D.new()
	var neck_mesh := CylinderMesh.new()
	neck_mesh.top_radius = 0.105
	neck_mesh.bottom_radius = 0.12
	neck_mesh.height = 0.20
	neck.mesh = neck_mesh
	neck.material_override = skin_dark
	neck.position = Vector3(0.0, 1.76, 0.0)
	root.add_child(neck)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.285
	head_mesh.height = 0.56
	head.mesh = head_mesh
	head.material_override = skin
	head.position = Vector3(0.0, 2.02, 0.0)
	root.add_child(head)

	# Hair block gives the silhouette a readable human head.
	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.295
	hair_mesh.height = 0.38
	hair.mesh = hair_mesh
	hair.material_override = boots
	hair.position = Vector3(0.0, 2.19, 0.035)
	hair.scale = Vector3(1.0, 0.58, 1.0)
	root.add_child(hair)

	# Legs
	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.115
		leg_mesh.height = 0.72
		leg.mesh = leg_mesh
		leg.material_override = pants
		leg.position = Vector3(0.19 * side, 0.39, 0.0)
		root.add_child(leg)

		var boot := MeshInstance3D.new()
		var boot_mesh := BoxMesh.new()
		boot_mesh.size = Vector3(0.25, 0.16, 0.42)
		boot.mesh = boot_mesh
		boot.material_override = boots
		boot.position = Vector3(0.19 * side, 0.08, -0.07)
		root.add_child(boot)

		# Upper arm, forearm, palm and four readable fingers.
		var upper := MeshInstance3D.new()
		var upper_mesh := CapsuleMesh.new()
		upper_mesh.radius = 0.095
		upper_mesh.height = 0.40
		upper.mesh = upper_mesh
		upper.material_override = jacket
		upper.position = Vector3(0.40 * side, 1.40, -0.01)
		upper.rotation_degrees = Vector3(0.0, 0.0, -8.0 * side)
		root.add_child(upper)

		var forearm := MeshInstance3D.new()
		var forearm_mesh := CapsuleMesh.new()
		forearm_mesh.radius = 0.082
		forearm_mesh.height = 0.38
		forearm.mesh = forearm_mesh
		forearm.material_override = jacket2
		forearm.position = Vector3(0.46 * side, 1.13, -0.12)
		forearm.rotation_degrees = Vector3(-24.0, 0.0, -12.0 * side)
		root.add_child(forearm)

		var palm := MeshInstance3D.new()
		var palm_mesh := SphereMesh.new()
		palm_mesh.radius = 0.115
		palm_mesh.height = 0.23
		palm.mesh = palm_mesh
		palm.material_override = skin
		palm.scale = Vector3(0.90, 1.05, 1.25)
		palm.position = Vector3(0.50 * side, 0.91, -0.24)
		root.add_child(palm)

		for finger_index in range(4):
			var finger := MeshInstance3D.new()
			var finger_mesh := CapsuleMesh.new()
			finger_mesh.radius = 0.027
			finger_mesh.height = 0.16
			finger.mesh = finger_mesh
			finger.material_override = skin
			var lateral := (float(finger_index) - 1.5) * 0.045
			finger.position = Vector3(0.50 * side + lateral * side, 0.89, -0.36 - absf(float(finger_index) - 1.5) * 0.012)
			finger.rotation_degrees = Vector3(-72.0, 0.0, 0.0)
			root.add_child(finger)

		var thumb := MeshInstance3D.new()
		var thumb_mesh := CapsuleMesh.new()
		thumb_mesh.radius = 0.032
		thumb_mesh.height = 0.15
		thumb.mesh = thumb_mesh
		thumb.material_override = skin
		thumb.position = Vector3(0.61 * side, 0.92, -0.28)
		thumb.rotation_degrees = Vector3(-55.0, 0.0, 34.0 * side)
		root.add_child(thumb)

	# Flashlight held naturally in the right hand.
	var flashlight := Node3D.new()
	flashlight.name = "RemoteFlashlight"
	flashlight.position = Vector3(0.57, 0.92, -0.38)
	flashlight.rotation_degrees = Vector3(72.0, 0.0, 0.0)
	root.add_child(flashlight)

	var flashlight_body := MeshInstance3D.new()
	var flashlight_mesh := CylinderMesh.new()
	flashlight_mesh.top_radius = 0.06
	flashlight_mesh.bottom_radius = 0.085
	flashlight_mesh.height = 0.48
	flashlight_body.mesh = flashlight_mesh
	flashlight_body.material_override = metal
	flashlight.add_child(flashlight_body)

	var flashlight_head := MeshInstance3D.new()
	var head_mesh2 := CylinderMesh.new()
	head_mesh2.top_radius = 0.105
	head_mesh2.bottom_radius = 0.105
	head_mesh2.height = 0.12
	flashlight_head.mesh = head_mesh2
	flashlight_head.position = Vector3(0.0, 0.0, -0.28)
	flashlight_head.material_override = metal
	flashlight.add_child(flashlight_head)

	var lens := MeshInstance3D.new()
	var lens_mesh := CylinderMesh.new()
	lens_mesh.top_radius = 0.082
	lens_mesh.bottom_radius = 0.082
	lens_mesh.height = 0.012
	lens.mesh = lens_mesh
	lens.position = Vector3(0.0, 0.0, -0.345)
	lens.material_override = lens_mat
	flashlight.add_child(lens)

	var light := SpotLight3D.new()
	light.name = "RemoteFlashlightLight"
	light.position = Vector3(0.0, 0.0, -0.48)
	light.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	light.light_color = Color(0.78, 0.91, 1.0)
	light.light_energy = 4.5
	light.spot_range = 14.0
	light.spot_angle = 28.0
	light.visible = false
	flashlight.add_child(light)

func _update_footsteps(delta: float) -> void:
	if not is_on_floor():
		_footstep_timer = 0.0
		return
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed < 0.6:
		_footstep_timer = 0.0
		return
	_footstep_timer -= delta
	if _footstep_timer <= 0.0:
		_footstep_timer = 0.30 if is_sprinting else 0.43
		if _audio_manager != null:
			_audio_manager.play("footstep")

func _update_flashlight_battery(delta: float) -> void:
	if flashlight_enabled and flashlight_battery > 0.0:
		flashlight_battery = maxf(0.0, flashlight_battery - flashlight_drain_rate * delta)
		if flashlight_battery <= 0.0:
			flashlight_enabled = false
	else:
		flashlight_battery = minf(max_flashlight_battery, flashlight_battery + flashlight_charge_rate * delta)
	_sync_hand_layout()

@rpc("any_peer", "unreliable", "call_remote", 0)
func _receive_network_transform(position_value: Vector3, yaw: float, pitch_value: float, flashlight_on: bool = true) -> void:
	if is_multiplayer_authority():
		return
	_remote_target_position = position_value
	_remote_target_yaw = yaw
	_remote_target_pitch = pitch_value
	_remote_flashlight = flashlight_on
	var remote_light := get_node_or_null("RemoteBody/RemoteFlashlightLight") as SpotLight3D
	if remote_light != null:
		remote_light.visible = _remote_flashlight

func _attack() -> void:
	if _attack_cooldown > 0.0 or not has_weapon() or _current_item_data == null:
		return
	_attack_cooldown = _current_item_data.attack_time
	if _audio_manager != null:
		_audio_manager.play("swing")
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	var base_rot: Vector3 = _current_item_data.grip_rotation
	_weapon.rotation = base_rot + _current_item_data.attack_rotation
	tween.tween_property(_weapon, "rotation", base_rot, 0.12)

func _update_weapon(_delta: float) -> void:
	if _weapon == null or not _weapon.visible or _attack_cooldown > 0.0:
		return
	var bob := sin(_bob_time) * (0.008 if is_sprinting else 0.004)
	_weapon.position.y = lerpf(_weapon.position.y, -0.22 + bob, 0.10)

func _update_viewmodel(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	_bob_time += delta * (10.0 if is_sprinting else 7.0)
	var moving: bool = Vector2(velocity.x, velocity.z).length() > 0.15 and is_on_floor()
	var bob_strength: float = 0.012 if moving else 0.003
	var bob_x: float = sin(_bob_time * 0.5) * bob_strength
	var bob_y: float = absf(cos(_bob_time)) * bob_strength
	var sway_x: float = clampf(-_view_velocity.x * 0.00018, -0.035, 0.035)
	var sway_y: float = clampf(-_view_velocity.y * 0.00018, -0.035, 0.035)

	var right_target: Vector3 = Vector3(0.34 + sway_x + bob_x, -0.34 - bob_y + sway_y, -0.62)
	var left_target: Vector3 = Vector3(-0.34 - sway_x - bob_x, -0.34 - bob_y + sway_y, -0.62)
	right_view.position = right_view.position.lerp(right_target, 1.0 - exp(-12.0 * delta))
	left_view.position = left_view.position.lerp(left_target, 1.0 - exp(-12.0 * delta))

	# Reduce mouse-motion memory smoothly to avoid abrupt viewmodel snapping.
	_view_velocity = _view_velocity.lerp(Vector2.ZERO, 1.0 - exp(-10.0 * delta))

func _sync_hand_layout() -> void:
	var holding_item := not _inventory_item.is_empty() and not _item_holstered
	var right_flashlight_active := flashlight_enabled and not holding_item
	var left_flashlight_active := flashlight_enabled and holding_item

	if flashlight != null:
		flashlight.visible = right_flashlight_active
		flashlight.light_energy = 3.2 if right_flashlight_active else 0.0
	if flashlight_left != null:
		flashlight_left.visible = left_flashlight_active
		flashlight_left.light_energy = 3.2 if left_flashlight_active else 0.0
	if right_view != null:
		right_view.visible = true
	if left_view != null:
		left_view.visible = true

	var right_flashlight_visual := right_view.get_node_or_null("FlashlightBody")
	var right_flashlight_head := right_view.get_node_or_null("FlashlightHead")
	var right_lens := right_view.get_node_or_null("Lens")
	var left_flashlight_visual := left_view.get_node_or_null("FlashlightBody")
	var left_flashlight_head := left_view.get_node_or_null("FlashlightHead")
	var left_lens := left_view.get_node_or_null("Lens")

	# The flashlight itself stays in the hand when switched off; only the
	# actual light source/lens glow is disabled. This prevents the flashlight
	# model from visually disappearing on F.
	for node in [right_flashlight_visual, right_flashlight_head]:
		if node != null:
			node.visible = not holding_item
	if right_lens != null:
		right_lens.visible = (not holding_item) and flashlight_enabled
	for node in [left_flashlight_visual, left_flashlight_head]:
		if node != null:
			node.visible = holding_item
	if left_lens != null:
		left_lens.visible = holding_item and flashlight_enabled

	if _weapon != null:
		_weapon.visible = holding_item

func _ensure_input_actions() -> void:
	_ensure_key_action("move_forward", KEY_W)
	_ensure_key_action("move_backward", KEY_S)
	_ensure_key_action("move_left", KEY_A)
	_ensure_key_action("move_right", KEY_D)
	_ensure_key_action("jump", KEY_SPACE)
	_ensure_key_action("crouch", KEY_CTRL)
	_ensure_key_action("sprint", KEY_SHIFT)
	_ensure_key_action("interact", KEY_E)
	_ensure_key_action("flashlight", KEY_F)
	_ensure_key_action("holster_item", KEY_Q)
	_ensure_key_action("drop_item", KEY_G)
	_ensure_key_action("slot_1", KEY_1)
	_ensure_key_action("slot_2", KEY_2)
	_ensure_key_action("slot_3", KEY_3)

func _ensure_key_action(action: StringName, keycode: Key) -> void:
	# Only create a default binding when the action does not exist yet.
	# Existing user bindings must never be overwritten or supplemented with defaults.
	if InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty():
		return
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = keycode
	InputMap.action_add_event(action, key_event)
