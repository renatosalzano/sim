@tool
extends Node3D

var timer:= PrintTimer.new()

var loop:Array[Image]= []

@onready var collision: CollisionShape3D = $StaticBody3D/CollisionShape3D
@export_tool_button("Test") var test_btn = test;

func _ready() -> void:
	var size:= 1024
	var noise:= FastNoiseLite.new()
	var noise_image:= noise.get_image(size, size)
	noise_image.convert(Image.FORMAT_R8)

	for x in 2:
		for y in 2:
			var index:= Vector2(x,y)
			var region_size:= size / 4
			var pos:= index * region_size
			var region:= noise_image.get_region(Rect2i(pos, Vector2i(region_size, region_size)))
			loop.append(region)



	# var image:= Image.create(size, size, false, Image.FORMAT_R8)

	# var data:= image.get_data().to_float32_array()
	# timer.start()
	# collision.shape.update_map_data_from_image(noise_image, 0.0, 50.0)
	# timer.end('generated in')

var count:= 0
func test() -> void:
	var region:= loop[count]
	
	timer.start()
	collision.shape.update_map_data_from_image(region, 0.0, 50.0)
	timer.end('generated in')

	count += 1



class PrintTimer:
	var time:= 0

	func start() -> void:
		time = Time.get_ticks_msec()

	func end(message: StringName = "End in") -> void:
		var result:= Time.get_ticks_msec() - time
		message += " :{ms}ms".format({ ms=result })
		print(message)
		time = Time.get_ticks_msec()
