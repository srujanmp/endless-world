extends CanvasLayer

@onready var btn: TextureButton = $ToggleButton
@onready var panel: Panel = $Panel
@onready var diff_label: Label = $Panel/VBox/DifficultyLabel
@onready var q_label: Label = $Panel/VBox/QText 

var rl
var grid: GridContainer

func _ready():
	rl = get_parent().get_node("DifficultyRL")

	# -------- BUTTON (Right Center) --------
	btn.texture_normal = load("res://assets/rl.png")
	btn.z_index = 1000
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.anchor_top = 0.5
	btn.anchor_bottom = 0.5
	btn.offset_left = -120
	btn.offset_right = -10
	btn.offset_top = -32
	btn.offset_bottom = 32
	btn.modulate.a = 0.7
	btn.pressed.connect(toggle)

	# -------- PANEL (Below Button, Widened for Larger Font) --------
	panel.visible = false
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	
	# offset_top starts below the button's bottom (32)
	panel.offset_left = -340 # Increased width to prevent crowding
	panel.offset_right = -10
	panel.offset_top = 40 
	panel.offset_bottom = 260 # Slightly taller to fit larger font rows

	# -------- UI ORGANIZATION --------
	var vbox = $Panel/VBox
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 12)
	
	var font = load("res://Jersey10-Regular.ttf")
	
	# Header Styling (Larger)
	diff_label.add_theme_font_override("font", font)
	diff_label.add_theme_font_size_override("font_size", 32)
	
	# Sub-header
	q_label.text = "EXPECTED REWARD [ Q(s,a) ]"
	q_label.add_theme_font_override("font", font)
	q_label.add_theme_font_size_override("font_size", 22)
	q_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q_label.modulate = Color(0.3, 0.9, 0.3)

	# The Q-Table Grid
	grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 40)
	vbox.add_child(grid)

	set_process(true)

func _process(_d):
	if panel.visible:
		update_text()

func toggle():
	panel.visible = !panel.visible
	if panel.visible:
		update_text()

func update_text():
	diff_label.text = "STATE: " + rl.last_difficulty.to_upper()

	# Refresh Grid
	for child in grid.get_children():
		child.queue_free()

	var font = load("res://Jersey10-Regular.ttf")
	for k in rl.DIFFICULTIES:
		var action_lbl = Label.new()
		var value_lbl = Label.new()
		
		# ML Table Formatting
		action_lbl.text = "  a_%s" % k.to_lower()
		value_lbl.text = "%.4f" % rl.q[k]
		
		# Larger Font for Table Rows
		action_lbl.add_theme_font_override("font", font)
		action_lbl.add_theme_font_size_override("font_size", 20) 
		
		value_lbl.add_theme_font_override("font", font)
		value_lbl.add_theme_font_size_override("font_size", 20)
		
		# Alignment
		value_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		
		grid.add_child(action_lbl)
		grid.add_child(value_lbl)
