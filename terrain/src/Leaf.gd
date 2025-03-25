class_name Leaf extends StaticBody3D

var index: Vector2i
var shader: Shader = preload("./shader/terrain.gdshader")
var tiles:= Node3D.new()

var camera: Camera3D
var lods: Array[int] = []

func _init(i: Vector2i, size: int, meshes: Array, hm: ImageTexture) -> void:

	index = i

	add_child(tiles)

	var tile_size:= 64
	# var tile_count:= size / tile_size

	var offset:= Vector2(
			7 * -32.0,
			7 * -32.0
		)

	lods.resize(meshes.size())

	for idx in lods.size():
		lods[idx] = 64 * (idx + 1)

	# print(lods)


	for x in 8:
		for y in 8:
			var tile_index = Vector2i((index.x * 8) + x, (index.y * 8) + y)
			var reposition = Vector3(offset.x + (x * tile_size), 0, offset.y + (y * tile_size))
			var tile = Tile.new(tile_index, meshes, shader, hm)

			tile.set_shader({ max_distance_LOD=lods[-1] })

			tile.translate(reposition)
			tiles.add_child(tile)


func enable():
	# print('max lod ', lods[-1])
	if Engine.is_editor_hint():
		camera = EditorInterface.get_editor_viewport_3d().get_camera_3d()
	each(func(tile): 
		tile.set_lod(tile.min_lod)
		tile.set_shader({ global_position = tile.global_position })
	)


func disable():
	camera = null
	each(func(tile): tile.set_lod(-1))


func update(camera_position: Vector3):
	# printraw("\r" + str(camera_position))

	each(func(tile):
		var distance = tile.global_position.distance_to(camera_position)
		# printraw("\r camera: "+ str(distance))

		if distance >= lods[-1]:
			tile.set_lod(tile.min_lod, camera_position)
		else:
			var lod = 0

			for i in lods.size():
				if distance < lods[i]:
					lod = i
					break
			
			tile.set_lod(lod, camera_position)
	)

	pass

var curr_position:= Vector3.ZERO

# func _process(_delta: float):
# 	if camera:
# 		printraw('\r'+ str(camera.global_position))
# 	pass


func each(callable: Callable):
	for tile in tiles.get_children():
		callable.call(tile)


func set_shader(dict: Dictionary):
	each(func(tile: Tile): tile.set_shader(dict))


class Tile extends MeshInstance3D:
	var index: Vector2i
	var meshes: Array = []
	var material:= ShaderMaterial.new()
	var min_lod:= 0

	func _init(i: Vector2i, _meshes: Array, shader: Shader, hm: ImageTexture) -> void:
		index = i
		meshes = _meshes
		min_lod = _meshes.size() - 1

		# var size:= 64

		var level:= 5.0

		material_override = material
		material_override.shader = shader

		material_override.set_shader_parameter("hm", hm)
		material_override.set_shader_parameter("level", level)
		material_override.set_shader_parameter("index", index)
		material_override.set_shader_parameter("is_tile", true)
		material_override.set_shader_parameter("min_LOD", min_lod)
		pass

	func set_lod(lod: int, camera_position:= Vector3.ZERO) -> void:
		if lod == -1:
			mesh = null
		else:
			lod = min(lod, min_lod)
			mesh = meshes[lod]
			set_shader({ LOD=lod, camera_position=camera_position })

	
	func set_shader(dict: Dictionary):
		for key in dict:
			material_override.set_shader_parameter(key, dict[key])
