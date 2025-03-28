class_name Leaf extends StaticBody3D

var shader: Shader = preload("./shader/terrain.gdshader")

var collision:= CollisionShape3D.new()
var heightmap_shape:= HeightMapShape3D.new()
var heightmap_region: Image

var index: Vector2i
var patches:= Node3D.new()

var camera: Camera3D
var lods: Array[int] = []
var leaf_size: int
var utils:= Utils.new(self)

func _init(i: Vector2i, size: int, meshes: Array, _heightmap: ImageTexture, _heightmap_height: float, _root_index: Vector2i) -> void:

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

	# print("ROOT INDEX ", _root_index * 32)

	for idx in lods.size():
		lods[idx] = 64 * (idx + 1)

	# max_distance_LOD = 448

	add_child(patches)
	add_child(collision)

	var _global_offset:= _root_index * 32

	# print("GLOBAL OFFSET ", _global_offset)

	for x in 8:
		for y in 8:
			var _index:= Vector2i(x, y)

			var patch_index:= Vector2i((index.x * 8) + x, (index.y * 8) + y)
			var global_index:= patch_index + _global_offset

			var reposition:= Vector3(offset.x + (x * tile_size), 0, offset.y + (y * tile_size))

			var patch = Patch.new(_index, patch_index, global_index, meshes, shader, _heightmap, _heightmap_height)

			patch.calc_height(heightmap_region, _heightmap_height)
			patch.set_shader({ max_distance_LOD=lods[-1] })
			patch.translate(reposition)

			patches.add_child(patch)

	update_collision(_heightmap_height)


func update_collision(_heightmap_height: float, _heightmap: ImageTexture = null) -> void:

	var update_fn:= func():
		var image:= heightmap_region if _heightmap == null else get_region(_heightmap)

		collision.shape.update_map_data_from_image.call_deferred(image, 0.0, _heightmap_height)

	var start_task:= func():
		# printraw('\r task started')
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
	for patch: Patch in patches.get_children():
		callable.call(patch)


func set_shader(dict: Dictionary):
	each(func(tile: Patch): tile.set_shader(dict))


func get_region(_heightmap: ImageTexture) -> Image:
	
	var src:= _heightmap.get_image()
	var pos:= index * leaf_size
	var region_size:= Vector2(leaf_size + 1, leaf_size + 1)
	var region:= src.get_region(Rect2i(pos, region_size))

	return region
