extends Node
class_name GeminiRiddle

# ================= LLM CONFIG =================
# Updated to your new local or hosted Node.js server endpoint
const SERVER_URL: String = "http://localhost:3000/generate-riddle"

# ================= FALLBACK RIDDLES =================
# Updated to match the new schema (options, fact_reference, source)
const FALLBACK_RIDDLES: Array[Dictionary] = [
	{
		"riddle": "I repeat a block of code until a condition becomes false. What am I?",
		"options": ["Loop", "Variable", "Function", "Array"],
		"solution": "Loop",
		"hints": ["Used for repetition", "Can be while or for", "Avoid infinite use", "Common control structure"],
		"fact_reference": "Loops are fundamental for iterating through data.",
		"source": "fallback"
	},
	{
		"riddle": "I store a value that can change while the program runs. What am I?",
		"options": ["Constant", "Variable", "Integer", "String"],
		"solution": "Variable",
		"hints": ["Holds data", "Can be int or string", "Declared before use", "Changes over time"],
		"fact_reference": "Variables allow programs to store and manipulate dynamic data.",
		"source": "fallback"
	}
]

@onready var http: HTTPRequest = $HTTPRequest

# ================= STORED DATA =================
var riddle_data: Dictionary = {
	"riddle": "",
	"options": [],
	"solution": "",
	"hints": [],
	"fact_reference": "",
	"source": ""
}

signal riddle_generated(data: Dictionary)

# =================================================
func _ready() -> void:
	print("[GeminiRiddle] Initializing...")
	
	if not has_node("HTTPRequest"):
		var new_http = HTTPRequest.new()
		add_child(new_http)
		http = new_http

	http.request_completed.connect(_on_response)

# =================================================
func generate_riddle() -> void:
	# Fetching difficulty and topic from your existing Global/Map logic
	var difficulty = "Easy" 
	if has_node("/root/Map/DifficultyRL"):
		difficulty = get_node("/root/Map/DifficultyRL").choose_difficulty()
		
	var topic = Global.selected_topic if "selected_topic" in Global else "Programming"
	
	print("[GeminiRiddle] Requesting Riddle. Topic: %s | Difficulty: %s" % [topic, difficulty])
	
	var body := {
		"difficulty": difficulty,
		"topic": topic
	}

	var headers: PackedStringArray = ["Content-Type: application/json"]
	
	# Send POST request to your Node.js server
	var err := http.request(SERVER_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

	if err != OK:
		push_error("[GeminiRiddle] HTTP Request failed to start.")
		_use_fallback()

# =================================================
func _on_response(_result, code, _headers, body):
	print("[GeminiRiddle] Response received. Code: ", code)
	
	if code != 200:
		push_warning("[GeminiRiddle] Server error or unreachable. Using fallback.")
		_use_fallback()
		return

	var text = body.get_string_from_utf8()
	var data = JSON.parse_string(text)

	if typeof(data) == TYPE_DICTIONARY and data.has("riddle"):
		riddle_data = data
		_log_riddle_details(riddle_data)
		emit_signal("riddle_generated", riddle_data)
	else:
		push_error("[GeminiRiddle] Received invalid JSON structure.")
		_use_fallback()

# =================================================
func _use_fallback() -> void:
	print("[GeminiRiddle] ⚠️ ACTIVATING FALLBACK.")
	riddle_data = FALLBACK_RIDDLES.pick_random().duplicate(true)
	_log_riddle_details(riddle_data)
	emit_signal("riddle_generated", riddle_data)

func _log_riddle_details(data: Dictionary) -> void:
	print("------------------------------------------")
	print("[GeminiRiddle] DATA SOURCE: ", data.get("source", "unknown"))
	print("QUESTION: ", data.get("riddle", "N/A"))
	print("OPTIONS: ", data.get("options", []))
	print("ANSWER: ", data.get("solution", "N/A"))
	print("FACT: ", data.get("fact_reference", "N/A"))
	print("------------------------------------------")
