class_name Compute extends Node

var shader_data: RDShaderFile = preload("res://terrain/src/shader/hm_fnoise.glsl")

var rd: RenderingDevice
var shader_rid: RID
var hm_rid: RID
# var buffer_rid: RID
# var uniform_set: RID
var pipeline: RID

var group_size:= 8
var groups:= Vector2i(8, 8) # da cambiare anche nel compute shader

var output_size: int
var texture_size: int
var resize_output:= false

var timer:= PrintTimer.new()

func init_rendering_device(_texture_size: int) -> void:

	rd = RenderingServer.create_local_rendering_device()

	if rd == null:
		print('Error with rendering server')
		return

	var shader_spirv: RDShaderSPIRV = shader_data.get_spirv()
	shader_rid = rd.shader_create_from_spirv(shader_spirv)

	groups = Vector2i(_texture_size / group_size, _texture_size / group_size)
	texture_size = _texture_size
	output_size = _texture_size

	var margin:= _texture_size % group_size

	if margin != 0:
		resize_output = true

		var temp:= (_texture_size - margin) / group_size
		texture_size = (_texture_size - margin) + temp
		groups =  Vector2i(texture_size / group_size, texture_size / group_size)

	hm_rid = texture_rid(texture_size)

	pipeline = rd.compute_pipeline_create(shader_rid)


func gpu_heightmap(_texture_size: int, index: Vector2i) -> void:

	if rd == null:
		# viene inizializzato RenderingDevice
		init_rendering_device(_texture_size)

	var hm_uniform:= image_uniform(hm_rid)

	var data:= PackedFloat32Array([index.x, index.y, output_size])

	var data_bytes:= data.to_byte_array()
	var buffer_rid = rd.storage_buffer_create(data_bytes.size(), data_bytes)
	var data_buffer:= buffer_uniform(buffer_rid)

	var uniform_set = rd.uniform_set_create([hm_uniform, data_buffer], shader_rid, 0)
	
	var compute_list := rd.compute_list_begin()

	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)


	# dimensione dell immagine / gruppi di lavoro
	rd.compute_list_dispatch(compute_list, groups.x, groups.y, 1)
	rd.compute_list_end()

	timer.start()
	rd.submit()
	rd.sync()
	timer.end("GPU SYNC")

	print(buffer_rid)
	print(uniform_set)

	var texture_data:= rd.texture_get_data(hm_rid, 0)
	timer.end("TEXTURE DATA")

	var output:= Image.create_from_data(texture_size, texture_size, false, Image.FORMAT_RGBAH, texture_data)

	rd.free_rid(buffer_rid)
	# rd.free_rid(uniform_set)

	if resize_output:
		var rect:= Rect2i(Vector2i(0, 0), Vector2i(output_size, output_size))
		output = output.get_region(rect)

	print("OUTPUT", output)
	print(" ")



func texture_rid(size: int) -> RID:

	var hm_format:= RDTextureFormat.new()
	# hm_format.format = RenderingDevice.DATA_FORMAT_R8_UNORM
	hm_format.format = RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT
	# hm_format.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	hm_format.width = size
	hm_format.height = size

	hm_format.usage_bits = \
			RenderingDevice.TEXTURE_USAGE_STORAGE_BIT + \
			RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + \
			RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var rid:= rd.texture_create(hm_format, RDTextureView.new())
	return rid


func image_uniform(rid: RID) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 0 # this needs to match the "binding" in our shader file
	uniform.add_id(rid)
	return uniform


func buffer_uniform(rid: RID) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 1
	uniform.add_id(rid)
	return uniform

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:

		if rd == null:
			return
		
		print('clean up')

		# All resources must be freed after use to avoid memory leaks.

		rd.free_rid(pipeline)
		rd.free_rid(hm_rid)
		rd.free_rid(shader_rid)

		rd.free()
		rd = null


class PrintTimer:
	var time:= 0

	func start() -> void:
		time = Time.get_ticks_msec()

	func end(message: StringName = "End in") -> void:
		var result:= Time.get_ticks_msec() - time
		message += " :{ms}ms".format({ ms=result })
		print(message)
		time = Time.get_ticks_msec()