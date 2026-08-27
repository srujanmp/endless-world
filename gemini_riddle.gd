extends Node
class_name GeminiRiddle

var resolved_search_topic: String = ""

# ================= SCRAPING CONFIG =================
const DEBUG_FILE: String = "user://debug_scrape.txt"

# ================= FALLBACK RIDDLES =================
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

@onready var http_server: HTTPRequest = HTTPRequest.new()
@onready var http_scrape: HTTPRequest = HTTPRequest.new()

# ================= STORED DATA =================
var riddle_data: Dictionary = {
	"riddle": "",
	"options": [],
	"solution": "",
	"hints": [],
	"fact_reference": "",
	"source": ""
}

var current_topic: String = ""
var current_difficulty: String = ""

var _log_timer: Timer
@onready var log_label: Label = get_node_or_null("../RiddleUI/Log")

signal riddle_generated(data: Dictionary)

# =================================================
func _ready() -> void:
	# 1. SETUP TIMER FIRST
	_log_timer = Timer.new()
	_log_timer.wait_time = 3.0
	_log_timer.one_shot = true
	_log_timer.timeout.connect(_on_log_timer_timeout)
	add_child(_log_timer)
	if log_label: log_label.hide()

	# 2. NOW YOU CAN CALL LOGS
	print("[GeminiRiddle] Initializing...")
	add_log("Initializing...")

	# Add HTTP nodes
	add_child(http_server)
	http_server.request_completed.connect(_on_server_response)
	
	add_child(http_scrape)
	http_scrape.request_completed.connect(_on_scrape_response)

# =================================================
func generate_riddle() -> void:
	# Fetching difficulty and topic from your existing Global/Map logic
	current_difficulty = "Easy" 
	if has_node("/root/Map/DifficultyRL"):
		current_difficulty = get_node("/root/Map/DifficultyRL").choose_difficulty()
		
	current_topic = Global.selected_topic if "selected_topic" in Global else "Programming"
	
	print("[GeminiRiddle] Requesting Riddle. Topic: %s | Difficulty: %s" % [current_topic, current_difficulty])
	add_log("Searching Web for: %s..." % current_topic)
	
	_request_scrape(current_topic)

func _request_scrape(topic: String) -> void:
	var body := {
		"topic": topic
	}
	
	var headers: PackedStringArray = [
		"Content-Type: application/json"
	]
	
	var err := http_scrape.request(
		"http://localhost:8000/api/scrape",
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	
	if err != OK:
		push_error("[GeminiRiddle] Failed to start request to python scrape server.")
		_use_fallback()

func _on_scrape_response(_result, code, _headers, body) -> void:
	if code == 200:
		var text: String = body.get_string_from_utf8()
		var data: Variant = JSON.parse_string(text)
		if typeof(data) == TYPE_DICTIONARY and data.has("url"):
			var chunks = data.get("chunks_stored", 0)
			add_log("Scraped %s. Stored %d chunks." % [data["url"], chunks])
			print("[GeminiRiddle] Scraped and stored %d chunks from %s" % [chunks, data["url"]])
		else:
			add_log("Web search finished.")
	else:
		push_warning("[GeminiRiddle] Scrape server returned code %d. Proceeding anyway." % code)
		add_log("Scrape failed. Proceeding with internal knowledge...")
		
	# Now that scraping is done, we generate the riddle
	add_log("Generating Riddle...")
	_request_riddle_from_server(current_topic, current_difficulty)

func _request_riddle_from_server(topic: String, difficulty: String) -> void:
	var body := {
		"topic": topic,
		"difficulty": difficulty
	}
	
	var headers: PackedStringArray = [
		"Content-Type: application/json"
	]
	
	var err := http_server.request(
		"http://localhost:8000/api/generate_riddle",
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	
	if err != OK:
		push_error("[GeminiRiddle] Failed to start request to python server.")
		_use_fallback()

# =================================================
func _on_server_response(_result, code, _headers, body) -> void:
	if code != 200:
		push_warning("[GeminiRiddle] Server returned code %d" % code)
		_use_fallback()
		return
		
	var text: String = body.get_string_from_utf8()
	var data: Variant = JSON.parse_string(text)
	
	if typeof(data) == TYPE_DICTIONARY and data.has("riddle"):
		riddle_data = data
		print("Riddle generated via %s." % riddle_data.get("source", "unknown"))
		_log_riddle_details(riddle_data)
		emit_signal("riddle_generated", riddle_data)
	else:
		push_error("[GeminiRiddle] Invalid format from python server")
		_use_fallback()

# =================================================
func _use_fallback() -> void:
	print("[GeminiRiddle] ⚠️ ACTIVATING FALLBACK.")
	riddle_data = FALLBACK_RIDDLES.pick_random().duplicate(true)
	_log_riddle_details(riddle_data)
	emit_signal("riddle_generated", riddle_data)

# =================================================
func _log_riddle_details(data: Dictionary) -> void:
	add_log("Generated Question \nClick 🔎");
	print("------------------------------------------")
	print("[GeminiRiddle] DATA SOURCE: ", data.get("source", "unknown"))
	print("QUESTION: ", data.get("riddle", "N/A"))
	print("OPTIONS: ", data.get("options", []))
	print("ANSWER: ", data.get("solution", "N/A"))
	print("FACT: ", data.get("fact_reference", "N/A"))
	print("------------------------------------------")

# ================= LOG SYSTEM =================
func add_log(message: String) -> void:
	if not log_label:
		return

	log_label.text = message
	log_label.show()

	# Restart idle timer every time a log comes
	_log_timer.stop()
	_log_timer.start()

func _on_log_timer_timeout() -> void:
	if log_label:
		log_label.hide()
