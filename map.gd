extends Node

@onready var tile_layer: TileMapLayer = $TileMap

# MAP SIZE
const MAP_WIDTH = 100
const MAP_HEIGHT = 100

# ATLAS SOURCE ID
const ATLAS_ID = 0

# ATLAS COORDINATES
const WATER = Vector2i(0, 0)
const SAND = Vector2i(6, 0)

const LIGHT_GRASS = Vector2i(0, 3)
const DARK_GRASS = Vector2i(3, 3)
const MEDIUM_DARK_GRASS = Vector2i(6, 3)
const BRIGHT_GRASS = Vector2i(0, 6)
const DULL_GRASS = Vector2i(3, 6)

const DRIED_GRASS = Vector2i(3, 9)
const DARK_DRIED_GRASS = Vector2i(0, 9)

const MAGMA = Vector2i(6, 6)

func _ready():
	randomize()
	generate_island()

func generate_island():
	tile_layer.clear()

	var center := Vector2(MAP_WIDTH / 2, MAP_HEIGHT / 2)
	var max_radius := min(MAP_WIDTH, MAP_HEIGHT) / 2 - 5

	for x in MAP_WIDTH:
		for y in MAP_HEIGHT:
			var pos := Vector2(x, y)
			var distance := pos.distance_to(center)

			# Organic edges
			var noise := randf_range(-6.0, 6.0)
			var island_radius := max_radius + noise

			if distance > island_radius:
				set_tile(x, y, WATER)
			elif distance > island_radius - 4:
				set_tile(x, y, SAND)
			else:
				set_tile(x, y, random_grass())

	add_magma_core(center)

func random_grass() -> Vector2i:
	var grass_tiles := [
		LIGHT_GRASS,
		DARK_GRASS,
		MEDIUM_DARK_GRASS,
		BRIGHT_GRASS,
		DULL_GRASS,
		DRIED_GRASS,
		DARK_DRIED_GRASS
	]
	return grass_tiles.pick_random()

func add_magma_core(center: Vector2):
	if randf() < 0.3:
		for x in range(-3, 4):
			for y in range(-3, 4):
				set_tile(
					int(center.x) + x,
					int(center.y) + y,
					MAGMA
				)

func set_tile(x: int, y: int, atlas_coords: Vector2i):
	tile_layer.set_cell(
		Vector2i(x, y),   # cell position
		ATLAS_ID,         # atlas source id
		atlas_coords      # atlas coords
	)
