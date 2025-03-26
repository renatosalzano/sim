class_name Compute extends Object

var shader_data: RDShaderFile = preload("res://terrain/src/shader/hm_fnoise.glsl")

var rd: RenderingDevice

func _init() -> void:
	print(shader_data)

func gpu_heightmap(size:= 512, index:= Vector2(0,0)) -> Image:

	if rd == null:
		rd = RenderingServer.create_local_rendering_device()

	if rd == null:
		print('Error with rendering server')
		return

	var resize:= false
	var groups = Vector2i(size / 8, size / 8)
	var texture_size:= size
	var margin:= size % 8

	if margin != 0:
		resize = true
		var temp:= (size - margin) / 8
		texture_size = (size - margin) + temp
		groups =  Vector2i(texture_size / 8, texture_size / 8)

	
	var shader_spirv: RDShaderSPIRV = shader_data.get_spirv()
	var shader_rid:= rd.shader_create_from_spirv(shader_spirv)

	var hm_rid:= texture_rid(texture_size)
	var hm_uniform:= image_uniform(hm_rid)

	var data:= PackedFloat32Array([index.x, index.y, size])
	var data_bytes:= data.to_byte_array()
	var buffer:= rd.storage_buffer_create(data_bytes.size(), data_bytes)
	var data_buffer:= buffer_uniform(buffer)

	var uniform_set = rd.uniform_set_create([hm_uniform, data_buffer], shader_rid, 0)

	var pipeline = rd.compute_pipeline_create(shader_rid)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)


	# dimensione dell immagine / gruppi di lavoro
	rd.compute_list_dispatch(compute_list, groups.x, groups.y, 1)
	rd.compute_list_end()

	rd.submit()
	rd.sync()
	

	var output_bytes:= rd.texture_get_data(hm_rid, 0)

	var output := Image.create_from_data(texture_size, texture_size, false, Image.FORMAT_R8, output_bytes)

	if resize:
		var rect:= Rect2i(Vector2i(0, 0), Vector2i(size, size))
		var resized = output.get_region(rect)
		return resized
	
	return output


func texture_rid(size: int) -> RID:

	var hm_format:= RDTextureFormat.new()
	hm_format.format = RenderingDevice.DATA_FORMAT_R8_UNORM
	hm_format.width = size
	hm_format.height = size

	hm_format.usage_bits = \
			RenderingDevice.TEXTURE_USAGE_STORAGE_BIT + \
			RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + \
			RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var hm_rid:= rd.texture_create(hm_format, RDTextureView.new())
	return hm_rid


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

