@tool
class_name Terrain extends Node3D

@export_group('Settings', 'set_')

@export var set_camera: Camera3D = null

@export var set_chunk:= Vector2i(2,2):
	set(value):
		if value.x > 0 && value.y > 0:
			set_chunk = value
	
var _height_scale:= 0.05 * 1000.0
@export_range(0.0, 1.0, 0.01) var set_height:= 0.05:
	set(value):
		set_height = value
		_height_scale = value * 1000.0

@export var set_noise_layer: Array[FastNoiseLite] = [FastNoiseLite.new()]:
	set(value):
		if value.size() > 0:
			set_noise_layer = value
		else:
			set_noise_layer = [FastNoiseLite.new()]

@export_tool_button("Generate") var set_generate = generate;
@export_tool_button("Test") var test_btn = test;
# @export_tool_button("GPU COMPUTE") var set_gpu_compute = gpu_generate;

func test() -> void:

	# Store.tiles[Vector2i(10,10)].set_shader({LOD_0=5})
	Store.patches[Vector2i(0,0)].material_override.set_shader_parameter("LOD_0", 1)
	pass
			
var camera_position:= Vector3.ZERO
var chunks:= Node3D.new()
var timer:= PrintTimer.new()


signal on_camera_move(position: Vector3)

func _ready() -> void:
	add_child(chunks)

	for x in 1:
		for y in 1:
			print(set_noise_layer[0].get_noise_2d(float(x), float(y)))

	pass



func _process(_delta: float) -> void:
	if set_camera:
		if camera_position != set_camera.global_position:
			camera_position = set_camera.global_position
			# printraw('\r camera move')
			on_camera_move.emit(camera_position)



func generate() -> void:
	# print("generate start")
	
	var compute:= Compute.new()

	remove_child(chunks)
	chunks.queue_free()

	chunks = Node3D.new()

	add_child(chunks)

	var meshes:= {
		chunk = generate_chunk_mesh(),
		leaf = generate_leaf_mesh()
	}

	var offset:= Vector2(
		(set_chunk.x - 1) * -2048 / 2.0,
		(set_chunk.y - 1) * -2048 / 2.0
	)

	timer.start()

	for x in set_chunk.x:
		for y in set_chunk.y:
			var index:= Vector2i(x,y)
			var hm_image:= compute.gpu_heightmap(2049, index)
			var hm:= ImageTexture.create_from_image(hm_image)

			create_chunk.call_deferred(index, offset, meshes, hm)

			pass

	# Store.print_patches()

	timer.end('generated map')
	pass


func update_shader(params: Dictionary) -> void:

	if !is_node_ready():
		return

	timer.start()

	for chunk: Chunk in chunks.get_children():
		chunk.update_shader(params)
	
	timer.end("update map height")

	
func create_chunk(index: Vector2i, offset: Vector2, meshes: Dictionary, heightmap: ImageTexture) -> void:

	var chunk:= Chunk.new(index, meshes, heightmap, _height_scale)

	chunk.position = Vector3(
			offset.x + (index.x * 2048),
			0,
			offset.y + (index.y * 2048)
		)

	chunks.add_child(chunk)
	on_camera_move.connect(chunk.check_distance)


func generate_chunk_mesh(size:= 2048, min_size:= 512, output:= []) -> Array:

	var subdiv:= (size / 64) - 1

	var mesh:= grid_mesh(size, subdiv)

	output.append(mesh)

	size /= 2
	if size > min_size - 1:
		generate_chunk_mesh(size, min_size, output)

	return output
	

func generate_leaf_mesh(size:= 64) -> Array:

	var subdivisions: Array[int] = []
	var subdiv: int = size

	var i: int = 0

	while subdiv > 1:
		subdiv /= 1 if i == 0 else 2
		if subdiv - 1 >= 0:
			subdivisions.append(subdiv - 1)
		else:
			break
		
		i += 1

	# print(subdivisions)

	var lod_meshes = []
	lod_meshes.resize(subdivisions.size())

	for lod_index in lod_meshes.size():

		var mesh:= grid_mesh(size, subdivisions[lod_index])

		lod_meshes[lod_index] = mesh

	return lod_meshes


func grid_mesh(size: int, subdiv: int) -> Mesh:

	var mesh:= PlaneMesh.new()
	mesh.subdivide_width = subdiv
	mesh.subdivide_depth = subdiv
	mesh.size = Vector2(size, size)
	mesh.add_uv2 = true

	mesh.custom_aabb.position = Vector3(-size / 2, -1500, -size / 2)
	mesh.custom_aabb.size = Vector3(size, 5000, size)

	return mesh


class PrintTimer:
	var time:= 0

	func start() -> void:
		time = Time.get_ticks_msec()

	func end(message: StringName = "End in") -> void:
		var result:= Time.get_ticks_msec() - time
		message += " :{ms}ms".format({ ms=result })
		print(message)
		time = Time.get_ticks_msec()