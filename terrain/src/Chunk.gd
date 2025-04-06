class_name Chunk extends MeshInstance3D

var shader: Shader = preload("./shader/terrain.gdshader")

var index: Vector2i
var level:= 0
var chunk_mesh: Mesh
var lod_mesh: Array = []
var radius: float
var divided:= false

var heightmap: Image
var heightmap_h: float

signal update_heightmap(_heightmap: Image)


func _init(
	_index: Vector2i,
	_meshes: Dictionary,
	_heightmap: Image,
	_heightmap_texture: ImageTexture,
	_heightmap_height: float,
	_size:= 2048,
	_level:= 0,
	_root_index:= Vector2i(0,0)
) -> void:


	index = _index
	level = _level
	heightmap = _heightmap
	heightmap_h = _heightmap_height
	_root_index = _index if level == 0 else _root_index
	
	var l:= pow(_size, 2)
	radius = sqrt(l + l) / 2.0

	material_override = ShaderMaterial.new()
	material_override.shader = shader

	set_shader.call_deferred({
		level = level,
		index = index,
		heightmap = _heightmap_texture,
		height_scale = _heightmap_height,
	})

	chunk_mesh = _meshes.chunk[level]
	mesh = chunk_mesh if level == 0 else null

	
	if _size > TerrainContext.chunk_min_size:

		var child_size: int = _size / 2
		var offset:= child_size / 2

		var is_leaf:= child_size == TerrainContext.chunk_min_size

		var global_offset: Vector2i
		if is_leaf:
			global_offset = _root_index * 16

		# y x-->
		# |
		# v

		for y in 2:
			for x in 2:

				var child_index:= Vector2i((index.x * 2) + x, (index.y * 2) + y) if level > 0 else Vector2i(x,y)

				var child:= ChunkLeaf.new(
					child_index,
					_meshes,
					_heightmap,
					_heightmap_texture,
					_heightmap_height,
					child_size,
					level + 1,
					_root_index,
					global_offset
				) if is_leaf else Chunk.new(
					child_index,
					_meshes,
					_heightmap,
					_heightmap_texture,
					_heightmap_height,
					child_size,
					level + 1,
					_root_index
				)

				child.position = Vector3(
					(x * child_size) - offset,
					0,
					(y * child_size) - offset
				)

				add_child.call_deferred(child)

	# else:
	# 	is_leaf = true
	# 	lod_mesh = _meshes.leaf
	# 	LOD_distance = _meshes.LOD_distance
	# 	min_LOD = _meshes.leaf.size() - 1

	# 	LOD = min_LOD

	# 	var center_vertex:= Vector2i(_size / 2, _size / 2)
	# 	var offset:= center_vertex * index
	# 	center_height = heightmap.get_pixelv(center_vertex + offset).r * heightmap_h

	# 	var global_index:= index + _global_index_offset
	# 	TerrainContext.chunks[global_index] = self




	pass



func check_distance(camera_position: Vector3):

	# printraw('\r check distance ' + str(camera_position))

	# if is_leaf && divided:
	# 	# calc LOD
	# 	check_leaf_distance(camera_position)

	var distance:= camera_position.distance_to(global_position) - 1024 # max lod in tile

	if distance < radius:
		# printraw("\r inside")
		if !divided:
			divided = true
			subdivide()
		else:
			each(func(q, _i): q.check_distance(camera_position))
	else:
		# printraw("\r outside")
		if divided:
			divided = false
			combine(level)


func subdivide():

	if self is ChunkLeaf:
		return

	mesh = null
	each(func(q, _i): q.mesh = q.chunk_mesh)
	# mesh = null
	# if is_leaf:
	# 	leaf.enable()
	# else:
	# 	each(func(q): q.mesh = q.chunk_mesh)




func combine(_level: int):
	# if leaf:
	# 	leaf.disable()
	
	mesh = chunk_mesh if level == _level else null
	each(func(q, _i):
		q.divided = false
		q.combine(_level)
	)


func each(callback: Callable):
	var i:= 0;
	for quad in get_children():
		callback.call(quad, i)
		i += 1


func set_shader(params: Dictionary) -> void:
	for k in params:
		material_override.set_shader_parameter(k, params[k])


func update_shader(params: Dictionary) -> void:
	set_shader(params)
	for quad in get_children():
		quad.update_shader(params)


