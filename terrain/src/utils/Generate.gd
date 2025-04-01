class_name Generate


static func chunk_mesh(size:= 2048, min_size:= 128, output:= [], level:= 0) -> Array:

	# TODO CHUNK LOD
	# print(level," ", size)
	var factor:= 64 / int(pow(2, level))

	var subdiv:= (size / factor) - 1

	var mesh:= grid_mesh(size, subdiv)

	output.append(mesh)

	size /= 2
	if size >= min_size:
		chunk_mesh(size, min_size, output, level + 1)

	return output


static func grid_mesh(size: int, subdiv: int) -> Mesh:

	var mesh:= PlaneMesh.new()
	mesh.subdivide_width = subdiv
	mesh.subdivide_depth = subdiv
	mesh.size = Vector2(size, size)
	mesh.add_uv2 = true

	mesh.custom_aabb.position = Vector3(-size / 2, -1500, -size / 2)
	mesh.custom_aabb.size = Vector3(size, 5000, size)

	return mesh


static func leaf_mesh(size:= 64) -> Array:

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