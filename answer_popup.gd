extends CanvasLayer
class_name AnswerPopup

@onready var message: Label = $Panel/VBoxContainer/MessageLabel
@onready var submit: Button = $Panel/VBoxContainer/SubmitButton
@onready var close_button: Button = $Panel/CloseButton

@onready var victory_sound: AudioStreamPlayer = $VictorySound
@onready var gameover_sound: AudioStreamPlayer = $GameOverSound


# EXISTING OPTION BUTTONS (NO DYNAMIC CREATION)
@onready var option_buttons: Array[Button] = [
	$Panel/VBoxContainer/OptionsContainer/OptionA,
	$Panel/VBoxContainer/OptionsContainer/OptionB,
	$Panel/VBoxContainer/OptionsContainer/OptionC,
	$Panel/VBoxContainer/OptionsContainer/OptionD
]

@onready var fill_container: VBoxContainer = $Panel/VBoxContainer/FillContainer
@onready var answer_input: LineEdit = $Panel/VBoxContainer/FillContainer/AnswerInput


var correct_answer := ""
var selected_answer := ""
var popup_type: Global.QuestionType
var hearts: HeartSystem
var map_ref

func _hide_all_popups():
	# Hide MCQ
	for btn in option_buttons:
		btn.visible = false

	# Hide fill in blank
	fill_container.visible = false
	answer_input.text = ""


# =============================
func _ready():
	visible = false
	submit.pressed.connect(_on_submit)
	close_button.pressed.connect(close)

# =============================
# OPEN POPUP WITH MCQs
# =============================
func open(solution: String, options: Array, heart_system: HeartSystem, map):
	if solution.is_empty():
		push_error("❌ Empty correct answer")
		return

	visible = true
	hearts = heart_system
	map_ref = map
	correct_answer = solution.to_lower()
	selected_answer = ""

	_hide_all_popups()

	# RANDOM POPUP TYPE
	
	popup_type = Global.current_question_type


	match Global.current_question_type:
		Global.QuestionType.MCQ:
			_open_mcq(options)
		Global.QuestionType.FILL_BLANK:
			_open_fill_blank()


func _open_mcq(options: Array):
	message.text = "Choose the correct answer"

	# RESET & FILL EXISTING BUTTONS
	for i in option_buttons.size():
		var btn := option_buttons[i]

		btn.modulate = Color.WHITE
		btn.disabled = false
		btn.visible = false

		# Disconnect old signals safely
		for c in btn.pressed.get_connections():
			btn.pressed.disconnect(c.callable)

		if i < options.size():
			btn.text = options[i]
			btn.visible = true
			btn.pressed.connect(_on_option_selected.bind(btn, options[i]))

func _open_fill_blank():
	message.text = "Fill in the correct answer"
	fill_container.visible = true
	answer_input.grab_focus()


# =============================
# OPTION SELECT
# =============================
func _on_option_selected(btn: Button, option_text: String):
	selected_answer = option_text.to_lower()

	# Reset all buttons
	for b in option_buttons:
		b.modulate = Color.WHITE

	# Highlight selected
	btn.modulate = Color(0.6, 1.0, 0.6)

# =============================
# SUBMIT ANSWER
# =============================
func _on_submit():
	var user_answer := ""

	match popup_type:
		Global.QuestionType.MCQ:
			user_answer = selected_answer
		Global.QuestionType.FILL_BLANK:
			user_answer = answer_input.text.strip_edges().to_lower()

	if user_answer == "":
		message.text = "⚠ Answer required"
		return

	if user_answer == correct_answer:
	
	
		$"../DifficultyRL".give_feedback(true, Global.current_hint_count)
		Global.end_game(true)

		spawn_confetti()
		message.text = "🎉 VICTORY!"
		victory_sound.play()


		Global.add_score(30)
		Global.next_level()

		await get_tree().create_timer(1.5).timeout
		close()
		get_tree().change_scene_to_file("res://HomeScreen.tscn")
	else:
		$"../DifficultyRL".give_feedback(false, Global.current_hint_count)
		message.text = "❌ Wrong Answer"
		gameover_sound.play()

		Global.add_score(-10)
		hearts.damage(2)
		await get_tree().create_timer(1.0).timeout
		close()

# =============================
func close():
	_hide_all_popups()
	visible = false
	selected_answer = ""
	message.text = ""

	for btn in option_buttons:
		btn.modulate = Color.WHITE
		btn.disabled = false

# =============================
# CONFETTI (UNCHANGED)
# =============================
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

	var shapes := ["circle", "square", "rectangle", "triangle", "parallelogram"]

	for c in colors:
		var particles := CPUParticles2D.new()
		add_child(particles)

		particles.position = viewport_size * 0.5 + Vector2(0, -200)
		particles.amount = 80
		particles.explosiveness = 1.0
		particles.lifetime = 2.0
		particles.one_shot = true
		particles.direction = Vector2(0, -1)
		particles.spread = 180
		particles.gravity = Vector2(0, 1200)
		particles.initial_velocity_min = 400
		particles.initial_velocity_max = 900
		particles.angular_velocity_min = 100
		particles.angular_velocity_max = 400
		particles.scale_amount_min = 0.6
		particles.scale_amount_max = 1.2
		particles.modulate = c

		var shape: Variant = shapes.pick_random()
		particles.texture = _make_shape_texture(shape, 16)

		particles.emitting = true
		get_tree().create_timer(3.0).timeout.connect(particles.queue_free)

func _make_shape_texture(shape: String, size := 16) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	var c := Color.WHITE

	match shape:
		"circle":
			for x in size:
				for y in size:
					if Vector2(x, y).distance_to(Vector2(size / 2.0, size / 2.0)) <= size / 2.0:
						img.set_pixel(x, y, c)
		"square":
			img.fill(c)
		"rectangle":
			for x in size:
				for y in int(size * 0.6):
					img.set_pixel(x, y + int(size * 0.2), c)
		"triangle":
			for y in size:
				for x in int((y / float(size)) * size):
					img.set_pixel(x + (size - x) / 2, y, c)
		"parallelogram":
			for y in size:
				for x in int(size * 0.7):
					img.set_pixel(x + int(y * 0.2), y, c)

	return ImageTexture.create_from_image(img)
