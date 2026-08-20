extends "res://features/interaction/test_item.gd"
class_name InteractableWrench

func _ready() -> void:
	item_id = "wrench"
	display_name = "гаечный ключ"
	mesh_color = Color("#71808a")
	mesh_length = 0.58
	mesh_radius = 0.075
	super._ready()
