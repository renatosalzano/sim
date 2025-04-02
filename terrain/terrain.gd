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


var idx:= Vector2i(0,0)
var compute: Compute


func generate() -> void:
	# print("generate start")

	var tasks:= ProcessTask.new(self)
	idx = Vector2i(0,0)

	remove_child(chunks)
	chunks.queue_free()

	chunks = Node3D.new()

	var meshes:= {
		chunk = Generate.chunk_mesh(),
		leaf = Generate.leaf_mesh()
	}

	var offset:= Vector2(
		(set_chunk.x - 1) * -2048 / 2.0,
		(set_chunk.y - 1) * -2048 / 2.0
	)

	var task:= func(_i: int) -> void:

		if idx.y == set_chunk.y:
			idx.y  = 0
			idx.x += 1
		
		# print(index)
		var hm_image:= compute.gpu_heightmap(2049, idx)
		var heightmap:= ImageTexture.create_from_image(hm_image)
		# create_chunk(idx, offset, meshes, heightmap)
		create_chunk(idx, offset, meshes, heightmap)

		idx.y += 1

	
	tasks.set_task(set_chunk.x * set_chunk.y, task)

	tasks.end.connect(func():
		remove_child(tasks)
		tasks.queue_free()

		add_child(chunks)
	)

	tasks.start()
	
	pass


func create_chunk(index: Vector2i, offset: Vector2, meshes: Dictionary, heightmap: ImageTexture) -> void:

	var time = Time.get_ticks_msec()
	var chunk:= Chunk.new(index, meshes, heightmap, _height_scale)

	chunk.position = Vector3(
			offset.x + (index.x * 2048),
			0,
			offset.y + (index.y * 2048)
		)

	chunks.add_child(chunk)
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


class ProcessTask extends Node:

	var node: Node
	var current_task:= 0;
	var grid_size:= Vector2i(1,0)
	var index:= Vector2i(0, 0)

	var callback: Callable

	signal end

	var last_time:= ms()
	var tickrate:= 1000 / 10

	func ms() -> int:
		return Time.get_ticks_msec()


	func _init(_node: Node) -> void:
		node = _node


	func start() -> void:
		last_time = ms()
		node.add_child(self)


	func set_task(tasks_count: int, _callback: Callable) -> void:
		current_task = tasks_count
		callback = _callback


	func _process(_delta: float) -> void:

		if current_task == 0:
			end.emit()
			return

		if ms() - last_time > tickrate:
			last_time = ms()
			callback.call_deferred(current_task)
			current_task -= 1
		


class PrintTimer:
	var time:= 0

	func start() -> void:
		time = Time.get_ticks_msec()

	func end(message: StringName = "End in") -> void:
		var result:= Time.get_ticks_msec() - time
		message += " :{ms}ms".format({ ms=result })
		print(message)
		time = Time.get_ticks_msec()