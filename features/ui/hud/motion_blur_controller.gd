extends Control
class_name MotionBlurController

var enabled := true
var player: PlayerController
var _material: ShaderMaterial

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_to_group("motion_blur_controller")
	var shader := Shader.new()
	shader.code = '''shader_type canvas_item;\nrender_mode unshaded;\nuniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;\nuniform float intensity = 0.0;\nvoid fragment(){\n vec2 uv=SCREEN_UV;\n vec2 d=vec2(0.0012,0.0)*intensity;\n vec4 c=textureLod(screen_texture,uv,0.0)*0.34;\n c+=textureLod(screen_texture,uv+d,0.0)*0.22;\n c+=textureLod(screen_texture,uv-d,0.0)*0.22;\n c+=textureLod(screen_texture,uv+d*2.0,0.0)*0.11;\n c+=textureLod(screen_texture,uv-d*2.0,0.0)*0.11;\n COLOR=c;\n}'''
	_material = ShaderMaterial.new()
	_material.shader = shader
	material = _material
	visible = false

func setup(player_ref: PlayerController) -> void:
	player = player_ref

func set_motion_blur_enabled(value: bool) -> void:
	enabled = value
	visible = enabled and player != null and Vector2(player.velocity.x, player.velocity.z).length() > 1.0

func _process(_delta: float) -> void:
	if not enabled or player == null:
		visible = false
		return
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	visible = speed > 1.0
	if _material != null:
		_material.set_shader_parameter("intensity", clampf(speed / 5.4, 0.0, 1.0))
