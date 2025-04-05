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

uniform int LOD_TOP = 0;
uniform int LOD_BOTTOM = 0;
uniform int LOD_LEFT = 0;
uniform int LOD_RIGHT = 0;

float get_height(vec2 uv) {
	float value =  texture(heightmap, uv).r * height_scale;
	return value;
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

	float vertex_step = pixel * pow(2.0, float(LOD));

	// LOD
	if (VERTEX_ID % 2 != 0) {

		if (LOD_TOP > LOD) {
			if (UV2.y == 0.0) {
				VERTEX.y = calc_middle(UV, vec2(vertex_step, 0));
			}
		}

		if (LOD_BOTTOM > LOD) {
			if (UV2.y > 0.99) {
				VERTEX.y = calc_middle(UV, vec2(vertex_step, 0));
			}
		}

		if (LOD_LEFT > LOD) {
			if (UV2.x == 0.0) {
				VERTEX.y = calc_middle(UV, vec2(0, vertex_step));
			}
		}

		if (LOD_RIGHT > LOD) {
			if (UV2.x > 0.99) {
				VERTEX.y = calc_middle(UV, vec2(0, vertex_step));
			}
		}

	}
	
}

void fragment() {
	ALBEDO = texture(heightmap, UV).rrr;
	float edge = 0.04;

	NORMAL_MAP = texture(heightmap, UV).gba;

	if (UV2.x < edge || UV2.y < edge) {
		//ALBEDO = color;
		ALBEDO += vec3(1.,0,0);
	}

	if (LOD_TOP > LOD && UV2.y < edge) {
		ALBEDO = vec3(1.,0,0);
	}

	if (LOD_BOTTOM > LOD && UV2.y > 1.0 - edge) {
		ALBEDO = vec3(1.,0,1.);
	}

	if (LOD_LEFT > LOD && UV2.x < edge) {
		ALBEDO = vec3(0,1,0);
	}

	if (LOD_RIGHT > LOD && UV2.x > 1.0 - edge) {
		ALBEDO = vec3(0,0,1.);
	}

	//if (LOD_0 > 0) {
		//ALBEDO = vec3(0,0.4,0);
	//}
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
