import os
import shutil
import glob

moves = {
    # ------------------
    # ENTITIES
    # ------------------
    # Player
    "scenes/player.tscn": "entities/player/player.tscn",
    "scripts/player.gd": "entities/player/player.gd",
    "scripts/camera_shake.gd": "entities/player/camera_shake.gd",
    
    # Objects
    "scenes/well.tscn": "entities/objects/well.tscn",
    "scripts/well.gd": "entities/objects/well.gd",
    "scenes/hint_pickup.tscn": "entities/objects/hint_pickup.tscn",
    "scripts/hint_pickup.gd": "entities/objects/hint_pickup.gd",
    "scenes/water_bubble.tscn": "entities/objects/water_bubble.tscn",
    "scripts/water_bubbles/WaterBubble.gd": "entities/objects/water_bubble.gd",

    # ------------------
    # ENVIRONMENTS
    # ------------------
    "map/map.tscn": "environments/map/map.tscn",
    "map/map.gd": "environments/map/map.gd",
    "map/world_generator.gd": "environments/map/world_generator.gd",
    "map/tree_spawner.gd": "environments/map/tree_spawner.gd",
    "map/flower_spawner.gd": "environments/map/flower_spawner.gd",
    "map/player_spawner.gd": "environments/map/player_spawner.gd",
    "map/firefly_manager.gd": "environments/map/firefly_manager.gd",
    "map/lighting_system.gd": "environments/map/lighting_system.gd",
    "map/time_system.gd": "environments/map/time_system.gd",
    "map/rain_system.tscn": "environments/map/rain_system.tscn",
    "map/rain_system.gd": "environments/map/rain_system.gd",
    "map/rain_controller.gd": "environments/map/rain_controller.gd",

    # ------------------
    # SYSTEMS (AI & RL)
    # ------------------
    "ai/DifficultyRL.gd": "systems/ai/difficulty_rl.gd",
    "map/rl_overlay.gd": "systems/ai/rl_overlay.gd",
    "scenes/ai_question_generator.tscn": "systems/ai/ai_question_generator.tscn",
    "scripts/ai_question_generator.gd": "systems/ai/ai_question_generator.gd",
    "scripts/ui/AgenticBot.gd": "systems/ai/agentic_bot.gd",

    # ------------------
    # UI
    # ------------------
    "scenes/home_screen.tscn": "ui/home_screen/home_screen.tscn",
    "scripts/home_screen.gd": "ui/home_screen/home_screen.gd",
    
    "scenes/answer_popup.tscn": "ui/popups/answer_popup.tscn",
    "scripts/answer_popup.gd": "ui/popups/answer_popup.gd",
    
    "scenes/joy_stick_ui.tscn": "ui/gameplay/joy_stick_ui.tscn",
    "scenes/tasks.tscn": "ui/gameplay/tasks.tscn",
    "scripts/tasks.gd": "ui/gameplay/tasks.gd",
    "scripts/ui/HeartSystem.gd": "ui/gameplay/heart_system.gd",
    
    "scripts/ui/LearningJournal.gd": "ui/journal/learning_journal.gd",
    "virtual_keyboard/CustomKeyboard.gd": "ui/virtual_keyboard/custom_keyboard.gd",
    
    "scripts/riddleui/HintBulb.gd": "ui/riddle/hint_bulb.gd",
    "scripts/riddleui/RiddleUI.gd": "ui/riddle/riddle_ui.gd",
    
    "tutorialscene/TutorialButton.tscn": "ui/tutorial/tutorial_button.tscn",
    "tutorialscene/tutorial_button.gd": "ui/tutorial/tutorial_button.gd",
    "tutorialscene/TutorialOverlay.tscn": "ui/tutorial/tutorial_overlay.tscn",
    "tutorialscene/tutorial_overlay.gd": "ui/tutorial/tutorial_overlay.gd",

    # ------------------
    # CORE
    # ------------------
    "scripts/utils/Global.gd": "core/global.gd",
    "scripts/utils/env_loader.gd": "core/env_loader.gd",
    "ambience/ambience_manager.gd": "core/ambience_manager.gd",
}

# Create all necessary parent directories
for new_path in moves.values():
    os.makedirs(os.path.dirname(new_path), exist_ok=True)

# Generate replacements for 'res://' paths
replacements = {}
for old, new in moves.items():
    replacements[f"res://{old}"] = f"res://{new}"

# Function to replace text in files
def update_file_contents(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except UnicodeDecodeError:
        return
        
    original = content
    # Replace res:// paths
    for old_res, new_res in replacements.items():
        content = content.replace(old_res, new_res)
    
    # We also update some explicit strings or class names if necessary,
    # but the paths are the most important part for Godot dependencies.
    # Note: we need to handle case variations if there are any specific imports like preload("res://...").
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated references in: {filepath}")

# Update all text resources
extensions = ['.tscn', '.tres', '.gd', '.cfg', '.godot']
for root_dir, dirs, files in os.walk("."):
    if ".git" in root_dir or ".godot" in root_dir or "addons" in root_dir or "venv" in root_dir:
        continue
    for file in files:
        if any(file.endswith(ext) for ext in extensions):
            update_file_contents(os.path.join(root_dir, file))

# Move files along with their .uid and .import files
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
dirs_to_clean = ["scripts", "scenes", "map", "ai", "ambience", "tutorialscene", "virtual_keyboard"]
for d in dirs_to_clean:
    if os.path.exists(d):
        # Only remove if empty, might have nested empty dirs
        for root_dir, dirs, files in os.walk(d, topdown=False):
            try:
                os.rmdir(root_dir)
                print(f"Removed empty dir: {root_dir}")
            except OSError:
                pass

print("Deep Refactoring complete.")
