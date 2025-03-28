class_name Leaf extends StaticBody3D

var shader: Shader = preload("./shader/terrain.gdshader")

var collision:= CollisionShape3D.new()
var heightmap_shape:= HeightMapShape3D.new()
var heightmap_region: Image

var index: Vector2i
var tiles:= Node3D.new()

var camera: Camera3D
var lods: Array[int] = []
var leaf_size: int
var utils:= Utils.new(self)

func _init(i: Vector2i, size: int, meshes: Array, _heightmap: ImageTexture, _heightmap_height: float) -> void:

	index = i
	leaf_size = size
	heightmap_region = get_region(_heightmap)

	collision.shape = heightmap_shape

	var tile_size:= 64
	# var tile_count:= size / tile_size

	var offset:= Vector2(
			7 * -32.0,
			7 * -32.0
		)

	lods.resize(meshes.size())

	for idx in lods.size():
		lods[idx] = 64 * (idx + 1)

	# max_distance_LOD = 448

	add_child(tiles)
	add_child(collision)

	for x in 8:
		for y in 8:
			var _index:= Vector2i(x, y)

			var tile_index:= Vector2i((index.x * 8) + x, (index.y * 8) + y)
			var reposition:= Vector3(offset.x + (x * tile_size), 0, offset.y + (y * tile_size))

			var tile = Tile.new(_index, tile_index, meshes, shader, _heightmap, _heightmap_height)
			tile.calc_height(heightmap_region, _heightmap_height)

			tile.set_shader({ max_distance_LOD=lods[-1] })

			tile.translate(reposition)
			tiles.add_child(tile)

	update_collision(_heightmap_height)


func update_collision(_heightmap_height: float, _heightmap: ImageTexture = null) -> void:

	var update_fn:= func():
		var image:= heightmap_region if _heightmap == null else get_region(_heightmap)

		collision.shape.update_map_data_from_image.call_deferred(image, 0.0, _heightmap_height)

	var start_task:= func():
		printraw('\r task started')
		WorkerThreadPool.add_task(update_fn)

	utils.debounce(start_task, 2000)
	pass


func update_shader(params: Dictionary) -> void:

	each(func(tile): tile.set_shader(params))

	if params.has("height_scale") || params.has("heightmap"):
		var texture: ImageTexture = null

		if params.has("heightmap"):
			texture = params.heightmap
		
		update_collision.call_deferred(params.height_scale, texture)


func enable():
	# print('max lod ', lods[-1])
	# if Engine.is_editor_hint():
	# 	camera = EditorInterface.get_editor_viewport_3d().get_camera_3d()
	each(func(tile): 
		tile.set_lod(tile.min_lod)
		# tile.set_shader({ global_position = tile.get_gloabl_position() })
	)


func disable():
	camera = null
	each(func(tile): tile.set_lod(-1))


func check_distance(camera_position: Vector3):
	# printraw("\r" + str(camera_position))

	each(func(tile):
		var distance = tile.get_gloabl_position().distance_to(camera_position)
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


func get_region(_heightmap: ImageTexture) -> Image:
	
	var src:= _heightmap.get_image()
	var pos:= index * leaf_size
	var region_size:= Vector2(leaf_size + 1, leaf_size + 1)
	var region:= src.get_region(Rect2i(pos, region_size))

	return region


class Tile extends MeshInstance3D:
	var index: Vector2i
	var tile_index: Vector2i
	var meshes: Array = []
	var material:= ShaderMaterial.new()
	var min_lod:= 0
	var height:= 0.0

	var neightbors: Array[Vector2i] = [
		Vector2i( 0, -1),
		Vector2i( 0,  1),
		Vector2i(-1,  0),
		Vector2i( 1,  0)
	]

	var neightbors_lod: Array[int] = [0,0,0,0]
			
	
	func _init(i: Vector2i, tile_i: Vector2i, _meshes: Array, shader: Shader, _heightmap: ImageTexture, _heightmap_height: float) -> void:
		index = i
		tile_index = tile_i
		meshes = _meshes
		min_lod = _meshes.size() - 1

		
		# Store.set_tile(tile_index)

		# var size:= 64


		for idx: int in 4:
			neightbors[idx] += tile_index

		var level:= 5.0

		material_override = material
		material_override.shader = shader

		material_override.set_shader_parameter("heightmap", _heightmap)
		material_override.set_shader_parameter("height_scale", _heightmap_height)
		material_override.set_shader_parameter("level", level)
		material_override.set_shader_parameter("index", tile_index)
		material_override.set_shader_parameter("is_tile", true)
		material_override.set_shader_parameter("min_LOD", min_lod)

		pass

	
	func _ready() -> void:
		Store.tiles[tile_index] = self


	func calc_height(_heightmap_region: Image, _heightmap_height: float) -> void:
		# var center_index:= 2112 # 32 * 65 + 32
		var offset:= Vector2i(32,32) * index
		height = _heightmap_region.get_pixelv(Vector2i(32,32) + offset).r * _heightmap_height

	
	func get_gloabl_position() -> Vector3:
		# return global_position
		var _global_position:= global_position
		_global_position.y = height
		return _global_position


	var keys:= [
		"LOD_1",
		"LOD_0",
		"LOD_3",
		"LOD_2",
	]


	func set_lod(lod: int, camera_position:= Vector3.ZERO) -> void:

		printraw('\r update' + str(tile_index))

		for i: int in 4:
			# 0: bottom 1: top 2: right 3: left
			var neightbor:= neightbors[i]

			if Store.has_tile(neightbor):
				# Store.tiles[neightbor].neightbors_lod[p[i]] = lod
				match i:
					0: Store.tiles[neightbor].set_shader({LOD_1 = lod})
					1: Store.tiles[neightbor].set_shader({LOD_0 = lod})
					2: Store.tiles[neightbor].set_shader({LOD_3 = lod})
					3: Store.tiles[neightbor].set_shader({LOD_2 = lod})
				# Store.tiles[neightbor].material_override.set_shader_parameter(key, lod)
				# Store.tiles[neightbor].set_shader({[key]})

			
		if lod == -1:
			mesh = null
		else:
			lod = min(lod, min_lod)
			mesh = meshes[lod]
			set_shader({ LOD=lod, camera_position=camera_position })



	
	func set_shader(dict: Dictionary) -> void:
		for key: StringName in dict:
			material_override.set_shader_parameter(key, dict[key])


