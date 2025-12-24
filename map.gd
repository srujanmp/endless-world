extends Node

@export var width := 800
@export var height := 800

@onready var tilemap : TileMapLayer = $TileMap
@onready var noise := FastNoiseLite.new()

const SRC := 0  # atlas source id

const GRASS = Vector2i(0, 0)
const DIRT  = Vector2i(1, 0)
const CLAY  = Vector2i(2, 0)
const MUD   = Vector2i(3, 0)

const SAND  = Vector2i(0, 1)
const LAVA  = Vector2i(1, 1)
const MAGMA = Vector2i(2, 1)
const WATER = Vector2i(3, 1)

func _ready():
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.04
	noise.seed = randi()

	generate_world()
func fill_water():
	for x in width:
		for y in height:
			tilemap.set_cell(Vector2i(x, y), SRC, WATER)
func generate_island():
	for x in width:
		for y in height:
			var n := noise.get_noise_2d(x, y)

			if n > -0.1:
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
func place_patches(tile: Vector2i, threshold: float):
	for x in width:
		for y in height:
			var n := noise.get_noise_2d(x + randi() % 999, y + randi() % 999)

			if n > threshold:
				var pos := Vector2i(x, y)
				if tilemap.get_cell_atlas_coords(pos) == GRASS:
					tilemap.set_cell(pos, SRC, tile)

func generate_world():
	fill_water()
	generate_island()
	add_sand_edges()

	# Medium dirt clusters
	place_patches(DIRT, 0.45)

	# Small magma clusters
	place_patches(MAGMA, 0.65)

	# Lava inside magma
	for x in width:
		for y in height:
			var pos := Vector2i(x, y)
			if tilemap.get_cell_atlas_coords(pos) == MAGMA and randf() < 0.15:
				tilemap.set_cell(pos, SRC, LAVA)

	# Small ponds
	place_patches(WATER, 0.6)

	# Very small patches
	place_patches(MUD, 0.72)
	place_patches(CLAY, 0.75)
