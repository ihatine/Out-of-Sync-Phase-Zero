extends Control
class_name MinimapHUD

var player: PlayerController
var world_size := Vector2(30.0, 24.0)
var map_size := Vector2(210.0, 170.0)
var _door_pos := Vector2(6.0, -5.0)
var _campfire_pos := Vector2(-1.5, 1.2)
var _table_pos := Vector2(2.4, 1.6)
var _room_mode := "main"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	position = Vector2(-236.0, 24.0)
	size = map_size + Vector2(20.0, 42.0)
	add_to_group("hud")
	add_to_group("minimap")
	queue_redraw()

func setup(player_ref: PlayerController) -> void:
	player = player_ref
	queue_redraw()

func configure_room(mode: String) -> void:
	_room_mode = mode
	if mode == "room02":
		world_size = Vector2(12.0, 12.0)
		map_size = Vector2(210.0, 170.0)
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var panel := Rect2(0.0, 0.0, size.x, size.y)
	draw_style_box(_panel_style(), panel)
	var title := ThemeDB.fallback_font
	draw_string(title, Vector2(14.0, 22.0), "МИНИ-КАРТА", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.74, 0.90, 0.98, 0.92))
	var map_rect := Rect2(10.0, 32.0, map_size.x, map_size.y)
	draw_rect(map_rect, Color(0.015, 0.045, 0.058, 0.88), true)
	draw_rect(map_rect, Color(0.34, 0.68, 0.82, 0.36), false, 1.0)
	for x in range(1, 6):
		var px := map_rect.position.x + map_rect.size.x * float(x) / 6.0
		draw_line(Vector2(px, map_rect.position.y), Vector2(px, map_rect.end.y), Color(0.25, 0.45, 0.52, 0.18), 1.0)
	for y in range(1, 5):
		var py := map_rect.position.y + map_rect.size.y * float(y) / 5.0
		draw_line(Vector2(map_rect.position.x, py), Vector2(map_rect.end.x, py), Color(0.25, 0.45, 0.52, 0.18), 1.0)

	var p: Vector2
	if _room_mode == "room02":
		# Room 02 is a compact lab: outline, central work table and two exits.
		draw_rect(map_rect.grow(-5.0), Color(0.26, 0.42, 0.48, 0.45), false, 2.0)
		p = _world_to_map(Vector2(2.0, 0.5), map_rect)
		draw_rect(Rect2(p - Vector2(12, 5), Vector2(24, 10)), Color(0.58, 0.39, 0.27, 0.90), true)
		for z in [-5.72, 5.72]:
			p = _world_to_map(Vector2(0.0, z), map_rect)
			draw_circle(p, 5.0, Color(0.58, 0.82, 0.96, 0.95))
	else:
		# Main street and landmarks.
		var road := _world_to_map(Vector2(-0.8, 0.0), map_rect)
		var road_end := _world_to_map(Vector2(-0.8, 11.0), map_rect)
		draw_line(road, road_end, Color(0.32, 0.48, 0.55, 0.55), 18.0)
		p = _world_to_map(_campfire_pos, map_rect)
		draw_circle(p, 5.0, Color(1.0, 0.55, 0.22, 0.95))
		p = _world_to_map(_table_pos, map_rect)
		draw_rect(Rect2(p - Vector2(5, 3), Vector2(10, 6)), Color(0.58, 0.39, 0.27, 0.90), true)
		p = _world_to_map(_door_pos, map_rect)
		draw_circle(p, 5.0, Color(0.58, 0.82, 0.96, 0.95))

	if player != null:
		p = _world_to_map(Vector2(player.global_position.x, player.global_position.z), map_rect)
		draw_circle(p, 5.5, Color(0.72, 0.92, 1.0, 1.0))
		var dir := Vector2(-sin(player.rotation.y), -cos(player.rotation.y))
		draw_line(p, p + dir * 13.0, Color(0.72, 0.92, 1.0, 0.95), 2.0)

func _world_to_map(pos: Vector2, rect: Rect2) -> Vector2:
	var nx := clampf((pos.x + world_size.x * 0.5) / world_size.x, 0.0, 1.0)
	var nz := clampf((pos.y + world_size.y * 0.5) / world_size.y, 0.0, 1.0)
	return Vector2(rect.position.x + nx * rect.size.x, rect.position.y + nz * rect.size.y)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.006, 0.018, 0.025, 0.82)
	style.border_color = Color(0.32, 0.64, 0.80, 0.40)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style
