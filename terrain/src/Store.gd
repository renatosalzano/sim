@tool
extends Node

var chunks:= {}
var patches:= {}

func print_patches() -> void:
	print(patches)

func has_patch(global_index: Vector2i) -> bool:
	return patches.has(global_index)

func has_chunk(global_index: Vector2i) -> bool:
	return chunks.has(global_index)
