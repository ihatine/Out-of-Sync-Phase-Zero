class_name GlassButton
extends Button

const NORMAL_BG: Color = Color(0.12, 0.16, 0.20, 0.52)
const HOVER_BG: Color = Color(0.24, 0.32, 0.39, 0.70)
const PRESSED_BG: Color = Color(0.33, 0.42, 0.49, 0.78)
const NORMAL_BORDER: Color = Color(0.72, 0.82, 0.88, 0.22)
const HOVER_BORDER: Color = Color(0.84, 0.94, 1.00, 0.58)
const PRESSED_BORDER: Color = Color(0.92, 0.98, 1.00, 0.82)

var _base_scale: Vector2 = Vector2.ONE
var _tween: Tween = null

func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 58.0)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_ALL
	_base_scale = scale
	_apply_styles()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _apply_styles() -> void:
	add_theme_stylebox_override("normal", _make_style(NORMAL_BG, NORMAL_BORDER, 1.0))
	add_theme_stylebox_override("hover", _make_style(HOVER_BG, HOVER_BORDER, 1.0))
	add_theme_stylebox_override("pressed", _make_style(PRESSED_BG, PRESSED_BORDER, 1.0))
	add_theme_stylebox_override("focus", _make_style(HOVER_BG, HOVER_BORDER, 1.0))
	add_theme_stylebox_override("disabled", _make_style(Color(0.10, 0.12, 0.14, 0.28), Color(0.50, 0.56, 0.60, 0.12), 0.8))
	add_theme_color_override("font_color", Color(0.91, 0.95, 0.98, 0.94))
	add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))
	add_theme_font_size_override("font_size", 16)

func _make_style(background: Color, border: Color, shadow_alpha: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	style.shadow_color = Color(0.45, 0.72, 0.88, shadow_alpha * 0.18)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0.0, 4.0)
	return style

func _animate_to(target_scale: Vector2, duration: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", target_scale, duration)

func _on_mouse_entered() -> void:
	_animate_to(_base_scale * 1.025, 0.12)

func _on_mouse_exited() -> void:
	_animate_to(_base_scale, 0.16)

func _on_focus_entered() -> void:
	_animate_to(_base_scale * 1.025, 0.12)

func _on_focus_exited() -> void:
	if not button_pressed:
		_animate_to(_base_scale, 0.16)

func _on_button_down() -> void:
	_animate_to(_base_scale * 0.975, 0.06)

func _on_button_up() -> void:
	if is_hovered():
		_animate_to(_base_scale * 1.025, 0.10)
	else:
		_animate_to(_base_scale, 0.12)
