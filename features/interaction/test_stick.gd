extends "res://features/interaction/test_item.gd"
class_name InteractableStick

func _ready() -> void:
	item_id = "stick"
	display_name = "палку"
	mesh_color = Color("#6d4a32")
	mesh_length = 0.85
	mesh_radius = 0.07
	super._ready()
