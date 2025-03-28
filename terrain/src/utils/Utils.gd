class_name Utils extends Node

var hash_map:= {}

func _init(instance: Node) -> void:
	instance.add_child(self)


func debounce(callback: Callable, ms: int) -> void:

	if !is_inside_tree():
		callback.call()
		return

	var key:= callback.hash()
	
	if !hash_map.has(key):
		hash_map[key] = null

	if hash_map[key] is SceneTreeTimer:
		if hash_map[key].timeout.is_connected(callback):
			hash_map[key].timeout.disconnect(callback)
	
	hash_map[key] = get_tree().create_timer(ms / 1000, true, false)
	hash_map[key].timeout.connect(callback)


		