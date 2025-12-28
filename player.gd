extends CharacterBody2D

@export var speed := 200.0
@export var water_speed_multiplier := 0.6

# DROWNING (PIXELS)
@export var sink_in_speed := 6.0      # slow descent
@export var sink_out_speed := 20.0    # fast recovery
@export var max_sink_px := 10.0       # small sink distance

# COLOR TINT
@export var max_blue_tint := 0.5      # 0–1 (how blue at max sink)

@onready var sprite := $AnimatedSprite2D

@export var bubble_scene := preload("res://WaterBubble.tscn")
@export var bubble_spawn_rate := 0.6  # seconds

@onready var bubble_spawner := $WaterBubbleSpawner

var bubble_timer := 0.0


var in_water := false        # SET FROM map.gd
var sink_px := 0.0
var base_sprite_pos := Vector2.ZERO
var last_dir := Vector2.DOWN

func _ready():
	base_sprite_pos = sprite.position
	sprite.modulate = Color.WHITE

func _physics_process(delta):
	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	var current_speed := speed

	# 🌊 WATER LOGIC
	if in_water:
		current_speed *= water_speed_multiplier
		sink_px = min(max_sink_px, sink_px + sink_in_speed * delta)
	else:
		sink_px = max(0.0, sink_px - sink_out_speed * delta)
		
	# 🫧 DROWNING BUBBLES
	if in_water:
		bubble_timer -= delta
		if bubble_timer <= 0.0:
			spawn_water_bubble()
			bubble_timer = bubble_spawn_rate
	else:
		bubble_timer = 0.0

	# VISUAL SINK (POSITION ONLY)
	sprite.position = base_sprite_pos + Vector2(0, sink_px)

	# VISUAL BLUE TINT (NO OVERLAY)
	apply_water_tint()

	# MOVEMENT + ANIMATION
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		last_dir = dir
		velocity = dir * current_speed
		play_animation(dir)
	else:
		velocity = Vector2.ZERO
		set_idle_frame()

	move_and_slide()

# ---------------- WATER TINT ----------------
func apply_water_tint():
	if max_sink_px <= 0.0:
		sprite.modulate = Color.WHITE
		return

	var t: float = sink_px / max_sink_px   # 0 → 1

	# Blend from white → blue
	sprite.modulate = Color(
		1.0 - t * max_blue_tint,  # red down
		1.0 - t * max_blue_tint,  # green down
		1.0,                      # blue stays
		1.0
	)

# ---------------- ANIMATION ----------------
func play_animation(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		sprite.play("walk_right" if dir.x > 0 else "walk_left")
	else:
		sprite.play("walk_down" if dir.y > 0 else "walk_up")

func set_idle_frame():
	sprite.stop()

	if abs(last_dir.x) > abs(last_dir.y):
		sprite.animation = "walk_right" if last_dir.x > 0 else "walk_left"
	else:
		sprite.animation = "walk_down" if last_dir.y > 0 else "walk_up"

	sprite.frame = 1


func spawn_water_bubble():
	var bubble := bubble_scene.instantiate()
	get_parent().add_child(bubble)

	# spawn near head
	var offset := Vector2(
		randf_range(-6, 6),
		-12 + randf_range(-4, 2)
	)

	bubble.global_position = bubble_spawner.global_position + offset
