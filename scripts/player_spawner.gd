extends Node

@export var width := 200
@export var height := 200

@onready var tilemap := $"../TileMap"
@onready var player := $"../Player"

const GRASS = Vector2i(0, 0)

func spawn_on_nearest_grass():
	var center := Vector2i(width / 2, height / 2)

	var best_pos := center
	var best_dist := INF

	for x in width:
		for y in height:
			var pos := Vector2i(x, y)

			if tilemap.get_cell_atlas_coords(pos) == GRASS:
				var d := pos.distance_squared_to(center)
				if d < best_dist:
					best_dist = d
					best_pos = pos

	var tile_size := Vector2(tilemap.tile_set.tile_size)
	player.global_position = tilemap.map_to_local(best_pos) + tile_size / 2.0
