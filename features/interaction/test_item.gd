extends RigidBody3D
class_name TestItem

@export var item_id: String = "stick"
@export var display_name: String = "Предмет"
@export var mesh_color: Color = Color("#6d4a32")
@export var mesh_length: float = 0.72
@export var mesh_radius: float = 0.055

var _taken: bool = false

func _ready() -> void:
	add_to_group("interactable")
	gravity_scale = 1.0
	contact_monitor = true

func can_interact(_player: Node) -> bool:
	return not _taken

func get_interaction_text() -> String:
	return "Взять %s [E]" % display_name

func interact(player: Node) -> void:
	if _taken or player == null or not player.has_method("equip_item"):
		return

	_taken = true
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0

	var target: Node3D = null
	if player.has_method("get_pickup_target"):
		target = player.call("get_pickup_target") as Node3D

	if target != null and is_inside_tree():
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "global_position", target.global_position, 0.18)
		tween.parallel().tween_property(self, "global_rotation", target.global_rotation, 0.18)
		tween.tween_callback(Callable(self, "_finish_pickup").bind(player))
	else:
		_finish_pickup(player)

func _finish_pickup(player: Node) -> void:
	if is_instance_valid(player) and player.has_method("equip_item"):
		if bool(player.call("equip_item", item_id)):
			queue_free()
			return

	_taken = false
	collision_layer = 1
	collision_mask = 1
	freeze = false
