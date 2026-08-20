class_name PlayerView
extends Node2D

@export var player_data: PlayerData

var sprite: Sprite2D


func _ready() -> void:
    sprite = Sprite2D.new()
    sprite.texture = _make_placeholder_texture()
    sprite.centered = true
    add_child(sprite)


func _process(_delta: float) -> void:
    update_from_data()


func update_from_data() -> void:
    if player_data == null or sprite == null:
        return

    global_position = player_data.position

    if player_data.last_facing_direction < 0.0:
        sprite.flip_h = true
    elif player_data.last_facing_direction > 0.0:
        sprite.flip_h = false


func _make_placeholder_texture() -> Texture2D:
    var image: Image = Image.create(
        48,
        64,
        false,
        Image.FORMAT_RGBA8
    )

    image.fill(Color("#b8c0c8"))

    return ImageTexture.create_from_image(image)
