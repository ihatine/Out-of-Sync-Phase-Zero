extends Node
class_name GameAudioManager

var _players: Dictionary = {}

func _ready() -> void:
	_ensure_buses()
	for key in ["footstep", "flashlight", "pickup", "switch_item", "drop", "swing"]:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_players[key] = player

func _ensure_buses() -> void:
	if AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
	if AudioServer.get_bus_index("UI") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "UI")

func play(key: String) -> void:
	var player := _players.get(key, null) as AudioStreamPlayer
	if player == null:
		return
	var path := "res://assets/audio/%s.wav" % key
	var stream := load(path) as AudioStream
	if stream == null:
		return
	player.stream = stream
	player.play()
