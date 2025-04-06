@tool
extends Node

var chunk_max_size:= 2048
var chunk_min_size:= 128

var chunks:= {}

signal changed

func has_chunk(global_index: Vector2i) -> bool:
	return chunks.has(global_index)

func get_chunk(global_index: Vector2i) -> Chunk:
	return chunks[global_index]

func emit_changed() -> void:
	changed.emit()