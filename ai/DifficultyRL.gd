extends Node
class_name DifficultyRL

const SAVE_PATH := "user://difficulty_rl.json"

# 5 difficulty levels
const DIFFICULTIES := ["VERY_EASY", "EASY", "MEDIUM", "HARD", "VERY_HARD"]
const ACTIONS := ["DOWN", "SAME", "UP"]

# Q-table now = {state: {action: value}}
var q: Dictionary = {}

# RL params (same spirit as python)
var learning_rate: float = 0.3
var discount_factor: float = 0.5

# Current difficulty
var last_difficulty: String = "MEDIUM"
var current_diff: String = "MEDIUM"

# Previous state/action for Q-learning update
var prev_state: String = ""
var prev_action: String = ""

# if you want to avoid double init
var initialized := false


func _ready():
	# still works if added as child normally
	init_rl()


# ✅ NEW: explicit init for Global.gd usage
func init_rl():
	if initialized:
		return
	initialized = true
	load_model()
	current_diff = last_difficulty


# ---------------------------------------------------
# KEEP SAME FUNCTION NAME/SIGNATURE
# ---------------------------------------------------
func choose_difficulty() -> String:
	last_difficulty = current_diff
	print("🎯 RL chose difficulty:", last_difficulty)
	return last_difficulty


# Not used in this strict logic version, but kept because other files might rely on it
func _best_difficulty() -> String:
	return current_diff


# ---------------------------------------------------
# STRICT LOGIC HELPERS (python port)
# ---------------------------------------------------
func _get_state(win: bool, hints_used: int) -> String:
	if win:
		return "BORING" if hints_used == 0 else "CHALLENGED"
	else:
		return "TOO_HARD"


func _init_state(state: String) -> void:
	if not q.has(state):
		q[state] = {}

		if state == "BORING":
			q[state]["UP"] = 2.0
			q[state]["SAME"] = -1.0
			q[state]["DOWN"] = -2.0
		elif state == "TOO_HARD":
			q[state]["DOWN"] = 2.0
			q[state]["SAME"] = -1.0
			q[state]["UP"] = -2.0
		else:
			# CHALLENGED
			q[state]["SAME"] = 2.0
			q[state]["UP"] = 0.5
			q[state]["DOWN"] = 0.5


func _max_future(state: String) -> float:
	var best := -999999.0
	for a in ACTIONS:
		if q[state].has(a) and q[state][a] > best:
			best = q[state][a]
	return best


func _argmax_action(state: String) -> String:
	var best_action := "SAME"
	var best_val := -999999.0
	for a in ACTIONS:
		if q[state].has(a) and q[state][a] > best_val:
			best_val = q[state][a]
			best_action = a
	return best_action


func _apply_action(action: String) -> void:
	var idx := DIFFICULTIES.find(current_diff)
	if idx == -1:
		idx = DIFFICULTIES.find("MEDIUM")

	if action == "UP":
		idx = min(DIFFICULTIES.size() - 1, idx + 1)
	elif action == "DOWN":
		idx = max(0, idx - 1)

	current_diff = DIFFICULTIES[idx]
	last_difficulty = current_diff


# ---------------------------------------------------
# KEEP SAME FUNCTION NAME/SIGNATURE
# ---------------------------------------------------
func give_feedback(win: bool, hints_used: int):
	var state := _get_state(win, hints_used)
	_init_state(state)

	# 1) reward for PREVIOUS choice (same as python)
	var reward: float = 2.0 if state == "CHALLENGED" else -2.0

	if prev_state != "" and prev_action != "":
		_init_state(prev_state)

		# Safety: only update if key exists
		if q.has(prev_state) and q[prev_state].has(prev_action):
			var old_q: float = float(q[prev_state][prev_action])
			var max_future: float = _max_future(state)

			q[prev_state][prev_action] = old_q + learning_rate * (reward + discount_factor * max_future - old_q)

	# 2) force logical action (Loss=DOWN, Win no hints=UP)
	var best_action := "SAME"
	if state == "BORING":
		best_action = "UP"
	elif state == "TOO_HARD":
		best_action = "DOWN"
	else:
		best_action = _argmax_action(state)

	prev_state = state
	prev_action = best_action

	# 3) apply action to difficulty
	_apply_action(best_action)

	print("📊 RESULT:", "WIN" if win else "LOSS", "| Hints:", hints_used)
	print("📌 State:", state, "| AI Action:", best_action)
	print("🎮 New Difficulty:", current_diff)

	save_model()


# ---------------------------------------------------
# DATA PERSISTENCE
# ---------------------------------------------------
func save_model():
	var data := {
		"q": q,
		"last_difficulty": last_difficulty,
		"current_diff": current_diff,
		"prev_state": prev_state,
		"prev_action": prev_action
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_model():
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var json_text = file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_text)

	if typeof(data) != TYPE_DICTIONARY:
		return

	# restore
	if data.has("q") and typeof(data["q"]) == TYPE_DICTIONARY:
		q = data["q"]
	else:
		q = {}

	if data.has("last_difficulty"):
		last_difficulty = str(data["last_difficulty"])

	if data.has("current_diff"):
		current_diff = str(data["current_diff"])
	else:
		current_diff = last_difficulty

	if data.has("prev_state"):
		prev_state = str(data["prev_state"])

	if data.has("prev_action"):
		prev_action = str(data["prev_action"])


# ✅ NEW: reset helper (Global can call this)
func reset_model():
	q = {}
	last_difficulty = "MEDIUM"
	current_diff = "MEDIUM"
	prev_state = ""
	prev_action = ""
	initialized = true # keep initialized to avoid reloading old save
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
