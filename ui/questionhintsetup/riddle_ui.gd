extends CanvasLayer
class_name RiddleUI

# ================= NODES =================
@onready var panel: Panel = $Panel
@onready var toggle_button: TextureButton = $Panel/RiddleToggle
@onready var riddle_label: Label = $Panel/RiddleText
@onready var bulb_column: VBoxContainer = $Panel/HintsColumn
@onready var tooltip: Label = $Panel/HintTooltip

# ================= DATA =================
var hints: Array[String] = []
var bulbs: Array[HintBulb] = []
var unlocked_count := 0
var riddle_visible := false

# ==================================================
func _ready() -> void:
	# --- Initial state ---
	riddle_label.visible = false
	riddle_label.modulate.a = 0.0
	riddle_visible = false

	tooltip.visible = false
	tooltip.text = ""

	# Toggle riddle
	toggle_button.pressed.connect(_on_toggle_pressed)

	# Collect bulbs
	for child in bulb_column.get_children():
		if child is HintBulb:
			var bulb := child as HintBulb
			bulbs.append(bulb)
			bulb.set_off()
			bulb.hovered.connect(_on_bulb_hovered.bind(bulb))
			bulb.unhovered.connect(_on_bulb_unhovered)

# ==================================================
# SETUP RIDDLE (called from Map.gd)
# ==================================================
func setup_riddle(data: Dictionary) -> void:
	riddle_label.text = str(data.get("riddle", ""))

	# Reset riddle visibility
	riddle_visible = false
	riddle_label.visible = false
	riddle_label.modulate.a = 0.0

	# Setup hints
	hints.clear()
	unlocked_count = 0

	var raw_hints: Array = data.get("hints", [])
	for h in raw_hints:
		hints.append(str(h))

	# Reset bulbs
	for bulb in bulbs:
		bulb.set_off()

	for i in range(min(hints.size(), bulbs.size())):
		bulbs[i].hint_text = hints[i]

# ==================================================
# TOGGLE RIDDLE TEXT
# ==================================================
func _on_toggle_pressed() -> void:
	riddle_visible = !riddle_visible
	var tween := create_tween()

	if riddle_visible:
		riddle_label.visible = true
		riddle_label.modulate.a = 0.0
		tween.tween_property(riddle_label, "modulate:a", 1.0, 0.25)
	else:
		tween.tween_property(riddle_label, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func(): riddle_label.visible = false)

# ==================================================
# UNLOCK HINTS
# ==================================================
func unlock_next_hint() -> void:
	if unlocked_count >= bulbs.size():
		return

	bulbs[unlocked_count].set_on()
	unlocked_count += 1

# ==================================================
# HOVER LOGIC (tooltip on RIGHT of bulb)
# ==================================================
func _on_bulb_hovered(text: String, bulb: HintBulb) -> void:
	tooltip.text = text
	tooltip.visible = true

	# Bulb global position
	var bulb_global: Vector2 = bulb.global_position
	
	# Convert to PANEL-local space (Control-safe)
	var local_pos: Vector2 = bulb_global - panel.global_position

	# Place tooltip to the RIGHT of the bulb
	tooltip.position = local_pos + Vector2(bulb.size.x + 12, 30)



func _on_bulb_unhovered() -> void:
	tooltip.visible = false
	tooltip.text = ""
