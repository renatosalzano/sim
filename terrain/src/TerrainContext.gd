@tool
extends Node

var chunk_max_size:= 2048
var chunk_min_size:= 128

var chunks:= []

func has_chunk(level: int, global_index: Vector2i) -> bool:
	return chunks[level].has(global_index)

func get_chunk(level: int, global_index: Vector2i) -> Chunk:
	return chunks[level][global_index]

