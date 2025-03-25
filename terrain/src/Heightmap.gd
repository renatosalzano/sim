class_name Heightmap

var size: int
var height_scale:= 50.
var offset:= Vector2i(0,0)

var image: Image
var normal: Image

var heightmap: ImageTexture
var heightmap_n: ImageTexture

var noise_layers: Array[FastNoiseLite]
var noise:= FastNoiseLite.new()
var noise2:= FastNoiseLite.new()

signal process


func _init(_size: int, _index: Vector2i, _noise_layers: Array[FastNoiseLite]) -> void:
	size = _size
	offset = _index * (size)
	image = Image.create_empty(size, size, false, Image.FORMAT_R8)
	normal = Image.create_empty(size, size, false, Image.FORMAT_RGB8)
	heightmap = ImageTexture.create_from_image(image)
	heightmap_n = ImageTexture.create_from_image(normal)

	noise_layers = _noise_layers


func create() -> void:

	# TODO
	# var cpu_count:= OS.get_processor_count()
	task_count = 4

	var chunks:= 2

	var _size:= (size - 1) / chunks
	print(_size)

	# var lt:= Time.get_ticks_msec()
	# var idx:= 0
	for y in chunks:
		for x in chunks:
			var index:= Vector2i(x,y)
			var x_size:int = _size + (1 if x == (chunks - 1) else 0)
			var y_size:int = _size + (1 if y == (chunks - 1) else 0)

			WorkerThreadPool.add_task(thread_region.bind(x_size, y_size, index))
			# idx += 1

	print('processing')
	await process

	heightmap.update(image)
	

var mutex:= Mutex.new()
var task_count:= 0


func thread_region(x_size: int, y_size: int, index: Vector2i) -> void:

	var region:= Image.create_empty(x_size, y_size, false, Image.FORMAT_R8)
	# var region_n:= Image.create_empty(x_size, y_size, false, Image.FORMAT_RGB8)

	var region_size:= Vector2i(x_size, y_size)
	var index_offset:= index * region_size

	for y: int in y_size:
		for x: int in x_size:

			var X:= float(x + index_offset.x + offset.x)
			var Y:= float(y + index_offset.y + offset.y)

			var value:= noise2.get_noise_2d(X, Y) * 0.5
			value += noise2.get_noise_2d(X, Y) * 0.5

			# value = (value + 1.0) * 0.5
			region.set_pixel(x,y, Color(value, 0, 0))

			# var normal_color: Color = n_color.call(X, Y)
			# region_n.set_pixel(x,y, normal_color)


	var pos_x:= x_size - (0 if x_size % 2 == 0 else 1)
	var pos_y:= y_size - (0 if y_size % 2 == 0 else 1)

	pos_x *= index.x
	pos_y *= index.y

	var rect := Rect2i(Vector2i(0, 0), region_size)
	image.blit_rect(region, rect, Vector2i(pos_x, pos_y))
	# normal.blit_rect(region_n, rect, Vector2i(pos_x, pos_y))

	mutex.lock()

	task_count -= 1
	# print("remaining task: {task}".format({ task=task_count }))
	# print(index)

	if task_count == 0:
		# print('done')
		process.emit()
	
	mutex.unlock()
	# DONE


# func normal_color(x: int, y: int):

# 	var h_sx = noise(x - 1, y)
# 	var h_dx = noise(x + 1, y)
# 	var h_tp = noise(x, y - 1)
# 	var h_bt = noise(x, y + 1)

# 	var dx = (h_dx - h_sx) * 0.5 * height_scale
# 	var dy = (h_tp - h_bt) * 0.5 * height_scale
# 	var dz = 1.0

# 	var n = Vector3(dx, dy, dz).normalized()
# 	var color = Color((n.x + 1.0) * 0.5, (n.y + 1.0) * 0.5, (n.z + 1.0) * 0.5)

# 	return color

