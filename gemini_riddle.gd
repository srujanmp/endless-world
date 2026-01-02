extends Node
class_name GeminiRiddle

# ================= GEMINI CONFIG =================
const GEMINI_URL: String = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

# ================= TECHNICAL FALLBACK RIDDLES =================
const FALLBACK_RIDDLES: Array[Dictionary] = [
	{
		"riddle": "I offer no resistance to the flow, yet I am the pressure that makes things go. What am I?",
		"hints": ["Measured in Volts", "Potential difference", "Battery rating", "Ohm's law: V", "The push for electrons", "Unit symbol is V"],
		"solution": "Voltage"
	},
	{
		"riddle": "I can store energy in a field of force, blocking DC but letting AC take its course. What am I?",
		"hints": ["Measured in Farads", "Two conductive plates", "Stores electric charge", "Decoupling component", "Passive element", "Reactance varies with freq"],
		"solution": "Capacitor"
	},
	{
		"riddle": "I am a loop that never ends unless a condition is met or a break is sent. What am I?",
		"hints": ["Repeats instructions", "Can cause stack overflow", "While or For", "Program structure", "Infinite versions crash CPUs", "Logic cycle"],
		"solution": "Iteration"
	},
	{
		"riddle": "I am the friction of the wire, turning energy into heat and fire. What am I?",
		"hints": ["Measured in Ohms", "Opposes current flow", "Color bands tell my value", "V = I * R", "Dissipates power", "Passive resistor"],
		"solution": "Resistance"
	},
	{
		"riddle": "I am the brain made of silicon and gates, processing logic at incredible rates. What am I?",
		"hints": ["The CPU", "Fetch-Decode-Execute", "Billions of transistors", "Central brain", "Clock speed in GHz", "Calculates everything"],
		"solution": "Processor"
	},
	{
		"riddle": "I am the force that turns the wheel, a twisting strength that you can feel. What am I?",
		"hints": ["Newton-meters unit", "Force times distance", "Engine output", "Rotational force", "Tightening a bolt", "Twisting moment"],
		"solution": "Torque"
	}
]

@onready var http: HTTPRequest = $HTTPRequest

var api_key: String = ""

# ================= STORED DATA =================
var riddle_data: Dictionary = {
	"riddle": "",
	"hints": [],
	"solution": ""
}

signal riddle_generated(data: Dictionary)

# =================================================
func _ready() -> void:
	var env: Dictionary = EnvLoader.load_env()
	api_key = env.get("GEMINI_API_KEY", "")

	if not has_node("HTTPRequest"):
		var new_http = HTTPRequest.new()
		add_child(new_http)
		http = new_http

	http.request_completed.connect(_on_response)

# =================================================
func generate_riddle() -> void:
	if api_key.is_empty():
		print("⚠️ Gemini API key missing — using fallback riddle")
		_use_fallback()
		return

	# 🔥 GEMINI MODE
	var prompt: String = """
Generate a riddle in STRICT JSON format only.

Structure:
{
  "riddle": "string",
  "hints": ["hint1", "hint2", "hint3", "hint4"],
  "solution": "string"
}

Rules:
- Technical question
- No markdown
- No explanation
- Valid JSON only
- solution should be a single word
"""

	var body: Dictionary = {
		"contents": [{"parts": [{"text": prompt}]}]
	}

	var headers: PackedStringArray = [
		"Content-Type: application/json",
		"x-goog-api-key: %s" % api_key
	]

	var err: int = http.request(GEMINI_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

	if err != OK:
		push_warning("❌ Gemini request failed — using fallback")
		_use_fallback()

# =================================================
func _on_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		_use_fallback()
		return

	var response_text: String = body.get_string_from_utf8()
	var parsed_var: Variant = JSON.parse_string(response_text)
	
	if parsed_var == null:
		_use_fallback()
		return

	var candidates: Array = parsed_var.get("candidates", [])
	if candidates.is_empty():
		_use_fallback()
		return

	var text_output: String = str(candidates[0].get("content", {}).get("parts", [{}])[0].get("text", ""))
	var riddle_var: Variant = JSON.parse_string(text_output)
	
	if riddle_var == null:
		_use_fallback()
		return

	riddle_data["riddle"] = str(riddle_var.get("riddle", ""))
	riddle_data["hints"] = riddle_var.get("hints", [])
	riddle_data["solution"] = str(riddle_var.get("solution", ""))

	emit_signal("riddle_generated", riddle_data)

# =================================================
func _use_fallback() -> void:
	# Randomly pick one of the 6 technical riddles
	var random_entry = FALLBACK_RIDDLES.pick_random()
	riddle_data = random_entry.duplicate(true)
	emit_signal("riddle_generated", riddle_data)
