extends CharacterBody2D

@export var speed := 200.0
@onready var sprite := $AnimatedSprite2D

var last_dir := Vector2.DOWN

func _physics_process(_delta):
	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		last_dir = dir
		velocity = dir * speed
		play_animation(dir)
	else:
		velocity = Vector2.ZERO
		set_idle_frame()

	move_and_slide()

func play_animation(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			sprite.play("walk_right")
		else:
			sprite.play("walk_left")
	else:
		if dir.y > 0:
			sprite.play("walk_down")
		else:
			sprite.play("walk_up")

func set_idle_frame():
	sprite.stop()

	if abs(last_dir.x) > abs(last_dir.y):
		if last_dir.x > 0:
			sprite.animation = "walk_right"
		else:
			sprite.animation = "walk_left"
	else:
		if last_dir.y > 0:
			sprite.animation = "walk_down"
		else:
			sprite.animation = "walk_up"

	sprite.frame = 1  # idle frame
