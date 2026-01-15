extends Node2D

@export var transition_speed : float = 0.4
@export var is_snow : bool = true : set = set_is_snow

@onready var rain_far : CPUParticles2D = $RainFar
@onready var rain_near : CPUParticles2D = $RainNear
@onready var camera := get_viewport().get_camera_2d()

var raining := false
var intensity := 0.0

# Inline Shader Code
var shader_code = """
shader_type canvas_item;
uniform float is_snow : hint_range(0.0, 1.0) = 0.0;
uniform float global_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    // Mix between original blue and pure white based on is_snow
    vec3 final_rgb = mix(tex_color.rgb, vec3(1.0, 1.0, 1.0), is_snow);
    COLOR = vec4(final_rgb, tex_color.a * global_alpha);
}
"""

func _ready():
	rain_far.emitting = false
	rain_near.emitting = false
	
	# Create and apply the material in-code
	var mat = ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = shader_code
	
	# Use duplicate() so each particle system has its own material instance
	rain_far.material = mat
	rain_near.material = mat.duplicate()
	
	apply_weather_type()

func _process(delta):
	if camera:
		global_position = camera.global_position

	if raining:
		intensity = move_toward(intensity, 1.0, transition_speed * delta)
	else:
		intensity = move_toward(intensity, 0.0, transition_speed * delta)

	# Update the shader parameters
	rain_far.material.set_shader_parameter("global_alpha", intensity)
	rain_near.material.set_shader_parameter("global_alpha", intensity)

func set_is_snow(value: bool):
	is_snow = value
	if is_inside_tree():
		apply_weather_type()

func apply_weather_type():
	var snow_val = 1.0 if is_snow else 0.0
	
	# Safety check to ensure materials exist
	if rain_far.material:
		rain_far.material.set_shader_parameter("is_snow", snow_val)
		rain_near.material.set_shader_parameter("is_snow", snow_val)
	
	if is_snow:
		# Snow behavior: Slow and floaty
		rain_far.speed_scale = 0.2
		rain_near.speed_scale = 0.2
	else:
		# Rain behavior: Fast
		rain_far.speed_scale = 1.0
		rain_near.speed_scale = 1.0

func start_rain():
	raining = true
	rain_far.emitting = true
	rain_near.emitting = true

func stop_rain():
	raining = false
	# We let the intensity fade finish before stopping emission
	if intensity <= 0.01:
		rain_far.emitting = false
		rain_near.emitting = false
