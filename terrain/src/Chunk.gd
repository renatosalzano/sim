class_name Chunk extends MeshInstance3D

var shader: Shader = preload("./shader/terrain.gdshader")

var index: Vector2i
var level:= 0
var is_leaf:= false

var chunk_mesh: Mesh
var radius: float

var leaf: Leaf

func _init(_index: Vector2i, _meshes: Dictionary, _heightmap: ImageTexture, _size:= 2048, _level:= 0) -> void:
	index = _index
	level = _level
	
	var l:= pow(_size, 2)
	radius = sqrt(l + l) / 2.0

	material_override = ShaderMaterial.new()
	material_override.shader = shader

	set_shader({
		level = 0,
		index = index,
		heightmap = _heightmap
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
				var child:= Chunk.new(child_index, _meshes, _heightmap, child_size, level + 1)

				add_child(child)

				child.translate(Vector3(
					(x * child_size) - offset,
					0,
					(y * child_size) - offset
				))

				
	else:
		is_leaf = true
		leaf = Leaf.new(index, 512, _meshes.leaf, _heightmap)

	pass


func set_shader(params: Dictionary) -> void:
	for k in params:
		material_override.set_shader_parameter(k, params[k])


class Tiles:
	var index: Vector2i
	var lods: Array[int] = []
	var tiles:= Node3D.new()