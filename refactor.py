import os
import shutil
import glob

moves = {
    "CameraShake.gd": "scripts/camera_shake.gd",
    "HintPickup.gd": "scripts/hint_pickup.gd",
    "HomeScreen.gd": "scripts/home_screen.gd",
    "answer_popup.gd": "scripts/answer_popup.gd",
    "gemini_riddle.gd": "scripts/ai_question_generator.gd",
    "player.gd": "scripts/player.gd",
    "tasks.gd": "scripts/tasks.gd",
    "well.gd": "scripts/well.gd",
    
    "GeminiRiddle.tscn": "scenes/ai_question_generator.tscn",
    "HintPickup.tscn": "scenes/hint_pickup.tscn",
    "HomeScreen.tscn": "scenes/home_screen.tscn",
    "Tasks.tscn": "scenes/tasks.tscn",
    "WaterBubble.tscn": "scenes/water_bubble.tscn",
    "answer_popup.tscn": "scenes/answer_popup.tscn",
    "joy_stick_ui.tscn": "scenes/joy_stick_ui.tscn",
    "player.tscn": "scenes/player.tscn",
    "well.tscn": "scenes/well.tscn",
    
    "tile_set.tres": "resources/tile_set.tres",
    
    "Jersey10-Regular.ttf": "assets/fonts/Jersey10-Regular.ttf",
    "NotoColorEmoji-Regular.ttf": "assets/fonts/NotoColorEmoji-Regular.ttf",
    "stock-vector-grey-dotted-world-map-vector-illustration-2392252911.jpg": "assets/images/world_map.jpg",
}

os.makedirs("scripts", exist_ok=True)
os.makedirs("scenes", exist_ok=True)
os.makedirs("resources", exist_ok=True)
os.makedirs("assets/fonts", exist_ok=True)
os.makedirs("assets/images", exist_ok=True)

replacements = {}
for old, new in moves.items():
    replacements[f"res://{old}"] = f"res://{new}"

def update_file_contents(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except UnicodeDecodeError:
        return
        
    original = content
    for old_res, new_res in replacements.items():
        content = content.replace(old_res, new_res)
    
    # specifically for gemini_riddle
    if "GeminiRiddle" in content or "gemini_riddle" in content:
        content = content.replace("GeminiRiddle", "AiQuestionGenerator")
        content = content.replace("gemini_riddle", "ai_question_generator")
        
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated references in: {filepath}")

extensions = ['.tscn', '.tres', '.gd', '.cfg', '.godot']
for root_dir, dirs, files in os.walk("."):
    if ".git" in root_dir or ".godot" in root_dir or "addons" in root_dir:
        continue
    for file in files:
        if any(file.endswith(ext) for ext in extensions):
            update_file_contents(os.path.join(root_dir, file))

for old, new in moves.items():
    if os.path.exists(old):
        shutil.move(old, new)
        print(f"Moved {old} -> {new}")
    if os.path.exists(old + ".uid"):
        shutil.move(old + ".uid", new + ".uid")
        print(f"Moved {old}.uid -> {new}.uid")
    if os.path.exists(old + ".import"):
        shutil.move(old + ".import", new + ".import")
        print(f"Moved {old}.import -> {new}.import")

print("Refactoring complete.")
