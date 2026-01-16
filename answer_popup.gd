extends CanvasLayer
class_name AnswerPopup

@onready var message: Label = $Panel/VBoxContainer/MessageLabel
@onready var input: LineEdit = $Panel/VBoxContainer/AnswerInput
@onready var submit: Button = $Panel/VBoxContainer/SubmitButton
@onready var close_button: Button = $Panel/CloseButton

var correct_answer: String = ""
var hearts: HeartSystem
var map_ref

func _ready():
	visible = false
	submit.pressed.connect(_on_submit)
	close_button.pressed.connect(close)

	# 🚫 Prevent Enter key from submitting
	input.gui_input.connect(_block_enter_key)

# =============================
# OPEN POPUP
# =============================
func open(solution: String, heart_system: HeartSystem, map):
	if solution.is_empty():
		push_error("❌ AnswerPopup opened with EMPTY solution!")
		return

	visible = true
	input.text = ""
	message.text = "Enter your answer"
	correct_answer = solution.to_lower()
	hearts = heart_system
	map_ref = map

	input.grab_focus()

# =============================
# BLOCK ENTER KEY
# =============================
func _block_enter_key(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()

# =============================
# ESC TO CLOSE
# =============================
func _input(event):
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		close()

func close():
	visible = false
	input.text = ""
	message.text = ""

# =============================
# SUBMIT LOGIC
# =============================
func _on_submit():
	var user_answer := input.text.strip_edges().to_lower()

	print(user_answer + " " + correct_answer)

	if user_answer == correct_answer:
		$"../DifficultyRL".give_feedback(true, Global.current_hint_count)
		Global.end_game(true)

		# 🎊 CONFETTI BLAST
		spawn_confetti()

		# 🎉 BIG VICTORY TEXT
		message.text = "🎉 VICTORY!"
		message.add_theme_font_size_override("font_size", 60)

		Global.add_score(50)
		Global.next_level()   # ⭐ LEVEL UP

		await get_tree().create_timer(1.5).timeout
		# # (Optional) reset font size so it doesn't affect reuse
		# message.remove_theme_font_size_override("font_size")
		close()
		
		# 🏠 GO BACK TO HOME
		get_tree().change_scene_to_file("res://HomeScreen.tscn")

	else:
		$"../DifficultyRL".give_feedback(false, Global.current_hint_count)
		message.text = "❌ Try again"
		hearts.damage(1)
		input.text = ""
		await get_tree().create_timer(1.0).timeout
		close()

func spawn_confetti():
	var viewport_size := get_viewport().get_visible_rect().size

	var colors := [
	Color.RED,
	Color.YELLOW,
	Color.GREEN,
	Color.CYAN,
	Color.MAGENTA,
	Color.ORANGE
	]

	for c in colors:
		var particles := CPUParticles2D.new()

		# 1. ADD TO SELF
		# This ensures it stays on the CanvasLayer (UI) and above the map
		add_child(particles) 

		# 2. POSITION
		# (viewport_size * 0.5) is the exact center
		# Vector2(0, -50) moves it UP by 50 pixels
		particles.position = (viewport_size * 0.5) + Vector2(0, -100)

		# 3. CONFIGURE PARTICLES
		particles.amount = 80
		particles.explosiveness = 1.0     # All particles pop at once
		particles.lifetime = 2.0          # How long they stay on screen
		particles.one_shot = true         # Play only once
		particles.direction = Vector2(0, -1) # Aim UP
		particles.spread = 180.0          # Blow out in a half-circle

		# Physics
		particles.gravity = Vector2(0, 1200)       # Pulls them down
		particles.initial_velocity_min = 400
		particles.initial_velocity_max = 900

		# Rotation (Makes them spin/flutter)
		particles.angular_velocity_min = 100
		particles.angular_velocity_max = 400

		# Size (Make sure they are big enough to see!)
		particles.scale_amount_min = 10.0 
		particles.scale_amount_max = 20.0

		# Color
		particles.modulate = c

		# 4. START
		particles.emitting = true

		# 5. CLEANUP
		# Automatically deletes the particle node after 3 seconds
		get_tree().create_timer(3.0).timeout.connect(particles.queue_free)	
