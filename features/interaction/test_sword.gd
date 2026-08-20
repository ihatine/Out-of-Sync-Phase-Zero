extends "res://features/interaction/test_item.gd"
class_name InteractableSword

func _ready() -> void:
	item_id = "sword"
	display_name = "меч"
	mesh_color = Color("#aab7c0")
	mesh_length = 1.05
	mesh_radius = 0.045
	super._ready()
