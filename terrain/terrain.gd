@tool
class_name Terrain extends Node3D

@export_group('Settings', 'set_')

@export var set_camera: Camera3D = null

@export var set_chunk:= Vector2i(2,2):
	set(value):
		if value.x > 0 && value.y > 0:
			set_chunk = value

@export var set_height:= 50.0:
	set(value): set_height = value;

@export var set_noise_layer: Array[FastNoiseLite] = [FastNoiseLite.new()]:
	set(value):
		if value.size() > 0:
			set_noise_layer = value
		else:
			set_noise_layer = [FastNoiseLite.new()]

@export_tool_button("Generate") var set_generate = generate;
# @export_tool_button("GPU COMPUTE") var set_gpu_compute = gpu_generate;
			
var camera_position:= Vector3.ZERO
var chunks:= Node3D.new()
var timer:= PrintTimer.new()


signal on_camera_move(position: Vector3)

func _ready() -> void:
	add_child(chunks)
	# generate()
		
	pass


func _process(_delta: float) -> void:
	if set_camera:
		if camera_position != set_camera.global_position:
			camera_position = set_camera.global_position
			# printraw('\r camera move')
			on_camera_move.emit(camera_position)


func generate() -> void:
	print("generate start")
	
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

	for x in set_chunk.x:
		for y in set_chunk.y:
			var index:= Vector2i(x,y)
			var hm_image:= compute.gpu_heightmap(2049, index)
			timer.start()
			var hm:= ImageTexture.create_from_image(hm_image)
			print(hm_image.get_size())
			timer.end('generate heightmap 2049')

			create_chunk.call_deferred(index, offset, meshes, hm)

			pass
	# hm.normal.save_jpg('res://hm_n.jpg')

	# var hm:= ImageTexture.new()

	# var test = Chunk.new(Vector2(0,0), meshes, hm)

	# add_child(test)

	
func create_chunk(index: Vector2i, offset: Vector2, meshes: Dictionary, heightmap: ImageTexture) -> void:

	var chunk:= Chunk.new(index, meshes, heightmap)

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