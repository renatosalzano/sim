@tool
extends Node

var patches:= {}

func print_patches() -> void:
	print(patches)

func has_patch(global_index: Vector2i) -> bool:
	return patches.has(global_index)


