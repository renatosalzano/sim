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

	compute = Compute.new()
	# compute.end.connect(compute_end)
	pass



func _process(_delta: float) -> void:
	if set_camera:
		if camera_position != set_camera.global_position:
			camera_position = set_camera.global_position
			# printraw('\r camera move')
			on_camera_move.emit(camera_position)



var compute: Compute
func generate() -> void:
	# print("generate start")

	remove_child(chunks)
	chunks.queue_free()

	chunks = Node3D.new()

	add_child(chunks)

	var meshes:= {
		chunk = Generate.chunk_mesh(),
		leaf = Generate.leaf_mesh()
	}

	var offset:= Vector2(
		(set_chunk.x - 1) * -2048 / 2.0,
		(set_chunk.y - 1) * -2048 / 2.0
	)
	

	for x in set_chunk.x:
		for y in set_chunk.y:
			var index:= Vector2i(x, y)
			
			# var end:= func(image: Image) -> void:
			# 	print("END COMPUTE ", index)
			# 	print(image)

			compute.gpu_heightmap(2049, index)

			# var hm_image:= compute.gpu_heightmap(2049, index)
			# var hm_image:= Image.create_empty(16,16,false, Image.FORMAT_RGBAF)
			# var hm:= ImageTexture.create_from_image(hm_image)
			# timer.end('compute texture')

			# create_chunk.call_deferred(index, offset, meshes, hm)
			# WorkerThreadPool.add_task(create_chunk.bind(index, offset, meshes, hm))

			pass

	# Store.print_patches()
	
	pass

func create_chunk(index: Vector2i, offset: Vector2, meshes: Dictionary, heightmap: ImageTexture) -> void:

	var time = Time.get_ticks_msec()
	var chunk:= Chunk.new(index, meshes, heightmap, _height_scale)

	chunk.position = Vector3(
			offset.x + (index.x * 2048),
			0,
			offset.y + (index.y * 2048)
		)

	chunks.add_child.call_deferred(chunk)
	# on_camera_move.connect(chunk.check_distance)
	print('end in ', Time.get_ticks_msec() - time)


func update_shader(params: Dictionary) -> void:

	if !is_node_ready():
		return

	timer.start()

	for chunk: Chunk in chunks.get_children():
		chunk.update_shader(params)
	
	timer.end("update map height")

	
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if compute is Compute:
			compute.queue_free()



class PrintTimer:
	var time:= 0

	func start() -> void:
		time = Time.get_ticks_msec()

	func end(message: StringName = "End in") -> void:
		var result:= Time.get_ticks_msec() - time
		message += " :{ms}ms".format({ ms=result })
		print(message)
		time = Time.get_ticks_msec()