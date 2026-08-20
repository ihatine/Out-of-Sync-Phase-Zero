class_name InputBootstrap
extends RefCounted

const ACTIONS: Array[String] = [
    "move_left",
    "move_right",
    "move_up",
    "move_down"
]

static func ensure_registered() -> void:
    _ensure_action("move_left", KEY_A, KEY_LEFT)
    _ensure_action("move_right", KEY_D, KEY_RIGHT)
    _ensure_action("move_up", KEY_W, KEY_UP)
    _ensure_action("move_down", KEY_S, KEY_DOWN)


static func are_registered() -> bool:
    for action_name: String in ACTIONS:
        if not InputMap.has_action(action_name):
            return false
    return true


static func _ensure_action(
    action_name: String,
    primary_key: Key,
    secondary_key: Key
) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)

    if InputMap.action_get_events(action_name).is_empty():
        InputMap.action_add_event(
            action_name,
            _make_key_event(primary_key)
        )
        InputMap.action_add_event(
            action_name,
            _make_key_event(secondary_key)
        )


static func _make_key_event(keycode: Key) -> InputEventKey:
    var event: InputEventKey = InputEventKey.new()
    event.keycode = keycode
    return event
