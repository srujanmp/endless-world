extends Node2D

@onready var world := $WorldGenerator
@onready var time := $TimeSystem
@onready var rain := $RainController
@onready var lighting := $LightingSystem
@onready var spawner := $PlayerSpawner

@onready var player := $Player
@onready var player_shape: CollisionShape2D = $Player/CollisionShape2D
@onready var tilemap : TileMapLayer = $TileMap
@onready var hearts := $HeartSystem   # ❤️ Heart system

# ================= TILE INFO =================
const TILE_NAMES := {
	Vector2i(0, 0): "Grass",
	Vector2i(1, 0): "Dirt",
	Vector2i(2, 0): "Clay",
	Vector2i(3, 0): "Mud",
	Vector2i(0, 1): "Sand",
	Vector2i(1, 1): "Lava",
	Vector2i(2, 1): "Magma",
	Vector2i(3, 1): "Water",
}

var tile_info_label: Label

# ================= DAMAGE SETTINGS =================
const DAMAGE_INTERVAL := 3.0  # seconds
var damage_timer := 0.0

# ==================================================
func _ready():
	world.generate()
	lighting.spawn_lava_lights()
	time.init_time()
	spawner.spawn_on_nearest_grass()

	create_tile_info_ui()

# ==================================================
func _process(delta):
	damage_timer -= delta
	update_player_tile_info()

# ==================================================
# TILE INFO UI
# ==================================================
func create_tile_info_ui():
	var canvas := CanvasLayer.new()
	add_child(canvas)

	tile_info_label = Label.new()
	canvas.add_child(tile_info_label)

	# Top-right using anchors (SAFE)
	tile_info_label.anchor_left = 1
	tile_info_label.anchor_top = 0
	tile_info_label.anchor_right = 1
	tile_info_label.anchor_bottom = 0

	tile_info_label.offset_left = -200
	tile_info_label.offset_top = 60
	tile_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tile_info_label.add_theme_font_size_override("font_size", 16)

# ==================================================
# TILE CHECK + DAMAGE
# ==================================================
func update_player_tile_info():
	var cell := tilemap.local_to_map(
		tilemap.to_local(player_shape.global_position)
	)

	var atlas := tilemap.get_cell_atlas_coords(cell)
	player.in_water = (atlas == Vector2i(3, 1))

	tile_info_label.text = "Tile: " + TILE_NAMES.get(atlas, "Unknown")

	# ---- DAMAGE WITH COOLDOWN ----
	if damage_timer > 0:
		return

	match atlas:
		Vector2i(1, 1): # Lava
			hearts.damage(1)
			damage_timer = DAMAGE_INTERVAL

		Vector2i(2, 1): # Magma
			hearts.damage(1)
			damage_timer = DAMAGE_INTERVAL

		Vector2i(3, 1): # Water
			hearts.damage(1)
			damage_timer = DAMAGE_INTERVAL

# ==================================================
# DEBUG INPUT (Optional)
# ==================================================
func _input(event):
	if event.is_action_pressed("ui_accept"):
		hearts.damage(1)
	if event.is_action_pressed("ui_cancel"):
		hearts.heal(1)
