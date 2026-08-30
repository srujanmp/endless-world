extends Node

@export var rain_enabled := true
@onready var rain := $"../RainSystem"

func _process(_delta):
	if rain_enabled and not rain.raining:
		rain.start_rain()
	elif not rain_enabled and rain.raining:
		rain.stop_rain()
