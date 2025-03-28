class_name Chunk extends MeshInstance3D

var shader: Shader = preload("./shader/terrain.gdshader")

var index: Vector2i
var level:= 0

var chunk_mesh: Mesh
var radius: float
var divided:= false

var is_leaf:= false
var leafs: Array[Leaf] = []
var leaf: Leaf

func _init(_index: Vector2i, _meshes: Dictionary, _heightmap: ImageTexture, _heightmap_height: float, _size:= 2048, _level:= 0) -> void:
	index = _index
	level = _level
	
	var l:= pow(_size, 2)
	radius = sqrt(l + l) / 2.0

	material_override = ShaderMaterial.new()
	material_override.shader = shader

	set_shader({
		level = level,
		index = index,
		heightmap = _heightmap,
		height_scale = _heightmap_height
	})

	chunk_mesh = _meshes.chunk[level]

	mesh = chunk_mesh if level == 0 else null
	
	if _size > 512:

		var child_size: int = _size / 2
		var offset:= child_size / 2

		# y x-->
		# |
		# v

		for y in 2:
			for x in 2:
				var child_index:= Vector2i((index.x * 2) + x, (index.y * 2) + y) if level > 0 else Vector2i(x,y)
				var child:= Chunk.new(child_index, _meshes, _heightmap, _heightmap_height, child_size, level + 1)

				add_child(child)

				child.translate(Vector3(
					(x * child_size) - offset,
					0,
					(y * child_size) - offset
				))

				

	else:
		is_leaf = true
		leaf = Leaf.new(index, 512, _meshes.leaf, _heightmap, _heightmap_height)
		leafs.append(leaf)
		add_child(leaf)

	pass




func check_distance(camera_position: Vector3):

	# printraw('\r check distance ' + str(camera_position))

	if is_leaf && divided:
		leaf.check_distance(camera_position)

	var distance:= camera_position.distance_to(global_position) - 448 # max lod in tile

	if distance < radius:
		# printraw("\r inside")
		if !divided:
			divided = true
			subdivide()
		else:
			each(func(q): q.check_distance(camera_position))
	else:
		# printraw("\r outside")
		if divided:
			divided = false
			combine(level)


func subdivide():
	# if leaf: return
	# mesh = null
	# each(func(q): q.mesh = q._mesh)
	mesh = null
	if is_leaf:
		leaf.enable()
	else:
		each(func(q): q.mesh = q.chunk_mesh)


func combine(_level: int):
	if leaf:
		leaf.disable()
	
	mesh = chunk_mesh if level == _level else null
	each(func(q):
		q.divided = false
		q.combine(_level)
	)


func each(callback: Callable):
	for quad in get_children():
		if quad is Chunk:
			callback.call(quad)


func update_collision(_heightmap: ImageTexture, _heightmap_height: int) -> void:
	pass


func set_shader(params: Dictionary) -> void:
	for k in params:
		material_override.set_shader_parameter(k, params[k])


func update_shader(params: Dictionary) -> void:
	set_shader(params)
	for quad in get_children():
		quad.update_shader(params)



class Tiles:
	var index: Vector2i
	var lods: Array[int] = []
	var tiles:= Node3D.new()