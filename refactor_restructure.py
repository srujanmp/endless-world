import os
import shutil

moves = {
    # popups -> answerpopups
    "ui/popups/answer_popup.tscn": "ui/answerpopups/answer_popup.tscn",
    "ui/popups/answer_popup.gd": "ui/answerpopups/answer_popup.gd",

    # riddle -> questionhintsetup
    "ui/riddle/hint_bulb.gd": "ui/questionhintsetup/hint_bulb.gd",
    "ui/riddle/riddle_ui.gd": "ui/questionhintsetup/riddle_ui.gd",

    # systems/ai -> ai
    "systems/ai/difficulty_rl.gd": "ai/difficulty_rl.gd",
    "systems/ai/rl_overlay.gd": "ai/rl_overlay.gd",
    "systems/ai/ai_question_generator.tscn": "ai/ai_question_generator.tscn",
    "systems/ai/ai_question_generator.gd": "ai/ai_question_generator.gd",
    "systems/ai/agentic_bot.gd": "ai/agentic_bot.gd",

    # environments/map -> map_components
    "environments/map/map.tscn": "map_components/map.tscn",
    "environments/map/map.gd": "map_components/map.gd",
    "environments/map/world_generator.gd": "map_components/world_generator.gd",
    "environments/map/tree_spawner.gd": "map_components/tree_spawner.gd",
    "environments/map/flower_spawner.gd": "map_components/flower_spawner.gd",
    "environments/map/player_spawner.gd": "map_components/player_spawner.gd",
    "environments/map/firefly_manager.gd": "map_components/firefly_manager.gd",
    "environments/map/lighting_system.gd": "map_components/lighting_system.gd",
    "environments/map/time_system.gd": "map_components/time_system.gd",
    "environments/map/rain_system.tscn": "map_components/rain_system.tscn",
    "environments/map/rain_system.gd": "map_components/rain_system.gd",
    "environments/map/rain_controller.gd": "map_components/rain_controller.gd",

    # entities/objects -> map_components
    "entities/objects/well.tscn": "map_components/well.tscn",
    "entities/objects/well.gd": "map_components/well.gd",
    "entities/objects/hint_pickup.tscn": "map_components/hint_pickup.tscn",
    "entities/objects/hint_pickup.gd": "map_components/hint_pickup.gd",
    "entities/objects/water_bubble.tscn": "map_components/water_bubble.tscn",
    "entities/objects/water_bubble.gd": "map_components/water_bubble.gd",

    # entities/player -> player
    "entities/player/player.tscn": "player/player.tscn",
    "entities/player/player.gd": "player/player.gd",
    "entities/player/camera_shake.gd": "player/camera_shake.gd",
}

# Ensure parent directories exist
for new_path in moves.values():
    os.makedirs(os.path.dirname(new_path), exist_ok=True)

# Build replacements dictionary
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
        
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated references in: {filepath}")

# Process text files
extensions = ['.tscn', '.tres', '.gd', '.cfg', '.godot']
for root_dir, dirs, files in os.walk("."):
    if ".git" in root_dir or ".godot" in root_dir or "addons" in root_dir or "venv" in root_dir:
        continue
    for file in files:
        if any(file.endswith(ext) for ext in extensions):
            update_file_contents(os.path.join(root_dir, file))

# Move files
for old, new in moves.items():
    if os.path.exists(old):
        shutil.move(old, new)
        print(f"Moved {old} -> {new}")
    
    # Move .uid
    if os.path.exists(old + ".uid"):
        shutil.move(old + ".uid", new + ".uid")
    # Move .import
    if os.path.exists(old + ".import"):
        shutil.move(old + ".import", new + ".import")

# Cleanup empty directories
dirs_to_clean = ["ui/popups", "ui/riddle", "systems/ai", "systems", "environments/map", "environments", "entities/objects", "entities/player", "entities"]
for d in dirs_to_clean:
    if os.path.exists(d):
        for root_dir, dirs, files in os.walk(d, topdown=False):
            try:
                os.rmdir(root_dir)
                print(f"Removed empty dir: {root_dir}")
            except OSError:
                pass

print("Refactoring complete.")
