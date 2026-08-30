extends Sprite2D

@export var rise_speed := 20.0
@export var lifetime := 1.2
@export var drift := 12.0

var age := 0.0
var drift_dir := randf_range(-1.0, 1.0)

func _ready():
	scale = Vector2.ONE * randf_range(0.6, 1.0)
	modulate.a = 0.9

func _process(delta):
	age += delta

	position.y -= rise_speed * delta
	position.x += drift_dir * drift * delta

	# fade out
	modulate.a = lerp(0.9, 0.0, age / lifetime)

	if age >= lifetime:
		queue_free()
