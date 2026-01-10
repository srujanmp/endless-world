extends Node2D

@export var transition_speed : float = 0.4

@onready var rain_far : CPUParticles2D = $RainFar
@onready var rain_near : CPUParticles2D = $RainNear
@onready var camera := get_viewport().get_camera_2d()

var raining := false
var intensity := 0.0   # 0 → 1

func _ready():
	rain_far.emitting = false
	rain_near.emitting = false

func _process(delta):
	if camera:
		global_position = camera.global_position

	if raining:
		intensity = lerp(intensity, 1.0, transition_speed * delta)
	else:
		intensity = lerp(intensity, 0.0, transition_speed * delta)

	rain_far.modulate.a = intensity
	rain_near.modulate.a = intensity

func start_rain():
	raining = true
	rain_far.emitting = true
	rain_near.emitting = true

func stop_rain():
	raining = false
	rain_far.emitting = false
	rain_near.emitting = false
