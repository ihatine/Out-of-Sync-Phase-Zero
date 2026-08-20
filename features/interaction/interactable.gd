class_name Interactable
extends Node3D

@export var interaction_text: String = "Взаимодействовать"
@export var interaction_enabled: bool = true

func _ready() -> void:
	add_to_group("interactable")

func can_interact(_player: Node) -> bool:
	return interaction_enabled

func get_interaction_text() -> String:
	return interaction_text

func interact(_player: Node) -> void:
	pass
