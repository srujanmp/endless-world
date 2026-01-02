extends Node
class_name GeminiRiddle

# ================= GEMINI CONFIG =================
const GEMINI_URL: String = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

# ================= FALLBACK RIDDLE =================
const FALLBACK_RIDDLE := {
	"riddle": "I speak without a mouth and hear without ears. I have no body, but I come alive with wind. What am I?",
	"hints": [
		"I repeat what you give me",
		"I live in caves and mountains",
		"I need sound to exist",
		"I fade over time"
	],
	"solution": "Echo"
}

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

	http.request_completed.connect(_on_response)

# =================================================
func generate_riddle() -> void:
	# 🔁 FALLBACK MODE
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
		"contents": [
			{
				"parts": [
					{ "text": prompt }
				]
			}
		]
	}

	var headers: PackedStringArray = [
		"Content-Type: application/json",
		"x-goog-api-key: %s" % api_key
	]

	var json_body: String = JSON.stringify(body)

	var err: int = http.request(
		GEMINI_URL,
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)

	if err != OK:
		push_warning("❌ Gemini request failed — using fallback")
		_use_fallback()

# =================================================
func _on_response(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
) -> void:

	if response_code != 200:
		push_warning("❌ Gemini API error — using fallback")
		_use_fallback()
		return

	var response_text: String = body.get_string_from_utf8()

	var parsed_var: Variant = JSON.parse_string(response_text)
	if parsed_var == null:
		push_warning("❌ Gemini parse error — using fallback")
		_use_fallback()
		return

	var parsed: Dictionary = parsed_var as Dictionary
	var candidates: Array = parsed.get("candidates", [])

	if candidates.is_empty():
		_use_fallback()
		return

	var content: Dictionary = candidates[0].get("content", {})
	var parts: Array = content.get("parts", [])

	if parts.is_empty():
		_use_fallback()
		return

	var text_output: String = str(parts[0].get("text", ""))

	var riddle_var: Variant = JSON.parse_string(text_output)
	if riddle_var == null:
		_use_fallback()
		return

	var riddle_json: Dictionary = riddle_var as Dictionary

	riddle_data["riddle"] = str(riddle_json.get("riddle", ""))
	riddle_data["hints"] = riddle_json.get("hints", [])
	riddle_data["solution"] = str(riddle_json.get("solution", ""))

	emit_signal("riddle_generated", riddle_data)

# =================================================
# FALLBACK HANDLER
# =================================================
func _use_fallback() -> void:
	riddle_data = FALLBACK_RIDDLE.duplicate(true)
	emit_signal("riddle_generated", riddle_data)
