class_name InteractionController
extends Node

@export var interaction_distance: float = 2.75
@export var collision_mask: int = 1
@export var action_name: StringName = &"interact"

var _player: PlayerController
var _camera: Camera3D
var _raycast: RayCast3D
var _prompt: InteractionPrompt
var _current: Node

func setup(player: PlayerController, camera: Camera3D) -> void:
	_player = player
	_camera = camera
	_ensure_action()
	_raycast = RayCast3D.new()
	_raycast.name = "InteractionRayCast"
	_raycast.enabled = true
	_raycast.collide_with_areas = true
	_raycast.collide_with_bodies = true
	_raycast.collision_mask = collision_mask
	_raycast.target_position = Vector3(0.0, 0.0, -interaction_distance)
	_camera.add_child(_raycast)
	_prompt = InteractionPrompt.new()
	_player.add_child(_prompt)

func _process(_delta: float) -> void:
	if _player == null or not _player.is_multiplayer_authority() or _camera == null or get_tree().paused:
		_clear_current()
		return
	_raycast.global_transform = _camera.global_transform
	_raycast.target_position = Vector3(0.0, 0.0, -interaction_distance)
	_raycast.force_raycast_update()
	var candidate: Node = _find_interactable(_raycast.get_collider())
	if candidate == null or not candidate.has_method("can_interact") or not candidate.can_interact(_player):
		_clear_current()
		return
	_current = candidate
	_prompt.show_prompt(str(candidate.get_interaction_text()))
	if Input.is_action_just_pressed(action_name):
		candidate.interact(_player)
		_prompt.show_prompt(str(candidate.get_interaction_text()))

func _find_interactable(collider: Object) -> Node:
	var node := collider as Node
	while node != null:
		if node.is_in_group("interactable") and node.has_method("interact") and node.has_method("get_interaction_text"):
			return node
		node = node.get_parent()
	return null

func _clear_current() -> void:
	_current = null
	if _prompt != null:
		_prompt.hide_prompt()

func _ensure_action() -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventKey and (event as InputEventKey).keycode == KEY_E:
			return
	var key := InputEventKey.new()
	key.keycode = KEY_E
	InputMap.action_add_event(action_name, key)
