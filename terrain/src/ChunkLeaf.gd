class_name ChunkLeaf extends Chunk

var LOD_meshes:= []
var LOD_distance:= []
var LOD_min:= 1
var center_height:= 0.0
var center_position:= Vector3.ZERO
var heightmap_region: Image

var neightbors: Array[Vector2i] = [
	Vector2i( 0, -1),
	Vector2i( 0,  1),
	Vector2i(-1,  0),
	Vector2i( 1,  0)
]

var neightbors_lod: Array[int] = [0,0,0,0]

func _init(
	_index: Vector2i,
	_meshes: Dictionary,
	_heightmap: Image,
	_heightmap_texture: ImageTexture,
	_heightmap_height: float,
	_size:= 2048,
	_level:= 0,
	_root_index:= Vector2i(0,0),
	_global_index_offset:= Vector2i(0,0)
) -> void:

	index = _index
	level = _level
	heightmap = _heightmap
	heightmap_h = _heightmap_height

	material_override = ShaderMaterial.new()
	material_override.shader = shader

	chunk_mesh = _meshes.chunk[level]
	LOD_meshes = _meshes.leaf
	LOD_distance = _meshes.LOD_distance
	LOD_min = _meshes.leaf.size() - 1

	var center_vertex:= Vector2i(_size / 2, _size / 2)
	var offset:= center_vertex * index
	center_height = heightmap.get_pixelv(center_vertex + offset).r * heightmap_h

	var global_index:= index + _global_index_offset
	TerrainContext.chunks[global_index] = self
	TerrainContext.changed.connect(update_neightbors)

	for i: int in neightbors.size():
		neightbors[i] += global_index

	set_shader({
		LOD = LOD_min,
		LOD_min = LOD_min,
		LOD_max_distance = 896,
		is_leaf = true,
		level = level,
		index = index,
		heightmap = _heightmap_texture,
		height_scale = _heightmap_height,
	})

	pass


func _ready() -> void:
	center_position = global_position
	center_position.y = center_height
	material_override.set_shader_parameter("global_position", global_position)
	pass


func update_neightbors() -> void:
	
	var i:= 0
	for idx in neightbors:
		if TerrainContext.has_chunk(idx):
			match i:
				0: TerrainContext.chunks[idx].set_shader({ BOTTOM_H = center_height })
				1: TerrainContext.chunks[idx].set_shader({ TOP_H    = center_height })
				2: TerrainContext.chunks[idx].set_shader({ RIGHT_H  = center_height })
				3: TerrainContext.chunks[idx].set_shader({ LEFT_H   = center_height })
		i += 1



func check_distance(camera_position: Vector3) -> void:

	var distance = camera_position.distance_to(center_position)
	var lod = LOD_min

	# this need to be same to terrain shader calc_LOD
	if distance > 1024:
		lod = LOD_min
	elif distance > 896:
		lod = 5
	elif distance > 640:
		lod = 4
	elif distance > 512:
		lod = 3
	elif distance > 256:
		lod = 2
	elif distance > 128:
		lod = 1
	else:
		lod = 0


	# if distance > 896:
	# 	mesh = LOD_meshes[LOD_min]
	# else:
	# 	if distance < 
		
	# 	for i: int in LOD_distance.size():
	# 		if distance < LOD_distance[i]:
	# 			lod = i
	# 			break

	mesh = LOD_meshes[lod]

	material_override.set_shader_parameter("camera_position", camera_position)
	material_override.set_shader_parameter("LOD", lod)

	pass


func update_collision() -> void:

	pass


func update_heightmap_region() -> void:
	var leaf_size:= TerrainContext.chunk_min_size
	var pos:= index * leaf_size
	var region_size:= Vector2(leaf_size + 1, leaf_size + 1)
	heightmap_region = heightmap.get_region(Rect2i(pos, region_size))

