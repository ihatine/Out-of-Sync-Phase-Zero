class_name InteractableDoor
extends AnimatableBody3D

@export var interaction_text_open: String = "Открыть"
@export var interaction_text_close: String = "Закрыть"
@export var open_angle_degrees: float = 92.0
@export var open_speed: float = 5.5
@export var locked: bool = false
@export var starts_open: bool = false
@export var open_sound: AudioStream
@export var close_sound: AudioStream
@export var locked_sound: AudioStream
@export_file("*.tscn") var target_scene: String = ""

var _is_open := false
var _closed_rotation_y := 0.0
var _target_rotation_y := 0.0
var _audio: AudioStreamPlayer3D
var _transitioning := false

func _ready() -> void:
	add_to_group("interactable")
	_closed_rotation_y = rotation.y
	_is_open = starts_open
	_target_rotation_y = _closed_rotation_y + deg_to_rad(open_angle_degrees) if _is_open else _closed_rotation_y
	rotation.y = _target_rotation_y
	_audio = AudioStreamPlayer3D.new()
	_audio.bus = "SFX"
	add_child(_audio)

func _physics_process(delta: float) -> void:
	rotation.y = lerp_angle(rotation.y, _target_rotation_y, 1.0 - exp(-open_speed * delta))

func can_interact(_player: Node) -> bool:
	return true

func get_interaction_text() -> String:
	if locked:
		return "Заперто"
	return interaction_text_close if _is_open else interaction_text_open

func interact(_player: Node) -> void:
	if locked or _transitioning:
		if locked:
			_play_sound(locked_sound)
		return
	if not target_scene.is_empty() and multiplayer.has_multiplayer_peer():
		if multiplayer.is_server():
			_server_open_and_transition(multiplayer.get_unique_id())
		else:
			rpc_id(1, "_server_request_transition")
		return
	_toggle_open()
	if not target_scene.is_empty():
		_transitioning = true
		await get_tree().create_timer(0.35).timeout
		if is_inside_tree() and not target_scene.is_empty():
			get_tree().change_scene_to_file(target_scene)

@rpc("any_peer", "reliable", "call_remote", 0)
func _server_request_transition() -> void:
	if not multiplayer.is_server() or locked or target_scene.is_empty() or _transitioning:
		return
	var requester_id := multiplayer.get_remote_sender_id()
	if requester_id <= 0:
		return
	_server_open_and_transition(requester_id)

func _server_open_and_transition(requester_id: int) -> void:
	if _transitioning or target_scene.is_empty():
		return
	_transitioning = true
	_toggle_open()
	if requester_id == multiplayer.get_unique_id():
		_client_transition(target_scene)
	else:
		rpc_id(requester_id, "_client_transition", target_scene)

@rpc("authority", "reliable", "call_remote", 0)
func _client_transition(scene_path: String) -> void:
	if scene_path.is_empty():
		return
	await get_tree().create_timer(0.35).timeout
	if not is_inside_tree() or scene_path.is_empty():
		return
	get_tree().change_scene_to_file(scene_path)

func _toggle_open() -> void:
	if _is_open:
		_is_open = false
		_target_rotation_y = _closed_rotation_y
		_play_sound(close_sound)
	else:
		_is_open = true
		_target_rotation_y = _closed_rotation_y + deg_to_rad(open_angle_degrees)
		_play_sound(open_sound)

func set_locked(value: bool) -> void:
	locked = value

func _play_sound(stream: AudioStream) -> void:
	if stream == null or _audio == null:
		return
	_audio.stream = stream
	_audio.play()
