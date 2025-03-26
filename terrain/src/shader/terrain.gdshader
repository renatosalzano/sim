shader_type spatial;

uniform float level;
uniform vec2 index;
uniform sampler2D heightmap: filter_nearest;
uniform float height_scale = 100.;

uniform bool is_tile;
uniform int LOD;
uniform int min_LOD;
uniform float max_distance_LOD;
uniform vec3 global_position;
uniform vec3 camera_position;

float get_height(vec2 uv) {
	float value =  texture(heightmap, uv).r * height_scale;
	value = pow(value, 1.4);
	return value;
}

int calc_LOD(vec3 next_tile) {
	float distance_to = distance(camera_position, next_tile);

	if (distance_to >= max_distance_LOD) {
		return min_LOD;
	}

	for (int x = 0; x <= min_LOD; ++x) {
		if (distance_to < float((x + 1) * 64)) {
			return x;
		}
	}

	return LOD;

}

bool LOD_is_lower(vec3 next_tile) {
	float distance_to = distance(camera_position, next_tile);

	if (distance_to >= max_distance_LOD) {
		return LOD < min_LOD;
	}

	for (int x = 1; x <= min_LOD; ++x) {
		if (distance_to < float(x * 64)) {
			return LOD < x;
		}
	}

	return false;

}

float calc_middle(vec2 uv, vec2 offset) {
	float h1 = get_height(vec2(uv.x - offset.x, uv.y - offset.y));
	float h2 = get_height(vec2(uv.x + offset.x, uv.y + offset.y));
	return mix(h1, h2, 0.5);
}

void vertex() {

	float pixel = 1.0 / 2049.;
	float half_pixel = pixel / 2.0;
	float factor = pow(2.0, level);

	float edges = 2048. / factor;

	int x = int(UV.x * float(edges));
    int y = int(UV.y * float(edges));

	vec2 offset = level > 0.0
		? index * (pixel * edges)
		: vec2(0,0);


	UV = offset + vec2(half_pixel, half_pixel) + vec2(float(x) * pixel, float(y) * pixel);

	VERTEX.y = get_height(UV);

	if (is_tile) {

		float vertex_step = pixel * pow(2.0, float(LOD));

		float distance_to = distance(camera_position, global_position);

		vec3 tile_top = global_position + vec3(0, 0, -64);
		vec3 tile_bottom = global_position + vec3(0, 0, 64);
		vec3 tile_left = global_position + vec3(-64, 0, 0);
		vec3 tile_right = global_position + vec3(64, 0, 0);

		// LOD
		if (VERTEX_ID % 2 != 0) {

			if (calc_LOD(tile_top) > LOD) {
				if (UV2.y == 0.0) {
					//float h1 = texture(heightmap, vec2(UV.x - vertex_step, UV.y)).r * height_scale;
					//float h2 = texture(heightmap, vec2(UV.x + vertex_step, UV.y)).r * height_scale;
					VERTEX.y = calc_middle(UV, vec2(vertex_step, 0));
				}
			}

			if (calc_LOD(tile_bottom) > LOD) {
				if (UV2.y > 0.99) {
					VERTEX.y = calc_middle(UV, vec2(vertex_step, 0));
				}
			}

			if (calc_LOD(tile_left) > LOD) {
				if (UV2.x == 0.0) {
					VERTEX.y = calc_middle(UV, vec2(0, vertex_step));
				}
			}

			if (calc_LOD(tile_right) > LOD) {
				if (UV2.x > 0.99) {
					VERTEX.y = calc_middle(UV, vec2(0, vertex_step));
				}
			}

		}
	}
}

void fragment() {


	ALBEDO = texture(heightmap, UV).rrr;
	float edge = 0.02;
	if (UV2.x < edge || UV2.y < edge) {
		//ALBEDO = color;
		ALBEDO += vec3(0,0.4,0);
	}
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
