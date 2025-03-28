@tool
extends Node

var tiles:= {}
var _tiles:Array[Vector2i] = []

func set_tile(global_index: Vector2i) -> void:
	tiles[global_index] = null
	_tiles.append(global_index)
	pass

func has_tile(global_index: Vector2i) -> bool:
	return tiles.has(global_index)

func get_tile(global_index: Vector2i):
	if tiles.has(global_index):
		return tiles[global_index]

func test(tile_index: Vector2i):
	print(tile_index, tiles[tile_index].min_lod)