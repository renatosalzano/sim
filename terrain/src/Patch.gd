class_name Patch extends MeshInstance3D

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
		

func _init(
	i: Vector2i,
	tile_i: Vector2i,
	global_i: Vector2i,

	_meshes: Array,
	_shader: Shader,
	_heightmap: ImageTexture,
	_heightmap_height: float
) -> void:

	index = i
	tile_index = tile_i
	meshes = _meshes
	min_lod = _meshes.size() - 1

	# print(global_index)


	# print(global_index)

	# var size:= 64

	

	for idx: int in 4:
		neightbors[idx] += global_i

	var level:= 5.0

	material_override = material
	material_override.shader = _shader

	material_override.set_shader_parameter("heightmap", _heightmap)
	material_override.set_shader_parameter("height_scale", _heightmap_height)
	material_override.set_shader_parameter("level", level)
	material_override.set_shader_parameter("index", tile_index)
	material_override.set_shader_parameter("is_tile", true)
	material_override.set_shader_parameter("min_LOD", min_lod)

	Store.patches[global_i] = self

	pass


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
	"LOD_BOTTOM",
	"LOD_TOP",
	"LOD_RIGHT",
	"LOD_LEFT",
]


func set_lod(lod: int, camera_position:= Vector3.ZERO) -> void:

	# printraw('\r update' + str(tile_index))

	for i: int in 4:
		# 0: bottom 1: top 2: right 3: left
		var neightbor:= neightbors[i]

		if Store.has_patch(neightbor):
			# Store.tiles[neightbor].neightbors_lod[p[i]] = lod
			match i:
				0: Store.patches[neightbor].set_shader({LOD_BOTTOM = lod})
				1: Store.patches[neightbor].set_shader({LOD_TOP = lod})
				2: Store.patches[neightbor].set_shader({LOD_RIGHT = lod})
				3: Store.patches[neightbor].set_shader({LOD_LEFT = lod})
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

