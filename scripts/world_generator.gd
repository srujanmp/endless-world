extends Node

# ---------------- WORLD SIZE ----------------
@export var width := 200
@export var height := 200

# ---------------- TILE REFERENCES ----------------
@onready var tilemap : TileMapLayer = $"../TileMap"
@onready var noise := FastNoiseLite.new()

# ---------------- TILE ATLAS ----------------
var SRC : int = 0

const GRASS = Vector2i(0, 0)
const DIRT  = Vector2i(1, 0)
const CLAY  = Vector2i(2, 0)
const MUD   = Vector2i(3, 0)

const SAND  = Vector2i(0, 1)
const LAVA  = Vector2i(1, 1)
const MAGMA = Vector2i(2, 1)
const WATER = Vector2i(3, 1)

# ==================================================
# GENERATE WORLD (ENTRY POINT)
# ==================================================
func generate():
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.008
	noise.seed = randi()

	fill_water()
	generate_island()
	add_sand_edges()

	place_patches(DIRT, 0.3, 0.015)
	place_patches(MAGMA, 0.45, 0.02)

	for x in width:
		for y in height:
			var pos := Vector2i(x, y)
			if tilemap.get_cell_atlas_coords(pos) == MAGMA and randf() < 0.12:
				tilemap.set_cell(pos, SRC, LAVA)

	place_patches(WATER, 0.4, 0.018)
	place_patches(MUD, 0.55, 0.025)
	place_patches(CLAY, 0.6, 0.028)

# ==================================================
# CORE STEPS (UNCHANGED)
# ==================================================
func fill_water():
	for x in width:
		for y in height:
			tilemap.set_cell(Vector2i(x, y), SRC, WATER)

func generate_island():
	for x in width:
		for y in height:
			if noise.get_noise_2d(x, y) > -0.1:
				tilemap.set_cell(Vector2i(x, y), SRC, GRASS)

func add_sand_edges():
	for x in range(1, width - 1):
		for y in range(1, height - 1):
			var pos := Vector2i(x, y)

			if tilemap.get_cell_atlas_coords(pos) == GRASS:
				for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					if tilemap.get_cell_atlas_coords(pos + d) == WATER:
						tilemap.set_cell(pos, SRC, SAND)
						break

func place_patches(tile: Vector2i, threshold: float, noise_frequency: float):
	var old_freq := noise.frequency
	noise.frequency = noise_frequency

	for x in width:
		for y in height:
			if noise.get_noise_2d(x, y) > threshold:
				var pos := Vector2i(x, y)
				if tilemap.get_cell_atlas_coords(pos) == GRASS:
					tilemap.set_cell(pos, SRC, tile)

	noise.frequency = old_freq
