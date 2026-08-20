class_name MovementSystem
extends RefCounted

var data: PlayerData

func _init(player_data: PlayerData) -> void:
    data = player_data

func update_position(delta: float, viewport_size: Vector2) -> void:
    var input_vector: Vector2 = _read_input()

    data.velocity = input_vector * data.speed
    data.position += data.velocity * delta

    var half_size: Vector2 = Vector2(24.0, 32.0)
    var min_position: Vector2 = half_size
    var max_position: Vector2 = Vector2(
        maxf(viewport_size.x - half_size.x, min_position.x),
        maxf(viewport_size.y - half_size.y, min_position.y)
    )

    data.position.x = clampf(
        data.position.x,
        min_position.x,
        max_position.x
    )
    data.position.y = clampf(
        data.position.y,
        min_position.y,
        max_position.y
    )

    if input_vector.x < 0.0:
        data.last_facing_direction = -1.0
    elif input_vector.x > 0.0:
        data.last_facing_direction = 1.0


func _read_input() -> Vector2:
    if not InputBootstrap.are_registered():
        return Vector2.ZERO

    return Input.get_vector(
        "move_left",
        "move_right",
        "move_up",
        "move_down"
    )
