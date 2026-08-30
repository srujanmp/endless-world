# Endless Worlds

**Endless Worlds** is an educational 2D top-down exploration game built in **Godot 4** that merges environmental sandbox gameplay with advanced AI-powered learning. 

Players navigate a procedurally-generated island world while solving AI-generated riddles and programming-focused educational challenges. Unlike static educational games, Endless Worlds leverages **Live Web Scraping**, **LLM Integration (Groq API)**, **Reinforcement Learning (RL)**, and **Live Code Execution** to create a deeply dynamic, personalized, and context-aware learning environment.

---

## 🌟 Key Features

### 🧠 Advanced AI & Learning Systems
- **Dynamic Content Generation:** Uses a Python backend to web-scrape context for user-selected topics, then uses the Groq API to generate unique riddles on the fly.
- **Reinforcement Learning (RL) Difficulty:** A built-in Q-Learning algorithm (`DifficultyRL`) analyzes your success rate and hint usage to dynamically adjust the difficulty of questions, ensuring you stay in the optimal learning flow.
- **Live Code Execution:** Integrated with the Piston API, allowing players to execute and validate real programming code directly within the game's UI.
- **Agentic Bot & Learning Journal:** Features an AI assistant (Agentic Bot) and a Learning Journal that tracks solved riddles, learned concepts, definitions, and real-world examples.
- **Progressive Scoring:** Gamified learning with stats (Logic, Memory) instead of just XP.

### 🌍 World & Exploration
- **Procedural Generation:** Simplex noise-based terrain generation featuring diverse biomes (grass, dirt, clay, magma, water) and connected islands.
- **Dynamic Environment:** A fully realized day-night cycle, dynamic lighting systems, and weather systems (including multi-layer parallax rain).
- **Immersive Physics:** Depth-based visual sinking in water, movement slowdowns, splash particle effects, and procedural object placement (flowers, trees, interactive wells, hint pickups).
- **Entity Mechanics:** Smooth top-down player movement with sprinting, camera shake, and animated footstep trails.

### 🎮 Interface & Accessibility
- **Multi-Input Support:** Seamlessly supports Keyboard/Mouse, Gamepads, and Touch devices (via Virtual Joystick).
- **Custom Virtual Keyboard:** Fully integrated virtual keyboard for accessibility and mobile support.
- **Polished UI:** Immersive HUDs, interactive popup dialogs, animated hint bulbs, and custom typography.

---

## 📁 How to Read the Folder Structure

The project has been deeply refactored into a scalable, feature-based modular architecture. Instead of separating scripts and scenes blindly, files are grouped by their logical function in the game. 

```text
endless-world/
├── core/                  # The backbone: Autoloads, Globals, and environment managers.
│   ├── global.gd          # Persistent game state and configuration.
│   ├── env_loader.gd      # Loads secrets from the .env file.
│   └── ambience_manager.gd
│
├── map_components/        # The procedural world generator, tilemaps, day/night cycles,
│                          # weather (rain), entity spawners (trees, fireflies, flowers),
│                          # and interactable world items (Wells, Hint Pickups, Water Bubbles).
│
├── player/                # Player scenes, movement logic, and camera effects.
│
├── ai/                    # 🧠 The brain of the game:
│   ├── difficulty_rl.gd          # Reinforcement Learning (Q-Learning) engine.
│   ├── rl_overlay.gd             # UI overlay for debugging the RL state.
│   ├── ai_question_generator.tscn # Web scraping and LLM API bridge.
│   └── agentic_bot.gd            # AI assistant logic.
│
├── ui/                    # All User Interface screens and components.
│   ├── gameplay/          # In-game HUD (Hearts, Joystick, Tasks).
│   ├── home_screen/       # Main Menu and topic selection.
│   ├── journal/           # The Learning Journal for reviewing concepts.
│   ├── answerpopups/      # The riddle answering interface and code execution.
│   ├── questionhintsetup/ # Riddle interaction UI and Hint Bulbs.
│   ├── tutorial/          # Onboarding overlays.
│   └── virtual_keyboard/  # On-screen keyboard for mobile/accessibility.
│
├── assets/                # Static visual and audio assets (fonts, images).
├── resources/             # Godot resource files (e.g., TileSets).
├── shaders/               # GLSL/Godot shaders (Fog, Screen Blur).
└── python_server/         # Fastapi/Python backend for web scraping.
```

---

## 🚀 Setup Instructions

1. **Godot 4**: Ensure you have Godot 4.x installed.
2. **Environment Variables**: Create a `.env` file in the root directory containing your necessary API keys (e.g., Groq API). You can use `test.env` as a template.
3. **Python Backend (Optional but recommended)**: Navigate to `python_server/`, install the dependencies from your virtual environment, and run the backend to enable live web-scraping for riddles.
4. **Play**: Open `project.godot` in the engine and run the project!

---

## 📈 Planned Features
- **Computer Vision:** Integration for identifying real-world concepts via webcam.
- **Expanded Accessibility:** Text-to-speech for audio hints and simple language modes.
- **Global Leaderboards:** Competitive learning with local and global high scores.
- **Daily Quests:** "Riddle of the Day" and "Concept of the Day".
