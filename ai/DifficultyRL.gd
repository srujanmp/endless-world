extends Node
class_name DifficultyRL

const SAVE_PATH := "user://difficulty_rl.json"

# 5 difficulty levels
const DIFFICULTIES := ["VERY_EASY", "EASY", "MEDIUM", "HARD", "VERY_HARD"]

# Q-values initialized to 0.0 (neutral)
var q: Dictionary = {
	"VERY_EASY": 0.0,
	"EASY": 0.0,
	"MEDIUM": 0.0,
	"HARD": 0.0,
	"VERY_HARD": 0.0
}

var epsilon: float = 0.2
var learning_rate: float = 0.1 # Lower LR for smoother, more believable transitions
var last_difficulty: String = "MEDIUM"

func _ready():
	load_model()

func choose_difficulty() -> String:
	if randf() < epsilon:
		last_difficulty = DIFFICULTIES.pick_random()
	else:
		last_difficulty = _best_difficulty()
	
	print("🎯 RL chose difficulty:", last_difficulty)
	return last_difficulty

func _best_difficulty() -> String:
	var best := "MEDIUM"
	var best_val: float = -999.0
	for d in DIFFICULTIES:
		if q[d] > best_val:
			best_val = q[d]
			best = d
	return best

# --- THE FIX: BELIEVABLE REWARD LOGIC ---
# --- IMPROVED FEEDBACK LOGIC ---
func give_feedback(win: bool, hints_used: int):
	# We use a very high Learning Rate (0.8) to make the change IMMEDIATE
	var adjust_rate: float = 0.8
	var reward: float = 0.0
	
	if win:
		# WINNING: If they win with 0-1 hints, give positive reward.
		# If they win but used 3+ hints, treat it like a 'struggle' (negative).
		reward = 1.0 - (hints_used * 0.5) 
		
		# If it was too easy, we cap the reward so it looks for harder challenges
		if last_difficulty == "VERY_EASY" or last_difficulty == "EASY":
			reward = clamp(reward, -0.5, 0.5)
	else:
		# LOSING: Massive penalty. 
		# This pushes the Q-value so low that _best_difficulty() 
		# will almost certainly pick a different one next time.
		reward = -2.0 - (hints_used * 0.5)

	# Apply the change
	var old_q = q[last_difficulty]
	q[last_difficulty] = lerp(old_q, reward, adjust_rate)

	print("📊 RESULT: ", "WIN" if win else "LOSS", " | Hints: ", hints_used)
	print("📈 New Q-Value for ", last_difficulty, " is ", q[last_difficulty])
	
	save_model()
# --- DATA PERSISTENCE ---
func save_model():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(q))

func load_model():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var json_text = file.get_as_text()
		var data = JSON.parse_string(json_text)
		if typeof(data) == TYPE_DICTIONARY:
			# Ensure we only load valid keys
			for key in q.keys():
				if data.has(key):
					q[key] = data[key]
